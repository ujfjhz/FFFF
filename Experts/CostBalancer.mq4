//+------------------------------------------------------------------+
//|                                                 CostBalancer.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
#include <CBUtil.mqh>
#include <CBRiskManager.mqh>
#include <CBFundsManager.mqh>
#include <CBAnalyst.mqh>
#include <CBMessage.mqh>
#include <CBTradeMomentum.mqh>
#include <CBTradeMAX.mqh>
#include <CBMonitor.mqh>

bool isTrade=true;//全局控制是否在tick来临时自动化交易
extern string stratedy="MAX";//交易策略。有如下选择：cutail,trend,inertia.默认为cutail收割利润尾巴；trend为按趋势交易；inertia为惯性策略。
string cbVersion="1.0";//version

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   Print("CostBalancer-"+cbVersion+" start running....");
   
   int sumcode = 0;
   for (int i=0; i<StringLen(formula); i++)
   {
      sumcode = sumcode + (i+1)*StringGetChar(formula,i);
   }
   if(sumcode!=7667)
   {
      isTrade=false;
	  
      log_err("auth false");
   }

   return(0);
  }
  
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
   log_info("CostBalancer has been stopped.");

   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//| 在每个ticket到来时执行
//+------------------------------------------------------------------+
int start()
  {
   //---- trade  only for first tiks of new bar.
   if(Volume[0]>1)
   {
      return(0);
   }

   
   //是否自动化交易
   if(!isTrade){
      return(0);
   }
   
   //---- check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
   {
      return(0);
   }
   
   //消息日平掉所有仓，不进行交易，以规避黑天鹅
   if(isMessegeDay()){
      closeAll(); 
      log_info("It's in stop business period now ,close all the position,and do nothing.");
      //不再交易
     return(0);
   }

   //节假日、消息日平掉所有仓，不进行交易，以规避黑天鹅
   if(isStopBusinessDay()){
     return(0);
   }
   
   //if(checkContinuousLoss()){
      //log_info("It's lost continuous this week ,stop trade this week.");
      //在判断是否连续loss中输出"It's lost continuous this week ,stop trade this week."，以防每个tick都输出一次。
    //  return(0);
   //}
   
   //get some data
   processMessage();
   
   if(stratedy=="momentum"){
   //以惯性策略交易
      tradeMomentum();
   }else if(stratedy=="cutail"){
   //以cutail策略(收割尾巴)交易
      tradeCutail();
   }else if(stratedy=="MAX"){
   //基于快速MA慢速MA的交叉进行交易
      tradeMAX();
   }else{
   //默认以趋势策略交易
      if(isLastStopLoss()){
         log_info("There's a ticket stop loss in the last hour,thus stop trade in this bar.");
         return(0);
      }
      tradeTrend();
   }

   return(0);
  }
  
