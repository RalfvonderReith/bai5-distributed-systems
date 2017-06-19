-module(senke).
-export([start/1]).

start(I) ->
	receive
		{inhalt, Text} ->
			werkzeug:logging("senke.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ Text ++ "\r\n"),
			start(I)
	end.
	