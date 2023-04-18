%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%%% Node end point  
%%% Creates and deletes Pods
%%% 
%%% API-kube: Interface 
%%% Pod consits beams from all services, app and app and sup erl.
%%% The setup of envs is
%%% -------------------------------------------------------------------
-module(lib_log).    
 
-export([
	 create_logfile/5,
	 parse/1,
	 create_logger/1
	]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("kernel/include/logger.hrl").



%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
create_logfile(MainLogDir,ProviderLogDir,LogFile,LogFilePath,MaxLogLength)->
    R1=file:make_dir(MainLogDir),
    R2=file:make_dir(ProviderLogDir),
   % case filelib:is_file(LogFilePath) of
%	false->
%	    file:write_file(LogFilePath," ");
%	true->
%%%%%	    ok
   % end,
    R3=create_logger(LogFilePath),
 
    {ok,[R1,R2,R3]}.

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
% {erlang:system_time(microsecond),ModuleString,Line,MsgAsString}
parse(ListRaw)->
    [parse_item(Item)||Item<-ListRaw].

parse_item({TimeStamp,SenderNode,SenderPid,Module,Function,Line,Data,MsgAsString})->
    {{Y,M,D},{H,Mi,S}}=calendar:now_to_datetime(TimeStamp),
    Year=integer_to_list(Y),
    Month=integer_to_list(M),
    Day=integer_to_list(D),
    Hour=integer_to_list(H),
    Min=integer_to_list(Mi),
    Sec=integer_to_list(S),

    SenderNodeStr=atom_to_list(SenderNode),
    SenderPidStr=pid_to_list(SenderPid),
    ModuleStr=atom_to_list(Module),
    FunctionStr=atom_to_list(Function),
    LineStr=integer_to_list(Line),
    
    
    DateTime=Year++"-"++Month++"-"++Day++" | "++Hour++":"++Min++":"++Sec++" | ",
    Text=DateTime++SenderNodeStr++" | "++SenderPidStr++" | "++ModuleStr++":"++FunctionStr++"/"++LineStr++" |  Msg : "++MsgAsString,
    [Text,Data].
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
%create_logger(LogDir)->
create_logger(LogFile)->
    Result=case logger:add_handler(my_standar_disk_h, logger_std_h,
			  #{formatter => {logger_formatter,
					  #{ template => [
							  timestamp," | ",
							  level," | ",
							  sender_node," | ",
							  sender_pid," | ",
							  sender_module," | ",
							  sender_function," | ",
							  sender_line," | ",
							  data," | ",
							  msg,"\n"
							 ]}}}) of
	       {error,Reason}->
		   {error,["Error when creating LogFile :",Reason,?MODULE,?LINE]};
	       ok->
		   case logger:add_handler(my_disk_log_h, logger_disk_log_h,
			  #{
			    config => #{file => LogFile,
					type => wrap,
					max_no_files => 4,
					max_no_bytes =>1000*100,
					filesync_repeat_interval => 1000},
			    formatter => {logger_formatter,
					    #{ template => [
							    timestamp," | ",
							    level," | ",
							    sender_node," | ",
							    sender_pid," | ",
							    sender_module," | ",
							    sender_function," | ",
							    sender_line," | ",
							    data," | ",
							    msg,"\n"
							   ]}}}) of
		       {error,Reason}->
			   {error,["Error when creating LogFile :",LogFile,Reason,?MODULE,?LINE]};
		       ok-> 
			   ok
		   end
	   end,
    Result.

%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% -------------------------------------------------------------------
