-module(server).
-export([start/0]).

%TODO: logging
start() -> 
	io:format("Starte Server ...\r\n", []),
	
	io:format("Lese Config ...\r\n", []),
	ConfigFile = "server.cfg",
	
	{ok, ConfigListe} = file:consult(ConfigFile),
	{ok, ClientLifeTime} = werkzeug:get_config_value(clientlifeTime, ConfigListe),
	{ok, Latency} = werkzeug:get_config_value(latency, ConfigListe),
	{ok, ServerName} = werkzeug:get_config_value(servername, ConfigListe),
	{ok, HBQNode} = werkzeug:get_config_value(hbqnode, ConfigListe),
	{ok, HBQName} = werkzeug:get_config_value(hbqname, ConfigListe),
	
	{ok, HostName} = inet:gethostname(),
	LogFile = lists:concat(["Server@",HostName,".log"]),
	
	io:format("Verbinde zu HBQ Node ~w ...\r\n", [HBQNode]),
	Ping = net_adm:ping(HBQNode),
	
	io:format("initialisiere HBQ... ",[]),
	{HBQName, HBQNode} ! {self(), {request, initHBQ}},
	receive
		{reply, ok} ->
			io:format("Erfolgreich!\r\n",[]);
		{reply, alredy_initialized} ->
			io:format("Ok. Bereits Initialisiert!\r\n",[]);
		_Any ->
			error("HBQ_not_found")
	end,
	io:format("~w\r\n", [Ping]),
	timer:sleep(1000),
	
	% #10
	register(ServerName,self()),
	
	CMEM = cmem:initCMEM(ClientLifeTime, LogFile),
	CurrentNNr = nummerndienst:initND(),
	
	io:format("Server Bereit.\r\n", []),
	communication(CurrentNNr, CMEM, null, Latency, LogFile, {HBQName, HBQNode}).
	
	%TODO:
	%load config
	%contact hbq or initialize it, if not already done
	
communication(CurrentNNr, CMEM, Timer, Latency, LogFile, HBQ) ->
	cmem:updateCMEM(CMEM), 
	%Server terminiert, wenn für bestimmte Zeit keine Anfragen mehr reinkommen #07
	NEW_Timer = werkzeug:reset_timer(Timer, Latency, shutdown),
	io:format("waiting for message...",[]),
	receive 
		{PID, getmessages} -> 
			io:format("received getmessages\r\n.",[]),
			io:format("CMEM: ~p\r\n",[CMEM]),
			NNr = cmem:getClientNNr(CMEM, PID),
			HBQ ! {self(), {request, deliverMSG, NNr, PID}},
			receive
				{reply, SentNNr} when is_integer(SentNNr) ->
					NEW_CMEM = cmem:updateClient(CMEM, PID, SentNNr, LogFile)
			end,
			io:format("NEW CMEM: ~p\r\n",[NEW_CMEM]),
			%dadurch, dass die rückmeldung der HBQ nicht die ClientPID enthält, muss ich hier explizit auf die antwort warten... alternative?
			communication(CurrentNNr, NEW_CMEM, NEW_Timer, Latency, LogFile, HBQ);
		{PID, getmsgid} -> %vergebe Nummern entsprechend #01
			io:format("received getmsgid\r\n.",[]),
			communication(nummerndienst:getNextNNr(CurrentNNr, PID, LogFile), CMEM, NEW_Timer, Latency, LogFile, HBQ);
		{dropmessage, [NNr, Msg, TSclientout]} ->
			io:format("received dropmessage: ~w\r\n.",[NNr]),
			HBQ ! {self(), {request, pushHBQ, [NNr, Msg, TSclientout]}},
			communication(CurrentNNr, CMEM, NEW_Timer, Latency, LogFile, HBQ);
		shutdown ->
			io:format("received shutdown\r\n.",[]),
			shutdown(HBQ, LogFile);
		{reply, ok} ->
			communication(CurrentNNr, CMEM, NEW_Timer, Latency, LogFile, HBQ);
		Any -> 
			io:format("received ~w\r\n.",[Any]),
			werkzeug:logging(LogFile, lists:concat(["Server: Unerwartete Nachricht.\r\n"])),
			communication(CurrentNNr, CMEM, NEW_Timer, Latency, LogFile, HBQ)
	end.
		
shutdown(HBQ, LogFile) ->
	HBQ ! {self(), {request,dellHBQ}},
	receive
		{reply,ok} -> 
			werkzeug:logging(LogFile, lists:concat(["Server: Beende Server und HBQ: ",werkzeug:timeMilliSecond(),".\r\n"]))
	end.
