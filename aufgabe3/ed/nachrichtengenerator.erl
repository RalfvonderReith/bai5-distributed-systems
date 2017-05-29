%%%-------------------------------------------------------------------
%%% @author Eugen Deutsch
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(nachrichtengenerator).
-author("Steven").

-compile(export_all).
%----------------------------------------------------------------------------------------------------------------------
% constants
%----------------------------------------------------------------------------------------------------------------------
% names
-define(FILENAME, "nachrichtengenerator.log").

%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
start(Class, MessageListener) ->
  PID = spawn(nachrichtengenerator, loop, [Class, empty, MessageListener]),
  util:log(?FILENAME, ["Nachrichtengenerator gestartet mit PID ", pid_to_list(PID)]),
  PID.

loop(Class, CurrentData, MessageListener) ->
  receive
    {input, Data} ->
      loop(Class, Data, MessageListener);
    {sending_time, {Slot, Time}} ->
      Message = <<Class:1/binary, CurrentData:24/binary, Slot:8/integer, Time:64/integer-big>>,
      util:distribute({send_message, Message}, MessageListener),
      util:log(?FILENAME, ["Daten von Nachrichtengenerator losgeschickt. (", Message, ")"]),
      loop(Class, CurrentData, MessageListener);
    kill ->
      util:logt(?FILENAME, ["Nachrichtengenerator beendet."]);
    Any ->
      io:format("Input erwartet, aber ~w bekommen.~n", [Any]),
      loop(Class, CurrentData, MessageListener)
  end.