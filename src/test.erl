%%%-------------------------------------------------------------------
%%% @author kishorebaktha
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Oct 2018 4:46 PM
%%%-------------------------------------------------------------------
-module(test).

-compile(export_all).



% Used to create the first worker, try:
%
% W1 = test:first(1, gms3, 3000)

first(N, Module, Sleep) ->
  worker:start(N, Module, random:uniform(256), Sleep).

% Used to create additional workers, try:
%
%%W1 = test:first(1, gms4, 3000).
%%  test:add(2, gms4, W1, 3000).
%%test:add(3, gms4, W1, 3000) .
%%W4=test:add(4, gms3, W1, 3000).
%%test:add(5, gms3, W1, 3000).
%%
%%test:add(6, gms3, W4, 3000).

add(N, Module, Wrk, Sleep) ->
  worker:start(N, Module, random:uniform(256), Wrk, Sleep).

%% To create a number of workers in one go,

more(N, Module, Sleep) when N > 1 ->
  Wrk = first(1, Module, Sleep),
  Ns = lists:seq(2,N),
  lists:map(fun(Id) -> add(Id, Module, Wrk, Sleep) end, Ns),
  Wrk.

% These are messages that we can send to one of the workers. It will
% multicast it to all workers. They should (if everything works)
% receive the message at the same (logical) time.

freeze(Wrk) ->
  Wrk ! {send, freeze}.

go(Wrk) ->
  Wrk ! {send, go}.

sleep(Wrk, Sleep) ->
  Wrk ! {send, {sleep, Sleep}}.

stop(Wrk) ->
  Wrk ! {send, stop}.




















