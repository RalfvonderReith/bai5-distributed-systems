-module(hbq).
-compile(dlq).
-compile(io_lib).
-export([start/0]).

-define(LogFile, "hb-dlq.log").

%%%
%HBQ-DATA
%HBQ = {SIZE, [MSGN, ...,MSG2, MSG1]}
%MSG = [NNr, MSG-CONTENT, TSClientout, TSHBQin]
%%%

-define(HBDLQ_FACTOR, 2/3).

start() -> 
	ConfigFile = "server.cfg",
	
	{ok, HostName} = inet:gethostname(),
	LogFile = lists:concat(["HB_DLQ@",HostName,".log"]),
	
	{ok, ConfigListe} = file:consult(ConfigFile),
	{ok, HBQName} = werkzeug:get_config_value(hbqname, ConfigListe),
	{ok, DLQSize} = werkzeug:get_config_value(dlqlimit, ConfigListe),

	io:format("started HB-DLQ on ~w@~w.~n",[HBQName, werkzeug:to_String(HostName)]),

	register(HBQName,self()),
	io:format("registered this process~w@~w as ~w~n",[self(), erlang:node(), HBQName]),
	initCommunication(DLQSize, LogFile).

initCommunication(DLQSize, LogFile) ->
	io:format("waiting for messsages to receive"),
	receive
		{PID, {request, initHBQ}} ->
			%create hbq and dlq
			io:format("hbq: received initHBQ~n"),
			NEW_HBQ = initHBQ(DLQSize * ?HBDLQ_FACTOR, LogFile), 
			NEW_DLQ = dlq:initDLQ(DLQSize, LogFile),
			PID ! {reply, ok},
			communication(NEW_HBQ, NEW_DLQ, LogFile);
		Any ->
			io:format("hqb: received unexpected message: ~p~n", [Any]),
			initCommunication(DLQSize, LogFile)
	end.

communication(HBQ, DLQ, LogFile) ->
	receive
		{PID, {request, pushHBQ, [NNr, Msg, TSclientout]}} ->
			io:format("received pushHBQ: ~w...~n", [NNr]), 
			%save message into hbq
			{NEW_HBQ, NEW_DLQ} = pushHBQ([NNr, Msg, TSclientout], HBQ, DLQ, LogFile),
			PID ! {reply, ok},
			io:format("HBQ: ~p~nDLQ: ~p~n",[NEW_HBQ, NEW_DLQ]),
			communication(NEW_HBQ, NEW_DLQ, LogFile);
		{PID, {request, deliverMSG, NNr, ToClient}} ->
			io:format("received deliverMSG: ~w...~n",[NNr]),
			%get message from dlq
			SentNNr = dlq:deliverMSG(NNr, ToClient, DLQ, LogFile),
			PID ! {reply, SentNNr},
			communication(HBQ, DLQ, LogFile);
		{PID, {request, dellHBQ}} ->
			io:format("received dellHBQ...~n",[]),
			%quit hbq
			ok = dlq:delDLQ(DLQ),
			werkzeug:logging(LogFile, "HBQ: closing HBQ and DLQ~n"),
			PID ! {reply, ok};
		{PID, {request, initHBQ}} ->	
			io:format("received initHBQ...~n",[]),
			PID ! {reply, alredy_initialized}, 
			communication(HBQ, DLQ, LogFile);
		Any ->
			io:format("HBQ: received unexpected message: ~p~n", [Any]),
			communication(HBQ, DLQ, LogFile)
	end.
	
%initialize HBQ and DLQ
initHBQ(HBQLimit, LogFile) ->
	werkzeug:logging(LogFile, "HBQ: initialising HBQ."),
	{HBQLimit, []}.

pushHBQ([NNr, Msg, TSclientout], {HBQSize, HBQList}, DLQ, LogFile) ->
	%append timestamp
	Message = [NNr, Msg, TSclientout, erlang:now()],
	werkzeug:logging(LogFile,io_lib:format("HBQ: Nachricht ~w in HBQ eingefuegt~n",[NNr])),
	%sort it into list!
	NewHBQList = insertIntoHBQ(Message, HBQList),
	checkHBQ({HBQSize, NewHBQList}, DLQ, LogFile).

%insert a message into HBQ
%list contains highest number first
insertIntoHBQ(Message, HBQList) ->
	insertIntoHBQHelper(Message, [], HBQList).
%if number is bigger than everything in the list, prepend it.
insertIntoHBQHelper(Message, Checked, []) ->
	[Message|Checked];
insertIntoHBQHelper(Message, Checked, HBQList) ->
	[MsgNr, _Msg, _TSco, _TShbqin] = Message, 
	Last = lists:last(HBQList),
	Rest = lists:droplast(HBQList),
	[LastNr|_Other] = Last,
	%if element is smaller than smallest element of listToCheck -> append it to this list and prepend it to checked 
	if
		MsgNr < LastNr ->
			lists:concat([HBQList, [Message], Checked]);
		MsgNr > LastNr ->
			insertIntoHBQHelper(Message, [Last|Checked], Rest)
	end.
	
%if HBQ is empty, return empty HBQ and unchanged DLQ
checkHBQ({HBQSize, []}, DLQ, LogFile) -> 
	werkzeug:logging(LogFile, "HBQ: HBQ is empty.~n"),
	{{HBQSize, []}, DLQ};
checkHBQ(HBQ, DLQ, LogFile) ->
	%get expected Number from DLQ
	Expected = dlq:expectedNr(DLQ),
	{HBQSize, HBQList} = HBQ,
	%get first message
	[NNr, Msg, TSco, TShbqin] = lists:last(HBQList),
	if
		%expected number is bigger than last message number of HBQ -> drop last message as it is too old and check next message
		NNr < Expected ->
			checkHBQ({HBQSize, lists:droplast(HBQList)}, DLQ, LogFile);
		%expected number equals last message number of HBQ -> push it through into DLQ and check next message.
		NNr == Expected ->
			NEW_DLQ = dlq:push2DLQ([NNr, Msg, TSco, TShbqin], DLQ, LogFile),
			checkHBQ({HBQSize, lists:droplast(HBQList)}, NEW_DLQ, LogFile);
		%expected number is smaller than last message number of HBQ -> check length of hbq and if needed, create replacement message
		NNr > Expected ->
			checkHBQLength(HBQ, DLQ, LogFile)
	end.
	
%checks length of HBQ and perhaps creates a replacement message, which is pushed into dlq. 
checkHBQLength(HBQ, DLQ, LogFile) ->
	{HBQSize, HBQList} = HBQ,
	HBQLength = length(HBQList),
	Expected = dlq:expectedNr(DLQ),
	if
		HBQSize < HBQLength ->
			[NNr, _Msg, _TSco, _TShbqin] = lists:last(HBQList),
			werkzeug:logging(LogFile, io_lib:format("HBQ: Nachrichten ~w bis ~w durch Fehlernachricht ersetzt~n",[Expected, NNr-1])),
			NEW_DLQ = dlq:push2DLQ([NNr-1, io_lib:format("HBQ: message ~w to ~w replaced~n",[Expected, NNr-1]), erlang:now(), erlang:now()], DLQ, LogFile),
			checkHBQ(HBQ, NEW_DLQ, LogFile);
		true ->
			{HBQ, DLQ}
	end.

