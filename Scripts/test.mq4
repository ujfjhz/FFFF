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
int start()
  {


		string title="[CostBalancer] Balance:"+AccountBalance()+", Equity:"+AccountEquity();
		string content="The open orders are:";
		content=content+"\nOrderSymbol\tOrderLots\tOrderType\tOrderProfit";
		
	   int totalOpen=OrdersTotal();
	   for(int posOpen=0;posOpen<totalOpen;posOpen++)
	   {
		  if(OrderSelect(posOpen,SELECT_BY_POS)==true)
		  {
			content=content+"\n"+OrderSymbol()+"\t"+OrderLots()+"\t"+OrderType()+"\t"+OrderProfit();
		  }
		} 
		
		content=content+"\n\n\nTHE OPEN ORDERS :";
		int hstTotal=OrdersHistoryTotal();
		for(int i=hstTotal-1;i>=0;i--)
		{
			if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
		    {
				break;
		    }
			
			if(OrderCloseTime()>0)
			{
				if((DayOfYear()-TimeDayOfYear(OrderCloseTime()))>1)
				{
					break;
				}
				 if(OrderType()==OP_BUY || OrderType()==OP_SELL)
				 {
					content=content+"\n"+OrderSymbol()+"\t"+OrderLots()+"\t"+OrderProfit();
				 }
			 }
		}
		
		
		SendMail(title,content);

return;
  }

