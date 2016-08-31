//+------------------------------------------------------------------+
//|                                                 	    FFFF.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
#include <CBUtil.mqh>
#include <CBRiskManager.mqh>
#include <CBPortfolioManager.mqh>
#include <CBAnalyst.mqh>
#include <CBMessage.mqh>
#include <CBTradeMomentum.mqh>
#include <CBTradeMAX.mqh>
#include <CBTradeTouch.mqh>
#include <CBTradeTrend.mqh>
#include <CBTradeCutail.mqh>
#include <CBJinGangJing.mqh>
#include <CBTradeBreakout.mqh>
#include <CBTradeMirror.mqh>


bool isTickStart=true;//全局控制是否在tick来临时开始自动处理
extern string strategy="true";//交易策略。有如下选择：cutail,trend,inertia.默认为cutail收割利润尾巴；trend为按趋势交易；inertia为惯性策略。
string cbVersion="1.0-160530";//version
int MAGICNUMBER=0;//用于同品种在不同的策略或者在不同的图上能独立运行
datetime prevtime=0; //the time of bar which before the just coming ticket. the new ticket can form a new bar or just add to the old bar.

extern bool isMirror = false;   // is mirror this by hedging .  If i'ts mirrored, the original position will set to 0.01.
int MAGICNUMBERMIRROR=0;    //magic number of mirror
int currentMinute=0;    //current minute

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
   log_info("FFFF-"+cbVersion+" start running for "+Symbol()+"....");
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
      log_info("Set minDistSL to 1000 Point, maxDistSL to 20000 Point.");
   }
   
   MAGICNUMBER=Period()*1000;//map to big number ，避免冲突，可支持(5000-1000)个不同的策略并发执行
   if(strategy=="momentum"){
      MAGICNUMBER=MAGICNUMBER+1;
   }else if(strategy=="cutail"){
      MAGICNUMBER=MAGICNUMBER+2;
   }else if(strategy=="MAX"){
      MAGICNUMBER=MAGICNUMBER+3;
   }else if(strategy=="trend"){
      MAGICNUMBER=MAGICNUMBER+4;
   }else if(strategy=="touch"){
      MAGICNUMBER=MAGICNUMBER+5;
   }else if(strategy=="breakout"){
      MAGICNUMBER=MAGICNUMBER+6;
   }
   Print("Magic number: "+MAGICNUMBER);
   if(MAGICNUMBER==(Period()*1000))
   {
      isTickStart=false;
      log_fatal("The MAGICNUMBER is not set, so it will conflict with mirror. I will not process the new ticket. "+
      "Please check if you have defined magicnumber for this strategy:"+strategy);
   }
   
   if(isMirror)
   {
      if(position!=0.01)
      {
         log_fatal("If you want to mirror it, the original position cannot be : "+position+". Stop mirroring.");
         isMirror=false;
      }else{
         MAGICNUMBERMIRROR = Period()*1000;
         log_info("I was mirrored. The magicnumber of mirror is: "+MAGICNUMBERMIRROR+". Mirror size is:"+mirror_position);
      }
   }
   
   return(0);
  }
  
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
  {
   //TODO: check if there's opening position.
   log_info("CostBalancer has been stopped.");
   return(0);
  }
//+------------------------------------------------------------------+
//| expert start function                                            |
//| 在每个ticket到来时执行
//+------------------------------------------------------------------+
int start()
  {
   //if go on after new tick coming 
   if(!isTickStart){
      return(0);
   }
   
   //mirror
   if(isMirror)
   {
      int newCurrentMinute=TimeMinute(TimeCurrent());
      if(newCurrentMinute!=currentMinute)
      {//new minute is coming
         tradeMirror();
         currentMinute=newCurrentMinute;
      }
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
      log_info("History data is too short or the trade is not allowed, stop trading.");
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
   if(strategy=="momentum"){
   //以惯性策略交易
      tradeMomentum();
   }else if(strategy=="cutail"){
   //以cutail策略(收割尾巴)交易
      tradeCutail();
   }else if(strategy=="MAX"){
   //基于快速MA慢速MA的交叉进行交易
      tradeMAX();
   }else if(strategy=="trend"){
   //以趋势策略交易
      if(isLastStopLoss()){
         log_info("There's a ticket stop loss in the last hour,thus stop trade in this bar.");
         return(0);
      }
      tradeTrend();
   }else if(strategy=="touch"){
      tradeTouch();
   }else if(strategy=="breakout"){
      tradeBreakout();
   }
   
   //monitor
   monitor();
   
   //update profile
   updateProfile();

   return(0);
  }
  
