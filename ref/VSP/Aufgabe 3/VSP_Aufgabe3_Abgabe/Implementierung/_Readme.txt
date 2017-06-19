Bemerkung:
Ueberpruefen Sie zuerst, ob alle *.sh Skripte und STDMAsniffer ausfuehrbar sind

Starten der Stationen:
--------------------------
startStations.sh Skript ausfuehren:
./startStations.sh eth2 225.10.1.2 15000 1 1 A 5

Das Skript wird die Stationen und die Datenquelle initialisieren. Somit wird die STDMA-Simulation gestartet.

Parameters:
#  network interface
#  multicast address
#  receive port
#  index of first station
#  index of last station
#  class of stations started (A or B)
#  UTC offset (ms)

Die Anzahl von Stationen laesst sich von 1 bis 25 einstellen.
Das Interface koennen Sie mit Hilfe von `inet:getifaddrs()` aus dem Erlang Shell entnehmen.

Kontrolle:
--------------------------
Sniffer starten:
./STDMAsniffer 225.10.1.2 15000 eth2 -adapt > sniffer.log

Runterfahren:
-------------
pkillAllStations.sh Skript ausfuehren:
./pkillAllStations.sh

Das Skript wird alle Erlang-Prozesse beenden. Somit werden alle Stationen terminiert.