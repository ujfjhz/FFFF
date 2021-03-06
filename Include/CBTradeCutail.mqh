//+------------------------------------------------------------------+
//|                                                      CBClose.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
#include <CBTradeCommon.mqh>

//cutail策略的变量们
double cutailTPfactor=1.0;   //影响因子

//收割上涨(看空时则是下跌)的尾巴
//原理：在连续3次上涨等条件后，仍然上涨的概率的期望大于50%；看空时同理。
//交易细节：在满足条件后，开单，设置较小的止盈止损点，让市场平仓。
//止损点最小为5。止损点设为前3bar的(open-low)的最大值;看空时为(high-open)的最大值。
//止盈点设为前3bar的利润点平均值
void tradeCutail()
{
   //交易前先刷新价格
   RefreshRates();

   int posLiveTime = getPosLiveTime();//该货币对已有仓位的存在时间，0表示无仓位
   if(posLiveTime>0){
      if(posLiveTime>(1500)){//每个仓位当达到30分钟还未自动平仓时，主动平仓。这里是15分钟曲线，用25区分
         closeAll();
         log_info("The position's life is exeeding 1500 senconds,close it.");
      }
   }else{
      int istail = analyseTail();//1为上涨的tail,-1为下跌的tail,0为非tail
      openTail(istail);
   }
}

//专为Cutail策略开仓
void openTail(int istail)
{
   if(istail!=0)
   {
      double lotToOpen=calculatePosition();

      if(lotToOpen<=0)
      {
         return;
      }

      int thisTicket=0;
      int retryCount=0;
      while(true)
      {
         retryCount=retryCount+1;
         if(retryCount>10)
         {
            log_err("Retry count reach the max, break it.");
            break;
         }
         //交易前先刷新价格
         RefreshRates();
         double stopLoss=0;
         double takeprofit=0;
         double minSLDistance=50*Point;
         double maxSLDistance=180*Point;
         double minTPDistance=50*Point;
         double maxTPDistance=210*Point;
         if(istail>0)
         {
            /*
            minSLDistance=MathMax(minSLDistance,(Open[1]-Low[1]));
            minSLDistance=MathMax(minSLDistance,(Open[2]-Low[2]));
            minSLDistance=MathMax(minSLDistance,(Open[3]-Low[3]));
            */
            
            //另外一种stoploss算法，取前三的最低值
            double lowest=MathMin(Low[1],Low[2]);
            //lowest=MathMin(lowest,Low[3]);
            stopLoss=MathMin((Ask-minSLDistance),lowest);
            if(stopLoss<(Ask-maxSLDistance)){
               stopLoss=Ask-maxSLDistance;
            }
            //takeprofit=Ask+(High[1]+High[2]+High[3]-Open[1]-Open[2]-Open[3])*cutailTPfactor/3;
            takeprofit=Ask+(High[1]+High[2]-Open[1]-Open[2])*cutailTPfactor/2;
            if(takeprofit<(Ask+minTPDistance)){
               takeprofit=Ask+minTPDistance;
            }
            if(takeprofit>(Ask+maxTPDistance)){
               takeprofit=Ask+maxTPDistance;
            }
            thisTicket=OrderSend(Symbol(),OP_BUY,lotToOpen,Ask,slippage,stopLoss,takeprofit,"",MAGICNUMBER,0,Blue);
            
            //反向交易
            /*
            takeprofit=Ask-minSLDistance;
            if((High[1]+High[2]+High[3]-Open[1]-Open[2]-Open[3])/3<minSLDistance){
               stopLoss=Bid+minSLDistance;
            }else{
               stopLoss=Bid+(High[1]+High[2]+High[3]-Open[1]-Open[2]-Open[3])/3;
            }
            thisTicket=OrderSend(Symbol(),OP_SELL,lotToOpen,Bid,slippage,stopLoss,takeprofit,"",MAGICNUMBER,0,Blue);
            */
         }else if(istail<0)
         {
            /*
            minSLDistance=MathMax(minSLDistance,(High[1]-Open[1]));
            minSLDistance=MathMax(minSLDistance,(High[2]-Open[2]));
            minSLDistance=MathMax(minSLDistance,(High[3]-Open[3]));
            */
            
            //另外一种stoploss算法，取前三的最低值
            double highest=MathMax(High[1],High[2]);
            //highest=MathMax(highest,High[3]);
            stopLoss=MathMax((Bid+minSLDistance),highest);
            if(stopLoss>(Bid+maxSLDistance)){
               stopLoss=Bid+maxSLDistance;
            }
            //takeprofit=Bid-(Open[3]+Open[2]+Open[1]-Low[3]-Low[2]-Low[1])*cutailTPfactor/3;
            takeprofit=Bid-(Open[2]+Open[1]-Low[2]-Low[1])*cutailTPfactor/2;
            if(takeprofit>(Bid-minTPDistance)){
               takeprofit=Bid-minTPDistance;
            }
            if(takeprofit<(Bid-maxTPDistance)){
               takeprofit=Bid-maxTPDistance;
            }
            thisTicket=OrderSend(Symbol(),OP_SELL,lotToOpen,Bid,slippage,stopLoss,takeprofit,"",MAGICNUMBER,0,Red);
            
            //反向交易
            /*
            takeprofit=Bid+minSLDistance;
            if((Open[3]+Open[2]+Open[1]-Low[3]-Low[2]-Low[1])/3<minSLDistance){
               stopLoss=Ask-minSLDistance;
            }else{
               stopLoss=Ask-(Open[3]+Open[2]+Open[1]-Low[3]-Low[2]-Low[1])/3;
            }
            thisTicket=OrderSend(Symbol(),OP_BUY,lotToOpen,Ask,slippage,stopLoss,takeprofit,"",MAGICNUMBER,0,Red);
            */
         }
         if(thisTicket>0)
         {
            log_info("Opened order: "+thisTicket);
            break;
         }else{
            int lastError=GetLastError();                 // Failed :(      
            switch(lastError)                             // Overcomable errors        
            {         
               case 135:
                  log_err("The price has changed. Retrying..");            
                  RefreshRates();                     // Update data            
                  continue;                           // At the next iteration         
               case 136:
                  log_err("No prices. Waiting for a new tick..");            
                  Sleep(500);                         // Simple solution            
                  RefreshRates();                     // Update data 
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
            break;
         }
      }
   }
}