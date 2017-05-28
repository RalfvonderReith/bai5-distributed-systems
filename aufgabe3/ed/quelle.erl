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
start(InputListener) ->
  PID = spawn(quelle, loop, [InputListener]),
  util:log(?FILENAME, ["Quelle gestartet mit PID ", pid_to_list(PID)]),
  PID.


-spec loop(list()) -> no_return().
loop(InputListener) ->
  case io:get_chars('', ?INPUT_SIZE) of
    eof ->
      util:log(?FILENAME, ["Eof erreicht... versuche es nochmal."]);
    {error, Error} ->
      io:format(["Quelle: Fehler beim lesen des inputs: ~w~n", Error]);
    Data ->
      util:distribute({input, Data}, InputListener)
  end.

