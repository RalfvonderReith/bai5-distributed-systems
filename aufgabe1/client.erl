%%%-------------------------------------------------------------------
%%% @author Eugen Deutsch
%%% @doc
%%%
%%% @end
%%%-------------------------------------------------------------------
-module(client).
-author("Eugen Deutsch").


%% API
-compile(export_all).
% -export([start/1]).
%----------------------------------------------------------------------------------------------------------------------
% constants
%----------------------------------------------------------------------------------------------------------------------
% files
-define(CONFIG_FILE, "client.cfg").
-define(GROUP_NUMBER, 1).
-define(TEAM_NUMBER, 5).

% cfg property names
-define(CLIENTS, clients).
-define(LIFETIME, lifetime).
-define(SERVER_NAME, servername).
-define(SERVER_NODE, servernode).
-define(SENDING_INTERVAL, sendeintervall). % --> spec: 9

% messages
-define(START_MESSAGE, "Start: ").

% numbers
-define(SEC_TO_MIL, 1000).
-define(MIL_TO_SEC, 0.001).
-define(MIN_SENDING_INTERVAL, 2 * ?SEC_TO_MIL).
-define(EDITOR_LOOP_AMOUNT, 5).
-define(SERVER_RESPONSE_TIME, 1 * ?SEC_TO_MIL).
%----------------------------------------------------------------------------------------------------------------------
% functions
%----------------------------------------------------------------------------------------------------------------------
% initialization and starts the clients.
start() ->
  {Clients, Lifetime, ServerName, ServerNode, SendInterval} = cfg_entries(config_list()),

  Server = {ServerName, ServerNode}, io:format("Server: ~w~n", [Server]),
  serverNodeConnection(ServerNode),

  start_clients(0, Clients, Lifetime * ?SEC_TO_MIL, SendInterval * ?SEC_TO_MIL, Server).

start_clients(ClientAmount, ClientAmount, _, _, _) -> io:format("Alle clienten gestartet (~w)~n", [ClientAmount]);
start_clients(ClientNumber, ClientAmount, Lifetime, SendInterval, Server) ->
  timer:send_after(
    Lifetime,
    spawn(client, start_client, [ClientNumber, SendInterval, Server]),
    die
  ),
  io:format(lists:concat(["Client ", ClientNumber, " gestartet\n"])),
  start_clients(ClientNumber + 1, ClientAmount, Lifetime, SendInterval, Server).

start_client(ClientNumber, SendingInterval, Server) ->
  {_, Node} = Server,
  LogFile = logging_file_name(ClientNumber, Node),
  file:delete(LogFile),
  werkzeug:logging(LogFile, client_start_message(ClientNumber, Node, self())),

  editor_message_loop(?EDITOR_LOOP_AMOUNT, LogFile, ClientNumber, SendingInterval, Server, []).

%--------------------------------------------------------------------
% editor
%--------------------------------------------------------------------
% Ask the server for the message number and sends him a message (5 times) and once not. After that the editor mode is
% over and the client switches into the reader mode.
-spec editor_message_loop(pos_integer(), string(), integer(), integer(), tuple(), list()) -> any().
editor_message_loop(LoopCounter, LogFile, ClientNumber, SendingInterval, Server, EditorMessageList) ->
  Server ! {self(), getmsgid},
  {_, Node} = Server,
  receive
    die ->
      werkzeug:logging(
        LogFile, shut_down_message(ClientNumber, Node, self())
      );
    {nid, MessageNumber} ->
      editor_send_message(
        LoopCounter, LogFile, ClientNumber, Node, MessageNumber, SendingInterval, Server, EditorMessageList
      );
    Any ->
      io:format("Nachrichtennummer erwartet, aber '~w' bekommen~n", [Any]),
      werkzeug:logging(LogFile,
        lists:concat([prefix_message_format(ClientNumber, Node, self()),
          "Nachrichten erwartet, aber etwas anderes bekommen\n"]
        )
      ),
      editor_message_loop(LoopCounter - 1, LogFile, ClientNumber, SendingInterval, Server, EditorMessageList)
  end.

% Asks the server for the message number (previously) without sending a message and switches to the reader.
% EditorMessageList: Contains the message numbers send by this client. This is needed for the reader to mark the
%  received messages which were created by his editor.
% --> spec: 11
-spec editor_send_message(pos_integer(), string(), integer(), string(), integer(), pos_integer(), tuple(), list()) -> any().
editor_send_message(0, LogFile, ClientNumber, _, MessageNumber, SendingInterval, Server, EditorMessageList) ->
  werkzeug:logging(LogFile, forgotten_message_format(MessageNumber)),

  NewSendingInterval = sendingInterval(LogFile, SendingInterval),
  timer:sleep(NewSendingInterval),
  reader(LogFile, ClientNumber, NewSendingInterval, Server, EditorMessageList);

% Ask the server for the message number (previously) and sends a message with it to him.
% --> spec: 9
editor_send_message(LoopCounter, LogFile, ClientNumber, Node, MessageNumber, SendingInterval, Server, EditorMessageList) ->
  TSclientout = werkzeug:timeMilliSecond(),

  Msg = editor_message(ClientNumber, Node, self(), MessageNumber),
  werkzeug:logging(LogFile, Msg),

  timer:sleep(SendingInterval),
  Server ! {dropmessage, [MessageNumber, Msg, TSclientout]},
  NewEditorMessageList = lists:concat([MessageNumber, EditorMessageList]),

  editor_message_loop(LoopCounter - 1, LogFile, ClientNumber, SendingInterval, Server, NewEditorMessageList).

% Returns a new sending interval number, that is 50% greater or smaller (random) than the previous one and at least
% ?MIN_SENDING_INTERVAL.
% --> spec: 10
-spec sendingInterval(string(), integer()) -> pos_integer().
sendingInterval(LogFile, SendingInterval) ->
  Random = rand:uniform(),
  NewInterval =
    if Random > 0.5 -> max(SendingInterval * 1.5, ?MIN_SENDING_INTERVAL);
      true -> max(SendingInterval * 0.5, ?MIN_SENDING_INTERVAL)
    end,
  werkzeug:logging(LogFile, new_interval_format(trunc(NewInterval * ?MIL_TO_SEC))),
  trunc(NewInterval).

%--------------------------------------------------------------------
% reader
%--------------------------------------------------------------------
% Asks the server for messages and logs them until he got all messages and switches then back to the editor mode.
-spec reader(string(), integer(), pos_integer(), tuple(), list()) -> any().
reader(LogFile, ClientNumber, SendingInterval, Server, EditorMessageList) ->
  Server ! {self(), getmessages},
  {_, Node} = Server,
  receive
    {die} ->
      shut_down_message(ClientNumber, Node, self());
    {reply, [MessageNumber, _, TSclientout, TShbqin, TSdlqin, TSdlqout], Terminated} ->
      NewEditorMessageList = lists:delete(MessageNumber, EditorMessageList),
      WasMyEditor = (NewEditorMessageList =/= EditorMessageList),

      werkzeug:logging(LogFile,
        reader_message(WasMyEditor, ClientNumber, Node, self(), MessageNumber, TSclientout, TShbqin, TSdlqin, TSdlqout)
      ),
      next(Terminated, LogFile, ClientNumber, SendingInterval, Server, NewEditorMessageList);
    Any ->
      io:format("Nachrichten erwartet, aber '~w' bekommen~n", [Any]),
      % necessary, because werkzeug:logging doesn't like Any

      werkzeug:logging(LogFile, lists:concat([prefix_message_format(ClientNumber, Node, self()),
        "Nachrichten erwartet, aber etwas anderes bekommen\n"])
      ),
      reader(LogFile, ClientNumber, SendingInterval, Server, EditorMessageList)
  end.

% Chooses the reader (if term/Terminated == false -> messages left) or the editor.
-spec next(boolean(), string(), integer(), pos_integer(), tuple(), list()) -> any().
next(false, LogFile, ClientNumber, SendingInterval, Server, EditorMessageList) ->
  reader(LogFile, ClientNumber, SendingInterval, Server, EditorMessageList);
next(true, LogFile, ClientNumber, SendingInterval, Server, EditorMessageList) ->
  werkzeug:logging(LogFile, no_message_left_format()),
  editor_message_loop(?EDITOR_LOOP_AMOUNT, LogFile, ClientNumber, SendingInterval, Server, EditorMessageList).
%----------------------------------------------------------------------------------------------------------------------
% private helper
%----------------------------------------------------------------------------------------------------------------------
%%% file format
%--------------------------------------------------------------------
% Returns the file name format for the logfile. (client_<number><node>.log)
% Example: Client_2client@KI-VS.log
-spec logging_file_name(integer(), string()) -> string().
logging_file_name(ClientNumber, Node) -> lists:concat(["client_", ClientNumber, Node, ".log"]).

%--------------------------------------------------------------------
%%% message format
%--------------------------------------------------------------------
% Defines the prefix of almost all messages of the client.
-spec prefix_message_format(integer(), string(), pid()) -> string().
prefix_message_format(ClientNumber, Node, PID) ->
  lists:concat([ClientNumber, "-client", Node, pid_to_list(PID), "-C-", ?GROUP_NUMBER, "-", ?TEAM_NUMBER, ": "]).

client_start_message(ClientNumber, Node, PID) ->
  lists:concat(
    [prefix_message_format(ClientNumber, Node, PID), "Start: ", werkzeug:timeMilliSecond(), ".\n"]
  ).

shut_down_message(ClientNumber, Node, PID) ->
  lists:concat([prefix_message_format(ClientNumber, Node, PID), "Lebenszeit um. Wird beendet.\n"]).

%%% editor
editor_message(ClientNumber, Node, PID, MessageNumber) ->
  lists:concat(
    [prefix_message_format(ClientNumber, Node, PID),
      MessageNumber, "te_Nachricht. Sendezeit: ", werkzeug:timeMilliSecond(), "(", MessageNumber, ")\n"]
  ).

% Returns the string to represent the message for interval switching.
-spec new_interval_format(integer()) -> string().
new_interval_format(NewInterval) ->
  lists:concat(["Neues Sendeintervall: ", NewInterval, " Sekunden (", NewInterval, ")\n"]).

forgotten_message_format(MessageNumber) ->
  lists:concat([MessageNumber, "te_Nachricht um ", werkzeug:timeMilliSecond(), "- vergessen zu senden ******\n"]).

%%% reader
reader_message(true, ClientNumber, Node, PID, MessageNumber, TSclientout, TShbqin, TSdlqin, TSdlqout) ->
  lists:concat(
    [prefix_message_format(ClientNumber, Node, PID),
      MessageNumber, "te_Nachricht. C Out: ", TSclientout, " HBQ In: ", TShbqin,
      " DLQ In: ", TSdlqin, " DLQ Out: ", TSdlqout, "*******; C In: ", werkzeug:timeMilliSecond(), "\n"]
  );

reader_message(false, ClientNumber, Node, PID, MessageNumber, TSclientout, TShbqin, TSdlqin, TSdlqout) ->
  lists:concat(
    [prefix_message_format(ClientNumber, Node, PID),
      MessageNumber, "te_Nachricht. C Out: ", TSclientout, " HBQ In: ", TShbqin,
      " DLQ In: ", TSdlqin, " DLQ Out: ", TSdlqout, " ; C In: ", werkzeug:timeMilliSecond(), "\n"]
  ).

% --> spec: 13
%time_difference_message(TSclientout,TShbqin, TSdlqin,TSdlqout) ->
%  .

%server_editor_time_diff(TSclientout,TShbqin) ->
%  if (werkzeug:lessTS())


no_message_left_format() -> "..getmessages..Done...".
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
serverNodeConnection(ServerNode) ->
  net_adm:ping(ServerNode),
  timer:sleep(?SERVER_RESPONSE_TIME).

