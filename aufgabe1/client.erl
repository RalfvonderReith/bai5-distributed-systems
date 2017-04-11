%%%-------------------------------------------------------------------
%%% @author Eugen Deutsch
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(client).
-author("Steven").


%% API
-compile(export_all).
% -export([start/1]).
%----------------------------------------------------------------------------------------------------------------------
% constants
%----------------------------------------------------------------------------------------------------------------------
% files
-define(CONFIG_FILE, "client.cfg").
-define(GROUP_NUMBER, 01).
-define(TEAM_NUMBER, 05).

% cfg property names
-define(CLIENTS, clients).
-define(LIFETIME, lifetime).
-define(SERVER_NAME, servername).
-define(SERVER_NODE, servernode).
-define(SENDING_INTERVAL, sendeintervall).

% messages
-define(START_MESSAGE, "Start: ").

% numbers
-define(MIL_TO_SEC, 1000).
-define(MIN_SENDING_INTERVAL, 2 * MIL_TO_SEC).
-define(EDITOR_LOOP_AMOUNT, 5).
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
% initialization and starts the clients.
start() ->
  {Clients, Lifetime, ServerName, ServerNode, SendInterval} = cfg_entries(config_list()),

  Server = {ServerName, ServerNode}, io:format("Server: ~w~n", [Server]),
  start_clients(Clients, Lifetime, SendInterval * ?MIL_TO_SEC, Server).

start_clients(ClientNumber, Lifetime, SendInterval, Server) -> % TODO: decrement clientNumber
  timer:kill_after(Lifetime,
    spawn(client, start_client, [ClientNumber, SendInterval, Server])
  ),
  io:format(lists:concat(["Client ", ClientNumber, " gestartet\n"])),
  start_clients(ClientNumber + 1, Lifetime, SendInterval, Server).

start_client(ClientNumber, Node, SendingInterval, Server) ->
  LogFile = logging_file_name(ClientNumber, Node),
  werkzeug:logging(LogFile, client_start_message(ClientNumber, Node, self())),
  editor_message_loop(?EDITOR_LOOP_AMOUNT, LogFile, ClientNumber, SendingInterval, Server).

%--------------------------------------------------------------------
% editor
%--------------------------------------------------------------------
-spec editor_message_loop(pos_integer(), string(), integer(), integer(), tuple()) -> any(). % TODO: Does tuple work?
editor_message_loop(LoopCounter, LogFile, ClientNumber, SendingInterval, Server) ->
  Server ! {self(), getmsgid},
  {_, Node} = Server,
  receive
    {nid, MessageNumber} ->
      editor_send_message(LoopCounter, LogFile, ClientNumber, Node, MessageNumber, SendingInterval, Server);
    Any -> werkzeug:logging(LogFile, lists:concat([prefix_message_format(ClientNumber, Node, self()),
      "Nachrichtennummer erwartet, aber ", Any, " bekommen"]))
  end.

-spec editor_send_message(pos_integer(), string(), integer(), string(), integer(), pos_integer(), tuple()) -> any().
editor_send_message(0, LogFile, ClientNumber, _, MessageNumber, SendingInterval, Server) ->
  werkzeug:logging(LogFile, forgotten_message_format(MessageNumber)),

  NewSendingInterval = sendingInterval(LogFile, SendingInterval),
  timer:sleep(NewSendingInterval),
  reader(LogFile, ClientNumber, NewSendingInterval, Server);

editor_send_message(LoopCounter, LogFile, ClientNumber, Node, MessageNumber, SendingInterval, Server) ->
  TSclientout = werkzeug:timeMilliSecond(),

  Msg = editor_message(ClientNumber, Node, self(), MessageNumber),
  werkzeug:logging(LogFile, Msg),

  timer:sleep(SendingInterval),
  Server ! {dropmessage, [MessageNumber, Msg, TSclientout]},

  editor_message_loop(LoopCounter - 1, LogFile, ClientNumber, SendingInterval, Server).


-spec sendingInterval(string(), integer()) -> integer().
sendingInterval(LogFile, SendingInterval) ->
  Random = random:uniform(),
  NewInterval =
    if Random > 0.5 -> min(SendingInterval * 1.5, ?MIN_SENDING_INTERVAL);
      true -> min(SendingInterval * 0.5, ?MIN_SENDING_INTERVAL)
    end,
  werkzeug:logging(LogFile, new_interval_format(NewInterval)),
  trunc(NewInterval).
%--------------------------------------------------------------------
% reader
%--------------------------------------------------------------------
-spec reader(string(), integer(), pos_integer(), tuple()) -> any().
reader(LogFile, ClientNumber, SendingInterval, Server) ->
  Server ! {self(), getmessages},
  {_, Node} = Server,
  receive
    {reply, [MessageNumber, _Msg, TSclientout, TShbqin, TSdlqin, TSdlqout], Terminated} ->
      werkzeug:logging(LogFile,
        reader_message(ClientNumber, Node, self(), MessageNumber, TSclientout, TShbqin, TSdlqin, TSdlqout)
      ),
      next(Terminated, LogFile, ClientNumber, SendingInterval, Server);
    Any ->
      werkzeug:logging(LogFile, lists:concat([prefix_message_format(ClientNumber, Node, self()),
        "Nachrichten erwartet, aber ", Any, " bekommen"])
      ),
      reader(LogFile, ClientNumber, SendingInterval, Server)
  end.

-spec next(atom(), string(), integer(), pos_integer(), tuple()) -> any().
next(false, LogFile, ClientNumber, SendingInterval, Server) ->
  reader(LogFile, ClientNumber, SendingInterval, Server);
next(true, LogFile, ClientNumber, SendingInterval, Server) ->
  editor_message_loop(?EDITOR_LOOP_AMOUNT, LogFile, ClientNumber, SendingInterval, Server).
%----------------------------------------------------------------------------------------------------------------------
% private helper
%----------------------------------------------------------------------------------------------------------------------
%%% file format
%--------------------------------------------------------------------
% Returns the file name format for the logfile. (client_<number><node>.log)
% Example: Client_2client@KI-VS.log
-spec logging_file_name(integer(), string()) -> string().
logging_file_name(ClientNumber, Node) -> io_lib:format("client_~w~w.log", [ClientNumber, Node]).

%--------------------------------------------------------------------
%%% message format
%--------------------------------------------------------------------
% Defines the prefix of almost all messages of the client.
-spec prefix_message_format(integer(), string(), pid()) -> string().
prefix_message_format(ClientNumber, Node, PID) ->
  lists:concat([ClientNumber, "~client@", Node, pid_to_list(PID), "-C-", ?GROUP_NUMBER, "-", ?TEAM_NUMBER, ": "]).

client_start_message(ClientNumber, Node, PID) ->
  lists:concat(
    [prefix_message_format(ClientNumber, Node, PID), werkzeug:timeMilliSecond(),".\r\n"]
  ).

%%% editor
editor_message(ClientNumber, Node, PID, MessageNumber) ->
  lists:concat(
    [prefix_message_format(ClientNumber, Node, PID),
      MessageNumber, "te_Nachricht. Sendezeit: ", werkzeug:timeMilliSecond(), "(", MessageNumber, ")\r\n"]
  ).
% TODO: Wozu das r? Und wieso hier \ statt ~?


% Returns the string to represent the message for interval switching.
-spec new_interval_format(interger()) -> string().
new_interval_format(NewInterval) ->
  lists:concat(["Neues Sendeintervall: ", NewInterval ++ " Sekunden (", NewInterval, ")~n"]).

forgotten_message_format(MessageNumber) ->
  lists:concat([MessageNumber, "te_Nachricht um ", werkzeug:timeMilliSecond(), "- vergessen zu senden ******\n"]).

%%% reader
reader_message(ClientNumber, Node, PID, MessageNumber, TSclientout, TShbqin, TSdlqin, TSdlqout) ->
  lists:concat(
    [prefix_message_format(ClientNumber, Node, PID),
      MessageNumber, "te_Nachricht. C Out: ", TSclientout, " HBQ In: ", TShbqin,
      " DLQ In: ", TSdlqin, " DLQ Out: ", TSdlqout, ".*******; C In: ", werkzeug:timeMilliSecond(), ")\r\n"]
    % TODO: Nur wenn die PID übereinstimmt *******
  ).
%--------------------------------------------------------------------
% config
%--------------------------------------------------------------------
% Loads the config file and returns its values in a list.
-spec config_list() -> list().
config_list() ->
  {ok, ConfigList} = file:consult(?CONFIG_FILE),
  io:format("~p Datei geöffnet.~n", [?CONFIG_FILE]),
  ConfigList.

% Returns the cfg entries from the given ConfigList. (config stored in ?CLIENT_FILE)
-spec cfg_entries(list()) -> tuple().
cfg_entries(ConfigList) ->
  Clients = cfg_entry(?CLIENTS, ConfigList),
  Lifetime = cfg_entry(?LIFETIME, ConfigList),
  ServerName = cfg_entry(?SERVER_NAME, ConfigList),
  ServerNode = cfg_entry(?SERVER_NODE, ConfigList),
  SendInterval = cfg_entry(?SENDING_INTERVAL, ConfigList),
  {Clients, Lifetime, ServerName, ServerNode, SendInterval}.

% returns the value with the same name as the given atom (EntryName) from the ConfigList.
-spec cfg_entry(atom(), list()) -> any().
cfg_entry(EntryName, ConfigList) ->
  {ok, Result} = werkzeug:get_config_value(EntryName, ConfigList),
  io:format("~w wurde aus der config Datei ausgelesen mit dem Wert: ~w~n", [EntryName, Result]),
  Result.

%--------------------------------------------------------------------
% server connection
%--------------------------------------------------------------------

%serverNodeConnection(ServerName, ServerNode) ->
%  net_adm:ping(ServerNode),
%  timer:sleep(500), % TODO: WIESO IST DAS HIER NÖTIG?

