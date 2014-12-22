//+------------------------------------------------------------------+
//|                                                    CBMonitor.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""

int sendMessage()
{
	if(Symbol()=="GBPJPY" && Period()==240)	//只由GBPJPY4H负责邮件发送
	{
		String title="[CostBalancer] Balance:"+AccountBalance()+", Equity:"+AccountEquity();
		String content="THE OPEN ORDERS :";
		content=content+"\nOrderSymbol\tOrderLots\tOrderProfit";
		
	    int totalOpen=OrdersTotal();
	    for(int posOpen=0;posOpen<totalOpen;posOpen++)
	    {
		   if(OrderSelect(posOpen,SELECT_BY_POS)==true)
		   {
			 content=content+"\n"+OrderSymbol()+"\t"+OrderLots()+"\t"+OrderProfit();
		   }
		}
		
		content=content+"\n\n\nTHE OPEN ORDERS :";
		int hstTotal=OrdersHistoryTotal();
		for(int i=hstTotal-1;i>=0;i--)
		{
			if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
		    {
				log_err("orderselect failed :"+GetLastError());
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
	}

	return(0);
}
