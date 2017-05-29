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
% TODO: Was ist wenn eine Class A Nachricht verworfen wird? Wird die Zeit trotzdem genommen?
start(SequenceInfoListener) ->
  PID = spawn(empfaenger, loop, [0, '', SequenceInfoListener]),
  util:log(?FILENAME, ["Empfaenger gestartet mit PID ", pid_to_list(PID)]),
  PID.


loop(PacketAmount, Packet, SequenceInfoListener) ->
  receive
    {packet, Packet} ->
      util:log(?FILENAME, ["Empfaenger erhaelt Paket ", Packet]),

      <<Class:1/binary, Data:24/binary, Slot:8/integer, Time:64/integer-big>> = Packet,
      loop(
        PacketAmount + 1,
        {erlang:binary_to_list(Class), erlang:binary_to_list(Data), Slot, Time},
        SequenceInfoListener
      );
    slot_ended ->
      case PacketAmount of
        0 -> ok;
        1 ->
          {Class, Data, Slot, Time} = Packet,
          util:logt(?SENKE_FILENAME, ["Senke erhaelt Datensatz ", Data]),

          if
            Class == "A" -> util:distribute({slot_time, {Slot, Time}}, SequenceInfoListener);
            true -> util:distribute({slot, Slot}, SequenceInfoListener)
          end
      end,
      loop(0, <<>>, SequenceInfoListener);
    Any ->
      io:format("UDP Empfaenger Nachricht erwartet, aber ~w bekommen.~n", [Any]),
      loop(PacketAmount + 1, Packet, SequenceInfoListener)
  end.

