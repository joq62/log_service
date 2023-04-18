%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : resource discovery accroding to OPT in Action 
%%% This service discovery is adapted to 
%%% Type = application 
%%% Instance ={ip_addr,{IP_addr,Port}}|{erlang_node,{ErlNode}}
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(log_server). 

-behaviour(gen_server). 

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
-define(SERVER,?MODULE).


-export([init/1, handle_call/3,handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
		debug=[],
		notice=[],
		warning=[],
		alert=[],
		main_log_dir,
		provider_log_dir,
		log_file_path,
		log_file,
		max_log_length
	
	       }).


%% ====================================================================
%% External functions
%% ====================================================================

%% ====================================================================
%% Server functions
%% ====================================================================

%% ====================================================================
%% Gen Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    {ok,MainLogDir}=application:get_env(main_log_dir),
    {ok,ProviderLogDir}=application:get_env(provider_log_dir),
    {ok,LogFile}=application:get_env(log_file),
    {ok,LogFilePath}=application:get_env(log_file_path),
    {ok,MaxLogLength}=application:get_env(max_log_length),
    io:format("dbg ~p~n",[{MainLogDir,ProviderLogDir,LogFilePath,MaxLogLength,?MODULE,?LINE}]),
    {ok, #state{
		main_log_dir=MainLogDir,
		provider_log_dir=ProviderLogDir,
		log_file_path=LogFilePath,
		log_file=LogFile,
		max_log_length=MaxLogLength},0
    }.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
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

handle_call({create,LogFile},_From, State) ->
    Reply=rpc:call(node(),lib_logger,create_logger,[LogFile],5000),
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

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({debug,Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp}}, State) ->
    R= io_lib:format("~p",[Msg]),
    MsgAsString=lists:flatten(R),
 %    logger:debug(MsgAsString,#{file=>ModuleString,line=>Line}),
    logger:debug(MsgAsString,#{timestamp=>TimeStamp,
			       sender_node=>SenderNode,
			       sender_pid=>SenderPid,
			       sender_module=>Module,
			       sender_function=>FunctionName,
			       sender_line=>Line,
			       sender_data=>Data}),
    Len=length(State#state.debug),
    if
	Len<State#state.max_log_length->
	    NewState=State#state{debug=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,Data,MsgAsString}|State#state.debug]};
	true->
	    Templist=lists:delete(lists:last(State#state.notice),State#state.debug),
	    NewState=State#state{debug=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,Data,MsgAsString}|Templist]}
    end,
    {noreply,NewState};

handle_cast({notice,Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp}}, State) ->
    R= io_lib:format("~p",[Msg]),
    MsgAsString=lists:flatten(R),
    logger:notice(MsgAsString,#{timestamp=>TimeStamp,
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
	    NewState=State#state{notice=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,Data,MsgAsString}|State#state.notice]};
	true->
	    Templist=lists:delete(lists:last(State#state.notice),State#state.notice),
	    NewState=State#state{notice=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,Data,MsgAsString}|Templist]}
    end,
    {noreply,NewState};

handle_cast({warning,Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp}}, State) ->
    R= io_lib:format("~p",[Msg]),
    MsgAsString=lists:flatten(R),
    logger:warning(MsgAsString,#{timestamp=>TimeStamp,
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
	    NewState=State#state{warning=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,Data,MsgAsString}|State#state.warning]};
	true->
	    Templist=lists:delete(lists:last(State#state.notice),State#state.warning),
	    NewState=State#state{warning=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,Data,MsgAsString}|Templist]}
    end,
    {noreply,NewState};

handle_cast({alert,Msg,Data,{SenderNode,SenderPid,Module,FunctionName,Line,TimeStamp}}, State) ->
    R= io_lib:format("~p",[Msg]),
    MsgAsString=lists:flatten(R),
    logger:alert(MsgAsString,#{timestamp=>TimeStamp,
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
	    NewState=State#state{alert=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,Data,MsgAsString}|State#state.alert]};
	true->
	    Templist=lists:delete(lists:last(State#state.notice),State#state.alert),
	    NewState=State#state{alert=[{TimeStamp,SenderNode,SenderPid,Module,FunctionName,Line,Data,MsgAsString}|Templist]}
    end,
    {noreply,NewState};



handle_cast(_Msg, State) ->
  %  rpc:cast(node(),log,log,[?Log_ticket("unmatched cast",[Msg])]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(timeout, State) ->
    io:format("dbg ~p~n",[{timeout,?MODULE,?LINE}]),
    Result=lib_log:create_logfile(State#state.main_log_dir,
				  State#state.provider_log_dir,
				  State#state.log_file,
				  State#state.log_file_path,
				  State#state.max_log_length),
    io:format("dbg Result ~p~n",[{Result,?MODULE,?LINE}]),
    log:notice("Server started ",Result,{node(),self(),?MODULE,?FUNCTION_NAME,?LINE,erlang:system_time(millisecond)}),
    {noreply, State};

handle_info(Info, State) ->
    io:format("dbg unmatched signal ~p~n",[{Info,?MODULE,?LINE}]),
    %rpc:cast(node(),log,log,[?Log_ticket("unmatched info",[Info])]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

		  
