Starten der Anwendungen:
java -jar <Anwendung>

Compiler: java -jar compiler.jar <idl filename>
NameServer: java -jar nameserver/nameserver.jar
Server: java -jar server/server.jar
Client: java -jar server/client.jar

Bei Bedarf können beim NameServer, Client und Server über config files Einstellungen vorgenommen werden
(jeweils als *.config Datei im Ordner beiliegend).

Falls über den Compiler neue Dateien kompiliert werden und man diese benutzen will, so muss der Quellcode des
Clients und Servers angepasst werden.