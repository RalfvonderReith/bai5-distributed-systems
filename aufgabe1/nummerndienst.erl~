-module(nummerndienst).
-export([initND/0, getNextNNr/3]).

initND() ->
	0.

%generiere fortlaufende Nummern nach ensprechend #01	
getNextNNr(CurrentNNr, ClientPID, LogFile) ->
	werkzeug:logging(LogFile, lists:concat(["Sende Nachrichtennummer ",integer_to_list(CurrentNNr+1)," an Client ",pid_to_list(ClientPID),".\r\n"])),
	ClientPID ! {nid, CurrentNNr+1},
	CurrentNNr+1.
