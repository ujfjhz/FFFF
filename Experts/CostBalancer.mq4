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
#include <CBTradeTouch.mqh>
#include <CBTradeTrend.mqh>
#include <CBTradeCutail.mqh>
#include <CBJinGangJing.mqh>
#include <CBTradeBreakout.mqh>


bool isTickStart=true;//全局控制是否在tick来临时开始自动处理
extern string stratedy="true";//交易策略。有如下选择：cutail,trend,inertia.默认为cutail收割利润尾巴；trend为按趋势交易；inertia为惯性策略。
string cbVersion="1.0-160515";//version
int MAGICNUMBER=0;//用于同品种在不同的策略或者在不同的图上能独立运行
datetime prevtime=0; //the time of bar which before the just coming ticket. the new ticket can form a new bar or just add to the old bar.

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   log_info("CostBalancer-"+cbVersion+" start running for "+Symbol()+"....");
   bless();
   log_info("Lot size in the base currency: "+MarketInfo(Symbol(),MODE_LOTSIZE));
   log_info("Minimum permitted amount of a lot: "+MarketInfo(Symbol(),MODE_MINLOT));
   log_info("Maximum permitted amount of a lot: "+MarketInfo(Symbol(),MODE_MAXLOT));
   log_info("Step for changing lots: "+MarketInfo(Symbol(),MODE_LOTSTEP));
   log_info("Free margin required to open 1 lot for buying: "+MarketInfo(Symbol(),MODE_MARGINREQUIRED));
   //int delOldGVCount=GlobalVariablesDeleteAll("MPP_");
   //log_info(delOldGVCount+" globalvariables(MPP_) has been deleted.");
   //kdfkdkfd
   int sumcode = 0;
   for (int i=0; i<StringLen(formula); i++)
   {
      sumcode = sumcode + (i+1)*StringGetChar(formula,i);
   }
   if(sumcode!=7667)
   {
      isTickStart=false;
      log_fatal("Auth false. I will not process the new ticket any more.");
   }
   
   //set the stoplose distance
   if(Period()==1440){
      minDistSL=1000*Point;
      maxDistSL=20000*Point;
   }else if(Period()==240){
      minDistSL=400*Point;
      maxDistSL=8000*Point;
   }else if(Period()==60){
      minDistSL=200*Point;
      maxDistSL=4000*Point;
   }else{
      minDistSL=100*Point;
      maxDistSL=1000*Point;
   }
   
   MAGICNUMBER=Period()*1000;//map to big number ，避免冲突，可支持(1440-1*1000)个不同的策略并发执行
   if(stratedy=="momentum"){
      MAGICNUMBER=MAGICNUMBER+1;
   }else if(stratedy=="cutail"){
      MAGICNUMBER=MAGICNUMBER+2;
   }else if(stratedy=="MAX"){
      MAGICNUMBER=MAGICNUMBER+3;
   }else if(stratedy=="trend"){
      MAGICNUMBER=MAGICNUMBER+4;
   }else if(stratedy=="touch"){
      MAGICNUMBER=MAGICNUMBER+5;
   }else if(stratedy=="breakout"){
      MAGICNUMBER=MAGICNUMBER+6;
   }
   
   Print("Magic number: "+MAGICNUMBER);
   
   if(MAGICNUMBER==(Period()*1000))
   {
      isTickStart=false;
      log_fatal("The MAGICNUMBER is not set. I will not process the new ticket any more.");
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
   //是否开始自动处理
   if(!isTickStart){
      return(0);
   }
   
   //trade only for first ticket of new bar.
   if(prevtime == Time[0])
   {
      return(0);
   }
   prevtime = Time[0];
   
   //check for history and trading
   if(Bars<100 || IsTradeAllowed()==false)
   {
      return(0);
   }

   //消息日平掉所有仓，不进行交易，以规避黑天鹅
   if(isMessegeDay()){
      if(Period()<=60){//认为小于等于1H级别的可能受黑天鹅影响的概率大
         closeAll();
      }
      log_info("It's in stop business period now ,close the position,and do nothing.");
      return(0);
   }

   //节假日，不进行交易，以规避黑天鹅
   if(isStopBusinessDay()){
     return(0);
   }
   
   /**
   //if(checkContinuousLoss()){
      //log_info("It's lost continuous this week ,stop trade this week.");
      //在判断是否连续loss中输出"It's lost continuous this week ,stop trade this week."，以防每个tick都输出一次。
    //  return(0);
   //}
   */
   
   //get and send  message
   processMessage();
   
   //Note: 在增加新策略时，除了这里添加外，还必须在init()中分配MAGICNUMBER
   if(stratedy=="momentum"){
   //以惯性策略交易
      tradeMomentum();
   }else if(stratedy=="cutail"){
   //以cutail策略(收割尾巴)交易
      tradeCutail();
   }else if(stratedy=="MAX"){
   //基于快速MA慢速MA的交叉进行交易
      tradeMAX();
   }else if(stratedy=="trend"){
   //以趋势策略交易
      if(isLastStopLoss()){
         log_info("There's a ticket stop loss in the last hour,thus stop trade in this bar.");
         return(0);
      }
      tradeTrend();
   }else if(stratedy=="touch"){
      tradeTouch();
   }else if(stratedy=="breakout"){
      tradeBreakout();
   }
   
   //monitor
   monitor();
   
   //update profile
   updateProfile();

   return(0);
  }
  
