-define(MainLogDir,"logs").
-define(MaxLogLength,10000).
-define(LogFile,"central.log").
-define(LogFilePath,"logs/control.logs").


-record(info,{
	      timestamp,
	      datetime,
	      level,
	      node,
	      pid,
	      module,
	      function,
	      line,
	      infotext,
	      infoargs
	     }).
