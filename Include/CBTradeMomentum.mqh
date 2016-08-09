//+------------------------------------------------------------------+
//|                                                      CBClose.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
#include <CBTradeCommon.mqh>

void tradeMomentum()
{
   //交易前先刷新价格
   RefreshRates();

   int posLiveTime = getPosLiveTime();//该货币对已有仓位的存在时间，0表示无仓位
   if(posLiveTime>0){
      if(posLiveTime>(3600*4)){//每个仓位当达到4小时还未自动平仓时，主动平仓。
         closeAll();
         log_info("The position's life is exeeding 4 hours,close it.");
      }else{
            modifyStopLevel();
      }
   }else{
      double  momentum= analyseMomentum();
      openMomentum(momentum);
   }
}

int analyseMomentum()
{
int momentum=0;
double moveUp=iCustom(NULL,1,"CBMomentum",Period(),0,0);
double moveDown=iCustom(NULL,1,"CBMomentum",Period(),0,1);
double move=iCustom(NULL,1,"CBMomentum",Period(),0,2);
double upA=iCustom(NULL,1,"CBMomentum",Period(),0,3);
double downA=iCustom(NULL,1,"CBMomentum",Period(),0,4);

double momentumUp=moveUp+upA*Period();
double momentumDown=moveDown+downA*Period();
momentum=int(momentumUp-momentumDown)/10;

if(momentum>-20 && momentum<20)
{
   momentum=0;
}
if(moveUp>0){
   if(MathAbs(move/moveUp)<0.1)
   {
      momentum=0;
   }
}else if(moveUp<0){
   if(MathAbs(move/moveDown)<0.1)
   {
      momentum=0;
   }
}
return(momentum);
}


//专为momentum策略开仓
void openMomentum(int momentum)
{
   if(momentum!=0)
   {
      double lotToOpen=analyseLotToOpen(momentum);//借助trend的概念进行分析需要open的手数

      if(lotToOpen<=0)
      {
         return;
      }

      int thisTicket=0;
      while(true)
      {
         //交易前先刷新价格
         RefreshRates();
         double stopLoss=0;
         double takeprofit=0;
         double minSLDistance=80*Point;
         double maxSLDistance=180*Point;
         double minTPDistance=130*Point;
         double maxTPDistance=210*Point;
         if(momentum>0)
         {
            //另外一种stoploss算法，取前三的最低值
            double lowest=MathMin(Low[1],Low[2]);
            lowest=MathMin(lowest,Low[3]);
            lowest=MathMin(lowest,Low[4]);
            stopLoss=MathMin((Ask-minSLDistance),lowest);
            if(stopLoss<(Ask-maxSLDistance)){
               stopLoss=Ask-maxSLDistance;
            }
            //takeprofit=Ask+(High[1]+High[2]+High[3]-Open[1]-Open[2]-Open[3])*cutailTPfactor/3;
            takeprofit=Ask+(High[1]+High[2]-Open[1]-Open[2])/2;
            if(takeprofit<(Ask+minTPDistance)){
               takeprofit=Ask+minTPDistance;
            }
            if(takeprofit>(Ask+maxTPDistance)){
               takeprofit=Ask+maxTPDistance;
            }
            thisTicket=OrderSend(Symbol(),OP_BUY,lotToOpen,Ask,slippage,stopLoss,takeprofit,"",MAGICNUMBER,0,Blue);
            
         }else if(momentum<0)
         {
            //另外一种stoploss算法，取前三的最低值
            double highest=MathMax(High[1],High[2]);
            highest=MathMax(highest,High[3]);
            highest=MathMax(highest,High[4]);
            stopLoss=MathMax((Bid+minSLDistance),highest);
            if(stopLoss>(Bid+maxSLDistance)){
               stopLoss=Bid+maxSLDistance;
            }
            //takeprofit=Bid-(Open[3]+Open[2]+Open[1]-Low[3]-Low[2]-Low[1])*cutailTPfactor/3;
            takeprofit=Bid-(Open[2]+Open[1]-Low[2]-Low[1])/2;
            if(takeprofit>(Bid-minTPDistance)){
               takeprofit=Bid-minTPDistance;
            }
            if(takeprofit<(Bid-maxTPDistance)){
               takeprofit=Bid-maxTPDistance;
            }
            thisTicket=OrderSend(Symbol(),OP_SELL,lotToOpen,Bid,slippage,stopLoss,takeprofit,"",MAGICNUMBER,0,Red);
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
                  while(RefreshRates()==false)        // Up to a new tick               
                     {
                        Sleep(1);                        // Cycle delay            
                     }
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
         }
      }
   }
}
