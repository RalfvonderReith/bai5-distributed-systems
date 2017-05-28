%%%-------------------------------------------------------------------
%%% @author Eugen Deutsch
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(sender).
-author("Steven").

-compile(export_all).
%----------------------------------------------------------------------------------------------------------------------
% constants
%----------------------------------------------------------------------------------------------------------------------
% names
-define(FILENAME, "sender.log").

%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
start(Socket, Addr, Port) ->
  PID = spawn(sender, loop, [Socket, Addr, Port]),
  util:log(?FILENAME, ["Sender gestartet mit PID ", pid_to_list(PID)]),
  PID.

loop(Socket, Addr, Port) ->
  receive
    {send_message, Message} ->
      util:log(?FILENAME, ["Nachricht beim Sender angekommen. (", Message, ")"]),
      gen_udp:send(Socket, Addr, Port, Message),
      loop(Socket, Addr, Port);
    kill ->
      util:logt(?FILENAME, ["Sender beendet."]);
    Any ->
      io:format("Sender Nachricht erwartet, aber ~w bekommen.~n", [Any]),
      loop(Socket, Addr, Port)
  end.
