-module(slotrsv).
-export([start/2]).

start(Uhrsync, I) ->
	receive
		% Warte auf naechsten Frame
		{start, Empfaenger, Sender} ->
			Uhrsync ! {telltime, self()},
			receive
				{time, LokaleZeit} ->
					%werkzeug:logging("slotrsv.log",pid_to_list(self()) ++ ": " ++ werkzeug:to_String(LokaleZeit) ++ "\r\n"),
					LokaleZeit
			end,
			% Zeit bis naechsten Frame
			erlang:send_after(1000 - (LokaleZeit rem 1000) + 5, self(), {startframe}),
			receive
				{startframe} ->
					self() ! {endslot},
					SlotsTaken = [],
					Slot = -1,
					Last = -1,
					Start = true,
					loop(Uhrsync, Empfaenger, Sender, SlotsTaken, Slot, Last, Start, I)
			end
	end.
	

loop(Uhrsync, Empfaenger, Sender, SlotsTaken, Slot, Last, Start, I) ->
	receive
		% Generiere zufaelligen Slot nach Anfrage
		{reserve, PID} ->
			All = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24],
			Free = lists:subtract(All,SlotsTaken),
			Random = rand:uniform(length(Free)),
			SlotNr = lists:nth(Random, Free),
			PID ! {slot, SlotNr},
			loop(Uhrsync, Empfaenger, Sender, SlotsTaken, SlotNr, Last, Start, I);
		
		% Geplantes Intervall ist abgelaufen
		{missed} ->
			loop(Uhrsync, Empfaenger, Sender, SlotsTaken, -1, Last, Start, I);

		% Einzelner Slot ist abgelaufen
		{endslot} ->
			Empfaenger ! {nextslot},
			Uhrsync ! {telltime, self()},
			receive
				{time, Aktuell} ->
					Aktuell
			end,
			% neuer Frame?
			case (not Start) and (Aktuell rem 1000 =< 40) of
				true ->
					{ESlotsTaken, ESlotNr} = vonEmpfaenger(Uhrsync, SlotsTaken, Slot, Last, I),
					
					Uhrsync ! {fixtime},
					case ESlotNr >= 0 of
						true ->
							% es wurde vorher ein Slot reserviert
							NextSlot = ESlotNr;
						false ->
							All = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24],
							Free = lists:subtract(All,ESlotsTaken),
							Random = rand:uniform(length(Free)),
							NextSlot = lists:nth(Random, Free)
					end,
					werkzeug:logging("slotrsv.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "Slot " ++ werkzeug:to_String(ESlotNr) ++ " analysiert und der folgende Slot wurde ausgewaehlt: " ++ werkzeug:to_String(NextSlot) ++ "\r\n"),
					Uhrsync ! {telltime, self()},
					receive
						{time, Zeit} ->
							Zeit
					end,
					StartFrame = Zeit - (Zeit rem 1000),
					Sender ! {counter, NextSlot * 40 + 10 - (Zeit rem 1000), {StartFrame + NextSlot * 40 + 5, StartFrame + NextSlot * 40 + 35}},
					% Slot Timer = (Slotdauer - (Zeitpunkt rem Slotdauer)) + extra Wartezeit
					Latenz = (40 - (Zeit rem 40)) + 5,
					erlang:send_after(Latenz, self(), {endslot}),
					
					loop(Uhrsync, Empfaenger, Sender, [], -1, NextSlot, Start, I);
				
				false ->
					Uhrsync ! {telltime, self()},
					receive
						{time, Zeit} ->
						Zeit
					end,
					% Slot Timer = (Slotdauer - (Zeitpunkt rem Slotdauer)) + extra Wartezeit
					Latenz = (40 - (Zeit rem 40)) + 5,
					erlang:send_after(Latenz, self(), {endslot}),
					{ESlotsTaken, ESlotNr} = vonEmpfaenger(Uhrsync, SlotsTaken, Slot, Last, I),
					EStart = false,
					loop(Uhrsync, Empfaenger, Sender, ESlotsTaken, ESlotNr, Last, EStart, I)
			end;

		_ ->
			werkzeug:logging("slotrsv.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "Eine falsche Nachricht ist angekommen.\r\n"),
			loop(Uhrsync, Empfaenger, Sender, SlotsTaken, Slot, Last, Start, I)
	end.
	
vonEmpfaenger(Uhrsync, SlotsTaken, SlotNr, Last, I) ->
	receive
		% keine Nachrichten angekommen waehrend des Slots
		{empty} ->
			%werkzeug:logging("slotrsv.log",pid_to_list(self()) ++ ": " ++ "Leerer Slot.\r\n"),
			{SlotsTaken, SlotNr};

		% genau eine Nachricht pro Slot wurde von Empfänger analysiert
		{onemsg, Slot} ->
			case (Slot == SlotNr) and (lists:member(Slot, SlotsTaken)) of
				true ->
					{SlotsTaken, -1};
				false ->
					{[Slot | SlotsTaken], SlotNr}
			end;

		% Kollision gefunden
		{collide} ->
			Uhrsync ! {telltime, self()},
			receive
				{time, Zeit} ->
					Zeit
			end,
			% aktueller Slot berechnen
			AktSlot = ((Zeit rem 1000) div 40) - 1,
			
			if 	AktSlot < 0 ->
					NeuSlot = 24;
				AktSlot >= 0 ->
					NeuSlot = AktSlot
			end,

			if
				Last == NeuSlot ->
					werkzeug:logging("slotrsv.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "Eine eigene Kollision ist aufgetreten.\r\n"),
					{SlotsTaken, -1};
							
				true ->
					werkzeug:logging("slotrsv.log",pid_to_list(self()) ++ " - " ++ werkzeug:to_String(I) ++ " : " ++ "Eine Kollision ist aufgetreten.\r\n"),
					{SlotsTaken, SlotNr}
			end
	end. 