//+------------------------------------------------------------------+
//|                                                CBRiskManager.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
//是否连续亏损
bool isContinuousLoss=false;
extern int continuousThreshold=5;//连续失败的判断阈值。
extern string formula="";

//判断是否最近(一小时内)close的单是被止损出场的
bool isLastStopLoss()
{
	int hstTotal=OrdersHistoryTotal();
	if(hstTotal==0){
		return(false);
	}
	if(OrderSelect((hstTotal-1),SELECT_BY_POS,MODE_HISTORY)==false)
   {
		log_err("orderselect failed :"+GetLastError());
		return(false);
   }else{
		if((DayOfYear()==TimeDayOfYear(OrderCloseTime()))&&(Hour()==TimeHour(OrderCloseTime()))){
			if((OrderType()==OP_BUY || OrderType()==OP_SELL) && OrderSymbol()==Symbol())
			{
				if(OrderClosePrice()==OrderStopLoss()){
					return(true);
				}
			}
		}
   }
	return(false);
}


//判断是否消息日：非农数据公布日等
//非农公布时间：北京时间每月第一个周五21:30(冬令)),20:30(夏令)
bool isMessegeDay()
{
	if(TimeDay(Time[0])<=7&&TimeDayOfWeek(Time[0])==5&&TimeHour(Time[0])>=20){
		return(true);
	}
	return(false);
}

//判断是否属于休市日：周末、节假日等
//安全起见，从周五的20:00到周一凌晨间定义为周末。
bool isStopBusinessDay()
{
	//周末
	if( (TimeDayOfWeek(Time[0])==5&&TimeHour(Time[0])>=20) || TimeDayOfWeek(Time[0])==6 || TimeDayOfWeek(Time[0])==0 ){
		isContinuousLoss=false;//每逢休市日初始化 是否连续亏损 的状态
		return(true);
	}
	
	//节假日
	
	return(false);
}

//是否连续亏损
//若一周内连续4次亏损则认为是连续亏损
//要求在isStopBusinessDay()后调用。
bool checkContinuousLoss()
{
	if(isContinuousLoss)
	{
		log_info("It's lost continuous(more than "+continuousThreshold+" times) this week ,stop trading this week.");
		return(true);
	}

	int continuousCount=0;
	int hstTotal=OrdersHistoryTotal();
	for(int i=hstTotal-1;i>=0;i--)
	{
	 if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
	   {
			log_err("orderselect failed :"+GetLastError());
			break;
	   }
	if((DayOfYear()-TimeDayOfYear(OrderOpenTime()))>=5)
	{
		break;
	}
	 if((OrderType()==OP_BUY || OrderType()==OP_SELL) && OrderSymbol()==Symbol())
	 {
		if(OrderProfit()<0)
		{
			continuousCount++;
			if(continuousCount>=continuousThreshold)
			{
				isContinuousLoss=true;
				log_info("It's lost "+continuousCount+" times (more than "+continuousThreshold+" times) this week ,stop trading this week.");
				return(true);
			}
		}else{
			continuousCount=0;
			isContinuousLoss=false;
			break;
		}
	 }
	}
	return(false);
}