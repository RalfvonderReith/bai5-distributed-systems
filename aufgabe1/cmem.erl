-module(cmem).
-export([initCMEM/2, delCMEM/1, updateClient/4, getClientNNr/2, updateCMEM/1]).

%TODO: LOGGING!

initCMEM(RemTime, LogFile) ->
	werkzeug:logging(LogFile, "CMEM: Initialisiere CMEM\r\n"),
	{RemTime, []}.
	
delCMEM(_CMEM) ->
	ok.
	
updateClient(CMEM, ClientID, NNr, LogFile) ->
	{RemTime, CList} = CMEM,
	updateClientHelper(RemTime, [], CList, ClientID, NNr, LogFile).
%check each entry of the CList
%replace the entry if found:
updateClientHelper(RemTime, Checked, [{ClientID, _NR, _TimeStamp}|Rest], ClientID, NNr, LogFile) ->
	werkzeug:logging(LogFile, lists:concat(["CMEM: updating client ",pid_to_list(ClientID)," - Next Message: ",integer_to_list(NNr),".\r\n"])),
	{RemTime, lists:concat([Checked, [{ClientID, NNr, erlang:system_time(seconds)}], Rest])};
	%TODO: set Timer
updateClientHelper(RemTime, Checked, [FirstEntry|Rest], ClientID, NNr, LogFile) ->
	updateClientHelper(RemTime, lists:append(Checked, [FirstEntry]), Rest, ClientID, NNr, LogFile);
%if there is no entry for ClientID, append it.
updateClientHelper(RemTime, Checked, [], ClientID, NNr, LogFile) ->
	werkzeug:logging(LogFile, lists:concat(["CMEM: adding client ",pid_to_list(ClientID)," - Next Message: ",integer_to_list(NNr),".\r\n"])),
	{RemTime, lists:append(Checked, [{ClientID, NNr, erlang:system_time(seconds)}])}.
	%TODO:set timer

%get next NNr for Client
getClientNNr({_RemTime, [{ClientID, NR, _TimeStamp}|_Rest]}, ClientID) ->
	NR+1;
getClientNNr({_RemTime, [_FirstEntry|Rest]}, ClientID) ->	
	getClientNNr({_RemTime, Rest}, ClientID);
%if there is no entry for the clientID, return 1
getClientNNr({_RemTime, []}, _ClientID) ->
	1.
	
updateCMEM({RemTime, CList}) ->
	updateCMEMHelper(RemTime, [], CList).
%check each entry of CMEM recursively
updateCMEMHelper(RemTime, Checked, [{ClientID, NR, TimeStamp}|Rest]) ->
	CurrentTime = erlang:system_time(seconds),
	if
		(CurrentTime - TimeStamp) < (RemTime) ->
			updateCMEMHelper(RemTime, lists:concat([Checked,[{ClientID, NR, TimeStamp}]]), Rest),
			io:format("updating ~w~n.",[ClientID]);
		true ->
			updateCMEMHelper(RemTime, Checked, Rest),
			io:format("forgetting ~w~n.",[ClientID])
	end;
%done, return new CMEM
updateCMEMHelper(RemTime, Checked, []) -> 
	{RemTime, Checked}.
