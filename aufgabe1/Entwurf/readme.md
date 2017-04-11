#Server and HBQ
#how to start server and hbq:

1. set a name for hbq and server in server.cfg
2. look up node name of node, which shall host the hbq and set it in server.cfg - for information on this, see erlang documentation
3. compile all server related files (server, cmem, nummerndienst, dlq, hbq)
4. start hbq node on server with hbq:start()
5. start server on servernode with server:start()

example:
shell for hbq:
1. erl -sname hbq -setcookie somecookie
-> the cursor will be prepended with the node name
2. c(hbq).
3. c(dlq).
4. hbq:start().

shell for server:
1. erl -sname server -setcookie somecookie
-> the cursor will be prepended with the node name
2. c(cmem).
3. c(server).
4. c(nummerndienst).
5. server:start().

for testing without a client:
shell for client:
1. erl -sname cl -setcookie somecookie
2. ping(servernodename)
3. {servername, servernodename} ! <some request> (e.g. <some request> = {self(), getmsgid}
