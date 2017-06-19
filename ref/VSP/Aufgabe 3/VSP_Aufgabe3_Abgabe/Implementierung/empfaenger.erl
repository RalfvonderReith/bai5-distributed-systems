-module(empfaenger).
-export([start/7,netrcv/5]).

start(Interface, IP, Port, SlotRsv, Uhrsync, Senke, I) ->
	spawn(empfaenger, netrcv, [self(), Interface, IP, Port, I]),
	loop(SlotRsv, Uhrsync, Senke, [], I).

% Empfang von UDP Nachrichten ueber Socket
netrcv(Empfaenger, Interface, IP, Port, I) ->
	Socket = werkzeug:openRec(IP, Interface, Port),
	gen_udp:controlling_process(Socket, self()),
	netloop(Empfaenger, Socket, I).

netloop(Empfaenger, Socket, I) ->
	Msg = gen_udp:recv(Socket, 34),
	werkzeug:logging("udp.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : UDP packet received" ++ "\r\n"),
	Empfaenger ! {netmsg, Msg},
	netloop(Empfaenger, Socket, I).

% Nachrichtenbearbeitung
loop(SlotRsv, Uhrsync, Senke, Nachrichten, I) ->
	receive
		% Inhalt extrahieren
		{netmsg, {ok, {_Address, _Port, Packet}}} ->
			Uhrsync ! {telltime, self()},
			receive
				{time, LokaleZeit} ->
					%werkzeug:logging("empfaenger.log",pid_to_list(self()) ++ ": " ++ LokaleZeit ++ "\r\n"),
					LokaleZeit
			end,
			% Bit Syntax - Value:Size/TypeSpecifierList
			<<Stationsklasse:1/binary,
			  Nutzdaten:24/binary,
			  SlotNr:8/integer,
			  VersandZeitpunkt:64/integer-big>> = Packet,
			Station = erlang:binary_to_list(Stationsklasse),
			Inhalt = erlang:binary_to_list(Nutzdaten),
			Slot = SlotNr,
			MsgZeitpunkt = VersandZeitpunkt,
			loop(SlotRsv, Uhrsync, Senke, [{Station, Inhalt, Slot, MsgZeitpunkt, LokaleZeit} | Nachrichten], I);
		% Slot ist vorbei
		{nextslot} ->
			% Pruefe ob genau eine Nachricht angekommen ist
			case length(Nachrichten) of
				% keine Nachrichten
				0 ->
					SlotRsv ! {empty},
					%werkzeug:logging("empfaenger.log",pid_to_list(self()) ++ ": " ++ "Leerer Slot.\r\n"),
					loop(SlotRsv, Uhrsync, Senke, [], I);
				% genau eine Nachricht angekommen
				1 ->
					[{Station, Inhalt, Slot, MsgZeitpunkt, LokaleZeit} | _] = Nachrichten,
					werkzeug:logging("empfaenger.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "Slot " ++ werkzeug:to_String(Slot) ++ " mit 1 Nachricht" ++ "\r\n"),
					SlotRsv ! {onemsg, Slot - 1},
					Senke ! {inhalt, Inhalt},
					if Station == "A" ->
							Uhrsync ! {syncmsg, MsgZeitpunkt, LokaleZeit};
						true ->
							ok
					end,
					loop(SlotRsv, Uhrsync, Senke, [], I);
				% eine Kollision, da mehrere Nachrichten innerhalb eines Slots angekommen sind
				_ ->
					SlotRsv ! {collide},
					werkzeug:logging("empfaenger.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "Slot mit kollidierten Nachrichten" ++ "\r\n"),
					loop(SlotRsv, Uhrsync, Senke, [], I)
			end
	end.
