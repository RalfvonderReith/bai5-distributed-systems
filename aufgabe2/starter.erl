%%%-------------------------------------------------------------------
%%% @author Tom
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Mai 2017 13:01
%%%-------------------------------------------------------------------
-module(starter).
-author("Tom").

%% API
-export([start/1]).
%----------------------------------------------------------------------------------------------------------------------
% constants
%----------------------------------------------------------------------------------------------------------------------
% files
-define(CONFIG_FILE, "ggt.cfg").

% cfg property names
-define(GROUP_NUMBER, praktikumsgruppe).
-define(TEAM_NUMBER, teamnummer).
-define(NAME_SERVICE_NODE, nameservicenode).
-define(NAME_SERVICE_NAME, nameservicename).
-define(COORDINATOR_NAME, koordinatorname). % --> spec: 9
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
start(StarterNumber) ->
  LogFile = logging_file_name(StarterNumber),
  file:delete(LogFile),
  start_log(LogFile, StarterNumber),
  GgtConfig = cfg_entries(config_list(LogFile), LogFile),

  {_, _, {NameServiceName, NameServiceNode}, CoordinatorName} = GgtConfig,
  util:serverNodeConnection(NameServiceNode),
  log(LogFile, ["Nameservice gebunden..."]),

  Coordinator = lookup({NameServiceName, NameServiceNode}, CoordinatorName),
  log(LogFile, ["Koordinator ", CoordinatorName, "(", CoordinatorName, ") gebunden."]),

  {WorkingTime, TermTime, Quota, GgtAmount} = get_steering_val(LogFile, Coordinator),
  io:format("post steering"),
  start_ggt(StarterNumber, GgtAmount, {WorkingTime, TermTime, Quota}, GgtConfig).

start_ggt(_, 0, _, _) -> ok;
start_ggt(StarterNumber, GgtNumber, SteerConfig, GgtConfig) ->
  spawn(ggt, start, [StarterNumber, GgtNumber, SteerConfig, GgtConfig]),
  start_ggt(StarterNumber, GgtNumber - 1, SteerConfig, GgtConfig).

get_steering_val(LogFile, Coordinator) ->
  io:format("setsteeringval presend: ~w~n", [Coordinator]),
  Coordinator ! {self(), getsteeringval},
  io:format("setsteeringval postsend, receive...~n"),
  receive
    {steeringval, WorkingTime, TermTime, Quota, GgtAmount} ->
      steering_val_log(LogFile, WorkingTime, TermTime, Quota, GgtAmount),
      {WorkingTime, TermTime, Quota, GgtAmount};
    Any ->
      io:format("get_steering_val unerwartete Nachricht: ~w~n", [Any]),
      get_steering_val(LogFile, Coordinator)
  end.
%--------------------------------------------------------------------
% config
%--------------------------------------------------------------------
% Loads the config file and returns its values in a list.
-spec config_list(string()) -> list().
config_list(LogFile) ->
  {ok, ConfigList} = file:consult(?CONFIG_FILE),
  log(LogFile, [?CONFIG_FILE, " geöffnet..."]),
  ConfigList.

% Returns the cfg entries from the given ConfigList. (config stored in ?CLIENT_FILE)
-spec cfg_entries(list(), string()) -> tuple().
cfg_entries(ConfigList, LogFile) ->
  TeamNumber = cfg_entry(?TEAM_NUMBER, ConfigList),
  GroupNumber = cfg_entry(?GROUP_NUMBER, ConfigList),
  NameServiceNode = cfg_entry(?NAME_SERVICE_NODE, ConfigList),
  NameServiceName = cfg_entry(?NAME_SERVICE_NAME, ConfigList),
  CoordinatorName = cfg_entry(?COORDINATOR_NAME, ConfigList),
  log(LogFile, [?CONFIG_FILE, " gelesen..."]),
  {TeamNumber, GroupNumber, {NameServiceName, NameServiceNode}, CoordinatorName}.

% returns the value with the same name as the given atom (EntryName) from the ConfigList.
-spec cfg_entry(atom(), list()) -> any().
cfg_entry(EntryName, ConfigList) ->
  {ok, Result} = werkzeug:get_config_value(EntryName, ConfigList),
  io:format("~w wurde aus der config Datei ausgelesen mit dem Wert: ~w~n", [EntryName, Result]),
  Result.

%----------------------------------------------------------------------------------------------------------------------
% logging
%----------------------------------------------------------------------------------------------------------------------
% Returns the file name format for the logfile. (GGTP_<name><hostname>.log)
-spec logging_file_name(atom()) -> string().
logging_file_name(StarterNumber) ->
  {ok, HostName} = inet:gethostname(),
  lists:concat(["ggtSTARTER_", StarterNumber, "@", HostName, ".log"]).

% Logs the start message for a ggt: <ggtname> Startzeit: <Time> mit PID <pid> auf <node>
start_log(LogFile, StarterNumber) ->
  log(LogFile, ["Starter_", StarterNumber, "-", node(), " Startzeit:", werkzeug:timeMilliSecond(), " mit PID ", pid_to_list(self())]).

steering_val_log(LogFile, WorkingTime, TermTime, Quota, GgtAmount) ->
  log(LogFile, ["getsteeringval: ", WorkingTime, " Arbeitszeit ggT; ",
    TermTime, " Wartezeit Terminierung ggT; ", Quota, " Abstimmungsquote ggT; ",
    GgtAmount, " Anzahl an ggt Prozessen."]).
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
    not_found -> io:format("Name ~w nicht gefunden.~n", [Name]);
    Any -> io:format("Nameservice lookup erwartet, aber ~w bekommen.~n", [Any])
  end.