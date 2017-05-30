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
-define(SENKE_FILENAME, "senke.log").

%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
start(LogFile, Index, Ablaufplanung) ->
  SenkeFile = Index ++ ?SENKE_FILENAME,
  file:delete(SenkeFile),
  util:log(LogFile, ["Empfaenger: Gestartet mit PID ", pid_to_list(self())]),
  loop(LogFile, SenkeFile, 0, '', 0, Ablaufplanung).


loop(LogFile, SenkeFile, PacketAmount, Packet, PacketOffset, Ablaufplanung) ->
  receive
    {packet, NewBPacket} ->
      Ablaufplanung ! time,
      <<BClass:1/binary, BData:24/binary, Slot:8/integer, Time:64/integer-big>> = NewBPacket,

      NewPacket = {erlang:binary_to_list(BClass), erlang:binary_to_list(BData), Slot, Time},
      util:logt(LogFile, ["Empfaenger: Erhaelt Paket ", werkzeug:to_String(NewPacket)]),

      loop(LogFile, SenkeFile, PacketAmount + 1, NewPacket, 0, Ablaufplanung),
      receive
        {time, OwnTime} ->
          loop(
            LogFile,
            SenkeFile,
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
          util:logt(?SENKE_FILENAME, ["Senke: Erhaelt Datensatz ", werkzeug:to_String(Packet)]),

          if
            Class == "A" -> Ablaufplanung ! {slot_time, {Slot, PacketOffset}};
            true -> Ablaufplanung ! {slot, Slot}
          end;
        _ -> util:logt(LogFile, ["Empfänger: Kollision !"])
      end,
      loop(LogFile, SenkeFile, 0, empty, 0, Ablaufplanung);
    Any ->
      io:format("UDP Empfaenger Nachricht erwartet, aber ~w bekommen.~n", [Any]),
      loop(LogFile, SenkeFile, PacketAmount, Packet, PacketOffset, Ablaufplanung)
  end.

% ---------------------------------------------------------------------------------------------------------------------
% private helper
% ---------------------------------------------------------------------------------------------------------------------
