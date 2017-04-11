-module(server).
-export([start/0]).

%TODO: logging
start() -> 
	io:format("Starte Server ...~n", []),
	
	io:format("Lese Config ...~n", []),
	ConfigFile = "server.cfg",
	
	{ok, ConfigListe} = file:consult(ConfigFile),
	{ok, ClientLifeTime} = werkzeug:get_config_value(clientlifeTime, ConfigListe),
	{ok, Latency} = werkzeug:get_config_value(latency, ConfigListe),
	{ok, ServerName} = werkzeug:get_config_value(servername, ConfigListe),
	{ok, HBQNode} = werkzeug:get_config_value(hbqnode, ConfigListe),
	{ok, HBQName} = werkzeug:get_config_value(hbqname, ConfigListe),
	
	{ok, HostName} = inet:gethostname(),
	LogFile = lists:concat(["Server@",HostName,".log"]),
	
	io:format("Verbinde zu HBQ Node ~w ...~n", [HBQNode]),
	Ping = net_adm:ping(HBQNode),
	
	io:format("initialisiere HBQ... ",[]),
	{HBQName, HBQNode} ! {self(), {request, initHBQ}},
	receive
		{reply, ok} ->
			io:format("Erfolgreich!~n",[]);
		{reply, alredy_initialized} ->
			io:format("Ok. Bereits Initialisiert!~n",[]);
		_Any ->
			error("HBQ_not_found")
	end,
	io:format("~w~n", [Ping]),
	timer:sleep(1000),
	
	register(ServerName,self()),
	
	CMEM = cmem:initCMEM(ClientLifeTime, LogFile),
	CurrentNNr = nummerndienst:initND(),
	
	io:format("Server Bereit.~n", []),
	communication(CurrentNNr, CMEM, null, Latency, LogFile, {HBQName, HBQNode}).
	
	%TODO:
	%load config
	%contact hbq or initialize it, if not already done
	
communication(CurrentNNr, CMEM, Timer, Latency, LogFile, HBQ) ->
	cmem:updateCMEM(CMEM), 
	NEW_Timer = werkzeug:reset_timer(Timer, Latency, shutdown),
	io:format("waiting for message...",[]),
	receive 
		{PID, getmessages} -> 
			io:format("received getmessages~n.",[]),
			io:format("CMEM: ~p~n",[CMEM]),
			NNr = cmem:getClientNNr(CMEM, PID),
			HBQ ! {self(), {request, deliverMSG, NNr, PID}},
			receive
				{reply, SentNNr} ->
					NEW_CMEM = cmem:updateClient(CMEM, PID, SentNNr, LogFile)
			end,
			io:format("NEW CMEM: ~p~n",[NEW_CMEM]),
			%dadurch, dass die rückmeldung der HBQ nicht die ClientPID enthält, muss ich hier explizit auf die antwort warten... alternative?
			communication(CurrentNNr, NEW_CMEM, NEW_Timer, Latency, LogFile, HBQ);
		{PID, getmsgid} ->
			io:format("received getmsgid~n.",[]),
			communication(nummerndienst:getNextNNr(CurrentNNr, PID, LogFile), CMEM, NEW_Timer, Latency, LogFile, HBQ);
		{dropmessage, [NNr, Msg, TSclientout]} ->
			io:format("received dropmessage: ~w~n.",[NNr]),
			HBQ ! {self(), {request, pushHBQ, [NNr, Msg, TSclientout]}},
			communication(CurrentNNr, CMEM, NEW_Timer, Latency, LogFile, HBQ);
		shutdown ->
			io:format("received shutdown~n.",[]),
			shutdown(HBQ, LogFile);
		Any -> 
			io:format("received ~w~n.",[Any]),
			werkzeug:logging(LogFile, lists:concat(["Server: Unerwartete Nachricht.~n"])),
			communication(CurrentNNr, CMEM, NEW_Timer, Latency, LogFile, HBQ)
	end.
		
shutdown(HBQ, LogFile) ->
	HBQ ! {self(), {request,dellHBQ}},
	receive
		{reply,ok} -> 
			werkzeug:logging(LogFile, lists:concat(["Server: Beende Server und HBQ: ",werkzeug:timeMilliSecond(),".~n"]))
	end.
