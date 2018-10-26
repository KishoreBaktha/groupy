%%%-------------------------------------------------------------------
%%% @author kishorebaktha
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Sep 2018 9:51 AM
%%%-------------------------------------------------------------------
-module(gms2).
-author("kishorebaktha").

%% API
-compile(export_all).

start(Id) ->
  Rnd = random:uniform(1000),
  Self = self(),
  {ok, spawn_link(fun()-> init(Id, Rnd, Self) end)}.

init(Id, Rnd, Master) ->
  random:seed(Rnd, Rnd, Rnd),
  leader(Id, Master, [], [Master]).

start(Id, Grp) ->
  Rnd = random:uniform(1000),
  Self = self(),
  {ok, spawn_link(fun()-> init(Id,Rnd, Grp, Self) end)}.

init(Id,Rnd, Grp, Master) ->
  random:seed(Rnd, Rnd, Rnd),
  Self = self(),
  %timer:sleep(15000),
  Grp ! {join, Master, Self},
  receive
    {view, [Leader|Slaves], Group} ->
      Master ! {view, Group},
      Ref=erlang:monitor(process, Leader),
      slave(Id,Ref, Master, Leader, Slaves, Group)
  after 2000 ->
    io:format("no reply~n"),
    Master ! {error, "no reply from leader"}
  end.


leader(Id, Master, Slaves, Group) ->
  receive
    {mcast, Msg} ->
      % io:format("received2"),
      bcast(Id, {msg, Msg}, Slaves),
      Master ! Msg,
      leader(Id, Master, Slaves, Group);
    {join, Wrk, Peer} ->
      Slaves2 = lists:append(Slaves, [Peer]),
      Group2 = lists:append(Group, [Wrk]),
      bcast(Id, {view, [self()|Slaves2], Group2}, Slaves2),
      Master ! {view, Group2},
      leader(Id, Master, Slaves2, Group2);
    status->
      io:format("Slaves-~w~n",[Slaves]),
      io:format("Master-~w~n",[Master]),
      io:format("Group-~w~n",[Group]),
      leader(Id, Master, Slaves, Group);
    stop -> ok
  end.

bcast(Id, Msg, Nodes) ->
  lists:foreach(fun(Node) -> Node ! Msg, crash(Id) end, Nodes).

crash(Id) ->
  case random:uniform(150) of
    150 ->
      io:format("leader ~w: crash~n", [Id]),
      exit(no_luck);
    _ -> ok
  end.

slave(Id,Ref, Master, Leader, Slaves, Group) ->
  receive
    {mcast, Msg} ->
      % io:format("received"),
      Leader ! {mcast, Msg},
      slave(Id,Ref, Master, Leader, Slaves, Group);

    {join, Wrk, Peer} ->
      Leader ! {join, Wrk, Peer},
      slave(Id,Ref, Master, Leader, Slaves, Group);

    {msg, Msg} ->
      Master ! Msg,
       io:format("Message received in ~w is~n",[Id]),
       io:format(" is ~w~n",[Msg]),
      slave(Id,Ref, Master, Leader, Slaves, Group);

    {view, [Leader|Slaves2], Group2} ->
      Master ! {view, Group2},
      slave(Id,Ref, Master, Leader, Slaves2, Group2);

    {'DOWN', Ref, process, Leader, _Reason} ->
      election(Id, Master, Slaves, Group);

    status->
      io:format("Slaves-~w~n",[Slaves]),
      io:format("Master-~w~n",[Master]),
      io:format("Group-~w~n",[Group]),
      io:format("Leader-~w~n",[Leader]),
      io:format("ID-~w~n",[Id]),
      slave(Id, Ref,Master, Leader, Slaves, Group);

    stop ->
      ok end.

election(Id, Master, Slaves, [_|Group]) ->
  Self = self(),
  case Slaves of
    [Self|Rest] ->
      bcast(Id, {view, Slaves, Group}, Rest),
      Master ! {view, Group},
      leader(Id, Master, Rest, Group);
    [Leader|Rest] ->
%%      io:format("id ~w ~n",[Id]),
%%      io:format("electionmessgaehere~n"),
%%      io:format("Leader~w~n",[Leader]),
%%      io:format("Rest~w~n",[Rest]),
      Ref=erlang:monitor(process, Leader),
      %leader(Id,Master,Rest,Group),
      slave(Id,Ref, Master, Leader, Rest, Group)
  end.
