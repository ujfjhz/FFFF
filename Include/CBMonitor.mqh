//+------------------------------------------------------------------+
//|                                                    CBMonitor.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
extern string monitor="GBPJPY240";	//默认只由GBPJPY4H负责邮件发送
string msgReport="none"; //messages to report generated during trading

int monitor()
{
	//NewYork Close Time 20:00 , Monday to Friday ，即北京时间周二至周六的凌晨1点或者2点
	if((Symbol()+Period())==monitor && TimeHour(Time[0])==20 && TimeMinute(Time[0])==0 && TimeDayOfWeek(Time[0])<=5 && TimeDayOfWeek(Time[0])>=1)	
	{
		string title="[REPORT]Balance:"+AccountBalance()+",Equity:"+AccountEquity();
		string content="THE OPEN ORDERS :";
		content=content+"\nSymbol\tPosition\tProfit";
		
	    int totalOpen=OrdersTotal();
	    for(int posOpen=0;posOpen<totalOpen;posOpen++)
	    {
		   if(OrderSelect(posOpen,SELECT_BY_POS)==true)
		   {
			 content=content+"\n"+OrderSymbol()+"\t"+OrderLots()+"\t"+OrderProfit();
		   }
		}
		
		content=content+"\nMessages :";
		content=content+"\n"+msgReport;
		
		log_info(title);
		if(!SendMail(title,content)){
			log_err("Send mail failed. The title is :"+title+". The error code is:"+GetLastError());    ;
		}
		msgReport="none";
	}
	return(0);
}
