#!/bin/bash

### Globale Variablen

# Pfad zum Script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# Version
VERSION_NUMBER="0.1"

# Variablen um die Logik mit dem Operatoren zu realisieren
__ADD_ARG=0
__ADD_VALUE=""
__DATE_ARG=0
__DATE_VALUE=""
__SHOW_WEEK_ARG=0
__SHOW_ARG=0
__SHOW_ID_ARG=0
__CHANGE_ARG=0
__CHANGE_VALUE=""
__ID_ARG=false
__ID_VALUE=""
__DELETE_ARG=false
__CREATE_ARG=false

### Laden der Konfigdatei

# Konfigdateien werden geladen. Wenn eine eigene Konfigdatei existiert, wird diese geladen
if [ -f "/etc/abheft/abheft.conf" ];then
    source /etc/abheft/abheft.conf
else
    source $SCRIPT_DIR/../conf/abheft.conf
fi

### Funktionen

function log {
    log_number=$1
    log_message=$2

    if [ "$log_number" -ge "$CONF_LOGLEVEL" ]; then
        log_type="DEBUG"

        case $log_number in
            1)  log_type="DEBUG" ;;
            2)  log_type="INFO " ;;
            3)  log_type="ERROR" ;;
        esac

        echo "$(date +'%Y.%m.%d %X') [$log_type]: $log_message" >> $CONF_PATH_LOGFILE
    fi
}

# Erwarteter Returncode - Fehlermeldung - fin?
function log_case {
    result=$?
    erwarteter_returncode=$1
    fehlermeldung=$2
    exec_fin=$3

    # TODO echo_value=$4,
    # TODO Damit könnte auch eine Echo Meldung angezeigt werden, muss aber überprüft werden, ob dieser Parameter angegeben wird.

    if [ "$result" != "$erwarteter_returncode" ]; then
        log 3 "$fehlermeldung - Returncode vom Befehl: $result"
        if [ "$exec_fin" == true ]; then
            fin 3 2
        fi
    fi
}

function print_help {
    log 1 "Function - print_help"

    echo -e "NAME\n\tAzubi-Berichtsheft\n"
    
    echo -e "SYNOPSIS\n\tabheft [OPTION]...\n"
    
    echo -e "DESCRIPTION"
    echo -e "\t-h, --help\n\t\tzeige die Hilfe an.\n"
    echo -e "\t-v, --version\n\t\tzeige die Version an.\n"
    echo -e "\t-a, --add=STRING\n\t\tWenn -d nicht gesetzt, wird STRING für heute als Eintrag in die Datenbank eingetragen.\n\t\tWenn -d gesetzt ist, wird STRING für das Datum in -d in die Datenbank eingetragen.\n"    
    echo -e "\t-d, --date=DATE\n\t\tLegt für aktuellen Befehl ein Datum fest.\n"
    echo -e "\t--show-week\n\t\tWenn -d nicht gesetzt, werden die Einträge der aktuellen Woche angezeigt.\n\t\tWenn -d gesetzt, werden die Einträge der Woche von -d angezeigt.\n"
    echo -e "\t--show\n\t\tWenn -d nicht gesetzt, werden die Einträge von heute angezeigt.\n\t\tWenn -d gesetzt, werden die Einträge von -d angezeigt.\n"
    echo -e "\t--show-id\n\t\tFunktioniert nur mit --show-week oder --show.\n\t\tZeigt die ID der Einträge an.\n"
    echo -e "\t--change=STRING\n\t\tFunktioniert nur zusammen mit --id.Ändert den Wert von Eintrag --id in STRING.\n"
    echo -e "\t--id=INT\n\t\tFunktioniert nur zusammen mit --change oder --delete.\n\t\tSetzt die ID des Eintrages, der zu bearbeiten oder löschen ist.\n"
    echo -e "\t--delete\n\t\tFunktioniert nur zusammen mit --id.\n\t\tLöscht den Eintrag --id aus der Datenbank.\n"
    echo -e "\t--create\n\t\tWenn -d nicht gesetzt, wird der Bericht der aktuellen Woche erstellt.\n\t\tWenn -d gesetzt, wird der Bericht der Woche von -d erstellt.\n"
}

function print_version {
    log 1 "Function - print_version"

    echo "Script um ein Berichtsheft zu erstellen."
    echo "Version $VERSION_NUMBER"
}

function fin {
    logcode=$1
    exitcode=$2

    log $logcode "Script wurde beendet, Returncode: $exitcode"
    exit $exitcode
}

function add_entry_to_db {
    log 1 "Function - add_entry_to_db - [$1|$2]"

    eintrag=$1
    datum=$2

    mysql_command="INSERT INTO eintraege (datum, eintrag) VALUES ('$(date -d "$datum" +%Y-%m-%d)', '$eintrag');"
    mysql --login-path=abheft --port="$CONF_DB_PORT" --database="$CONF_DB_DBNAME" --execute="$mysql_command"
    log_case 0 "MySQL Befehl konnte nicht ausgeführt werden" true
}

function print_entries_of_week {
    log 1 "Function - print_entries_of_week - [$1|$2]"

    datum=$1
    id=$2

    case $(date -d "$datum" +%w) in
        0) monday=$(date -d "$datum - 6 days" +%Y-%m-%d) ;;
        1) monday=$(date -d "$datum - 0 days" +%Y-%m-%d) ;;
        2) monday=$(date -d "$datum - 1 days" +%Y-%m-%d) ;;
        3) monday=$(date -d "$datum - 2 days" +%Y-%m-%d) ;;
        4) monday=$(date -d "$datum - 3 days" +%Y-%m-%d) ;;
        5) monday=$(date -d "$datum - 4 days" +%Y-%m-%d) ;;
        6) monday=$(date -d "$datum - 5 days" +%Y-%m-%d) ;;
    esac

    log 1 "Montag ist der $(date -d "$monday" +%d.%m.%Y)"

    for i in {0..4}; do
        echo "$(date -d "$monday + $i days" +%A) - $(date -d "$monday + $i days" +%d.%m.%Y)"

        if [ "$id" == false ]; then
            mysql_command="SELECT eintrag FROM eintraege WHERE datum='$(date -d "$monday + $i days" +%Y-%m-%d)';"
        else
            mysql_command="SELECT id, eintrag FROM eintraege WHERE datum='$(date -d "$monday + $i days" +%Y-%m-%d)';"
        fi

        if [ "$(mysql --login-path=abheft --port="$CONF_DB_PORT" --database="$CONF_DB_DBNAME" -N -s --execute="$mysql_command")" != "" ]; then
            mysql --login-path=abheft --port="$CONF_DB_PORT" --database="$CONF_DB_DBNAME" -N -s --execute="$mysql_command" | sed 's/^/- /'
            log_case 0 "MySQL Befehl konnte nicht ausgeführt werden" true
        else
            echo "- Kein Eintrag"
        fi
    done
}

function print_entries_of_day {
    log 1 "Function - print_entries_of_day - [$1|$2]"

    datum=$1
    id=$2

    echo "$(date -d "$datum" +%A) - $(date -d "$datum" +%d.%m.%Y)"
    if [ "$id" == false ]; then
        mysql_command="SELECT eintrag FROM eintraege WHERE datum='$(date -d "$datum" +%Y-%m-%d)';"
    else
        mysql_command="SELECT id, eintrag FROM eintraege WHERE datum='$(date -d "$datum" +%Y-%m-%d)';"
    fi
    
    if [ "$(mysql --login-path=abheft --port="$CONF_DB_PORT" --database="$CONF_DB_DBNAME" -N -s --execute="$mysql_command")" != "" ]; then
        mysql --login-path=abheft --port="$CONF_DB_PORT" --database="$CONF_DB_DBNAME" -N -s --execute="$mysql_command" | sed 's/^/- /'
        log_case 0 "MySQL Befehl konnte nicht ausgeführt werden" true   
    else
        echo "- Kein Eintrag"
    fi
}

function change_entry_of_day {
    log 1 "Function - change_entry_of_day - [$1|$2]"

    id=$1
    neuerWert=$2

    mysql_command="UPDATE eintraege SET eintrag='$neuerWert' WHERE id='$id';"
    mysql --login-path=abheft --port="$CONF_DB_PORT" --database="$CONF_DB_DBNAME" -N -s --execute="$mysql_command"
    log_case 0 "MySQL Befehl konnte nicht ausgeführt werden" true
}

function delete_entry_of_day {
    log 1 "Function - delete_entry_of_day - [$1]"

    id=$1

    mysql_command="DELETE FROM eintraege WHERE id='$id';"
    mysql --login-path=abheft --port="$CONF_DB_PORT" --database="$CONF_DB_DBNAME" -N -s --execute="$mysql_command"
    log_case 0 "MySQL Befehl konnte nicht ausgeführt werden" true
}

function fill_report_days {
    log 1 "Function - fill_report_days - [$1|$2]"

    datum=$1
    platzhaltername=$2

    mysql_command="SELECT eintrag FROM eintraege WHERE datum='$datum';"
    result=""
    i=0

    # Prüfen, ob MySQL Befehl funktionieren würde
    mysql --login-path=abheft --port="3306" --database="abheft" -N -s --execute="$mysql_command" 2>1&>/dev/null
    log_case 0 "MySQL Befehl konnte nicht ausgeführt werden" true

    while IFS=$'\t' read zeile; do
        eintrag[$i]=$zeile
        ((i++))
    done < <(mysql --login-path=abheft --port="3306" --database="abheft" -N -s --execute="$mysql_command")
    
    for (( e=0; e<$i; e++ )); do
        if [ "$e" -eq 0 ];then
            result="${eintrag[$e]}"
        else
            result="$result; ${eintrag[$e]}"
        fi
    done

    # In $result steht eine "0", wenn es für den Tag keine Einträge in der DB gibt.
    # Damit nicht 0 im Report eingefügt wird, wird der Fall abgefangen
    if [ "$result" == "0" ]; then
        result=""
    fi

    sed -i "s/%%${platzhaltername}%%/$result/g" /tmp/abreport/word/document.xml
    log_case 0 "Sed Befehl konnte nicht ausgeführt werden" false
}

function create_report_of_week {
    log 1 "Function - create_report_of_week - [$1]"

    datum=$1

    case $(date -d "$datum" +%w) in
        0) monday=$(date -d "$datum - 6 days" +%Y-%m-%d) ;;
        1) monday=$(date -d "$datum - 0 days" +%Y-%m-%d) ;;
        2) monday=$(date -d "$datum - 1 days" +%Y-%m-%d) ;;
        3) monday=$(date -d "$datum - 2 days" +%Y-%m-%d) ;;
        4) monday=$(date -d "$datum - 3 days" +%Y-%m-%d) ;;
        5) monday=$(date -d "$datum - 4 days" +%Y-%m-%d) ;;
        6) monday=$(date -d "$datum - 5 days" +%Y-%m-%d) ;;
    esac

    log 1 "Montag ist der $(date -d "$monday" +%d.%m.%Y)"

    # tmp Ordner erstellen
    mkdir /tmp/abreport
    log_case 0 "mkdir /tmp/abreport konnte nicht ausgeführt werden" true
    # Template in tmp Ordner unzippen
    unzip -qq $CONF_PATH_TEMPLATE_REPORT -d /tmp/abreport
    log_case 0 "unzip konnte nicht ausgeführt werden" true
    # Platzhalter ersetzen
    sed -i "s/%%NAME%%/$CONF_REPORT_NAME/g" /tmp/abreport/word/document.xml
    sed -i "s/%%AUSBILDUNGSJAHR%%/$CONF_REPORT_YEAR/g" /tmp/abreport/word/document.xml
    sed -i "s/%%ABTEILUNG%%/$CONF_REPORT_DEPARTMENT/g" /tmp/abreport/word/document.xml
    sed -i "s/%%VON%%/$(date -d "$monday" +%d.%m.%Y)/g" /tmp/abreport/word/document.xml
    sed -i "s/%%BIS%%/$(date -d "$monday + 4 days" +%d.%m.%Y)/g" /tmp/abreport/word/document.xml
    
    fill_report_days $(date -d "$monday" +%Y-%m-%d) "MONTAG"
    fill_report_days $(date -d "$monday + 1 days" +%Y-%m-%d) "DIENSTAG"
    fill_report_days $(date -d "$monday + 2 days" +%Y-%m-%d) "MITTWOCH"
    fill_report_days $(date -d "$monday + 3 days" +%Y-%m-%d) "DONNERSTAG"
    fill_report_days $(date -d "$monday + 4 days" +%Y-%m-%d) "FREITAG"

    # Dateien zippen
    cd /tmp/abreport
    zip --quiet -r $CONF_PATH_REPORTS/$(date -d "$monday" +%Y%m%d).docx .
    log_case 0 "zip konnte nicht ausgeführt werden" true
    # Ordner in tmp löschen
    rm -Rf /tmp/abreport
    if [ "$?" != "0" ]; then
        log 3 "rm -Rf /tmp/abreport konnte nicht ausgeführt werden - Returncode vom Befehl: $?"
        echo "/tmp/abreport konnte nicht gelöscht werden. Achtung beim erneuten Ausführen des Scriptes!"
    fi

    echo "Bericht der Woche vom $(date -d "$monday" +%d.%m.%Y) bis einschließlich $(date -d "$monday + 4 days" +%d.%m.%Y) wurde erstellt."
    log 2 "Bericht für die Woche $(date -d "$monday" +%d.%m.%Y) - $(date -d "$monday + 4 days" +%d.%m.%Y) wurde erstellt"
}

function check_if_programm_is_installed {
    programm=$1

    command -v $programm &> /dev/null
    if [ "$?" != "0" ]; then
        log 3 "$programm ist nicht installiert - Returncode vom Befehl: $?"
        echo "$programm ist nicht installiert!"
        fin 3 4
    else
        log 1 "$programm ist installiert"
    fi
}

### Scriptstart

argumente=$@
log 2 "abheft.sh wurde von $(whoami) mit den Optionen \"$argumente\" gestartet"

# Prüfen, ob benötigte Programme installiert sind
check_if_programm_is_installed "mysql"
check_if_programm_is_installed "zip"
check_if_programm_is_installed "unzip"

# Prüft, ob Parameter richtig sind
if [ "$(echo $?)" != 0 ]; then
    fin 3 1
fi

# Parameter werden geladen
options=$(getopt -l "help,version,add:,date:,show-week,show,show-id,change:,id:,delete,create" -o "hva:d:" -a -- "$@")
eval set -- "$options"

# Parameter werden ausgeführt
while true; do
    case $1 in
        -h|--help)
            print_help
            fin 2 0
            ;;
        -v|--version)
            print_version
            fin 2 0
            ;;
        -a|--add)
            shift
            __ADD_ARG=1
            __ADD_VALUE="$1"
            ;;
        -d|--date)
            shift
            __DATE_ARG=1
            __DATE_VALUE=$1
            ;;
        --show-week)
            __SHOW_WEEK_ARG=1
            ;;
        --show)
            __SHOW_ARG=1
            ;;
        --show-id)
            __SHOW_ID_ARG=1
            ;;
        --change)
            shift
            __CHANGE_ARG=1
            __CHANGE_VALUE=$1
            ;;
        --id)
            shift
            __ID_ARG=true
            __ID_VALUE=$1
            ;;
        --delete)
            __DELETE_ARG=true
            ;;
        --create)
            __CREATE_ARG=true
            ;;
        --)
            shift
            break
            ;;
    esac

    shift
done

# Eintrag in Datenbank wird entsprechend der Optionen durchgeführt
if [ "$__ADD_ARG" == 1 ] && [ "$__DATE_ARG" == 1 ]; then
    add_entry_to_db "$__ADD_VALUE" "$__DATE_VALUE"
elif [ "$__ADD_ARG" == 1 ]; then
    add_entry_to_db "$__ADD_VALUE" "$(date +'%Y-%m-%d')"
fi

# Show-week wird entsprechend der Optionen durchgeführt
if [ "$__SHOW_WEEK_ARG" == 1 ] && [ "$__DATE_ARG" == 1 ] && [ "$__SHOW_ID_ARG" == 1 ]; then
    print_entries_of_week "$__DATE_VALUE" true
elif [ "$__SHOW_WEEK_ARG" == 1 ] && [ "$__DATE_ARG" == 1 ]; then
    print_entries_of_week "$__DATE_VALUE" false
elif [ "$__SHOW_WEEK_ARG" == 1 ] && [ "$__SHOW_ID_ARG" == 1 ]; then
    print_entries_of_week "$(date +'%Y-%m-%d')" true
elif [ "$__SHOW_WEEK_ARG" == 1 ]; then
    print_entries_of_week "$(date +'%Y-%m-%d')" false
fi

# Show wird entsprechend der Optionen durchgeführt
if [ "$__SHOW_ARG" == 1 ] && [ "$__DATE_ARG" == 1 ] && [ "$__SHOW_ID_ARG" == 1 ]; then
    print_entries_of_day "$__DATE_VALUE" true
elif [ "$__SHOW_ARG" == 1 ] && [ "$__DATE_ARG" == 1 ]; then
    print_entries_of_day "$__DATE_VALUE" false
elif [ "$__SHOW_ARG" == 1 ] && [ "$__SHOW_ID_ARG" == 1 ]; then
    print_entries_of_day "$(date +'%Y-%m-%d')" true
elif [ "$__SHOW_ARG" == 1 ]; then
    print_entries_of_day "$(date +'%Y-%m-%d')" false
fi

# Eintrag nur ändern, wenn --id gesetzt ist!
if [ "$__ID_ARG" == true ] && [ "$__CHANGE_ARG" == 1 ]; then
    change_entry_of_day "$__ID_VALUE" "$__CHANGE_VALUE"
fi

# Eintrag nur löschen, wenn --id gesetzt ist!
if [ "$__ID_ARG" == true ] && [ "$__DELETE_ARG" == true ]; then
    delete_entry_of_day "$__ID_VALUE"
fi

# Berichtsheft nur erstellen, wenn -d gesetzt ist!
if [ "$__DATE_ARG" == 1 ] && [ "$__CREATE_ARG" == true ]; then
    create_report_of_week "$__DATE_VALUE"
elif [ "$__CREATE_ARG" == true ]; then
    create_report_of_week "$(date +'%Y-%m-%d')"
fi

fin 2 0