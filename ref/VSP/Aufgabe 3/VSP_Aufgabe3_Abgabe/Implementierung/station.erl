-module(station).
-export([start/1,start/6]).

start([SInterface, SIP, SPort, SClass, I]) ->
	spawn(fun() -> station:start(SInterface, SIP, SPort, SClass, '0', I) end);
start([SInterface, SIP, SPort, SClass, SOffset, I]) ->
	spawn(fun() -> station:start(SInterface, SIP, SPort, SClass, SOffset, I) end).

start(SInterface, SIP, SPort, SClass, SOffset, I) ->
	werkzeug:logging("station.log","\r\n" ++ pid_to_list(self()) ++ ": " ++ "Station Nr > " ++ werkzeug:to_String(I) ++ "\r\n"),
	Interface = getIfAddr(SInterface),
	{ok, IP} = inet_parse:address(SIP),
	{Port, _} = string:to_integer(SPort),
	Class = SClass,
	{Offset, _} = string:to_integer(SOffset),

	Uhrsync = spawn(fun() -> uhrsync:start(Offset, I) end),
	SlotRsv = spawn(fun() -> slotrsv:start(Uhrsync, I) end),
	Senke = spawn(fun() -> senke:start(I) end),
	Empfaenger = spawn(fun() -> empfaenger:start(Interface, IP, Port, SlotRsv, Uhrsync, Senke, I) end),
	Quelle = spawn(fun() -> quelle:start(I) end),
	Sender = spawn(fun() -> sender:start(Interface, IP, Port, SlotRsv, Uhrsync, Class, Quelle, I) end),
	werkzeug:logging("station.log",pid_to_list(self()) ++ ": " ++ "Interface: " ++ werkzeug:to_String(Interface) ++ " IP: " ++ werkzeug:to_String(IP) ++ " Port: " ++ werkzeug:to_String(Port) ++ " Typ: " ++ werkzeug:to_String(Class) ++ " Offset: " ++ werkzeug:to_String(Offset) ++ "\r\n"),
	werkzeug:logging("station.log",pid_to_list(self()) ++ ": " ++ "Uhrsync: " ++ pid_to_list(Uhrsync) ++ " SlotRsv: " ++ pid_to_list(SlotRsv) ++ " Senke: " ++ pid_to_list(Senke) ++ " Empfaenger: " ++ pid_to_list(Empfaenger) ++ " Quelle: " ++ pid_to_list(Quelle) ++ " Sender: " ++ pid_to_list(Sender) ++ "\r\n"),
	SlotRsv ! {start, Empfaenger, Sender}.


getIfAddr(Interface) ->
	{ok, Iflist} = inet:getifaddrs(),
	getAddr(Interface, Iflist).

getAddr(_Interface, []) ->
	{addr, err};
getAddr(Interface, [{Ifname, _Ifopt} | Rest]) when Interface =/= Ifname ->
	getAddr(Interface, Rest);
getAddr(Interface, [{Ifname, Ifopt} | _Rest]) when Interface == Ifname ->
	getIP(Ifopt).

getIP([{_Ifopt, _Wert} | []]) ->
	{err};
getIP([{Ifopt, _Wert} | Rest]) when Ifopt =/= addr ->
	getIP(Rest);
getIP([{Ifopt, Wert} | _Rest]) when Ifopt == addr ->
	Wert.
