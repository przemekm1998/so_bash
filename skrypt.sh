#!/bin/bash

# Wyswietlenie obecnej sciezki
echo_path() {
    echo "Wybrana sciezka: $path"
}

# Wybor opcji przez uzytkownika
show_choices() {
    echo -e "\n"
    echo 'MENU'
    echo '1. Podanie sciezki dzialania programu'
    echo '2. Wyswietl obecna sciezke'
    echo '3. Zajetosc dysku'
    echo '4. Uruchomione procesy przez uzytkownika'
    echo '5. Perdiodyczny zapis logow'
    echo '9. Wyjscie ze skryptu'
}

run_script=true # Warunek dzialania skryptu
path=$(pwd) # Domyslna sciezka zanim uzytkownik wprowadzi nowa

while [[ "$run_script" = true ]] ; do
    # Wybor opcji przez uzytkownika
    show_choices
    echo 'Podaj numer opcji'
    read choice

    # Podano niepoprawny numer opcji
    if ! [[ ${choice} =~ ^[0-9]?$ ]] ; then
        echo 'Niepoprawna opcja'

    # Wybor sciezki dzialania skryptu
    elif [[ "$choice" -eq "1" ]] ; then
        echo 'WYBOR SCIEZKI'
        echo 'Podaj sciezke'
        read path
        echo_path

    # Obecna sciezka
    elif [[ "$choice" -eq "2" ]] ; then
        echo_path

    # Zajetosc dysku
    elif [[ "$choice" -eq "3" ]] ; then
        echo 'ZAJETOSC DYSKU'
        df -h

    # Procesy zalogowanego uzytkownika
    elif [[ "$choice" -eq "4" ]] ; then
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
    elif [[ "$choice" -eq "5" ]] ; then
        # Wczytanie nazwy pliku do zapisywania logow
        echo 'Podaj nazwe pliku do jakiego chcesz zapisywac logi'
        read filename

        # Wczytanie parametrow ktore maja byc zapisywane
        echo 'Podaj jakie parametry chcesz zapisywac do logow'
        echo '0. Zalogowani uzytkownicy'
        echo '1. Obciazanie dysku'
        echo 'Cyfry podawaj po przecinku w formacie: 0, 1, ...'
        read params

        IFS=', ' read -r -a array <<< "$params" # Wczytanie parametrow do tablicy

        # Wczytanie czestotliwosci zapisu
        echo 'Podaj czestotliwosc z jaka chcesz zapisywac logi, pamietaj o formacie crontab'
        echo '* * * * *'
        echo 'minuta(0-59) godzina(0-23) dzien_miesiaca(1-31) miesiac(1-12) dzien_tygodnia(0-6)'
        echo '"*" = dla kazdej wartosci'
        read schedule

        # Wczytanie obecnej tablicy cron
        crontab -l > mycron
        echo "${schedule} date -u >> ${path}/${filename}" >> mycron # Zapis daty logow

        # Zapisanie wybranych polecen do crontab
        for index in "${!array[@]}"
        do
            if ! [[ ${index} =~ ^[0-9]?$ ]] ; then
                echo 'Niepoprawny parametr'
            elif [[ "$index" -eq "0" ]] ; then
                echo "${schedule} w >> ${path}/${filename}" >> mycron
            elif [[ "$index" -eq "1" ]] ; then
                echo "${schedule} df -h >> ${path}/${filename}" >> mycron
            fi
        done

        # Zapisanej nowej tablicy cron
        crontab mycron
        rm mycron

    # Wyjscie ze skryptu
    elif [[ "$choice" -eq "9" ]] ; then
        run_script=false
    fi
done


