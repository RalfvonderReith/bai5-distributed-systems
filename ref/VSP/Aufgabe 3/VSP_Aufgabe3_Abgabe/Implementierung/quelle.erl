-module(quelle).
-export([start/1]).

start(I) ->
	MsgGenerator = self(),
	spawn(fun() -> readBuffer(MsgGenerator) end),
	provideData("__________INIT__________", I).

% Lese 24 Bytes aus dem Puffer
readBuffer(PID) ->
	case io:get_chars('', 24) of
		eof ->
			%werkzeug:logging("quelle.log",pid_to_list(self()) ++ ": " ++ "readBuffer: EOF\r\n"),
			timer:sleep(500);
		Text ->
			%werkzeug:logging("quelle.log",pid_to_list(self()) ++ ": Read Text " ++ Text ++ "and sent to:" ++ pid_to_list(PID) ++ ": " ++ "readBuffer: READ\r\n"),
			PID ! {inhalt, Text}
	end,
	readBuffer(PID).

% Nachrichtengenerator
provideData(Data, I) ->
	receive
		{inhalt, New} ->
			provideData(New, I);
		{generate, PID} ->
			werkzeug:logging("quelle.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "generated data fuer " ++ pid_to_list(PID) ++ "\r\n"),
			PID ! {generated, Data},
			provideData(Data, I)
	end.
