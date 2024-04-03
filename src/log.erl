%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created :  2 Jun 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(log).

-behaviour(gen_server).
 

-include("log.api").
-include("logs.hrl").
%% API
-export([
	 create_logger/5,

	 is_config/0,
	 config/1,
	 raw/1,
	 read/1,
	 log/4,

	 debug/3,notice/3,warning/3,alert/3,
	 create_logfile/3,
	 create/1,

	 get_state/0,
	 ping/0
	]).


-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3, format_status/2]).

-define(SERVER, ?MODULE).

-record(state, {
		debug=[],
		notice=[],
		warning=[],
		alert=[],
		main_log_dir,
		local_log_dir,
		logfile,
		max_num_files,
		max_num_bytes,
		
		log_file_path,
		log_file,
		max_log_length
	
	       }).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%% @end
%%--------------------------------------------------------------------
-spec start_link() -> {ok, Pid :: pid()} |
	  {error, Error :: {already_started, pid()}} |
	  {error, Error :: term()} |
	  ignore.
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
create_logger(MainLogDir,LocalLogDir,LogFile,MaxNumFiles,MaxNumBytes)->
    gen_server:call(?SERVER, {create_logger,MainLogDir,LocalLogDir,LogFile,MaxNumFiles,MaxNumBytes},infinity).

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------

create_logfile(MainLogDir,ProviderLogDir,LogFilePath)->
    gen_server:call(?SERVER, {create_logfile,MainLogDir,ProviderLogDir,LogFilePath},infinity).

is_config()->
    gen_server:call(?SERVER, {is_config},infinity).

config(LogFile)->
    gen_server:call(?SERVER, {config,LogFile},infinity).


raw(LogLevel)->
    gen_server:call(?SERVER, {raw,LogLevel},infinity).

read(LogLevel)->
    gen_server:call(?SERVER, {read,LogLevel},infinity).


create(LogFile)->
    gen_server:call(?SERVER, {create,LogFile},infinity).


log(Level,ModuleString,Line,Msg)-> 
    gen_server:cast(?SERVER, {log,Level,ModuleString,Line,Msg}).



debug(Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp})->
    gen_server:cast(?SERVER, {debug,Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp}}).
notice(Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp})->
    gen_server:cast(?SERVER, {notice,Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp}}).
warning(Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp})->
    gen_server:cast(?SERVER, {warning,Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp}}).
alert(Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp})->
    gen_server:cast(?SERVER, {alert,Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp}}).


%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
ping()-> 
    gen_server:call(?SERVER, {ping},infinity).    


get_state()->
    gen_server:call(?SERVER, {get_state},infinity).
%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%% @end
%%--------------------------------------------------------------------
init([]) ->

    ?LOG_NOTICE("Server started ",[]),
    {ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%% @end
%%--------------------------------------------------------------------
handle_call({create_logger,MainLogDir,LocalLogDir,LogFile,MaxNumFiles,MaxNumBytes},_From, State) ->
    Reply=rpc:call(node(),lib_log,create_logger,[MainLogDir,LocalLogDir,LogFile,MaxNumFiles,MaxNumBytes],5000),
    NewState=State#state{main_log_dir=MainLogDir,
			 local_log_dir=LocalLogDir,	
			 logfile=LogFile,
			 max_num_files=MaxNumFiles,
			 max_num_bytes=MaxNumBytes},
    {reply, Reply, NewState};

handle_call({read,Level},_From, State) ->
    Reply = case Level of
		debug->
		    lib_log:parse(State#state.debug);
		notice->
		    lib_log:parse(State#state.notice);
		warning->
		    lib_log:parse(State#state.warning);
		alert->
		    lib_log:parse(State#state.alert);
		Unmatched->
		    {error,["Unmatched level ",Unmatched,?MODULE,?LINE]}
	    end,
    
    {reply, Reply, State};

handle_call({raw,Level},_From, State) ->
    Reply = case Level of
		debug->
		    State#state.debug;
		notice->
		    State#state.notice;
		warning->
		    State#state.warning;
		alert->
		    State#state.alert;
		Unmatched->
		    {error,["Unmatched level ",Unmatched,?MODULE,?LINE]}
	    end,
    
    {reply, Reply, State};

handle_call({get_state},_From, State) ->
    Reply=State,
    {reply, Reply, State};

handle_call({ping},_From, State) ->
    Reply=pong,
    {reply, Reply, State};

handle_call({stopped},_From, State) ->
    Reply=ok,
    {reply, Reply, State};


handle_call({not_implemented},_From, State) ->
    Reply=not_implemented,
    {reply, Reply, State};

handle_call({stop}, _From, State) ->
    {stop, normal, shutdown_ok, State};

handle_call(Request, From, State) ->
    %rpc:cast(node(),log,log,[?Log_ticket("unmatched call",[Request, From])]),
    Reply = {ticket,"unmatched call",Request, From},
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%% @end
%%--------------------------------------------------------------------
handle_cast({debug,Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp}}, State) ->
    R= io_lib:format("~p",[Msg]),
    MsgAsString=lists:flatten(R),
    
    logger:debug(MsgAsString,#{timestamp=>TimeStamp,
			       sender_time=>calendar:now_to_datetime(TimeStamp),
			       sender_node=>SenderNode,
			       sender_pid=>SenderPid,
			       sender_module=>Module,
			       sender_function=>FunctionName,
			       sender_line=>Line,
			       sender_data=>Data}),
    Len=length(State#state.debug),
    if
	Len<State#state.max_log_length->
	    NewState=State#state{debug=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,MsgAsString,Data}|State#state.debug]};
	true->
	    Templist=lists:delete(lists:last(State#state.notice),State#state.debug),
	    NewState=State#state{debug=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,MsgAsString,Data}|Templist]}
    end,
    {noreply,NewState};

handle_cast({notice,Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp}}, State) ->
    R= io_lib:format("~p",[Msg]),
    MsgAsString=lists:flatten(R),
  %  R_data= io_lib:format("~p",[Data]),
  %  DataAsString=lists:flatten(R_data),
    logger:notice(MsgAsString,#{timestamp=>TimeStamp,
				sender_time=>calendar:now_to_datetime(TimeStamp),
				sender_node=>SenderNode,
				sender_pid=>SenderPid,
				sender_module=>Module,
				sender_function=>FunctionName,
				sender_line=>Line,
				sender_data=>Data}),
    Len=length(State#state.notice),
						%   io:format("notice Len= ~p~n",[{Len,?MODULE,?LINE}]),
    if
	Len<State#state.max_log_length->
	    NewState=State#state{notice=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,MsgAsString,Data}|State#state.notice]};
	true->
	    Templist=lists:delete(lists:last(State#state.notice),State#state.notice),
	    NewState=State#state{notice=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,MsgAsString,Data}|Templist]}
    end,
    {noreply,NewState};

handle_cast({warning,Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp}}, State) ->
    R= io_lib:format("~p",[Msg]),
    MsgAsString=lists:flatten(R),
    logger:warning(MsgAsString,#{timestamp=>TimeStamp,
				 sender_time=>calendar:now_to_datetime(TimeStamp),
				 sender_node=>SenderNode,
				 sender_pid=>SenderPid,
				 sender_module=>Module,
				 sender_function=>FunctionName,
				 sender_line=>Line,
				 sender_data=>Data}),
    Len=length(State#state.warning),
						%   io:format("notice Len= ~p~n",[{Len,?MODULE,?LINE}]),
    if
	Len<State#state.max_log_length->
	    NewState=State#state{warning=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,MsgAsString,Data}|State#state.warning]};
	true->
	    Templist=lists:delete(lists:last(State#state.notice),State#state.warning),
	    NewState=State#state{warning=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,MsgAsString,Data}|Templist]}
    end,
    {noreply,NewState};

handle_cast({alert,Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp}}, State) ->
    R= io_lib:format("~p",[Msg]),
    MsgAsString=lists:flatten(R),
    logger:alert(MsgAsString,#{timestamp=>TimeStamp,
			       sender_time=>calendar:now_to_datetime(TimeStamp),
			       sender_node=>SenderNode,
			       sender_pid=>SenderPid,
			       sender_module=>Module,
			       sender_function=>FunctionName,
			       sender_line=>Line,
			       sender_data=>Data}),
    Len=length(State#state.alert),
						%   io:format("notice Len= ~p~n",[{Len,?MODULE,?LINE}]),
    if
	Len<State#state.max_log_length->
	    NewState=State#state{alert=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,MsgAsString,Data}|State#state.alert]};
	true->
	    Templist=lists:delete(lists:last(State#state.notice),State#state.alert),
	    NewState=State#state{alert=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,MsgAsString,Data}|Templist]}
    end,
    {noreply,NewState};



handle_cast(_Msg, State) ->
  %  rpc:cast(node(),log,log,[?Log_ticket("unmatched cast",[Msg])]),
    {noreply, State}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%% @end
%%--------------------------------------------------------------------
handle_info(timeout, State) ->
    io:format("dbg ~p~n",[{timeout,?MODULE,?LINE}]),
    Result=lib_log:create_logfile(State#state.main_log_dir,
				  State#state.log_file,
				  State#state.log_file_path,
				  State#state.max_log_length),
    ?LOG_NOTICE("Server started and created log file with result",[Result]),
    {noreply, State};

handle_info(Info, State) ->
    io:format("dbg unmatched signal ~p~n",[{Info,?MODULE,?LINE}]),
    %rpc:cast(node(),log,log,[?Log_ticket("unmatched info",[Info])]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%% @end
%%--------------------------------------------------------------------
-spec terminate(Reason :: normal | shutdown | {shutdown, term()} | term(),
		State :: term()) -> any().
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%% @end
%%--------------------------------------------------------------------
-spec code_change(OldVsn :: term() | {down, term()},
		  State :: term(),
		  Extra :: term()) -> {ok, NewState :: term()} |
	  {error, Reason :: term()}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called for changing the form and appearance
%% of gen_server status when it is returned from sys:get_status/1,2
%% or when it appears in termination error logs.
%% @end
%%--------------------------------------------------------------------
-spec format_status(Opt :: normal | terminate,
		    Status :: list()) -> Status :: term().
format_status(_Opt, Status) ->
    Status.

%%%===================================================================
%%% Internal functions
%%%===================================================================
