%%%-------------------------------------------------------------------
%%% @author Eugen Deutsch
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(station).
-author("Steven").

-compile(export_all).
%----------------------------------------------------------------------------------------------------------------------
% constants
%----------------------------------------------------------------------------------------------------------------------
% names
-define(FILENAME, "station.log").

%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
% Starting function. Call this method to start a station.
% station:start(["\\DEVICE\\TCPIP_{5312F9A6-7898-4D70-98CA-55F2D9C1FA65}", "225.10.1.2", "15005", "A", "0", "0"]).
-spec start(list()) -> pid().
start([NetworkInterface, MulticastAddress, ReceivePort, Class, Offset, Index]) ->
  spawn(station, init, [NetworkInterface, MulticastAddress, ReceivePort, Class, Offset, Index]).

-spec init(string(), string(), string(), string(), string(), string()) -> none().
init(NetworkInterface, MulticastAddress, ReceivePort, Class, Offset, Index) ->
  util:logt(?FILENAME, ["Station ", Index, " gestartet mit PID ", pid_to_list(self())]),
  parsed(NetworkInterface, MulticastAddress, ReceivePort, Index),

  Socket = werkzeug:openRecA(MulticastAddress, NetworkInterface, ReceivePort),

  Sender = spawn(sender, start, [Socket, MulticastAddress, ReceivePort]),
  Nachrichtengenerator = spawn(nachrichtengenerator, start, [Class, [Sender]]),
  spawn(quelle, start, [[Nachrichtengenerator]]),
  Ablaufplanung = spawn(ablaufplanung, start, [Offset]),
  Empfaenger = spawn(empfaenger, start, [[Ablaufplanung]]),

  Udp = spawn(udp, start, [[Empfaenger]]),
  Ablaufplanung ! {listener, {[Empfaenger], [Sender]}},
  gen_udp:controlling_process(Socket, Udp).
%----------------------------------------------------------------------------------------------------------------------
% private helper
%----------------------------------------------------------------------------------------------------------------------
% Converts the given program input parameter into a tuple containing the converted versions of it. This is needed
% TODO: Werden wirklich strings beim Start übergeben?
-spec parsed(string(), string(), string(), string()) -> tuple().
parsed(NetworkInterface, MulticastAddress, ReceivePort, Offset) ->
  MulticastAddressConverted = inet_parse:address(MulticastAddress),
  PortConverted = string:to_integer(ReceivePort),
  OffsetConverted = string:to_integer(Offset),

  {network_address(NetworkInterface), MulticastAddressConverted, PortConverted, OffsetConverted}.

% Takes the NetworkInterface and returns the address for it. The address is a string (eth2 most likely) and this
% function returns the corresponding ip address of it (tuple).
-spec network_address(string()) -> tuple().
network_address(NetworkInterface) ->
  {ok, Iflist} = inet:getifaddrs(),
  Ifopt = value(Iflist, NetworkInterface),
  value(Ifopt, addr).

% Expects a list with a tuple and a key. Searches through the tuples for the key (first) and returns the value of
% the found tuple (second).
% Raises an error, if the key couldn't be found.
-spec value(list(), any()) -> any().
value([], Key) -> error(lists:concat([Key, " konnte nicht gefunden werden."]));
value([{Key, Value}|_], Key) -> Value;
value([_|Rest], Key) -> value(Rest, Key).