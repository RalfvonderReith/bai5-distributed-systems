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
% names
-define(FILENAME, "quelle.log").

% numbers
-define(INPUT_SIZE, 24).
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
-spec start(list()) -> pid().
start(Nachrichtengenerator) ->
  file:delete(?FILENAME),
  util:log(?FILENAME, ["Quelle gestartet mit PID ", pid_to_list(self())]).
  %loop(Nachrichtengenerator).


-spec loop(list()) -> no_return().
loop(Nachrichtengenerator) ->
  case io:get_chars('', ?INPUT_SIZE) of
    eof ->
      %io:format("Eof erreicht... versuche es nochmal.~n"),
      loop(Nachrichtengenerator);
    {error, Error} ->
      %io:format("Quelle: Fehler beim lesen des inputs: ~w~n", [Error]),
      loop(Nachrichtengenerator);
    Data ->
      %io:format("Naechste Nachricht: ~p~n", [Data]),
      Nachrichtengenerator ! {input, Data},
      loop(Nachrichtengenerator)
  end.

