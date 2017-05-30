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
start(Ablaufplanung) ->
  file:delete(?FILENAME),
  file:delete(?SENKE_FILENAME),
  util:log(?FILENAME, ["Empfaenger gestartet mit PID ", pid_to_list(self())]),
  loop(0, '', 0, Ablaufplanung).


loop(PacketAmount, Packet, PacketOffset, Ablaufplanung) ->
  receive
    {packet, NewBPacket} ->
      Ablaufplanung ! time,
      <<BClass:1/binary, BData:24/binary, Slot:8/integer, Time:64/integer-big>> = NewBPacket,

      NewPacket = {erlang:binary_to_list(BClass), erlang:binary_to_list(BData), Slot, Time},
      util:logt(?FILENAME, ["Empfaenger erhaelt Paket ", werkzeug:to_String(NewPacket)]),
      receive
        {time, OwnTime} ->
          loop(
            PacketAmount + 1,
            NewPacket,
            OwnTime - Time,
            Ablaufplanung
          )
      end;
    slot_ended ->
      case PacketAmount of
        0 -> ok;
        1 ->
          {Class, _, Slot, _} = Packet,
          util:logt(?SENKE_FILENAME, ["Senke erhaelt Datensatz ", werkzeug:to_String(Packet)]),

          if
            Class == "A" -> Ablaufplanung ! {slot_time, {Slot, PacketOffset}};
            true -> Ablaufplanung ! {slot, Slot}
          end;
        _ -> util:logt(?SENKE_FILENAME, ["Kollision !"])
      end,
      loop(0, empty, 0, Ablaufplanung);
    Any ->
      io:format("UDP Empfaenger Nachricht erwartet, aber ~w bekommen.~n", [Any]),
      loop(PacketAmount, Packet, PacketOffset, Ablaufplanung)
  end.

% ---------------------------------------------------------------------------------------------------------------------
% private helper
% ---------------------------------------------------------------------------------------------------------------------
