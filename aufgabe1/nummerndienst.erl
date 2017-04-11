-module(nummerndienst).
-export([initND/0, getNextNNr/3]).

initND() ->
	0.
	
getNextNNr(CurrentNNr, ClientPID, LogFile) ->
	werkzeug:logging(LogFile, lists:concat(["Sende Nachricht ",integer_to_list(CurrentNNr+1)," an Client ",pid_to_list(ClientPID),".~n"])),
	ClientPID ! {nid, CurrentNNr+1},
	CurrentNNr+1.
