%%%-------------------------------------------------------------------
%%% @author kishorebaktha
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. Oct 2018 3:39 PM
%%%-------------------------------------------------------------------
%%%-------------------------------------------------------------------
%%% @author kishorebaktha
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 29. Sep 2018 8:17 AM
%%%-------------------------------------------------------------------
-module(gms4).
-author("kishorebaktha").

%% API
-compile(export_all).

start(Id) ->
  Rnd = random:uniform(1000),
  Self = self(),
  {ok, spawn_link(fun()-> init(Id, Rnd, Self) end)}.

init(Id, Rnd, Master) ->
  random:seed(Rnd, Rnd, Rnd),
  leader(Id,0, Master, [], [Master]).

start(Id, Grp) ->
  Rnd = random:uniform(1000),
  Self = self(),
  {ok, spawn_link(fun()-> init(Id,Rnd, Grp, Self) end)}.

init(Id,Rnd, Grp, Master) ->
  random:seed(Rnd, Rnd, Rnd),
  Self = self(),
  Grp ! {join, Master, Self},
  receive
    {view, N,[Leader|Slaves], Group} ->
      Master ! {view, Group},
      erlang:monitor(process, Leader),
      Leader !{ack,Id},
%%      slave(Id,Ref,Master, Leader,N+1,{view, N,[Leader|Slaves], Group}, Slaves, Group)
      slave(Id,Master, Leader,N+1,{view, N,[Leader|Slaves], Group}, Slaves, Group)
  after 5000 ->
    %  io:format("no reply from leader~n"),
    Master ! {error, "no reply from leader"}
  end.


leader(Id,N, Master, Slaves,Group) ->
  receive
    {mcast, Msg} ->
      % io:format("received2"),
      bcast(Id, {msg,N, Msg}, Slaves),
      Master ! Msg,
      leader(Id,N+1, Master, Slaves, Group);
    {join, Wrk, Peer} ->
      Slaves2 = lists:append(Slaves, [Peer]),
      Group2 = lists:append(Group, [Wrk]),
      bcast(Id, {view, N,[self()|Slaves2], Group2}, Slaves2),
      Master ! {view, Group2},
      leader(Id,N+1, Master, Slaves2, Group2);
    status->
      io:format("Slaves-~w~n",[Slaves]),
      io:format("Master-~w~n",[Master]),
      io:format("Group-~w~n",[Group]),
      io:format("N-~w~n",[N]),
      leader(Id,N, Master, Slaves, Group);
    stop -> io:format("received stop~n"),
      ok
  end.

bcast(Id, Msg, Nodes) ->
lists:foreach(fun(Node) ->  resend(Node,Msg),crash(Id) end, Nodes).

resend(Node,Msg) ->
  case random:uniform(100) of
    100 ->
      io:format("message lost ~w", [Msg]);
    _ -> Node ! Msg
      %io:format("sent ~w ~n to ~w",[Msg,Node])
  end,
  receive
    {ack,Id}->{ok,Id}
      after 100->io:format("no ack~n"),
    resend(Node,Msg)
  end .

crash(Id) ->
  case random:uniform(100) of
    100 ->
      io:format("leader ~w: crash~n", [Id]),
      exit(stop);
    _ -> false
  end.


slave(Id,Master, Leader, N, Last, Slaves, Group) ->
  receive
    {mcast, Msg} ->
      % io:format("received"),
      Leader ! {mcast, Msg},
      slave(Id, Master, Leader,N,Last, Slaves, Group);

    {join, Wrk, Peer} ->
      Leader ! {join, Wrk, Peer},
      Leader ! {ack,Id},
      slave(Id, Master, Leader,N,Last, Slaves, Group);

    {msg,I, Msg} ->
      if I<N->
        %io:format("Message2 received~n"),
        Leader ! {ack,Id},
        slave(Id, Master, Leader, N, Last, Slaves, Group);
        true->
          Leader ! {ack,Id},
          Master ! Msg,
          io:format("Message received in ~w is~n",[Id]),
          io:format(" is ~w~n",[Msg]),
          slave(Id, Master, Leader,I+1,{msg,I, Msg}, Slaves, Group)
      end;

    {view, I,[Leader|Slaves2], Group2} ->
      if I<N->
        Leader ! {ack,Id},
        slave(Id, Master, Leader, N, Last, Slaves2, Group);
        true->
          Leader ! {ack,Id},
          Master ! {view, Group2},
          %io:format("received view~n"),
          slave(Id, Master, Leader,I+1,{view, I,[Leader|Slaves2], Group2}, Slaves2, Group2)
      end;

    {'DOWN', _Ref, process, Leader, _Reason} ->
%%      io:format("Slaves-~w",[Slaves]),
      election(Id, Master,N,Last, Slaves, Group);

    status->
      io:format("Slaves-~w~n",[Slaves]),
      io:format("Master-~w~n",[Master]),
      io:format("Group-~w~n",[Group]),
      io:format("Leader-~w~n",[Leader]),
      io:format("ID-~w~n",[Id]),
      io:format("N-~w~n",[N]),
      io:format("Last-~w~n",[Last]),
      slave(Id,Master, Leader, N,Last,Slaves, Group);

    stop ->io:format("endslave~n"),
      ok end.

election(Id, Master,N,Last, Slaves, [_|Group]) ->
  Self = self(),
%%  io:format("Self-~w~n",[Self]),
  %timer:sleep(2000),
  case Slaves of
    [Self|Rest] ->
%%      io:format("here2~n"),
      bcast(Id, Last, Rest),
      bcast(Id, {view, N,Slaves, Group}, Rest),
      Master ! {view, Group},
      leader(Id,N+1, Master, Rest, Group);
    [Leader|Rest] ->
%%      io:format("here~n"),
%%      io:format("Leader-~w~n",[Leader]),
%%      io:format("Last-~w~n",[Last]),
%%      io:format("ID-~w~n",[Id]),
      erlang:monitor(process, Leader),
      %bcast(Id, Last, Rest),
      slave(Id, Master, Leader,N,Last, Rest, Group)
  end.


