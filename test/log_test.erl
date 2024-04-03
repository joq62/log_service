%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%%% Node end point  
%%% Creates and deletes Pods
%%% 
%%% API-kube: Interface §
%%% Pod consits beams from all services, app and app and sup erl.
%%% The setup of envs is
%%% -------------------------------------------------------------------
-module(log_test).   
 
-export([start/0
	]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("log.api").

-define(NodeNames,["n0","n1","n2"]).
-define(Nodes,['n0@c50','n1@c50','n2@c50']).



-define(MainLogDir,"logs").
-define(LocalLogDir,"log.logs").
-define(LogFile,"test_logfile").
-define(MaxNumFiles,10).
-define(MaxNumBytes,100000).

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
start()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    ok=setup(),
    ok=create_log_file(),
    ok=logging(),
    ok=read_test(),

    ok=dist_test(),

    io:format("Test SUCCEDED OK!!!! ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    ok.


%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
create_log_file()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
    
    file:del_dir_r(?MainLogDir),
    ok=file:make_dir(?MainLogDir),
    
    [NodeName,_HostName]=string:tokens(atom_to_list(node()),"@"),
    NodeNodeLogDir=filename:join(?MainLogDir,NodeName),
    ok=log:create_logger(NodeNodeLogDir,?LocalLogDir,?LogFile,?MaxNumFiles,?MaxNumBytes),
  
    ok.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
dist_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
    
    [N0,N1,N2]=?Nodes,
    [NodeName0,NodeName1,NodeName2]=?NodeNames,
    [ok,ok,ok]=[rpc:call(N,application,start,[log],5000)||N<-?Nodes],
    
    ok=create_logger(N0,NodeName0),
    ok=create_logger(N1,NodeName1),
    ok=create_logger(N2,NodeName2),
    
    %% add teat application adder 
    [true,true,true]=[rpc:call(N,code,add_path,["test_ebin"],5000)||N<-?Nodes],
    [ok,ok,ok]=[rpc:call(N,application,start,[adder],5000)||N<-?Nodes],
    [42,42,42]=[rpc:call(N,adder,add,[20,22],5000)||N<-?Nodes],
    ok.


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
logging()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
  
    ok=?LOG_DEBUG("debug_1",[]),
    ok=?LOG_NOTICE("notice_1",[]),
    ok=?LOG_WARNING("warning_1",[{a,1},atom]),    
    ok=?LOG_ALERT("alert_1",[]),
    
    Term={error,[eexists,{?MODULE,?FUNCTION_NAME}]},
    R=io_lib:format("~p",[Term]),
    TermAsStering=lists:flatten(R),
    ok=?LOG_ALERT(TermAsStering,[]),

    ok.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
read_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    [
     {_,control_a@c50,_,log_test,logging,_,"\"debug_1\"",[]}
    ]=log:raw(debug),

    [
     {_,control_a@c50,_,log_test,logging,_,"\"notice_1\"",[]},
     {_,control_a@c50,_,log,init,_,"\"Server started \"",[]}
    ]=log:raw(notice),

    [
     {_,control_a@c50,_,log_test,logging,_,"\"warning_1\"",[{a,1},atom]}
    ]=log:raw(warning),
    
    [
     {_,control_a@c50,_,log_test,logging,_,"\"{error,[eexists,{log_test,logging}]}\"",[]},
     {_,control_a@c50,_,log_test,logging,_,"\"alert_1\"",[]}
    ]=log:raw(alert),

    ok.
    

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
setup()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    StartResult=[{ok,Node}||Node<-?Nodes],
    StartResult=[test_nodes:start_slave(NodeName)||NodeName<-?NodeNames],
    
    [true,true,true]=[rpc:call(N,code,add_path,["test_ebin"],5000)||N<-?Nodes],
    [ok,ok,ok]=[rpc:call(N,application,start,[rd],5000)||N<-?Nodes],
    

    ok.



%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
create_logger(WorkerNode,NodeName)->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
     %%---------------- Check if need for creating a main log dir

    case rpc:call(WorkerNode,filelib,is_dir,[?MainLogDir],5000) of
	{badrpc,Reason}->
	    {error,[badrpc,Reason,?MODULE,?LINE]};
	false->
	    
	    %%----------- create new log dir

	    case rpc:call(WorkerNode,filelib,is_dir,[?MainLogDir],5000) of
		{badrpc,Reason}->
		    {error,[badrpc,Reason,?MODULE,?LINE]};
		false->
		    case rpc:call(WorkerNode,file,make_dir,[?MainLogDir],5000) of
			{badrpc,Reason}->
			    {error,[badrpc,Reason,?MODULE,?LINE]};
			{error,Reason}->
			    {error,["Failed to make dir ",Reason,?MODULE,?LINE]};
			ok ->
			    ok
		    end;
		true ->
		    ok
	    end,
	    
	    %%----------- create logger files
	    NodeNodeLogDir=filename:join(?MainLogDir,NodeName),
	    case rpc:call(WorkerNode,log,create_logger,[NodeNodeLogDir,?LocalLogDir,?LogFile,?MaxNumFiles,?MaxNumBytes],5000) of
		{badrpc,Reason1}->
		    {error,[badrpc,Reason1,?MODULE,?LINE]};
		{error,Reason1}->
		    {error,["Failed to create logger file ",Reason1,?MODULE,?LINE]};
		ok ->
		    ok
	    end;
	true->
	      %%----------- create logger files
    
	    NodeNodeLogDir=filename:join(?MainLogDir,NodeName),
	    case rpc:call(WorkerNode,log,create_logger,[NodeNodeLogDir,?LocalLogDir,?LogFile,?MaxNumFiles,?MaxNumBytes],5000) of
		{badrpc,Reason}->
		    {error,[badrpc,Reason,?MODULE,?LINE]};
		{error,Reason2}->
		    {error,["Failed to create logger file ",Reason2,?MODULE,?LINE]};
		ok ->
		    ok
	    end
    end.
    
