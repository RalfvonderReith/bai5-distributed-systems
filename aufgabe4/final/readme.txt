Starten der Anwendungen:
java -jar <Anwendung>

Compiler: java -jar idl_compiler_jar/idl_compiler.jar <idl filename>
NameServer: java -jar nameserver_jar/nameserver.jar
Server: java -jar server_jar/server.jar <ip> <port>
Client: java -jar client_jar/client.jar <ip> <port>

Bei Bedarf können beim NameServer, Client und Server über config files Einstellungen vorgenommen werden
(jeweils als *.config Datei im Ordner beiliegend).

Falls über den Compiler neue Dateien kompiliert werden und man diese benutzen will, so muss der Quellcode des
Clients und Servers angepasst werden.