%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2023, c50
%%% @doc
%%%
%%% @end
%%% Created : 19 Dec 2023 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(log_read_test).

%% API
-export([start/0]).

-include("logs.hrl").

% -define(TestLogFile,"test/logs_short.txt").
-define(TestLogFile,"test/logs.txt").

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
start()->
   
    ok=setup(),
    ok=read_log_test(),
                
    io:format("Test OK !!! ~p~n",[?MODULE]),
   
 
    ok.

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
read_log_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),

    {ok,Bin}=file:read_file(?TestLogFile),
    String=erlang:binary_to_list(Bin),
    NoBreaks=string:lexemes(String,"\n"),
  %  [io:format("Str =>> ~p~n",[Str])||Str<-NoBreaks],
    InfoStrings=[string:lexemes(Str,"|")||Str<-NoBreaks],
    TrimedStrings=[trim(String)||String<-InfoStrings],
 %   [io:format(" Line = ~p~n",[InfoStrings])||InfoString<-TrimedStrings],
%    Maps=[do_map(InfoString)||InfoString<-TrimedStrings],


    Recs=[do_rec(InfoString)||InfoString<-TrimedStrings],
    65=length(Recs),
 %   io:format("Recs = ~p~n",[Recs]),

  %  [io:format(" Map = ~p~n",[Map])||Map<-Maps],
%    io:format(" notice = ~p~n",[print_level("notice",Recs)]),
%    io:format(" error = ~p~n",[print_level("error",Recs)]),
%    io:format(" alert = ~p~n",[print_level("alert",Recs)]),

  %  io:format(" control= ~p~n",[print_module("control",Recs)]),
 %   io:format(" init= ~p~n",[print_function("init",Recs)]),

    io:format("after {{2023,12,9},{13,53,44}}= ~p~n",[print_after("{{2023,12,9},{13,53,44}}",Recs)]),
    

  
    ok. 
    

trim(ListOfStrings)->
    [string:trim(String)||String<-ListOfStrings].

do_rec([TimeStamp,DateTime,Level,Node,Pid,Module,Function,Line,InfoText])->
%    io:format("InfoString wo args = ~p~n",[{TimeStamp,DateTime,Level,Node,Pid,Module,Function,Line,InfoText}]),
    Rec=#info{timestamp=TimeStamp,datetime=DateTime,level=Level,node=Node,pid=Pid,
	  module=Module,function=Function,line=Line,infotext=InfoText,infoargs=[]},
%    io:format("Rec = ~p~n",[Rec]),
    Rec;

do_rec([TimeStamp,DateTime,Level,Node,Pid,Module,Function,Line,InfoText,InfoArgs])->
%    io:format("InfoString wo args = ~p~n",[{TimeStamp,DateTime,Level,Node,Pid,Module,Function,Line,InfoText,InfoArgs}]),
    Rec=#info{timestamp=TimeStamp,datetime=DateTime,level=Level,node=Node,pid=Pid,
	  module=Module,function=Function,line=Line,infotext=InfoText,infoargs=InfoArgs},
%    io:format("Rec = ~p~n",[Rec]),
    Rec;
do_rec(X) ->
    io:format("X  = ~p~n",[X]),
    Rec=#info{timestamp=[],datetime=[],level="alert",node=[],pid=[],
	      module=[],function=[],line=[],infotext=[],infoargs=X},
    io:format("Rec = ~p~n",[Rec]),
    Rec.
    

do_map(["   "])->
    io:format("InfoString = ~p~n",[["   "]]),
    Map=#{timestamp=>na,date_time=>na,level=>na,node=>na,pid=>na,
	  module=>na,function=>na,line=>na,infotext=>na,infoargs=>na},
    io:format("Map = ~p~n",[Map]),
    Map;

do_map([TimeStamp,DateTime,Level,Node,Pid,Module,Function,Line,InfoText])->
    io:format("InfoString wo args = ~p~n",[{TimeStamp,DateTime,Level,Node,Pid,Module,Function,Line,InfoText}]),
    Map=#{timestamp=>TimeStamp,datetime=>DateTime,level=>Level,node=>Node,pid=>Pid,
	  module=>Module,function=>Function,line=>Line,infotext=>InfoText,infoargs=>"[]"},
    io:format("Map = ~p~n",[Map]),
    Map;
do_map([TimeStamp,DateTime,Level,Node,Pid,Module,Function,Line,InfoText,InfoArgs])->
    io:format("InfoString w args = ~p~n",[{TimeStamp,DateTime,Level,Node,Pid,Module,Function,Line,InfoText,InfoArgs}]),
    Map=#{timestamp=>TimeStamp,date_time=>DateTime,level=>Level,node=>Node,pid=>Pid,
	  module=>Module,function=>Function,line=>Line,infotext=>InfoText,infoargs=>InfoArgs},
    io:format("Map = ~p~n",[Map]),
    Map.
	

%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
print_level(Key,InfoRecords)->
    [R||R<-InfoRecords,
	Key=:=R#info.level].


%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
print_module(Key,InfoRecords)->
    [R||R<-InfoRecords,
	Key=:=R#info.module].

  
%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
print_function(Key,InfoRecords)->
    [R||R<-InfoRecords,
	Key=:=R#info.function].


%%--------------------------------------------------------------------
%% @doc
%% @spec
%% @end
%%--------------------------------------------------------------------
print_after(DateTimeStr,InfoRecords)->
    print_after(DateTimeStr,InfoRecords,[]).


print_after(_,[],Acc)->
    lists:reverse(Acc);
print_after(DateTimeStr,[R|T],Acc)->
    NewAcc=case R#info.datetime of
	       []->
		   [R|Acc];
	       DateTime->
		   if
		       DateTime>DateTimeStr->
			   [R|Acc];
		        DateTime=:=DateTimeStr->
			   [R|Acc];
		       true->
			   Acc
		   end
	   end,
    print_after(DateTimeStr,T,NewAcc).
    

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------


setup()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    pong=log:ping(),
    ok.
