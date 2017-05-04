-module(dlq).
-export([initDLQ/2, delDLQ/1, deliverMSG/4, push2DLQ/3, expectedNr/1]).

-compile(debug_info).

%initDLQ(SIZE, DATEI) -> {SIZE, []}
%creates and returns a new, empty DLQ
initDLQ(SIZE, LogFile) -> %Groessenanforderung aus #02
		werkzeug:logging(LogFile, "DLQ: DLQ initialisiert\r\n"),
		{SIZE, []}.

%delDLQ(DLQ) -> ok
%deletes the DLQ and returns ok
delDLQ(_) -> 	io:format("dlq: delete dlq\r\n"),
				ok.

%deliverMSG(NNr, PID, DLQ, LogFile) -> SentNNr
%searches for Message with Number NNr and sends it to PID and returns number of sent message.
%if it is not available, returns oldest message to PID instead.
deliverMSG(NNr, PID, DLQ, LogFile) ->
				{_SIZE, MSGList} = DLQ,
				io:format("dlq: deliver message\r\n"),
				MSG = findMSG(NNr, MSGList),
				[FIRST_MSG|_OTHER_MSGS] = MSGList,
				Terminated = (MSG == FIRST_MSG),
				%append timestamp out
				%send message
				PID ! {reply, lists:concat([MSG,[erlang:now()]]), Terminated},
				[Number|_REST] = MSG,
				werkzeug:logging(LogFile, io_lib:format("DLQ: Nachricht ~w an Client~w ausgeliefert.\r\n", [Number, PID])),
				Number.

%push2DLQ(Msg, Queue, Logfile) -> new DLQ
%push a message into the dlq and if dlq exceeds max_length, drop last message.
push2DLQ([NNr, Msg, TSclientout, TShbqin], DLQ, LogFile) ->
				{Size, MSGList} = DLQ,
				%hänge Zeitstempel an Nachricht und Tupel entsprechend #03
				Message = [NNr, lists:concat([Msg,"|dlqin:",werkzeug:timeMilliSecond()]), TSclientout, TShbqin, erlang:now()],
				io:format("dlq: push message into DLQ"),
				%prepend message and add in-timestamp
				MSGListWithNewMessage = lists:concat([[Message],MSGList]),
				werkzeug:logging(LogFile, lists:concat(["DLQ: Nachricht ",integer_to_list(NNr)," in DLQ eingefuegt.\r\n"])),
				%check for length, if list is too long: droplast(List)
				{Size, checkLength(Size, MSGListWithNewMessage)}.

%expectedNr(Queue) -> Number
%returns the expected Message Number.
expectedNr({_SIZE, []}) -> 
				io:format("dlq: get expected Number\r\n"),
				1;
expectedNr({_SIZE, [[NNr, _Msg, _TSco, _TShbqin, _TSdlqin]|_REST]}) ->
				io:format("dlq: get expected Number\r\n"),
				NNr+1.

%findMSG(NNr, MSGList) -> MSG
%searches for a message with NNr in DLQ and returns it. 
%if no such message is present, return last message (oldest).

%if requested number is smaller than smallest number -> return oldest message
findMSG(NNr, []) -> [NNr-1, "no new messages available", erlang:now(), erlang:now(), erlang:now()];
findMSG(NNr, MsgList) ->
	[MsgNNr|Rest] = lists:last(MsgList),
	if
		MsgNNr >= NNr ->
			[MsgNNr|Rest];
		NNr > MsgNNr ->
			findMSG(NNr, lists:droplast(MsgList))
	end.
%checkLength(Size MSGList) -> MSGList
%checks length of queue and removed last element, if list is too long.
checkLength(Size, MessageList) -> checkLengthHelp(Size, MessageList, [], 0).
checkLengthHelp(_Size, [], NewMessageList, _Result) -> NewMessageList;
checkLengthHelp(Size, _, NewMessageList, Size) -> NewMessageList;
checkLengthHelp(Size, [Elem|Rest], NewMessageList, Result) -> checkLengthHelp(Size, Rest, lists:append(NewMessageList, [Elem]), Result+1).
