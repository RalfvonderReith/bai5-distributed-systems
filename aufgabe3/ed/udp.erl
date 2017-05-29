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
-spec start(list()) -> pid().
start(UdpMessageListener) ->
  PID = spawn(udp, loop, [UdpMessageListener]),
  util:logt(?FILENAME, ["UDP gestartet mit PID ", pid_to_list(PID), " und folgenden Listenern: ", UdpMessageListener]),
  PID.

% 1) receive {udp, ReceiveSocket, IP, InPortNo, Packet} -> Receives an udp message and sends it to its listeners.
% (! {udp_message, Message})
% 2) receive kill -> Kills this component
-spec loop(list()) -> any().
loop(UdpMessageListener) ->
  receive
    {udp, Socket, IP, InPortNo, Packet} ->
      util:log(?FILENAME, ["UDP Nachricht angekommen von ", {Socket, IP, InPortNo}, ". Nachricht: ", Packet]),
      util:distribute({packet, Packet}, UdpMessageListener),
      loop(UdpMessageListener);
    Any ->
      io:format("UDP Nachricht erwartet, aber ~w bekommen.~n", [Any]),
      loop(UdpMessageListener)
  end.