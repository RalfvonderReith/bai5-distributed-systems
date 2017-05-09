-module(koordinator).
-export([start/0]).

%TODO: toggle einbauen

%TODO: Korrigieren flag durchreichen
start() ->
	io:format("starte Server... \r\n",[]),
	
	io:format("konfiguriere... \r\n", []),
	ConfigFile = "koordinator.cfg",
	{ok, ConfigListe} = file:consult(ConfigFile),
	
	{ok, Arbeitszeit} = werkzeug:get_config_value(arbeitszeit, ConfigListe),
	{ok, Termzeit} = werkzeug:get_config_value(termzeit, ConfigListe),
	{ok, GGTProzessNummer} = werkzeug:get_config_value(ggtprozessnummer, ConfigListe),
	{ok, NameServiceNode} = werkzeug:get_config_value(nameservicenode, ConfigListe),
	{ok, NameServiceName} = werkzeug:get_config_value(nameservicename, ConfigListe),
	{ok, KoordinatorName} = werkzeug:get_config_value(koordinatorname, ConfigListe),
	{ok, Quote} = werkzeug:get_config_value(quote, ConfigListe),
	{ok, Korrigieren} = werkzeug:get_config_value(korrigieren, ConfigListe),

	{ok, HostName} = inet:gethostname(),
	ClientList = [],
	LogFile = lists:concat([KoordinatorName,"@",HostName,".log"]),

	register(KoordinatorName, self()),
	io:format("verbinde zu NameServer ~w ...", [NameServiceNode]),
	pong = net_adm:ping(NameServiceNode),
	{NameServiceName, NameServiceNode} ! {self(), {rebind, KoordinatorName, node()}},
	receive
		ok ->
			io:format("Erfolgreich!\r\n",[]),
			io:format("Initialisierungsphase...\r\n",[]),
			initialisierungsphase(ClientList, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, {NameServiceName, NameServiceNode}, KoordinatorName);
		_Any ->
			error("Fehlgeschlagen!\r\n")
	end.

%TODO: anmelden der starter hier -> alle gemeldeten Starter mitgeben
initialisierungsphase(ClientList, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName) ->
	receive
		{PID, getsteeringval} ->
			io:format("received getsteeringval from: ~p. \r\n", [PID]),
			NewClientList = sendSteeringVal(PID, ClientList, GGTProzessNummer, Arbeitszeit, Termzeit, Quote, LogFile),
			initialisierungsphase(NewClientList, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName);
		{hello, ClientName} ->
			io:format("received hello from: ~p. \r\n", [ClientName]),
			initialisierungsphase([ClientName|ClientList], Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName);
		kill ->
			kill(ClientList, LogFile, NameService, KoordinatorName);
		step ->
			io:format("received step. \r\n", []),
			%TODO: hier ein zwischenschritt, in dem erst hier die starter kontaktiert werden und die erwartete Anzahl an GGT-Prozessen eingesammelt wird.
			step(ClientList, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName);
		reset ->
			reset(ClientList, LogFile, NameService);
		toggle ->
			werkzeug:logging(LogFile, lists:concat(["Ändere Korrigieren-Flag zu ", not Korrigieren, ". ", werkzeug:now2string(erlang:timestamp()), "\r\n"])),
			initialisierungsphase(ClientList, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, not Korrigieren, NameService, KoordinatorName);
		_Any ->
			io:format("received unexpected message! \r\n", [])
	end.

sendSteeringVal(PID, ClientList, GGTProzessNummer, Arbeitszeit, Termzeit, Quote, LogFile) ->
	%compute quota
	io:format("additional GGTs ~p.~n",[GGTProzessNummer]),
	AbsoluteParticipants = length(ClientList)+GGTProzessNummer,
	io:format("Abs GGTs ~p.~n",[AbsoluteParticipants]),
	io:format("Quote: ~p, Abs Quota ~p. ~n", [Quote, getAbsoluteQuota(AbsoluteParticipants, Quote)]),
	PID ! {steeringval, Arbeitszeit, Termzeit, getAbsoluteQuota(AbsoluteParticipants, Quote), GGTProzessNummer},
	getGGTs(ClientList, GGTProzessNummer, LogFile).
		
getGGTs(ClientList, 0, _LogFile) ->
	ClientList;
getGGTs(ClientList, GGTProzessNummer, LogFile) ->
	receive
		{hello, ClientName} ->
			werkzeug:logging(LogFile, lists:concat(["Hello: ", ClientName, ". ",werkzeug:now2string(erlang:timestamp()), "\r\n"])),
			getGGTs([ClientName|ClientList], GGTProzessNummer - 1, LogFile)
	end.
 
			
step(ClientList, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName) ->
	RandomList = werkzeug:shuffle(ClientList),
	createRing(RandomList, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName).

%creates a ring from a list
createRing(ClientList, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName) ->
	createRingH(ClientList, ClientList, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName).
createRingH(RandomList, [Left, Middle, Right|Rest], Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName) ->
	setNeighbors(Left, Middle, Right, LogFile, NameService),
	createRingH(RandomList, [Middle, Right|Rest], Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName);
createRingH([Right|Rest], [Left, Middle|[]], Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName) ->
	setNeighbors(Left, Middle, Right, LogFile, NameService),
	createRingH([Right|Rest], [Middle], Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName);
createRingH([Middle,Right|Rest], [Left], Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName) ->
	setNeighbors(Left, Middle, Right, LogFile, NameService), 
	bereitschaftsphase([Middle,Right|Rest], Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName).
	
setNeighbors(Left, Middle, Right, LogFile, NameService) ->
	NameService ! {self(), {lookup, Middle}},
	io:format("~p~n", [Left]),
	%io:format("set neighbors of ~p: ~p, ~p.\r\n", [Middle, Left, Right]).
	receive
		{pin,GGT} ->
			werkzeug:logging(LogFile, lists:concat(["Sende Nachbarn an ", Middle, ": Links: ", Left, ", Rechts: ", Right, ". ",werkzeug:now2string(erlang:timestamp()),"\r\n"])),
			GGT ! {setneighbors, Left, Right};
		not_found ->
			error("a ggt process is not registered")
			
	end.

%createRing2(RandomList) ->
%	createRingH2(RandomList, RandomList, []).
%createRingH2(RandomList, [Left, Middle, Right|Rest], Akku) ->
%	createRingH2(RandomList, [Middle, Right|Rest], [[Left, Middle, Right]|Akku]);
%createRingH2([Right|Rest], [Left, Middle|[]], Akku) ->
%	createRingH2([Right|Rest], [Middle], [[Left, Middle, Right]|Akku]);
%createRingH2([Middle,Right|_Rest], [Left], Akku) ->
%	[[Left, Middle, Right]|Akku].

bereitschaftsphase(ClientList, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName) ->
	io:format("Bereitschaftsphase...\r\n",[]),
	io:format("test; Clientlist: ~p\r\n",[ClientList]),
	receive 
		{calc, WggT} ->
			werkzeug:logging(LogFile, lists:concat(["Starte Berechnung mit ", WggT, ". ", werkzeug:now2string(erlang:timestamp()), "\r\n"])),
			NumberOfGGTs = length(ClientList),
			io:format("NumberOfGGTs ~p~n", [NumberOfGGTs]),
			ListOfPis = werkzeug:bestimme_mis(WggT, NumberOfGGTs*1.2),
			io:format("ListOfPis ~p~n", [ListOfPis]),
			MinimumMi = lists:min(ListOfPis),
			io:format("Minimum Pi ~p~n.", [MinimumMi]),
			ListOfUnusedPis = sendPis(ClientList, LogFile, NameService, ListOfPis),
			io:format("List of Unused Pis ~p~n", [ListOfUnusedPis]),
			sendStartMis(werkzeug:shuffle(ClientList), LogFile, NameService, ListOfUnusedPis),
			arbeitsphase(ClientList, MinimumMi, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName);
		reset ->
			reset(ClientList, LogFile, NameService);
		toggle ->
			werkzeug:logging(LogFile, lists:concat(["Ändere Korrigieren-Flag zu ", not Korrigieren, ". ", werkzeug:now2string(erlang:timestamp()), "\r\n"])),
			bereitschaftsphase(ClientList, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, not Korrigieren, NameService, KoordinatorName)
	end.

%sets starting Pis and returns a list of not yet used pis
sendPis([GGTName|RestGGT], LogFile, NameService, [Pi|RestPi]) ->
	NameService ! {self(), {lookup, GGTName}},
	io:format("test sendPis~n",[]),
	receive
		{pin,GGT} ->
			werkzeug:logging(LogFile, lists:concat(["Sende Pi ", Pi, " zu ", GGTName, ". ", werkzeug:now2string(erlang:timestamp()), "\r\n"])),
			GGT ! {setPi, Pi};
		not_found ->
			error("a ggt process is not registered")
	end, 
	sendPis(RestGGT, LogFile, NameService, RestPi);
sendPis([], _LogFile, _NameServer, RestPi) ->
	RestPi.

%sendStartMis(StartGGts, LogFile, NameServer, ListOfMis) ->	
sendStartMis([Client|Rest], LogFile, NameService, [Mi|RestMi]) ->
	sendy(Client, Mi, NameService, LogFile),
	sendStartMis(Rest, LogFile, NameService, RestMi);
sendStartMis(_ClientList, _LogFile, _NameService, []) ->	
	ok.
	
sendy(GGTName, Mi, NameService, LogFile) ->
	NameService ! {self(), {lookup, GGTName}},
	receive
		{pin,GGT} ->
			werkzeug:logging(LogFile, lists:concat(["Sende Mi ", Mi, " zu ", GGTName, ". ",werkzeug:now2string(erlang:timestampe()),"\r\n"])),
			GGT ! {sendy, Mi};
		not_found ->
			error("a ggt process is not registered")
	end.

arbeitsphase(ClientList, MinimumMi, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName) ->
	io:format("Arbeitsphase...\r\n", []), 
	receive
		reset ->
			reset(ClientList, LogFile, NameService);
		kill -> 
			kill(ClientList, LogFile, NameService, KoordinatorName);
		{briefmi, {Clientname, CMi, CZeit}} ->
			Message = lists:concat(["Neues Mi ", CMi, " von ", Clientname, " erhalten: ", werkzeug:now2string(CZeit), "\r\n"]),
			werkzeug:logging(LogFile, Message),
			if
				CMi < MinimumMi ->
					arbeitsphase(ClientList, CMi, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName);
				true ->
					arbeitsphase(ClientList, MinimumMi, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName)
			end;
		{_PID, briefterm, {Clientname, CMi, CZeit}} ->
			Message = lists:concat(["Terminierungsmeldung mit  Mi ", CMi, " von ", Clientname, " erhalten: ", werkzeug:now2string(CZeit), "\r\n"]),
			werkzeug:logging(LogFile, Message),
			%korrigiere, wenn nötig.
			if 
				Korrigieren == true, CMi > MinimumMi ->
					werkzeug:logging(LogFile, lists:concat(["Bekanntes Minimum (", MinimumMi, ") ist kleiner als gemeldetes Mi.\r\n"])),
					sendy(Clientname, MinimumMi, NameService, LogFile);
				true -> 
					ok
			end,
			bereitschaftsphase(ClientList, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName);
		prompt ->
			werkzeug:logging(LogFile, "prompt Kommando erhalten.\r\n"),
			tellMi(ClientList, LogFile, NameService),
			arbeitsphase(ClientList, MinimumMi, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName);
		nudge ->
		werkzeug:logging(LogFile, "nudge Kommando erhalten.\r\n"),
			nudge(ClientList, LogFile, NameService),
			arbeitsphase(ClientList, MinimumMi, Arbeitszeit, Termzeit, GGTProzessNummer, Quote, LogFile, Korrigieren, NameService, KoordinatorName)
	end.
	%do arbeitsphasen stuff

%TODO: Log into File
tellMi([], _LogFile, _NameService) ->
	ok;
tellMi([Client|Rest], LogFile, NameService) ->
	NameService ! {self(), {lookup, Client}},
	receive
		{pin,GGT} ->
			io:format("get mi of GGT ~p.", [Client]),
			GGT ! {self(), tellmi},
			receive
				{mi,Mi} ->
					werkzeug:logging(LogFile, lists:concat(["Aktuelles mi von ", Client, ": ", Mi, ". ",werkzeug:now2string(erlang:timestamp()),"\r\n"]))
			end,
			tellMi(Rest, LogFile, NameService);
		not_found ->
			error("a ggt process is not registered")
	end.

%TODO: Log into file	
nudge([], _LogFile, _NameService) ->
	ok;
nudge([Client|Rest], LogFile, NameService) ->
	NameService ! {self(), {lookup, Client}},
	receive
		{pin,GGT} ->
			io:format("get state of GGT ~p.", [Client]),
			GGT ! {self(), pingGGT},
			receive
				{pongGGT, GGTName} ->
					werkzeug:logging(LogFile, lists:concat([GGTName, " ist noch aktiv. ",werkzeug:now2string(erlang:timestamp()),"\r\n"]))
			end,
			nudge(Rest, LogFile, NameService);
		not_found ->
			error("a ggt process is not registered")
	end.

kill(ClientList, LogFile, NameService, KoordinatorName) ->
	werkzeug:logging(LogFile, "kill Kommando erhalten. \r\n", []),
	killGGTS(ClientList, LogFile, NameService),
	NameService ! {self(), {unbind, KoordinatorName}}.

killGGTS([], _LogFile, _NameService) ->
	ok;
killGGTS([First|Rest], LogFile, NameService) ->
	NameService ! {self(), {lookup, First}},
	receive
		{pin,GGT} ->
			io:format("kill GGT ~p.", [First]),
			GGT ! kill,
			killGGTS(Rest, LogFile, NameService);
		not_found ->
			error("a ggt process is not registered")
	end.
	
reset(ClientList, LogFile, NameService) ->
	werkzeug:logging(LogFile, "reset Kommando erhalten. \r\n"),
	killGGTS(ClientList, LogFile, NameService),
	start().

getAbsoluteQuota(Absolute, Percent) ->
	erlang:round(Absolute / 100 * Percent).
