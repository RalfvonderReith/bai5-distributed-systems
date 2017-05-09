--------------------
Compilieren der Dateien:
--------------------
Zu dem Paket gehören die Dateien
ggt.erl; koordinator.erl; starter.erl, nameservice.beam; werkzeug.erl

sowie:
readme.txt; koordinator.cfg; ggt.cfg

(w)erl -(s)name wk -setcookie zummsel
1> make:all().

koordinator.cfg
--------------------
Vor Starten des Koordinators sollten folgende Werte in koordinator.cfg konfiguriert werden:
% {arbeitszeit, 1}. Die Zeit, die ein GGT Prozess mindestens braucht, um eine Berechnung durchzuführen
% {termzeit, 6}. Wenn ein GGT diese Zeit lang keine Nachricht durch setpm/sendy bekommen hat, startet er eine Terminierungsumfrage
% {ggtprozessnummer, 2}. Die Anzahl der GGTs, die pro Starter gestartet werden
% {nameservicenode, 'ns@Brummpa'}. Der Name der nameservice node
% {nameservicename, nameservice}. Der Name, mit dem sich der nameservice registriert
% {koordinatorname, chef}. Der Name, mit dem sich der Koordinator registriert
% {quote, 80}. Die Quote in Prozent die nötig ist, damit eine Terminierungsumfrage erfolgreich ist
% {korrigieren, true}. Sofern der Koordinator ein kleineres Mi hat, als das durch briefterm Gesendete, wird er bei true dieses an den GGT Prozess senden
und bei false nur als Fehler loggen.

ggt.cfg
--------------------
% in der client.cfg:
% {praktikumsgruppe, 4}. Die Praktikumsgruppe (bei uns 1). Wird zur Benennung der GGTs benutzt
% {teamnummer, 88}. Die Teamnummer (bei uns 5). Wird zur Benennung der GGTs benutzt
% {nameservicenode, 'ns@Brummpa'}. Der Name der nameservice node
% {nameservicename, nameservice}. Der Name, mit dem sich der nameservice registriert
% {koordinatorname, chef}. Der Name, mit dem sich der Koordinator registriert


Starten des Namensdienstes:
--------------------
(w)erl -(s)name ns@<myIP> -setcookie zummsel
1> nameservice:start().

Starten des Koordinators:
--------------------
(w)erl -(s)name ko@<myIP> -setcookie zummsel
1> koordinator:start().

Starten der Starter:
--------------------
(w)erl -(s)name st@<myIP> -setcookie zummsel
1> starter:start(<StarterNumber>)

Interaktion:
--------------------
Der Koordinator kann mit mehreren Befehlen angesprochen werden. Das funktioniert dabei wie folgt:
(w)erl -(s)name cmd@<myIP> -setcookie zummsel
1> {<koordinatorName>, <koordinatorNode>} ! <Befehl>
Mit den oben genannten config Dateien sehe das so aus:
1> {chef, 'ns@Brummpa'} ! <Befehl>

% TODO
Folgende Befehle sind vorgesehen:
- reset:
- step:
- prompt:
- nudge:
- toggle:
- kill:
- {calc, WggT}:

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
