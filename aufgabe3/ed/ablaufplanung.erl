%%%-------------------------------------------------------------------
%%% @author Eugen Deutsch
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(ablaufplanung).
-author("Steven").

%-export([start/1]).
-compile(export_all).
%----------------------------------------------------------------------------------------------------------------------
% constants
%----------------------------------------------------------------------------------------------------------------------
% names
-define(ALL_SLOTS, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]).

-define(FRAME_DURATION, 1000).
-define(MAX_SLOT_AMOUNT, length(?ALL_SLOTS)).
-define(SLOT_DURATION, trunc(?FRAME_DURATION / ?MAX_SLOT_AMOUNT)).
-define(ADDITIONAL_TIME, trunc(?SLOT_DURATION / 2)).
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
start(LogFile, Offset) ->
  receive
    {listener, {Empfaenger, Nachrichtengenerator}} ->
      timer:send_after(?SLOT_DURATION - werkzeug:getUTC() rem ?SLOT_DURATION + Offset, self(), slot_ended),
      timer:send_after(?FRAME_DURATION - werkzeug:getUTC() rem ?FRAME_DURATION + Offset, self(), frame_ended),


      timer:send_after(
        ?FRAME_DURATION - werkzeug:getUTC() rem ?FRAME_DURATION + ?SLOT_DURATION *
          (lists:nth(rand:uniform(?MAX_SLOT_AMOUNT), ?ALL_SLOTS) - 1) + Offset + ?ADDITIONAL_TIME, self(), sending_time
      ),

      util:logt(LogFile, ["Ablaufplanung: Gestartet mit PID ", pid_to_list(self())]),
      loop(LogFile, Offset, [Offset], ?ALL_SLOTS, Empfaenger, Nachrichtengenerator, true, true, 1);
    Any ->
      io:format("Unerwartete Nachricht an Ablaufplanung (erwarte listener): ~w~n", [Any]),
      start(LogFile, Offset)
  end.

loop(LogFile, Offset, ClassAOffsets, AvailableSlots, Empfaenger, Nachrichtengenerator, SlotAvailable, SlotWasAvailable, Counter) ->
  receive
    time ->
      Empfaenger ! {time, werkzeug:getUTC() + Offset},
      loop(LogFile, Offset, ClassAOffsets, AvailableSlots, Empfaenger, Nachrichtengenerator, false, SlotWasAvailable, Counter);
    {slot, Slot} ->
      util:logt(LogFile, ["Ablaufplanung: Slot ", Slot, " wurde reserviert."]),
      loop(LogFile, Offset, ClassAOffsets, lists:delete(Slot, AvailableSlots), Empfaenger, Nachrichtengenerator, SlotAvailable, SlotWasAvailable, Counter);
    {slot_time, {Slot, NewClassAOffset}} ->
      util:logt(LogFile, ["Ablaufplanung: Slot ", Slot, " wurde reserviert und Offset ", NewClassAOffset, " angekommen."]),
      loop(LogFile, Offset, [NewClassAOffset | ClassAOffsets], lists:delete(Slot, AvailableSlots), Empfaenger, Nachrichtengenerator, SlotAvailable, SlotWasAvailable, Counter);
    slot_ended ->
      Empfaenger ! slot_ended,
      timer:send_after(?SLOT_DURATION - werkzeug:getUTC() rem ?SLOT_DURATION + Offset, self(), slot_ended),
      %util:logt(LogFile, ["Ablaufplanung: Slotende. (Nr. ", Counter, ")",
      %  " Verfügbare Slots: ", werkzeug:to_String(AvailableSlots)]),

      loop(LogFile, Offset, ClassAOffsets, AvailableSlots, Empfaenger, Nachrichtengenerator, true, SlotWasAvailable, Counter + 1);
    frame_ended ->
      timer:send_after(?FRAME_DURATION - werkzeug:getUTC() rem ?FRAME_DURATION + Offset, self(), frame_ended),

      util:logt(LogFile, ["Ablaufplanung: Frameende."]),

      if
        not SlotWasAvailable ->
          ChosenSlot = lists:nth(rand:uniform(length(AvailableSlots)), AvailableSlots),
          timer:send_after(
            ?SLOT_DURATION * (ChosenSlot - 1) + Offset + ?ADDITIONAL_TIME, self(), sending_time
          ),
          util:log(LogFile,
            ["Ablaufplanung: Es gab eine Kollision. Wähle aus ",
              werkzeug:to_String(AvailableSlots), " Slot ", ChosenSlot,
              " für nächsten Frame."]);
        true -> ok
      end,

      util:log(LogFile, ["\n"]),
      loop(
        LogFile, trunc(lists:sum(ClassAOffsets) / length(ClassAOffsets)), [Offset], ?ALL_SLOTS, Empfaenger, Nachrichtengenerator, true, true, 1
      );
    sending_time ->
      util:logt(LogFile, ["Ablaufplanung: Zeit zum senden."]),
      if
        SlotAvailable ->
          Slot = lists:nth(rand:uniform(length(AvailableSlots)), AvailableSlots),
          Nachrichtengenerator ! {sending_time, {Slot, werkzeug:getUTC() + Offset}},

          timer:send_after(
            ?FRAME_DURATION - werkzeug:getUTC() rem ?FRAME_DURATION + ?SLOT_DURATION * (Slot - 1) + Offset + ?ADDITIONAL_TIME, self(), sending_time
          ),
          util:log(LogFile, ["Ablaufplanung: Slot war verfügbar. Reserviere ", Slot, " für nächsten Frame aus ", werkzeug:to_String(AvailableSlots)]),
          util:log(LogFile, ["Ablaufplanung: Sende in ", ?FRAME_DURATION - werkzeug:getUTC() rem ?FRAME_DURATION + ?SLOT_DURATION * (Slot - 1) + Offset + ?ADDITIONAL_TIME, " Millisekunden."]);
        true ->
          util:log(LogFile, ["Ablaufplanung: Sendezeit, aber Slot war besetzt. Momentan verfügbare: ", werkzeug:to_String(AvailableSlots)])
      end,

      loop(LogFile, Offset, ClassAOffsets, AvailableSlots, Empfaenger, Nachrichtengenerator, SlotAvailable, SlotAvailable, Counter);
    Any ->
      io:format("Unerwartete Nachricht an Ablaufplanung: ~w~n", [Any]),
      loop(LogFile, Offset, ClassAOffsets, AvailableSlots, Empfaenger, Nachrichtengenerator, SlotAvailable, SlotWasAvailable, Counter)
  end.