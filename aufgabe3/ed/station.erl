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
% wlp3s0"
% station:start(["\\DEVICE\\TCPIP_{08DC52FC-C501-4108-9EF2-006431AE9793}", "239.255.255.255", "15005", "A", "0", "0"]).
% station:start(["\\DEVICE\\TCPIP_{08DC52FC-C501-4108-9EF2-006431AE9793}", "225.10.1.2", "15005", "A", "0", "0"]).

% cd IdeaProjects/bai5-distributed-systems/aufgabe3/ed
% ./startStations.sh wlp3s0 225.10.1.2 15015 1 1 A 5
%-spec start(list()) -> pid().
start(NetworkInterface, MulticastAddress, ReceivePort, Class, Index) ->
  start(NetworkInterface, MulticastAddress, ReceivePort, Class, "0", Index).

start(NetworkInterface, MulticastAddress, ReceivePort, Class, Offset, Index) ->
  spawn(station, init, [NetworkInterface, MulticastAddress, ReceivePort, Class, Offset, Index]).

-spec init(string(), string(), string(), string(), string(), string()) -> none().
init(NetworkInterface, MulticastAddress, ReceivePort, Class, OffsetS, StationIndex) ->
  file:delete(?FILENAME),
  util:logt(?FILENAME, ["Station ", StationIndex, " gestartet mit PID ", pid_to_list(self())]),
  {Interface, Address, Port, Offset} = parsed(NetworkInterface, MulticastAddress, ReceivePort, OffsetS),

  Ablaufplanung = spawn(ablaufplanung, start, [Offset]),
  Empfaenger = spawn(empfaenger, start, [Ablaufplanung]),
  spawn(udp, start, [Interface, Address, Port, Empfaenger]),

  Sender = spawn(sender, start, [Interface, Address, Port]),
  Nachrichtengenerator = spawn(nachrichtengenerator, start, [Class, Sender]),
  spawn(quelle, start, [Nachrichtengenerator]),

  Ablaufplanung ! {listener, {Empfaenger, Nachrichtengenerator}}.
%----------------------------------------------------------------------------------------------------------------------
% private helper
%----------------------------------------------------------------------------------------------------------------------
% Converts the given program input parameter into a tuple containing the converted versions of it. This is needed
-spec parsed(string(), string(), string(), string()) -> tuple().
parsed(NetworkInterface, MulticastAddress, ReceivePort, Offset) ->
  {ok, MulticastAddressConverted} = inet_parse:address(MulticastAddress),
  {PortConverted, []} = string:to_integer(ReceivePort),
  {OffsetConverted, []} = string:to_integer(Offset),

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