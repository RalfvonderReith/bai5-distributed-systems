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
% other
-define(EMPTY_BINARY, list_to_binary([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24])).
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
start(LogFile, Class, Sender) ->
  util:log(LogFile, ["Nachrichtengenerator: Gestartet mit PID ", pid_to_list(self())]),
  loop(LogFile, list_to_binary(Class), ?EMPTY_BINARY, Sender).

loop(LogFile, Class, CurrentData, Sender) ->
  receive
    {input, Data} ->
      %io:format("Bekam Nachricht von Quelle: ~p~n", [Data]),
      loop(LogFile, Class, list_to_binary(Data), Sender);
    {sending_time, {Slot, Time}} ->
      Message = <<Class:1/binary, CurrentData:24/binary, Slot:8/integer, Time:64/integer-big>>,
      util:logt(LogFile, ["Nachrichtengenerator: Nachricht ", werkzeug:to_String(werkzeug:message_to_string(Message)), " vorbereitet."]),
      Sender ! {send_message, Message},
      loop(LogFile, Class, CurrentData, Sender);
    Any ->
      io:format("Input erwartet, aber ~w bekommen.~n", [Any]),
      loop(LogFile, Class, CurrentData, Sender)
  end.