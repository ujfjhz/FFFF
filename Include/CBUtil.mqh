//+------------------------------------------------------------------+
//|                                                       CBUtil.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
extern bool debug=false;

void log_info(string content)
{
Print(content);
}

void log_err(string content)
{
Alert(content);
}

void log_debug(string content)
{
	if(debug){
		Print(content);
	}
}