%%%-------------------------------------------------------------------
%%% @author Eugen Deutsch
%%% @doc
%%% This component is part of the empfaenger component. It isn't supposed to be started from another point, it
%%% could've been inside the empfaenger.erl file, but this way every process gets its own file and it seems a little
%%% bit clearer.
%%%
%%% This component implicitly assumes a sending udp process, started from outside and closed from outside.
%%% @end
%%%-------------------------------------------------------------------
-module(udp).
-author("Steven").

-compile(export_all).
%----------------------------------------------------------------------------------------------------------------------
% constants
%----------------------------------------------------------------------------------------------------------------------
% names
-define(FILENAME, "udp.log").

% numbers
-define(MESSAGE_BYTE_AMOUNT, 34).
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
% Starts the udp component.
% UdpMessageListener: A list filled with listeners. After receiving the message, it will be spread between all
% listeners.
%-spec start(list()) -> pid().
start(Interface, Address, Port, Empfaenger) ->
  Socket = werkzeug:openRec(Address, Interface, Port),
  gen_udp:controlling_process(Socket, self()),

  file:delete(?FILENAME),
  util:logt(?FILENAME, ["UDP gestartet mit PID ", pid_to_list(self())]),

  loop(Socket, Empfaenger).

% 1) receive {udp, ReceiveSocket, IP, InPortNo, Packet} -> Receives an udp message and sends it to its listeners.
% (! {udp_message, Message})
% 2) receive kill -> Kills this component
%-spec loop(list()) -> any().
loop(Socket, Empfaenger) ->
  {ok, {_, _, Packet}} = gen_udp:recv(Socket, ?MESSAGE_BYTE_AMOUNT),
  %util:log(?FILENAME, ["UDP Nachricht angekommen Nachricht: ", Packet]),
  io:format("UDP: Nachricht empfangen ~n~n"),
  Empfaenger ! {packet, Packet},
  loop(Socket, Empfaenger).