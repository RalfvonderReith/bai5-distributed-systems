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
-define(FILENAME, "ablaufplanung.log").
-define(ALL_SLOTS, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]).

-define(FRAME_DURATION, 1000).
-define(MAX_SLOT_AMOUNT, length(?ALL_SLOTS)).
-define(SLOT_DURATION, trunc(?FRAME_DURATION / ?MAX_SLOT_AMOUNT)).
-define(ADDITIONAL_TIME, trunc(?SLOT_DURATION / 4)).
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
start(Offset) ->
  file:delete(?FILENAME),
  init(Offset).

init(Offset) ->
  receive
    {listener, {Empfaenger, Nachrichtengenerator}} ->
      io:format("Ablaufplanung SLOT: ~p~n", [?SLOT_DURATION]),
      io:format("Ablaufplanung Offset: ~p~n", [Offset]),
      io:format("Ablaufplanung UTC: ~p~n", [werkzeug:getUTC()]),
      io:format("Alles: ~p~n", [werkzeug:getUTC() rem ?SLOT_DURATION + Offset]),
      timer:send_after(?SLOT_DURATION - werkzeug:getUTC() rem ?SLOT_DURATION + Offset, self(), slot_ended),
      timer:send_after(?FRAME_DURATION - werkzeug:getUTC() rem ?FRAME_DURATION + Offset, self(), frame_ended),

      SlotTime = ?SLOT_DURATION * (lists:nth(rand:uniform(?MAX_SLOT_AMOUNT), ?ALL_SLOTS) - 1),
      NextFrameTime = ?FRAME_DURATION - werkzeug:getUTC() rem ?FRAME_DURATION,
        timer:send_after(
        NextFrameTime + SlotTime + Offset + ?ADDITIONAL_TIME, self(), sending_time
      ),

      %io:format("Sende Nachricht in... ~p~n", [?FRAME_DURATION - werkzeug:getUTC() ]),
      util:logt(?FILENAME, ["Ablaufplanung gestartet mit PID ", pid_to_list(self())]),
      loop(Offset, [Offset], ?ALL_SLOTS, Empfaenger, Nachrichtengenerator);
    Any ->
      io:format("Unerwartete Nachricht an Ablaufplanung (erwarte listener): ~w~n", [Any]),
      init(Offset)
  end.

loop(Offset, ClassAOffsets, AvailableSlots, Empfaenger, Nachrichtengenerator) ->
  receive
    time ->
      Empfaenger ! {time, werkzeug:getUTC() + Offset},
      loop(Offset, ClassAOffsets, AvailableSlots, Empfaenger, Nachrichtengenerator);
    {slot, Slot} ->
      loop(Offset, ClassAOffsets, lists:delete(Slot, AvailableSlots), Empfaenger, Nachrichtengenerator);
    {slot_time, {Slot, NewClassAOffset}} ->
      loop(Offset, [NewClassAOffset|ClassAOffsets], lists:delete(Slot, AvailableSlots), Empfaenger, Nachrichtengenerator);
    slot_ended ->
      Empfaenger ! slot_ended,
      timer:send_after(?SLOT_DURATION - werkzeug:getUTC() rem ?SLOT_DURATION + Offset, self(), slot_ended),
      %util:logt(?FILENAME, ["Ablaufplanung meldet Slotende."]),
      loop(Offset, ClassAOffsets, AvailableSlots, Empfaenger, Nachrichtengenerator);
    frame_ended ->
      timer:send_after(?FRAME_DURATION - werkzeug:getUTC() rem ?FRAME_DURATION + Offset, self(), frame_ended),
      util:logt(?FILENAME, ["Ablaufplanung meldet Frameende."]),
      loop(
        trunc(lists:sum(ClassAOffsets) / length(ClassAOffsets)), [Offset], ?ALL_SLOTS, Empfaenger, Nachrichtengenerator
      );
    sending_time ->
      Slot = lists:nth(rand:uniform(length(AvailableSlots)), AvailableSlots),

      Nachrichtengenerator ! {sending_time, {Slot, werkzeug:getUTC() + Offset}},

      SlotTime = ?SLOT_DURATION * (Slot - 1),
      NextFrameTime = ?FRAME_DURATION - werkzeug:getUTC() rem ?FRAME_DURATION,
      timer:send_after(
        NextFrameTime + SlotTime + Offset, self(), sending_time
      ),

      %io:format("Sende Nachricht in... ~p~n", [SlotTime]),

      io:format("Ablaufplanung Slot: ~p~n", [Slot]),
      loop(Offset, ClassAOffsets, [], Empfaenger, Nachrichtengenerator);
    Any ->
      io:format("Unerwartete Nachricht an Ablaufplanung: ~w~n", [Any]),
      loop(Offset, ClassAOffsets, AvailableSlots, Empfaenger, Nachrichtengenerator)
  end.