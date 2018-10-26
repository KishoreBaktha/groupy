%%%-------------------------------------------------------------------
%%% @author kishorebaktha
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Oct 2018 4:47 PM
%%%-------------------------------------------------------------------
%%%-------------------------------------------------------------------
%%% @author kishorebaktha
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Sep 2018 7:27 AM
%%%-------------------------------------------------------------------
-module(gms1).
-author("kishorebaktha").

%% API
-compile(export_all).

start(Id) ->
  Self = self(),
  {ok, spawn_link(fun()-> init(Id, Self) end)}.

init(Id, Master) ->
  leader(Id, Master, [], [Master]).

start(Id, Grp) ->
  Self = self(),
  {ok, spawn_link(fun()-> init(Id, Grp, Self) end)}.

init(Id, Grp, Master) ->
  Self = self(),
  %io:format("Grp~w~n",[Grp]),
  Grp ! {join, Master, Self},
  receive
    {view, [Leader|Slaves], Group} ->
      Master ! {view, Group},
      % io:format("Group-~w~n",[Group]),
      slave(Id, Master, Leader, Slaves, Group)
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

bcast(Id,Msg, Slaves)->
  lists:foreach(fun(Node)-> Node ! Msg end,Slaves).


slave(Id, Master, Leader, Slaves, Group) ->
  receive
    {mcast, Msg} ->
      % io:format("received"),
      Leader ! {mcast, Msg},
      slave(Id, Master, Leader, Slaves, Group);
    {join, Wrk, Peer} ->
      Leader ! {join, Wrk, Peer},
      slave(Id, Master, Leader, Slaves, Group);
    {msg, Msg} ->
      Master ! Msg,
      slave(Id, Master, Leader, Slaves, Group);
    {view, [Leader|Slaves2], Group2} ->
      Master ! {view, Group2},
      slave(Id, Master, Leader, Slaves2, Group2);
    status->
      io:format("Slaves-~w~n",[Slaves]),
      io:format("Master-~w~n",[Master]),
      io:format("Group-~w~n",[Group]),
      io:format("Leader-~w~n",[Leader]),
      io:format("ID-~w~n",[Id]),
      slave(Id, Master, Leader, Slaves, Group);
    stop ->
      ok end.

