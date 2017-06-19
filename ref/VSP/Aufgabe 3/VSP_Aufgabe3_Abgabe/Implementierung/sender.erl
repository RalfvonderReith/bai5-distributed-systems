-module(sender).
-export([start/8]).

start(Interface, IP, Port, SlotRsv, Uhrsync, Typ, Quelle, I) ->
	Socket = werkzeug:openSe(Interface, Port),
	Zeitslot = 0,
	Timer = erlang:send_after(1, self(), {ping}),
	loop(Socket, IP, Port, SlotRsv, Uhrsync, Typ, Quelle, Zeitslot, Timer, I).

loop(Socket, IP, Port, SlotRsv, Uhrsync, Typ, Quelle, Zeitslot, Timer, I) ->
	receive
		% init
		{ping} ->
			werkzeug:logging("sender.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "ping\r\n"),
			loop(Socket, IP, Port, SlotRsv, Uhrsync, Typ, Quelle, Zeitslot, Timer, I);
		% Timer wird gesetzt
		{counter, Dauer, NZeitslot} ->
			werkzeug:logging("sender.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "counter\r\n"),
			_Cancel = erlang:cancel_timer(Timer),
			if 	Dauer > 0 ->
					Latenz = Dauer;
				true ->
					Latenz = 0
			end,
			Pause = erlang:send_after(Latenz, self(), {timeout}),
			loop(Socket, IP, Port, SlotRsv, Uhrsync, Typ, Quelle, NZeitslot, Pause, I);
		% Timer ist um
		{timeout} ->
			{Start, End} = Zeitslot,
			% bereite Inhalt vor
			Quelle ! {generate, self()},
			receive
				{generated, NewData} ->
					werkzeug:logging("sender.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "generated: " ++ NewData ++ "\r\n"),
					NewData
			end,

			% reserviere Uebergabeslot
			SlotRsv ! {reserve, self()},
			receive
				{slot, Nr} ->
					werkzeug:logging("sender.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "received Slot: " ++ werkzeug:to_String(Nr) ++ "\r\n"),
					Nr
			end,

			% merke aktuelle Zeit
			Uhrsync ! {telltime, self()},
			receive
				{time, LokaleZeit} ->
					werkzeug:logging("sender.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "received Time: " ++ werkzeug:to_String(LokaleZeit) ++ "\r\n"),
					LokaleZeit
			end,

			% Pruefe ob wir uns innerhalb des geplanten Zeitintervalls befinden
			if (Start > LokaleZeit) or (End < LokaleZeit) ->
					SlotRsv ! {missed};
				true ->
					Stationsklasse = list_to_binary(Typ),
					Nutzdaten = list_to_binary(NewData),
					SlotNr = Nr + 1,
					VersandZeitpunkt = LokaleZeit,
					Packet = <<Stationsklasse:1/binary,
							   Nutzdaten:24/binary,
							   SlotNr:8/integer,
							   VersandZeitpunkt:64/integer-big>>,
					ok = gen_udp:send(Socket, IP, Port, Packet),
					werkzeug:logging("sender.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "new message sent per socket " ++ werkzeug:to_String(Socket) ++ " to IP " ++ werkzeug:to_String(IP) ++ "\r\n")
			end,
			loop(Socket, IP, Port, SlotRsv, Uhrsync, Typ, Quelle, Zeitslot, Timer, I)
	end.
