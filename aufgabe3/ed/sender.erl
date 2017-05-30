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
% functions
%----------------------------------------------------------------------------------------------------------------------
start(LogFile, Interface, Addr, Port) ->
  Socket = werkzeug:openSe(Interface, Port),
  util:logt(LogFile, ["Sender: Gestartet mit PID ", pid_to_list(self())]),
  loop(LogFile, Socket, Addr, Port).

loop(LogFile, Socket, Addr, Port) ->
  receive
    {send_message, Message} ->
      gen_udp:send(Socket, Addr, Port, Message),
      %util:logt(LogFile, ["Sender: Nachricht abgeschickt: ", werkzeug:to_String(werkzeug:message_to_string(Message)]),
      loop(LogFile, Socket, Addr, Port);
    Any ->
      io:format("Sender Nachricht erwartet, aber ~w bekommen.~n", [Any]),
      loop(LogFile, Socket, Addr, Port)
  end.
