%%%-------------------------------------------------------------------
%%% @author Steven
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Mai 2017 10:46
%%%-------------------------------------------------------------------
-module(ggt).
-author("Steven").

%% API
%-export([]).
-compile(export_all).

%----------------------------------------------------------------------------------------------------------------------
% constants
%----------------------------------------------------------------------------------------------------------------------
% files
-define(CONFIG_FILE, "ggt.cfg").

% numbers
-define(PRE_MI, 0).
-define(TERM_VOTE_FACTOR, 0.5).
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
dummy_start() ->
  % PID3 | PID1, PID2, PID3 | PID1
  register(coord, self()),
  PID1 = spawn(ggt, start, [5, 1, 10, 1, 1, 5, 2, coord, {nameservicename, nameservicenode}]),
  PID2 = spawn(ggt, start, [5, 1, 20, 2, 1, 5, 2, coord, {nameservicename, nameservicenode}]),
  PID3 = spawn(ggt, start, [5, 1, 30, 3, 1, 5, 2, coord, {nameservicename, nameservicenode}]),

  timer:sleep(1000),
  PID1 ! ok,
  PID2 ! ok,
  PID3 ! ok,
  timer:sleep(1000),
  FIRST = ggt_name(5, 1, 10, 1),
  SECOND = ggt_name(5, 1, 20, 2),
  THIRD = ggt_name(5, 1, 30, 3),

  timer:sleep(1000),
  PID1 ! {setneighbors, THIRD, SECOND},
  PID2 ! {setneighbors, FIRST, THIRD},
  PID3 ! {setneighbors, FIRST, SECOND}.

% TODO: Kann man wirklich an den Coordinator senden, oder braucht man den NameService dazu?
start(WorkingTime, TermTime, GgtNumber, StarterNumber, GroupNumber, TeamNumber, Quota, CoordinatorName, NameService) ->
  GgtName = ggt_name(GroupNumber, TeamNumber, GgtNumber, StarterNumber), % 16
  io:format("FileName: ~w~n", [GgtName]),
  LogFile = logging_file_name(GgtName),
  file:delete(LogFile),
  start_log(LogFile, GgtName),

  register(GgtName, self()),
  register_on_name_service(NameService, GgtName),
  register_log(LogFile),

  Neighbours = register_on_coordinator(CoordinatorName, GgtName, LogFile),
  loop(
    LogFile,
    {WorkingTime, TermTime, Quota, CoordinatorName, NameService},
    GgtName, timer:send_after(TermTime, self(), term), werkzeug:getUTC(), ?PRE_MI, Neighbours, 0
  ).

register_on_name_service(NameService, GgtName) ->
  {_, NameServiceNode} = NameService,
  util:serverNodeConnection(NameServiceNode),
  NameService ! {self(), {rebind, GgtName, node()}},
  receive
    ok -> io:format("NameService meldet ok.~n");
    Any ->
      io:format("Erwarte ok vom Namensdienst, bekomme aber: ~w~n", [Any]),
      register_on_name_service(NameService, GgtName)
  end.

% 17
register_on_coordinator(CoordinatorName, GgtName, LogFile) ->
  CoordinatorName ! {hello, GgtName},
  hello_log(LogFile),
  receive
    {setneighbors, LeftN, RightN} ->
      left_neighbor_bound_log(LogFile, LeftN),
      right_neighbor_bound_log(LogFile, RightN),
      {LeftN, RightN};
    Any ->
      io:format("Erwarte Nachbaren durch setneighbors, bekam aber: ~w~n", [Any]),
      register_on_coordinator(CoordinatorName, GgtName, LogFile)
  end.

% TODO: Reduce Parameters
loop(LogFile, Config, GgtName, TermTimer, StartTermTime, Mi, Neighbors, ReachedQuota) ->
  {_, _, Quota, CoordinatorName, NameService} = Config,
  if ReachedQuota >= Quota ->
    term_log(LogFile, Mi),
    CoordinatorName ! {self(), briefterm, {GgtName, Mi, erlang:timestamp()}}, % 22
    loop(LogFile, Config, GgtName, TermTimer, StartTermTime, Mi, Neighbors, 0);
  true -> ok
  end,

  receive
    {setpm, Mi} ->
      pm_log(LogFile, Mi, GgtName),
      loop(LogFile, Config, GgtName, TermTimer, werkzeug:getUTC(), Mi, Neighbors, 0);
    {sendy, Y} ->
      timer:cancel(TermTimer),
      {WorkingTime, TermTime, _, CoordinatorName, _} = Config,

      calcMi(LogFile, WorkingTime, Mi, Y, GgtName, Neighbors, CoordinatorName),
      NewTermTimer = timer:send_after(TermTime, self(), term),
      loop(LogFile, Config, GgtName, NewTermTimer, werkzeug:getUTC(), Mi, Neighbors, 0);
    {From, {vote, Initiator}} -> % TODO: Wozu wird der Initiator benötigt?
      CurrentTime = werkzeug:getUTC(),
      {_, TermTime, _, _, _} = Config,
      if (CurrentTime - StartTermTime) > (TermTime * ?TERM_VOTE_FACTOR) -> % 22
        From ! {voteYes, GgtName}
      end,
      loop(LogFile, Config, GgtName, TermTimer, StartTermTime, Mi, Neighbors, 0);
    {voteYes, Name} ->
      {_, _, Quota, CoordinatorName, NameService} = Config,
      vote_log(LogFile, GgtName, Name, 2),
      loop(LogFile, Config, GgtName, TermTimer, StartTermTime, Mi, Neighbors, ReachedQuota + 1);
    term ->
      {_, _, _, _, NameService} = Config,
      NameService ! {self(), {multicast, vote, GgtName}},
      term_init_log(LogFile, GgtName, Mi),
      loop(LogFile, Config, GgtName, TermTimer, StartTermTime, Mi, Neighbors, 1);
    kill ->
      kill_log(LogFile, GgtName);
    {From, tellmi} ->
      From ! {mi, Mi},
      loop(LogFile, Config, GgtName, TermTimer, StartTermTime, Mi, Neighbors, ReachedQuota);
    {From, pingGGT} ->
      From ! {pongGGT, GgtName},
      loop(LogFile, Config, GgtName, TermTimer, StartTermTime, Mi, Neighbors, ReachedQuota);
    Any ->
      io:format("Erwarte initiales Mi, bekam aber: ~w~n", [Any]),
      loop(LogFile, Config, GgtName, TermTimer, StartTermTime, Mi, Neighbors, ReachedQuota)
  end.

calcMi(LogFile, WorkTime, Mi, Y, GgtName, Neighbors, CoordinatorName) ->
  timer:sleep(WorkTime),
  if Mi > Y ->
    NewMi = ((Mi - 1) rem Y) + 1,
    CoordinatorName ! {briefmi, {GgtName, NewMi, erlang:timestamp()}},

    {LeftN, RightN} = Neighbors,
    LeftN ! {sendy, NewMi},
    RightN ! {sendy, NewMi},
    sendy_log(LogFile, Y, Mi, NewMi);
    true ->
      sendy_log(LogFile, Y, Mi)
  end.

% Creates the ggt name as an atom.
% 16
-spec ggt_name(pos_integer(), pos_integer(), pos_integer(), pos_integer()) -> atom().
ggt_name(GroupNumber, TeamNumber, GgtNumber, StarterNumber) ->
  list_to_atom(lists:concat([GroupNumber, TeamNumber, GgtNumber, StarterNumber])).

%----------------------------------------------------------------------------------------------------------------------
% logging
%----------------------------------------------------------------------------------------------------------------------
% Returns the file name format for the logfile. (GGTP_<name><hostname>.log)
-spec logging_file_name(atom()) -> string().
logging_file_name(GgtName) ->
  {ok, HostName} = inet:gethostname(),
  lists:concat(["GGTP_", GgtName, "@", HostName, ".log"]).

% Logs the start message for a ggt: <ggtname> Startzeit: <Time> mit PID <pid> auf <node>
start_log(LogFile, GgtName) ->
  log(LogFile, [GgtName, " Startzeit: ", werkzeug:timeMilliSecond(), " mit PID ", pid_to_list(self()), " auf ", node()]).

% Logs: "beim Namensdienst und auf Node lokal registriert."
register_log(LogFile) -> log(LogFile, ["beim Namensdienst und auf der Node lokal registriert."]).

% Logs: "beim Koordinator gemeldet."
hello_log(LogFile) -> log(LogFile, ["beim Koordinator gemeldet"]).

% Logs: "Linker Nachbar <neighbor name> (<neighbor name>) gebunden."
left_neighbor_bound_log(LogFile, NeighbourName) -> neighbour_bound_log(LogFile, NeighbourName, "Linker ").

% Logs: "Rechter Nachbar <neighbor name> (<neighbor name>) gebunden."
right_neighbor_bound_log(LogFile, NeighbourName) -> neighbour_bound_log(LogFile, NeighbourName, "Rechter ").

% Logs: "Rechter Nachbar <neighbor name> (<neighbor name>) gebunden."
% Used by left_neighbor_bound_log and right_neighbor_bound_log.
neighbour_bound_log(LogFile, NeighbourName, Side) ->
  log(LogFile, [Side, NeighbourName, "(", NeighbourName, ") gebunden."]).

pm_log(LogFile, Mi, GgtName) ->
  log(LogFile, ["setpm: ", Mi, ". (", GgtName, ")"]).

kill_log(LogFile, GgtName) ->
  log(LogFile, ["Downtime: ", werkzeug:timeMilliSecond(), " vom Client ", GgtName]).

sendy_log(LogFile, Y, OldMi, NewMi) ->
  log(LogFile, ["sendy: ", Y, "(", OldMi, "); berechnet als neues Mi ", NewMi, ". ", werkzeug:timeMilliSecond()]).

sendy_log(LogFile, Y, Mi) ->
  log(LogFile, ["sendy: ", Y, "(", Mi, "); keine Berechnung."]).

term_init_log(LogFile, GgtName, Mi) ->
  log(LogFile, [GgtName, ": initiiere eine Terminierungsabstimmung (", Mi, "). ", werkzeug:timeMilliSecond()]).

vote_log(LogFile, GgtName, VoteGgt, Code) ->
  log(
    LogFile,
    [GgtName, ": stimme ab (", VoteGgt, ") mit >JA< gestimmt(Code ", Code, "). ", werkzeug:timeMilliSecond()] % TODO: Was ist Code?
  ).

term_log(LogFile, Mi) -> % TODO: Wie soll das N ermittelt werden?
  log(LogFile, ["Koordinator ", 1, "te Terminierung gemeldet mit ", Mi, ". ", werkzeug:timeMilliSecond()]).
%----------------------------------------------------------------------------------------------------------------------
% shortcuts
%----------------------------------------------------------------------------------------------------------------------
% Used as a shortcut to write a message as a string into the file.
-spec log(string(), list()) -> atom().
log(LogFile, Message) -> werkzeug:logging(LogFile, [lists:concat(Message), "\n"]).