//+------------------------------------------------------------------+
//|                                                    CBAnalyst.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
int maxTrend=10;
extern int distStopLoss=210;	//单位为point(MT4中定义的单位，比外汇的点低一个数量级，一般为0.00001，日元为0.001)
extern int distTakeProfit=210;	//单位为point(0.00001)

//analyse the current situation to indicate trades.
//Trades action depends on the return values:
//0:There is an error during analyse or the situation is clam, or the situation is very difficult to analyse.
//从各种指标分析出当前所处趋势(对未来的一种预测)
//正数:看多；负数:看空
//零：什么都不做或者修改stop level.
//用返回值表达趋势信号的强弱状态[-10,10]
int analyseTrend()
{
	int trend = 0;
	
	//获取指标
	double indicatorCBRate1=iCustom(NULL,0,"CBRate",1,0);
	double indicatorCBRate2=iCustom(NULL,0,"CBRate",2,0);
	double indicatorCBRate3=iCustom(NULL,0,"CBRate",3,0);
	
	//分析指标
   if(indicatorCBRate1>=0.0001)  
     {	//---- buy conditions
		if(indicatorCBRate2>=0.0002)
		{
			if(indicatorCBRate3>=0.0003)
			{	
				trend=10;
			}else if(indicatorCBRate3>=0.0001){
				trend=8;
			}
		}else if(indicatorCBRate2>=-0.0001){
			if(indicatorCBRate3>=0.0002)
			{
				trend=8;
			}
		}else if(indicatorCBRate2>-0.0005){
			if(indicatorCBRate3>=0.0003)
			{
				trend=5;
			}
		}
     }else  if(indicatorCBRate1<-0.0001)  
     {	//---- sell conditions
		if(indicatorCBRate2<-0.0002)
		{
			if(indicatorCBRate3<=-0.0003)
			{	
				trend=-10;
			}else if(indicatorCBRate3<=-0.0001){
				trend=-8;
			}
		}else if(indicatorCBRate2<0.0001){
			if(indicatorCBRate3<=-0.0002)
			{
				trend=-8;
			}
		}
	 }
	 
	 //判断trend是否ok
	 if(!checkTrendSmooth(trend)){
		log_info("The trend is not smooth,set trend to 0.");
		trend=0;
	 }
	
	return(trend);
}

/**
分析是否是尾巴
更大、更小的时间尺度相结合
*/
int analyseTail()
{
	int istail=0;
	
	double q1=iCustom(NULL,PERIOD_M1,"CBDistribution",0,0);
	double q2=iCustom(NULL,PERIOD_M1,"CBDistribution",1,0);
	double q3=iCustom(NULL,PERIOD_M1,"CBDistribution",2,0);
	double upCount=iCustom(NULL,PERIOD_M1,"CBDistribution",3,0);
	double downCount=iCustom(NULL,PERIOD_M1,"CBDistribution",4,0);
	
	double sum=q1+q2+q3;
	
	if(sum>0){
		//log_debug("q1,q2,q3,upcount,downcount,istail are:"+q1+"-"+q2+"-"+q3+"-"+upCount+"-"+downCount+"-"+istail);
		if((q1/sum)<0.382 && (q3/sum)<0.382 && (upCount/sum)>0.618){//微观
			if((Close[3]-Open[3])>0 && (Close[2]-Open[2])>0 && (Close[1]-Open[1])>0){//宏观：前三bar分别为阳
				if((Close[4]-Open[4])<0){//连续4bar不允许
					istail=1;
				}
			}else if((Close[3]-Open[3])<0 && (Close[2]-Open[2])<0 && (Close[1]-Open[1])<0){
				if((Close[4]-Open[4])>0){//连续4bar不允许
					istail=-1;
				}
			}
		}
	}
	
	return(istail);
}

/**
分析局部的惯性
*/
int analyseInertia()
{
	int inertia = 0;
	
	//获取指标
	double indicatorCBRate1=iCustom(NULL,0,"CBRate",1,0);
	double indicatorCBRate2=iCustom(NULL,0,"CBRate",2,0);
	
	//分析指标
   if(indicatorCBRate1>=0.0001) {
		if(indicatorCBRate2>=0.0002){
			inertia=10;
		}else if(indicatorCBRate2>=0.0001){
			inertia=8;
		}
   }
   
	if(indicatorCBRate1<=-0.0001) {
		if(indicatorCBRate2<=-0.0002){
			inertia=-10;
		}else if(indicatorCBRate2<=-0.0001){
			inertia=-8;
		}
   }
   
   return(inertia);
}

//检查trend是否平滑
bool checkTrendSmooth(int trend)
{
	int n=51;//指标CBShake计算的时间周期
	double indicatorCBWave=iCustom(NULL,0,"CBWave",n,trend,2,0);

	if(indicatorCBWave==1){
		return(true);
	}else{
		return(false);
	}
}

//检查当前是否处于震荡
//默认为false:非震荡，即趋势性
bool checkIsShake()
{
	int n=5;//指标CBShake计算的时间周期
	double indicatorCBShake1=iCustom(NULL,0,"CBShake",n,0,0);
	double indicatorCBShake2=iCustom(NULL,0,"CBShake",n,1,0);
	
	log_debug("n:"+n+"---0:"+indicatorCBShake1+"---1:"+indicatorCBShake2);
	
	if(indicatorCBShake2>=(n*340)){
		if(indicatorCBShake1==0){
			return(true);
		}else if((indicatorCBShake2/indicatorCBShake1)>=(n*1.618)){
			return(true);
		}
	}
	return(false);
}

//计算需要开的手数
double analyseLotToOpen(int trend)
{
	double lot=0;
	trend=MathAbs(trend);
	double minLot=MarketInfo(Symbol(),MODE_MINLOT);// Min. volume     
	double step=MarketInfo(Symbol(),MODE_LOTSTEP);//Step to change lots        
	double lotCost=MarketInfo(Symbol(),MODE_MARGINREQUIRED);//Cost per 1 lot     	
	double quotaFund=getQuota();
	
	log_debug("quotaFund:"+quotaFund+"--trend:"+trend+"---max:"+maxTrend+"---lotCost:"+lotCost+"---step:"+step);
	lot=MathFloor((quotaFund*(trend*1.0/maxTrend)/lotCost)/step)*step;
	if(lot<minLot)
	{
		return(0);
	}
	return(lot);
}

//计算开仓止损价
double analyseStopLoss(int trend)
{
	double stopLoss=0;
	//交易前先刷新价格
    RefreshRates();
	if(trend>0)
	{
		stopLoss=Ask-distStopLoss*Point;
	}else if(trend<0)
	{
		stopLoss=Bid+distStopLoss*Point;
	}
	return(stopLoss);
}

//计算开仓止盈价
double analyseTakeProfit(int trend)
{
	double takeprofit=0;
	//交易前先刷新价格
    RefreshRates();
	if(trend>0)
	{
		takeprofit=Ask+distTakeProfit*Point;
	}else if(trend<0)
	{
		takeprofit=Bid-distTakeProfit*Point;
	}
	return(takeprofit);
}

//重新计算所选订单止损价
//有限止损原则
//多单：在递增的前提下位于当前价格的下方distStopLoss处
//空单：在递减的前提下位于当前价格的上方distStopLoss处
double analyseNewStopLoss()
{
	//交易前先刷新价格
    RefreshRates();
	double oldStopLoss=OrderStopLoss();
	double newStopLoss=oldStopLoss;
	if(OrderType()== OP_BUY)
	{
		if(OrderProfit()>0)
		{
			newStopLoss=Ask-distStopLoss*Point-(OrderProfit()*0.382*Point/OrderLots());
		}else{
			newStopLoss=OrderOpenPrice()-distStopLoss*Point;
		}
	}else if(OrderType()== OP_SELL)
	{
		if(OrderProfit()>0)
		{
			newStopLoss=Bid+distStopLoss*Point+(OrderProfit()*0.382*Point/OrderLots());
		}else{
			newStopLoss=OrderOpenPrice()+distStopLoss*Point;
		}
	}
	return(newStopLoss);
}

//重新计算所选订单止盈价
//无限盈利原则
//新的takeprofit至少比开盘价高1个distTakeProfit
double analyseNewTakeProfit()
{
	//交易前先刷新价格
    RefreshRates();
	double newTakeProfit=OrderTakeProfit();
	double rcTakeProfit=newTakeProfit;
	if(OrderType()== OP_BUY)
	{
		rcTakeProfit=Ask+distTakeProfit*Point;
		if(rcTakeProfit>=(OrderOpenPrice()+distTakeProfit*Point))
		{
			newTakeProfit=rcTakeProfit;
		}else{
			newTakeProfit=OrderOpenPrice()+distTakeProfit*Point;
		}
	}else if(OrderType()== OP_SELL)
	{
		rcTakeProfit=Bid-distTakeProfit*Point;
		if(rcTakeProfit<=(OrderOpenPrice()-distTakeProfit*Point))
		{
			newTakeProfit=rcTakeProfit;
		}else{
			newTakeProfit=OrderOpenPrice()-distTakeProfit*Point;
		}
	}
	return(newTakeProfit);
}


//fibonacii主动stoploss and takeprice
//无限盈利，有限止损原则
bool isPositiveStop()
{
	string gvKey="MaxProfit_"+OrderTicket();
	if(GlobalVariableCheck(gvKey)){
      double maxProfit=GlobalVariableGet(gvKey);
	  if(OrderProfit()>maxProfit)
	  {
			if(GlobalVariableSet(gvKey,OrderProfit())==0){
			  log_err("Error:when set global variable for "+gvKey+" : "+GetLastError());
			}
	  }
	  double maxProfitPoint=maxProfit/OrderLots();
	  double thisProfitPoint=OrderProfit()/OrderLots();
	  if(thisProfitPoint<=-210)
	  {//主动止损
		return(true);
	  }
	  if(maxProfitPoint>=550)
	  {//保守止盈
		if(thisProfitPoint<=((0.618+0.382*0.618)*maxProfitPoint)){
			if(thisProfitPoint>130){//一定盈利的情况下才主动止盈，否则因为可能属于震荡而保持原状。
				return(true);
			}
		}
	  }else if(maxProfitPoint>=340 && maxProfitPoint<550)
	  {
		if(thisProfitPoint<=(0.618*maxProfitPoint)){
			if(thisProfitPoint>80){//一定盈利的情况下才主动止盈，否则因为可能属于震荡而保持原状。
				return(true);
			}
		}
	  }else if(maxProfitPoint<340)
	  {
		if(thisProfitPoint<=130){
			return(true);
		}
	  }
	   return(false);
	}else{
		if(OrderProfit()>0)
		{
			if(GlobalVariableSet(gvKey,OrderProfit())==0){
			  log_err("Error:when set global variable for "+gvKey+" : "+GetLastError());
			}
		}
		return(false);
	}
	return(false);
}