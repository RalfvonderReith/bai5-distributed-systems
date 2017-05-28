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
-define(ALL_SLOTS, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24]).

-define(FRAME_DURATION, 1000).
-define(MAX_SLOT_AMOUNT, length(?ALL_SLOTS)).
-define(SLOT_DURATION, trunc(?FRAME_DURATION / ?MAX_SLOT_AMOUNT)).
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
start(Offset) -> spawn(ablaufplanung, init, [Offset]).

init(Offset) ->
  receive
    {listener, {SlotEndListener, SendingTimeListener}} ->
      PID = spawn(ablaufplanung, loop, [Offset, 0, 0, ?ALL_SLOTS, SlotEndListener, SendingTimeListener]),

      timer:send_after(?SLOT_DURATION - (werkzeug:getUTC() rem ?SLOT_DURATION) + Offset, PID, slot_ended),
      timer:send_after(?FRAME_DURATION - (werkzeug:getUTC() rem ?FRAME_DURATION) + Offset, PID, frame_ended),

      NextMessageTime = ?FRAME_DURATION + ?SLOT_DURATION * lists:nth(rand:uniform(length(?ALL_SLOTS)), ?ALL_SLOTS),
      timer:send_after(
        NextMessageTime - (werkzeug:getUTC() rem NextMessageTime) + Offset, PID, sending_time
      ),

      util:logt(?FILENAME, ["Ablaufplanung gestartet mit PID ", pid_to_list(PID)]);
    kill ->
      util:logt(?FILENAME, ["Ablaufplanung beendet. (im Start)"]);
    Any ->
      io:format("Unerwartete Nachricht an Ablaufplanung (erwarte listener): ~w~n", [Any]),
      init(Offset)
  end.

loop(Offset, ClassAOffset, ClassAAmount, AvailableSlots, SlotEndListener, SendingTimeListener) ->
  receive
    {slot, Slot} ->
      loop(Offset, ClassAOffset, ClassAAmount, lists:delete(Slot, AvailableSlots), SlotEndListener, SendingTimeListener);
    {slot_time, {NewClassAOffset, Slot}} ->
      loop(Offset, (ClassAOffset * ClassAAmount + NewClassAOffset) / (ClassAAmount + 1),
        ClassAAmount, lists:delete(Slot, AvailableSlots), SlotEndListener, SendingTimeListener
      );

    slot_ended ->
      timer:send_after((werkzeug:getUTC() + Offset) rem ?SLOT_DURATION, self(), slot_ended),
      util:distribute(slot_ended, SlotEndListener),
      util:logt(?FILENAME, "Ablaufplanung meldet Slotende."),
      loop(Offset, ClassAAmount, ClassAAmount, AvailableSlots, SlotEndListener, SendingTimeListener);
    frame_ended ->
      timer:send_after((werkzeug:getUTC() + Offset) rem ?FRAME_DURATION, self(), frame_ended),
      util:logt(?FILENAME, "Ablaufplanung meldet Frameende."),
      loop((ClassAOffset * ClassAAmount + Offset) / (ClassAAmount + 1), 0, 0,
        ?ALL_SLOTS, SlotEndListener, SendingTimeListener
      );
    sending_time ->
      Slot = lists:nth(rand:uniform(length(AvailableSlots)), AvailableSlots),
      timer:send_after((werkzeug:getUTC() + Offset) rem (?FRAME_DURATION + Slot * ?SLOT_DURATION), self(), sending_time),
      util:distribute(
        {sending_time, {Slot, werkzeug:getUTC() + Offset}}, SendingTimeListener
      ),
      loop(Offset, ClassAOffset, ClassAAmount, AvailableSlots, SlotEndListener, SendingTimeListener);
    kill ->
      util:logt(?FILENAME, ["Ablaufplanung beendet."]);
    Any ->
      io:format("Unerwartete Nachricht an Ablaufplanung: ~w~n", [Any]),
      loop(Offset, ClassAAmount, ClassAAmount, AvailableSlots, SlotEndListener, SendingTimeListener)
  end.