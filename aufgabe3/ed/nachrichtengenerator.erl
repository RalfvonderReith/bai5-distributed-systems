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

% other
-define(EMPTY_BINARY, list_to_binary([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24])).
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
start(Class, Sender) ->
  file:delete(?FILENAME),
  util:log(?FILENAME, ["Nachrichtengenerator gestartet mit PID ", pid_to_list(self())]),
  loop(list_to_binary(Class), ?EMPTY_BINARY, Sender).

loop(Class, CurrentData, Sender) ->
  receive
    {input, Data} ->
      io:format("Bekam Nachricht von Quelle: ~p~n", [Data]),
      loop(Class, Data, Sender);
    {sending_time, {Slot, Time}} ->
      %util:log(?FILENAME, ["Bereite Daten zum Senden vor: Class: ", Class, ", CurrentData: ", CurrentData, ", Slot: ", Slot, ", Time: ", Time]),
      Message = <<Class:1/binary, CurrentData:24/binary, Slot:8/integer, Time:64/integer-big>>,
      Sender ! {send_message, Message},
      %util:log(?FILENAME, ["Daten von Nachrichtengenerator losgeschickt. (", Message, ")"]),
      io:format("Nachrichtengenerator sendet: ~p~n", [Message]),
      loop(Class, CurrentData, Sender);
    Any ->
      io:format("Input erwartet, aber ~w bekommen.~n", [Any]),
      loop(Class, CurrentData, Sender)
  end.