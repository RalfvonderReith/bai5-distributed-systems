%%%-------------------------------------------------------------------
%%% @author Eugen Deutsch
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(empfaenger).
-author("Steven").

-compile(export_all).
%----------------------------------------------------------------------------------------------------------------------
% constants
%----------------------------------------------------------------------------------------------------------------------
% names
-define(FILENAME, "empfaenger.log").
-define(SENKE_FILENAME, "senke.log").

%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
start(Socket, Interface, Address, Port, Ablaufplanung) ->
  file:delete(?FILENAME),
  file:delete(?SENKE_FILENAME),
  PID = spawn(empfaenger, loop, [0, '', Ablaufplanung]),
  util:log(?FILENAME, ["Empfaenger gestartet mit PID ", pid_to_list(PID)]),
  gen_udp:controlling_process(Socket, PID),

  PID.


loop(PacketAmount, Packet, Ablaufplanung) ->
  receive
    {udp, Socket, IP, InPortNo, Packet} ->
      util:log(?FILENAME, ["Empfaenger erhaelt Paket ", Packet, " von ", {Socket, IP, InPortNo}]),
      <<Class:1/binary, Data:24/binary, Slot:8/integer, Time:64/integer-big>> = Packet,
      loop(
        PacketAmount + 1,
        {erlang:binary_to_list(Class), erlang:binary_to_list(Data), Slot, Time},
        Ablaufplanung
      );
    slot_ended ->
      case PacketAmount of
        0 -> ok;
        1 ->
          {Class, Data, Slot, Time} = Packet,
          util:logt(?SENKE_FILENAME, ["Senke erhaelt Datensatz ", Data]),

          if
            Class == "A" -> Ablaufplanung ! {slot_time, {Slot, Time}};
            true -> Ablaufplanung ! {slot, Slot}
          end
end,
      loop(0, empty, Ablaufplanung);
    Any ->
      io:format("UDP Empfaenger Nachricht erwartet, aber ~w bekommen.~n", [Any]),
      loop(PacketAmount + 1, Packet, Ablaufplanung)
  end.

