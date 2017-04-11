--------------------
Compilieren der Dateien:
--------------------
Zu dem Paket gehören die Dateien
client.erl; cmem.erl; dlq.erl; hbq.erl; nummerndienst.erl;
server; werkzeug.erl;

sowie:
Readme.txt; client.cfg; server.cfg

(w)erl -(s)name wk -setcookie zummsel
1> make:all().

Server.cfg
--------------------
Vor Starten des Servers und der HBQ sollten folgende Werte in server.cfg konfiguriert werden:
% {latency, 60}. Zeit in Sekunden, die der Server bei Leerlauf wartet, bevor er sich beendet
% {clientlifetime,5}. Zeitspanne, in der sich an den Client erinnert wird
% {servername, wk}. Name des Servers als Atom
% {hbqname, hbq}. Name der HBQ als Atom
% {hbqnode, 'hbqNode@KI-VS'}. Name der Node der HBQ als Atom
% {dlqlimit, 13}. Größe der DLQ

Information:
hbqnode - muss vor dem Starten des Servers konfiguriert werden und muss dem Namen entsprechen, 
mit dem die Erlang-Shell gestartet wird, in der die hbq ausgeführt werden soll.

Starten der HB-DLQ:
--------------------
(w)erl -(s)name hbdlq@<myIP> -setcookie zummsel
1> hbq:start()

Starten des Servers:
--------------------
Information: Die HBQ muss gestartet sein, bevor der Server gestartet wird, 
da Letzterer während der Initialisierung versucht, eine Verbindung zur HBQ herzustellen.

(w)erl -(s)name server@<myIP> -setcookie zummsel
1> server:start().
--------------------
Starten des Clients:
--------------------
(w)erl -(s)name client -setcookie zummsel
1> client:start().
% Im Falle von name: client@IP benutzen.

% 'server@lab33.cpt.haw-hamburg.de': Name der Server Node, erhält man zB über node()
% ' wegen dem - bei haw-hamburg, da dies sonst als minus interpretiert wird.
% in der client.cfg:
% {clients, 2}.  Anzahl der Clients, die gestartet werden sollen
% {lifetime, 42}. Laufzeit der Clients
% {servername, wk}. Name des Servers
% {servernode, 'server@KI-VS'}. Node des Servers
% {sendeintervall, 3}. Zeitabstand der einzelnen Nachrichten

Runterfahren:
-------------
2> Ctrl/Strg Shift G
-->q

Informationen zu Prozessen:
-------------
2> process_info(PID).
2> observer:start().

Informationen zum manuellen Testen des Servers:
-------------
(w)erl -(s)name cl -setcookie zummsel
1> ping(<servernodename>)
	-> pong
2> {<servername>, <servernodename>} ! <some request> (e.g. <some request> = {self(), getmsgid})
