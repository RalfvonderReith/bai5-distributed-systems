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
%"C:\Program Files\erl8.3\bin\erl" -sname ns -setcookie zummsel
%"C:\Program Files\erl8.3\bin\erl" -sname chef -setcookie zummsel
%"C:\Program Files\erl8.3\bin\erl" -sname st -setcookie zummsel
%{chef,'chef@DESKTOP-FMLRDQI'} !
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
% {TeamNumber, GroupNumber, NameService, CoordinatorName}
% {WorkingTime, TermTime, Quota}
start(GgtNumber, StarterNumber, SteerConfig, GgtConfig) ->
  {TeamNumber, GroupNumber, NameService, CoordinatorName} = GgtConfig,
  GgtName = ggt_name(GroupNumber, TeamNumber, GgtNumber, StarterNumber), % 16
  io:format("FileName: ~w~n", [GgtName]),
  LogFile = logging_file_name(GgtName),
  file:delete(LogFile),
  start_log(LogFile, GgtName),

  register(GgtName, self()),
  register_on_name_service(NameService, GgtName),
  register_log(LogFile),

  Coordinator = lookup(NameService, CoordinatorName),
  Neighbours = register_on_coordinator(Coordinator, GgtName, LogFile),
  wait_for_pm_loop(
    LogFile,
    SteerConfig, Coordinator, NameService,
    GgtName, werkzeug:getUTC(), ?PRE_MI, Neighbours
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
register_on_coordinator(Coordinator, GgtName, LogFile) ->
  Coordinator ! {hello, GgtName},
  hello_log(LogFile),
  receive
    {setneighbors, LeftN, RightN} ->
      left_neighbor_bound_log(LogFile, LeftN),
      right_neighbor_bound_log(LogFile, RightN),
      {LeftN, RightN};
    Any ->
      io:format("Erwarte Nachbaren durch setneighbors, bekam aber: ~w~n", [Any]),
      register_on_coordinator(Coordinator, GgtName, LogFile)
  end.

wait_for_pm_loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, StartTermTime, Mi, Neighbors) ->
  receive
    {setpm, InitMi} ->
      pm_log(LogFile, InitMi, GgtName),

      {_, TermTime, _} = SteerConfig,
      {ok, NewTermTimer} = timer:send_after(TermTime, self(), term),
      loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, NewTermTimer, werkzeug:getUTC(), InitMi, Neighbors, 0);
    {From, {vote, Initiator}} ->
      CurrentTime = werkzeug:getUTC(),
      {_, TermTime, _} = SteerConfig,
      if (CurrentTime - StartTermTime) > (TermTime * ?TERM_VOTE_FACTOR) -> % 22
        From ! {voteYes, GgtName},
        io:format("Stimme ja für: ~w~n", [Initiator]);
        true -> io:format("Stimme nein für ~w~n", [Initiator])
      end,
      wait_for_pm_loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, StartTermTime, Mi, Neighbors);
    {voteYes, Name} ->
      io:format("Alten vote abgefangen von: ~w~n", [Name]),
      wait_for_pm_loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, StartTermTime, Mi, Neighbors);
    Any ->
      io:format("Initiales mi erwartet, aber ~w bekommen.~n", [Any]),
      wait_for_pm_loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, StartTermTime, Mi, Neighbors)
  end.

loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, TermTimer, StartTermTime, Mi, Neighbors, ReachedQuota) ->
  {_, _, Quota} = SteerConfig,
  if ReachedQuota >= Quota ->
    term_log(LogFile, Mi),
    Coordinator ! {self(), briefterm, {GgtName, Mi, erlang:timestamp()}}, % 22
    wait_for_pm_loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, StartTermTime, Mi, Neighbors);
    true -> ok
  end,

  receive
    {setpm, InitMi} ->
      {ok, cancel} = timer:cancel(TermTimer),
      pm_log(LogFile, InitMi, GgtName),

      {_, TermTime, _} = SteerConfig,
      {ok, NewTermTimer} = timer:send_after(TermTime, self(), term),
      loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, NewTermTimer, werkzeug:getUTC(), InitMi, Neighbors, 0);
    {sendy, Y} ->
      {ok, cancel} = timer:cancel(TermTimer),
      {WorkingTime, TermTime, _} = SteerConfig,

      NewMi = calcMi(LogFile, WorkingTime, Mi, Y, GgtName, Neighbors, Coordinator),
      {ok, NewTermTimer} = timer:send_after(TermTime, self(), term),
      loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, NewTermTimer, werkzeug:getUTC(), NewMi, Neighbors, 0);
    {From, {vote, Initiator}} ->
      CurrentTime = werkzeug:getUTC(),
      {_, TermTime, _} = SteerConfig,
      if (CurrentTime - StartTermTime) > (TermTime * ?TERM_VOTE_FACTOR) -> % 22
        From ! {voteYes, GgtName};
        true -> vote_no_log(LogFile, GgtName, Initiator)
      end,
      loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, TermTimer, StartTermTime, Mi, Neighbors, 0);
    {voteYes, Name} ->
      {_, _, Quota} = SteerConfig,
      vote_log(LogFile, GgtName, Name),
      loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, TermTimer, StartTermTime, Mi, Neighbors, ReachedQuota + 1);
    term ->
      NameService ! {self(), {multicast, vote, GgtName}},
      term_init_log(LogFile, GgtName, Mi),
      loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, TermTimer, StartTermTime, Mi, Neighbors, 0);
    kill ->
      kill_log(LogFile, GgtName);
    {From, tellmi} ->
      From ! {mi, Mi},
      loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, TermTimer, StartTermTime, Mi, Neighbors, ReachedQuota);
    {From, pingGGT} ->
      From ! {pongGGT, GgtName},
      loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, TermTimer, StartTermTime, Mi, Neighbors, ReachedQuota);
    Any ->
      io:format("Unerwartete Nachricht bekommen (loop): ~w~n", [Any]),
      loop(LogFile, SteerConfig, Coordinator, NameService, GgtName, TermTimer, StartTermTime, Mi, Neighbors, ReachedQuota)
  end.

calcMi(LogFile, WorkTime, Mi, Y, GgtName, Neighbors, Coordinator) ->
  timer:sleep(WorkTime),
  if Mi > Y ->
    NewMi = ((Mi - 1) rem Y) + 1,
    Coordinator ! {briefmi, {GgtName, NewMi, erlang:timestamp()}},

    {LeftN, RightN} = Neighbors,
    LeftN ! {sendy, NewMi},
    RightN ! {sendy, NewMi},
    sendy_log(LogFile, Y, Mi, NewMi),
    NewMi;
    true ->
      sendy_log(LogFile, Y, Mi),
      Mi
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

vote_log(LogFile, GgtName, VoteGgt) ->
  log(
    LogFile,
    [GgtName, ": stimme ab (", VoteGgt, ") mit >JA< gestimmt. ", werkzeug:timeMilliSecond()]
  ).

vote_no_log(LogFile, GgtName, VoteGgt) ->
  log(
    LogFile,
    [GgtName, ": stimme ab (", VoteGgt, ") mit >NEIN< gestimmt und ignoriert."]
  ).

term_log(LogFile, Mi) ->
  log(LogFile, ["Koordinator Terminierung gemeldet mit ", Mi, ". ", werkzeug:timeMilliSecond()]).
%----------------------------------------------------------------------------------------------------------------------
% shortcuts
%----------------------------------------------------------------------------------------------------------------------
% Used as a shortcut to write a message as a string into the file.
-spec log(string(), list()) -> atom().
log(LogFile, Message) -> werkzeug:logging(LogFile, [lists:concat(Message), "\n"]).

lookup(Nameservice, Name) ->
  Nameservice ! {self(), {lookup, Name}},
  receive
    {pin, {Name, Node}} -> {Name, Node};
    not_found -> io:format("Name ~w nicht gefunden.~n", [Name])
  end.