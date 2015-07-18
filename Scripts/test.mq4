//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+

extern string monitor="GBPJPY240";	//默认只由GBPJPY4H负责邮件发送

int monitor()
{
	//if((Symbol()+Period())==monitor && TimeMinute(Time[0])==0 && TimeDayOfWeek(Time[0])<=6 && TimeDayOfWeek(Time[0])>=2)	
   Alert(Symbol());
   Alert(MarketInfo(Symbol(),MODE_LOTSIZE));
   Alert(MarketInfo(Symbol(),MODE_MINLOT));
   Alert(MarketInfo(Symbol(),MODE_LOTSTEP));
   Alert(MarketInfo(Symbol(),MODE_MAXLOT));
 Alert(MarketInfo(Symbol(),MODE_MARGINREQUIRED));
 Alert(Point);
	return(0);
}

int start()
  {
	monitor();
	return(0);
  }

