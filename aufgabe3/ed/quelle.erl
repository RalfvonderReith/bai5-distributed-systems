%%%-------------------------------------------------------------------
%%% @author Eugen Deutsch
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(quelle).
-author("Steven").

-compile(export_all).
%----------------------------------------------------------------------------------------------------------------------
% constants
%----------------------------------------------------------------------------------------------------------------------
% numbers
-define(INPUT_SIZE, 24).
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
-spec start(any(), any()) -> any().
start(LogFile, Nachrichtengenerator) ->
  util:logt(LogFile, ["Quelle: Gestartet mit PID ", pid_to_list(self())]),
  loop(Nachrichtengenerator).


-spec loop(list()) -> no_return().
loop(Nachrichtengenerator) ->
  case io:get_chars('', ?INPUT_SIZE) of
    eof ->
      loop(Nachrichtengenerator);
    {error, _} ->
      loop(Nachrichtengenerator);
    Data ->
      Nachrichtengenerator ! {input, Data},
      loop(Nachrichtengenerator)
  end.

