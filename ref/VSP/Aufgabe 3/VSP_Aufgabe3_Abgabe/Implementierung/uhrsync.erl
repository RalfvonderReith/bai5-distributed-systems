-module(uhrsync).
-export([start/2]).

start(TimeShift, I) ->
	loop(TimeShift,[], I).
	
% Uhr-Operationen
loop(TimeShift, TimeOffsets, I) ->
	receive
		% Erzeuge aktuellen Zeitstempel nach Anfrage
		{telltime, PID} ->
			TimeInMilliS = werkzeug:getUTC(),
			PID ! {time, TimeInMilliS + TimeShift},
			werkzeug:logging("uhrsync.log",pid_to_list(self()) ++ ": " ++ "Told " ++ pid_to_list(PID) ++ werkzeug:to_String(TimeInMilliS) ++ " mit Offset " ++ werkzeug:to_String(TimeShift) ++ "\r\n"),
			loop(TimeShift, TimeOffsets, I);
		% Merke die Zeit von Typ-A-Station aus der eingegangenen Nachricht
		{syncmsg, RemoteTime, RecTime} ->
			Offset = (RemoteTime - RecTime) div 2,
			loop(TimeShift, [Offset | TimeOffsets], I);
		% Zeit-Korrektur (Mittelwert Berechnung ueber alle akkumulierten Zeitstempel von Typ-A-Stationen)
		{fixtime} ->
			if
				length(TimeOffsets) > 0  ->
					AvgOffset = lists:sum(TimeOffsets) div length(TimeOffsets),
					werkzeug:logging("uhrsync.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "Zeit wurde synchronisiert" ++ "\r\n");
				true ->
					AvgOffset = 0
			end,
			loop(TimeShift + (AvgOffset), [], I)
	end.
	