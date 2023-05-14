%%%-------------------------------------------------------------------
%% @doc ops public API
%% @end
%%%-------------------------------------------------------------------

-module(app_sim_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    app_sim_sup:start_link(). 

stop(_State) ->
    ok.

%% internal functions
