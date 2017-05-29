%%%-------------------------------------------------------------------
%%% @author Steven
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Mai 2017 11:57
%%%-------------------------------------------------------------------
-module(util).
-author("Steven").

%% API
-compile(export_all).
-export([serverNodeConnection/1, config_list/1, as_dict/3]).

%----------------------------------------------------------------------------------------------------------------------
% constants
%----------------------------------------------------------------------------------------------------------------------
% numbers
-define(SERVER_RESPONSE_TIME, 1000).
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------

%--------------------------------------------------------------------
% server connection
%--------------------------------------------------------------------
serverNodeConnection(ServerNode) ->
  ping = net_adm:ping(ServerNode),
  timer:sleep(?SERVER_RESPONSE_TIME).

%--------------------------------------------------------------------
% config
%--------------------------------------------------------------------
% Loads the config file and returns its values in a list.
-spec config_list(string()) -> list().
config_list(ConfigFile) ->
  {ok, ConfigList} = file:consult(ConfigFile),
  io:format("~p Datei geöffnet.~n", [ConfigFile]),
  ConfigList.

as_dict(CfgList, AttributeNameList) -> as_dict(CfgList, AttributeNameList, dict:new()).

% Returns the cfg entries from the given ConfigList.
-spec as_dict(list(), list(), any()) -> any().
as_dict(_, [], CfgDict) -> CfgDict;
as_dict(CfgList, [EntryName|Rest], CfgDict) ->
  as_dict(CfgList, Rest, dict:append(EntryName, cfg_entry(EntryName, CfgList), CfgDict)).

% returns the value with the same name as the given atom (EntryName) from the ConfigList.
-spec cfg_entry(atom(), list()) -> any().
cfg_entry(EntryName, ConfigList) ->
  {ok, Result} = werkzeug:get_config_value(EntryName, ConfigList),
  io:format("~w wurde aus der config Datei ausgelesen mit dem Wert: ~w~n", [EntryName, Result]),
  Result.