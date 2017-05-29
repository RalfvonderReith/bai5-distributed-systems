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
start(Socket, Interface, Addr, Port) ->
  file:delete(?FILENAME),
  %Socket = werkzeug:openSeA(Interface, Port),
  util:log(?FILENAME, ["Sender gestartet mit PID ", pid_to_list(self())]),
  loop(Socket, Addr, Port).

loop(Socket, Addr, Port) ->
  receive
    {send_message, Message} ->
      %util:log(?FILENAME, ["Nachricht beim Sender angekommen. (", Message, ")"]),
      io:format("Nachricht beim Sender angekommen. (~p)~n", [Message]),
      gen_udp:send(Socket, Addr, Port, Message),
      loop(Socket, Addr, Port);
    Any ->
      io:format("Sender Nachricht erwartet, aber ~w bekommen.~n", [Any]),
      loop(Socket, Addr, Port)
  end.
