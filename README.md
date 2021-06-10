# ABheft
Azubi-Berichtsheft

## Beschreibung
Mit diesem Script kann man Einträge für bestimmte Tage in eine Datenbank pflegen und Wochenberichte erstellen.

## Installation
### Anforderungen
- Linux (entwickelt und getestet mit WSL2 Ubuntu 20.04)
- MySQL 5.7 Server oder höher
- Rechte um eine Datenbank und ein User erstellen zu können.
- Folgende Programme
  - mysql
  - zip
  - unzip

### Installieren
#### Datenbank
* Datenbank erstellen
* User erstellen
* User auf Datenbank berechtigen
##### MySQL
```shell
mysql -u root -p
```
```mysql
CREATE DATABASE abheft;
CREATE USER 'abheft'@'%' IDENTIFIED BY 'TOPSECRETPASSWORD';
GRANT ALL PRIVILEGES ON abheft.* TO 'abheft'@'%';
EXIT;
```

## Platzhalter
Platzhalter sind dazu da um sie ins Bericht-Template einzutragen, die dann mittels dem Befehl `./abheft.sh --create` mit Werten aus der Datenbank ersetzt werden.
Es gibt folgende Platzhalter:
- %%NAME%%
- %%AUSBILDUNGSJAHR%%
- %%ABTEILUNG%%
- %%VON%%
- %%BIS%%
- %%MONTAG%%
- %%DIENSTAG%%
- %%MITTWOCH%%
- %%DONNERSTAG%%
- %%FREITAG%%

## Beispiele
```shell
# Zeige Einträge der aktuellen Woche
./abheft.sh --show-week

# Füge Eintrag zum 09.06.2021 hinzu
./abheft.sh -a "Testeintrag" -d "20210609"

# Erstelle Bericht der aktuellen Woche
./abheft.sh --create
```

## Parameter

- `-h, --help`
  - Zeige die Hilfe an.
- `-v, --version`
  - Zeige die Version an.
- `-a, --add=STRING`
  - Wenn `-d` nicht gesetzt, wird `STRING` für heute als Eintrag in die Datenbank eingetragen.
    Wenn `-d` gesetzt ist, wird `STRING` für das Datum in `-d` in die Datenbank eingetragen.
- `-d, --date=DATE`
  - Legt für aktuellen Befehl ein Datum fest.
- `--show-week`
  - Wenn `-d` nicht gesetzt, werden die Einträge der aktuellen Woche angezeigt.
    Wenn `-d` gesetzt, werden die Einträge der Woche von `-d` angezeigt.
- `--show`
  - Wenn `-d` nicht gesetzt, werden die Einträge von heute angezeigt.
    Wenn `-d` gesetzt, werden die Einträge von `-d` angezeigt.
- `--show-id`
  - Funktioniert nur mit `--show-week` oder `--show`.
    Zeigt die ID der Einträge an.
- `--change=STRING`
  - Funktioniert nur zusammen mit `--id`. Ändert den Wert von Eintrag `--id` in `STRING`.
- `--id=INT`
  - Funktioniert nur zusammen mit `--change` oder `--delete`.
    Setzt die ID des Eintrages, der zu bearbeiten oder löschen ist.
- `--delete`
  - Funktioniert nur zusammen mit `--id`.
    Löscht den Eintrag `--id` aus der Datenbank.
- `--create`
  - Wenn `-d` nicht gesetzt, wird der Bericht der aktuellen Woche erstellt.
    Wenn `-d` gesetzt, wird der Bericht der Woche von `-d` erstellt.
