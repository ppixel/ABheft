#!/bin/bash

### Funktionen

function fin {
    exitcode=$1

    echo "Installer wird beendet, Returncode: $exitcode"
    exit $exitcode
}

function check_if_programm_is_installed {
    programm=$1

    command -v $programm &> /dev/null
    if [ "$?" != "0" ]; then
        echo "$programm ist nicht installiert!"
        fin 1
    else
        echo "$programm ist installiert"
    fi
}

### Scriptstart

# Prüfen ob benötigte Programm installiert sind
check_if_programm_is_installed "mysql"
check_if_programm_is_installed "mysql_config_editor"
check_if_programm_is_installed "zip"
check_if_programm_is_installed "unzip"

# User Daten abfragen
echo "MySQL Login-Path wird gesetzt."
echo "Host:"
read __db_host
echo "Port:"
read __db_port
echo "User:"
read __db_user

# mysql login-path setzen
echo "Passwort für den MySQL Login-Path:"
mysql_config_editor set --login-path=abheft --host=$__db_host --port=$__db_port --user=$__db_user --password