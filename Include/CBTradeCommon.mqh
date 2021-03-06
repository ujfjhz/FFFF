//+------------------------------------------------------------------+
//|                                                      CBClose.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
#include <CBMonitor.mqh>

int slippage=13; //单位为point(0.00001)

//获得当前货币对已有仓位的存在时间，单位为秒
//不算周六、日
int getPosLiveTime()
{
   int posLiveTime=0;
   int total=OrdersTotal();
   for(int pos=0;pos<total;pos++)
   {
     if(OrderSelect(pos,SELECT_BY_POS)==true)
     {
         if(OrderSymbol() !=Symbol()  || OrderMagicNumber()!=MAGICNUMBER)// Don't handle other symbols and other timeframes.
         {
            continue;
         }
         posLiveTime=TimeCurrent()-OrderOpenTime();
         break;
     }else
     {
         log_err("orderselect failed :"+GetLastError());
     }
   }
   int numWeek=MathFloor(posLiveTime/(7*24*3600));
   posLiveTime=posLiveTime-numWeek*2*24*3600;
    return(posLiveTime);
}

//获得当前货币对已有仓位的类别
//大于0表示多单，小于0表示空单，等于0表示无单
int getPosType()
{
   int posType=0;
   int total=OrdersTotal();
   for(int pos=0;pos<total;pos++)
   {
     if(OrderSelect(pos,SELECT_BY_POS)==true)
     {
         if(OrderSymbol() !=Symbol()  || OrderMagicNumber()!=MAGICNUMBER)// Don't handle other symbols and other timeframes.
         {
            continue;
         }
         if(OP_BUY==OrderType())
         {
            posType=1;
         }else if(OP_SELL==OrderType())
         {
            posType=-1;
         }
         break;
     }else
     {
         log_err("orderselect failed :"+GetLastError());
     }
   }
    return(posType);
}

//平掉所选仓
void closeSelectedTicket()
{
   //交易前先刷新价格
   RefreshRates();
   int retryCount=0;
   while(true)
   {    
      retryCount=retryCount+1;
      if(retryCount>10)
      {
         log_err("Retry count reach the max, break it.");
         break;
      }
      int lastError=0;
      
      if(OrderType()== OP_BUY){
          if(OrderClose(OrderTicket(),OrderLots(),Bid,slippage,Green)==false)
         {
            lastError=GetLastError();
         }else
         {
            log_debug("Closed:"+OrderSymbol()+" ;Lots  "+OrderLots()+"; Price:"+Bid);
            break;
         }
      }else if(OrderType()== OP_SELL){
         if(OrderClose(OrderTicket(),OrderLots(),Ask,slippage,Red)==false)
         {
            lastError=GetLastError();
         }else
         {
            log_debug("Closed:"+OrderSymbol()+" ;Lots  "+OrderLots()+"; Price:"+Ask);
            break;
         }
      }
      
      switch(lastError)                             // Overcomable errors        
      {         
         case 135:
            log_err("The price has changed. Retrying..");            
            RefreshRates();                     // Update data            
            continue;                           // At the next iteration         
         case 136:
            log_err("No prices. Waiting for a new tick..");            
            Sleep(500);                
            RefreshRates();
            continue;                           // At the next iteration         
         case 146:
            log_err("Trading subsystem is busy. Retrying..");            
            Sleep(500);                         // Simple solution            
            RefreshRates();                     // Update data            
            continue;                           // At the next iteration        
      }      
      
      switch(lastError)                             // Critical errors        
      {         
         case 2 : 
            log_err("Common error.");            
            break;                              // Exit 'switch'         
         case 5 : 
            log_err("Outdated version of the client terminal.");            
            break;                              // Exit 'switch'         
         case 64: 
            log_err("The account is blocked.");            
            break;                              // Exit 'switch'         
         case 133:
            log_err("Trading forbidden");            
            break;                              // Exit 'switch'         
         default: 
            log_err("Occurred error :"+lastError);// Other alternatives         
            break;
      }
      break; // break the loop for critical errors      
   }
}

//close all the positions in this Symbol.
//Note: cannot close the positions in mirror.
void closeAll()
{
RefreshRates();
int total=OrdersTotal();
for(int pos=0;pos<total;pos++)
 {
  if(OrderSelect(pos,SELECT_BY_POS)==true)
  {
   if(OrderSymbol() !=Symbol() || OrderMagicNumber()!=MAGICNUMBER)// Don't handle other symbols and other timeframes.
   {
      continue;
   }
   
   closeSelectedTicket();

  }else
  {
      log_err("orderselect failed :"+GetLastError());
  }
 }
 //log_debug("I've close all the tickets in "+Symbol());
}

/*
获取最大盈利的Point数目
*/
double getMaxProfitPoint()
{
	string gvKey="MPP_"+OrderTicket();
    double thisProfitPoint=OrderProfit()/OrderLots();
    double maxProfitPoint = 0;
	if(GlobalVariableCheck(gvKey)){
      maxProfitPoint=GlobalVariableGet(gvKey);

	  if(thisProfitPoint>maxProfitPoint)
	  {
         maxProfitPoint=thisProfitPoint;
         if(GlobalVariableSet(gvKey,maxProfitPoint)==0){
           log_err("Error:when set global variable for "+gvKey+" : "+GetLastError());
         }
	  }
	}else{
		if(thisProfitPoint>0)
		{
            maxProfitPoint=thisProfitPoint;
			if(GlobalVariableSet(gvKey,maxProfitPoint)==0){
			  log_err("Error:when set global variable for "+gvKey+" : "+GetLastError());
			}
		}
	}
    return(maxProfitPoint);
}