#!/bin/bash

run_script=true # Warunek dzialania skryptu
path=$(pwd) # Domyslna sciezka zanim uzytkownik wprowadzi nowa

# Wyswietlenie obecnej sciezki
echo_path() {
    echo "Wybrana sciezka: $path"
}

# Wyswietlenie plikow z obecnej sciezki
echo_files() {
        echo "LISTA PLIKOW W $path"
        ls -l
}

# Wybor opcji przez uzytkownika
show_choices() {
    echo -e "\n"
    echo 'OPCJE PROGRAMU'
    echo '1. Podanie sciezki dzialania programu'
    echo -e "2. Wyswietl obecna sciezke\n"
    echo 'FUNKCJE JEDNORAZOWE'
    echo '3. Zajetosc dysku'
    echo '4. Backup partycji'
    echo -e "5. Uruchomione procesy przez uzytkownika\n"
    echo 'LOGI I ZADANIA PERIODYCZNE'
    echo '6. Perdiodyczny zapis logow'
    echo '7. Wyswietl wykonywane periodycznie polecenia'
    echo -e "8. Edytuj wykonywane periodycznie polecenia\n"
    echo 'PLIKI W KATALOGU'
    echo '9. Lista plikow w katalogu'
    echo '10. Odczytaj plik w katalogu'
    echo -e "11. Edytuj plik w katalogu\n"
    echo '0. Wyjscie ze skryptu'
}

while [[ "$run_script" = true ]] ; do
    # Wybor opcji przez uzytkownika
    show_choices
    echo 'Podaj numer opcji'
    read choice

    # Podano niepoprawny numer opcji
    if ! [[ ${choice} =~ ^([0-9]|1[01])$ ]] ; then
        clear
        echo 'Niepoprawna opcja'

    # Wybor sciezki dzialania skryptu
    elif [[ "$choice" -eq "1" ]] ; then
        clear
        echo 'WYBOR SCIEZKI'
        echo 'Podaj sciezke'
        read temp_path
        if [[ -d "$temp_path" ]]
            then
                echo "$temp_path istnieje."
                path=${temp_path}
            else
                echo "Error: $temp_path nie istnieje."
            fi
        echo_path

    # Obecna sciezka
    elif [[ "$choice" -eq "2" ]] ; then
        clear
        echo_path

    # Zajetosc dysku
    elif [[ "$choice" -eq "3" ]] ; then
        clear
        echo 'ZAJETOSC DYSKU'
        df -h | grep ^/dev

    # Backup partycji
    elif [[ "$choice" -eq "4" ]] ; then
        clear
        echo 'BACKUP PARTYCJI'
        echo 'Komenda zakomentowana w kodzie, bo backup partycji troche by trwal :)'
        echo 'tar -cvjf backup.tar.bzip2 --exclude=/backup.tar.bzip2 --one-file-system /'
#        tar -cvjf backup.tar.bzip2 --exclude=/backup.tar.bzip2 --one-file-system /

    # Procesy zalogowanego uzytkownika
    elif [[ "$choice" -eq "5" ]] ; then
        clear
        echo 'ZALOGOWANI UZYTKOWNICY'

        users="$(who | cut -d ' ' -f 1)" # Wyciecie listy zalogowanych uzytkownikow
        IFS=$'\n' read -r -a array <<< "$users" # Wczytanie uzytkownikow do tablicy

        # Wyswietlenie listy uzytkownikow z tablicy
        for index in "${!array[@]}"
        do
            echo "${index}. ${array[index]}" # numer. uzytkownik
        done

        echo 'Podaj numer uzytkownika ktorego procesy chcesz wyswietlic'
        read user_number

        echo "Procesy uzytkownika ${array[user_number]}"
        top -u ${array[user_number]}

    # Operacje periodyczne
    elif [[ "$choice" -eq "6" ]] ; then
        clear
        # Wczytanie nazwy pliku do zapisywania logow
        echo 'Podaj nazwe pliku do jakiego chcesz zapisywac logi'
        read filename

        # Wczytanie parametrow ktore maja byc zapisywane
        echo 'Podaj jakie parametry chcesz zapisywac do logow'
        echo '0. Zalogowani uzytkownicy'
        echo '1. Obciazanie dysku'
        echo '2. Backup partycji'
        echo 'Cyfry podawaj po przecinku w formacie: 0, 1, ...'
        read params

        IFS=', ' read -r -a array <<< "$params" # Wczytanie parametrow do tablicy

        # Wczytanie czestotliwosci zapisu
        echo 'Podaj czestotliwosc z jaka chcesz zapisywac logi, pamietaj o formacie crontab'
        echo '* * * * *'
        echo 'minuta(0-59) godzina(0-23) dzien_miesiaca(1-31) miesiac(1-12) dzien_tygodnia(0-6)'
        echo '"*" = dla kazdej wartosci'
        echo '"*/5" = co 5 wartosc, np co 5 minut'
        read schedule

        # Wesole sprawdzanie poprawnosci skladni czasu polecenia crontab
        # Sprawdzone na https://regex101.com/
        if [[ "$schedule" =~ ^(([0-9]|[1-4][0-9]|5[0-9])|\*|\*\/([0-9]|[1-4][0-9]|5[0-9]))\ (([0-9]|1[0-9]|2[0-3])|\*|\*\/([0-9]|1[0-9]|2[0-3]))\ (([1-9]|[12][0-9]|3[01])|\*|\*\/([1-9]|[12][0-9]|3[01]))\ (([1-9]|1[0-2])|\*|\*\/([1-9]|1[0-2]))\ (([0-6])|\*|\*\/([0-6]))$ ]] ; then
            crontab -l > mycron  # Wczytanie obecnej tablicy cron
            echo "${schedule} date -u >> ${path}/${filename}" >> mycron  # Zapis daty logow

            # Zapisanie wybranych polecen do crontab
            for index in "${!array[@]}"
            do
                if ! [[ ${index} =~ ^[0-9]?$ ]] ; then
                    echo 'Niepoprawny parametr'
                elif [[ "$index" -eq "0" ]] ; then
                    echo "${schedule} w >> ${path}/${filename}" >> mycron  # Lista zalogowanych uzytkownikow
                elif [[ "$index" -eq "1" ]] ; then
                    echo "${schedule} df -h | grep ^/dev >> ${path}/${filename}" >> mycron  # Zajetosc dysku
                elif [[ "$index" -eq "2" ]] ; then
                    echo "${schedule} tar -cvjf backup.tar.bzip2 --exclude=/backup.tar.bzip2 --one-file-system / >> ${path}/${filename}" >> mycron  # Backup partycji
                fi
            done

            crontab mycron  # Zapisanej nowej tablicy cron
            rm mycron  # Usuniecie pomocniczej zmiennej
        else
            echo 'Niepoprawny format czestotliwosci wykonywania polecen'
        fi

    # Obecnie wykonywane periodycznie polecenia
    elif [[ "$choice" -eq "7" ]] ; then
        clear
        crontab -l

    # Edycja periodycznych operacji
    elif [[ "$choice" -eq "8" ]] ; then
        clear
        crontab -e

    # Lista plikow w katalogu
    elif [[ "$choice" -eq "9" ]] ; then
        clear
        echo_files

    # Wyswietlanie pliku w katalogu
    elif [[ "$choice" -eq "10" ]] ; then
        clear
        echo_files # Wyswietlenie listy plikow

        # Pobranie nazwy pliku do przeczytania
        echo 'PODAJ PLIK DO ODCZYTANIA'
        read filename

        FILE=${path}/${filename}

        if [[ -f "$FILE" ]] ; then
            cat ${filename} # Wyswietlenie pliku, jezeli istnieje
        else
            echo "$filename nie istnieje w katalogu $path" # Komunikat jezeli plik nie istnieje
        fi

    # Edycja pliku w katalogu
    elif [[ "$choice" -eq "11" ]] ; then
        clear
        echo_files # Wyswietlenie listy plikow

        # Pobranie nazwy pliku do przeczytania
        echo 'PODAJ PLIK DO EDYCJI'
        read filename

        file=${path}/${filename}

        if [[ -f "$file" ]] ; then
            vi ${filename} # Edycja pliku jezeli istnieje
        else
            echo "$filename nie istnieje w katalogu $path" # Komunikat jezeli plik nie istnieje
        fi

    # Wyjscie ze skryptu
    elif [[ "$choice" -eq "0" ]] ; then
        clear
        run_script=false
    fi
done


