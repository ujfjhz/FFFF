//+------------------------------------------------------------------+
//|                                                      CBClose.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
#include <CBTradeCommon.mqh>
//基于快速MA慢速MA的交叉进行交易
//以简单的规则进行交易。若无单，凡快速MA高于慢速MA则做多，反之做空。只做SL修改，不设TP。
//MAX追求利润最大化
//for 4H only

//TODO 自适应
extern int periodFast=80;//快速MA的period
extern int periodSlow=260;//慢速MA的period

double maDiff=0.0004;//如果maFast与maSlow之间的距离小于该值，那么粗略的认为他们是相等的
double minRateFast=0.0005;//fastma必须即时增长0.0005以上
double minRateSlow=-0.0001;//slowma的即时增长必须大于-0.0001  似乎这个影响

double minDistSL=100*Point;
double maxDistSL=3000*Point;

int exemptNumClose=0;//豁免在交叉后强制close的机会数。豁免权在开仓后，maslow与mafast交叉或重合后有机会获取。该属性只属于已有仓位。每bar自动减1。
int lastUpdownStatus=0;//上一bar的fast与slow MA的相对位置


void tradeMAX()
{

   //this bar
   double maFast=iMA(NULL,0,periodFast,0,MODE_LWMA,PRICE_OPEN,0);    
   double maSlow=iMA(NULL,0,periodSlow,0,MODE_LWMA,PRICE_OPEN,0);  
   //last bar
   double maFast1=iMA(NULL,0,periodFast,0,MODE_LWMA,PRICE_OPEN,1);    
   double maSlow1=iMA(NULL,0,periodSlow,0,MODE_LWMA,PRICE_OPEN,1);  
   //last two*periodFast bar
   double maFast2=iMA(NULL,0,periodFast,0,MODE_LWMA,PRICE_OPEN,MathMax(2*periodFast,10));    
   double maSlow2=iMA(NULL,0,periodSlow,0,MODE_LWMA,PRICE_OPEN,MathMax(2*periodFast,10));  

   int posLiveTime = getPosLiveTime();//该货币对已有仓位的存在时间，0表示无仓位
   int posType=getPosType();//该货币对已有仓位的类别
   
   double atr = iATR(NULL,0,periodSlow,0);
   
   //atrDist=atr*atrFactor;   // atr stop.  have the simular performance with atr dev stop.
   atrDist=atr+3.25*calculateAtrStdDev(periodSlow,atr);   // atr dev stop

   maDiff=(0.001)*atr;
   minRateFast=(0.001)*atr;
   minRateSlow=(-0.0005)*atr;
   
   if(maFast>(maSlow+maDiff))
   {
      if(posLiveTime>0)
      {
         if(lastUpdownStatus<0 && (maFast2+maDiff)<maSlow2 ) //考虑加上 && maFast<(maSlow+n*maDiff)
         {
            exemptNumClose=3+exemptNumClose;
            if(exemptNumClose>8){
               exemptNumClose=8;
            }
         }
      
         if(posType<0 && exemptNumClose<=0)
         {
            closeAll();
            if((maFast-maFast1)>=minRateFast && (maSlow-maSlow1)>=minRateSlow)
            {
               openMAX(10);//做多
            }
         }else if(posType>0)
         {
         /* set stop loss for every period
            if(posLiveTime>(3*MathMax(5,periodFast)*Period()*60))
            {
               modifyStopLoseMAX(MathMax(1*atrDist,MathAbs(maSlow-Ask)));
            }else if(posLiveTime>(2*MathMax(5,periodFast)*Period()*60))
            {
               modifyStopLoseMAX(MathMax(1.5*atrDist,MathAbs(maSlow-Ask)));
            }else if(posLiveTime>(MathMax(5,periodFast)*Period()*60))
            {
               modifyStopLoseMAX(MathMax(2*atrDist,MathAbs(maSlow-Ask)));
            }else
            {
               modifyStopLoseMAX(MathMax(3*atrDist,MathAbs(maSlow-Ask)));
            }
            */
            
            //set stop loss simply
            modifyStopLoseMAX(atrDist);
         }
      }else if(posLiveTime==0)
      {
         if((maFast-maFast1)>=minRateFast && (maSlow-maSlow1)>=minRateSlow)
         {
            openMAX(10);//做多
         }
      }
      
      if(exemptNumClose>0)
      {
         exemptNumClose=exemptNumClose-1;
      }
      lastUpdownStatus=1;
   }else if(maFast<(maSlow-maDiff))
   {
      if(posLiveTime>0)
      {
         if(lastUpdownStatus>0 && (maFast2-maDiff)>maSlow2)
         {
            exemptNumClose=3+exemptNumClose;
            if(exemptNumClose>8){
               exemptNumClose=8;
            }
         }
         if(posType>0 && exemptNumClose<=0)
         {
            closeAll();
            if((maFast1-maFast)>=minRateFast && (maSlow1-maSlow)>=minRateSlow)
            {
               openMAX(-10);//做空
            }
         }else if(posType<0)
         {
         /*
            if(posLiveTime>(3*MathMax(5,periodFast)*Period()*60))
            {
               modifyStopLoseMAX(MathMax(1*atrDist,MathAbs(maSlow-Bid)));
            }else if(posLiveTime>(2*MathMax(5,periodFast)*Period()*60))
            {
               modifyStopLoseMAX(MathMax(1.5*atrDist,MathAbs(maSlow-Bid)));
            }else if(posLiveTime>(MathMax(5,periodFast)*Period()*60))
            {
               modifyStopLoseMAX(MathMax(2*atrDist,MathAbs(maSlow-Bid)));
            }else
            {
               modifyStopLoseMAX(MathMax(3*atrDist,MathAbs(maSlow-Bid)));
            }
            */
            modifyStopLoseMAX(atrDist);
         }
      }else if(posLiveTime==0)
      {
         if((maFast1-maFast)>=minRateFast && (maSlow1-maSlow)>=minRateSlow)
         {
            openMAX(-10);//做空
         }
      }
      
      if(exemptNumClose>0)
      {
         exemptNumClose=exemptNumClose-1;
      }
      lastUpdownStatus=-1;
   }else{
      //不需要修改stoplose
      if(posType<0)
      {
         if(lastUpdownStatus<0 && (maFast2+maDiff)<maSlow2 ) 
         {
            exemptNumClose=3+exemptNumClose;
            if(exemptNumClose>8){
               exemptNumClose=8;
            }
         }
      }else if(posType>0)
      {
         if(lastUpdownStatus>0 && (maFast2-maDiff)>maSlow2)
         {
            exemptNumClose=3+exemptNumClose;
            if(exemptNumClose>8){
               exemptNumClose=8;
            }
         }
      }
      lastUpdownStatus=0;
   }
}

//根据stoplose distance修改stoplose (保持单调性)
void modifyStopLoseMAX(double distSL)
{
   //set the maxreturn profit
   //double maxReturnPrice = 3000*Point;
   double profitPoints=0;
   double profitRelRNum=0;
   
   int total=OrdersTotal();
   double newSL=0;
   for(int pos=0;pos<total;pos++)
   {
      if(OrderSelect(pos,SELECT_BY_POS)==true)
      {
         if(OrderSymbol() !=Symbol()  || OrderMagicNumber()!=MAGICNUMBER)// Don't handle other symbols and other timeframes and other stratedy.
         {
            continue;
         }
         
         //profit back stoploss check
         profitRelRNum=OrderProfit()/(OrderLots()*MarketInfo(Symbol(),MODE_MARGINREQUIRED));   //  take margin as R, the profit R num is: profit/margin
         if(profitRelRNum>=7){
            //log_info(distSL+"---7---"+OrderProfit()*Point*0.14/OrderLots()+"---"+OrderProfit()*Point/OrderLots());
            distSL=MathMin(distSL,OrderProfit()*Point*0.14/OrderLots());
         }else if(profitRelRNum>=6){
            //log_info(distSL+"---6---"+OrderProfit()*Point*0.22/OrderLots()+"---"+OrderProfit()*Point/OrderLots());
            distSL=MathMin(distSL,OrderProfit()*Point*0.22/OrderLots());
         }else if(profitRelRNum>=5){
            //log_info(distSL+"---5---"+OrderProfit()*Point*0.3/OrderLots()+"---"+OrderProfit()*Point/OrderLots());
            distSL=MathMin(distSL,OrderProfit()*Point*0.3/OrderLots());
         }else if(profitRelRNum>=4){
            //log_info(distSL+"---4---"+OrderProfit()*Point*0.36/OrderLots()+"---"+OrderProfit()*Point/OrderLots());
            distSL=MathMin(distSL,OrderProfit()*Point*0.36/OrderLots());
         }else if(profitRelRNum>=3){
            //log_info(distSL+"---3---"+OrderProfit()*Point*0.4/OrderLots()+"---"+OrderProfit()*Point/OrderLots());
            distSL=MathMin(distSL,OrderProfit()*Point*0.4/OrderLots());
         }
         
         if(distSL<minDistSL){
            distSL=minDistSL;
         }
         if(distSL>maxDistSL){
            distSL=maxDistSL;
         }
         
         if(OrderType()==OP_BUY)
         {
            newSL=Ask-distSL;
            if(newSL>OrderStopLoss() || OrderStopLoss()==NULL)
            {
               if(OrderModify(OrderTicket(),OrderOpenPrice(),newSL,OrderTakeProfit(),0,Blue)==false)
               {
                  log_err("Error: set new stop level for "+OrderTicket()+" failed! errorcode:"+GetLastError());    
               }
            }
         }else if(OrderType()==OP_SELL)
         {
            newSL=Bid+distSL;
            if(newSL<OrderStopLoss() || OrderStopLoss()==NULL)
            {
               if(OrderModify(OrderTicket(),OrderOpenPrice(),newSL,OrderTakeProfit(),0,Blue)==false)
               {
                  log_err("Error: set new stop level for "+OrderTicket()+" failed! errorcode:"+GetLastError());    
               }
            }
         }
      }else
      {
         log_err("orderselect failed :"+GetLastError());
      }
   }
}

void openMAX(double measure)
{
   double lotToOpen=calculatePosition();
 
   if(lotToOpen<=0)
   {
      return;
   }
   if(lotToOpen>1)
   {//each time, we'd better trade not greater than 1 lot.
      lotToOpen=1;
      log_err("The caculated position is greater than 1, set it to 1.");
   }
   log_debug("try to open :"+lotToOpen);
     
   //交易前先刷新价格
   RefreshRates();
   int thisTicket=0;
   double distSLOpen=0;
   if((atrDist)>maxDistSL)
   {
      distSLOpen=maxDistSL;
   }else{
      distSLOpen=atrDist;
   }
   if((atrDist)<minDistSL)
   {
      distSLOpen=minDistSL;
   }else{
      distSLOpen=atrDist;
   }
   int retryCount=0;
   while(true)
   {
      retryCount=retryCount+1;
      if(retryCount>10)
      {
         log_err("Retry count reach the max, break it.");
         break;
      }
      log_info("The request was sent to the server. Waiting for reply...");
      if(measure>0)
      {
         thisTicket=OrderSend(Symbol(),OP_BUY,lotToOpen,Ask,slippage,Ask-distSLOpen,NULL,"",MAGICNUMBER,0,Blue);
      }else if(measure<0)
      {
         thisTicket=OrderSend(Symbol(),OP_SELL,lotToOpen,Bid,slippage,Bid+distSLOpen,NULL,"",MAGICNUMBER,0,Red);
      }
      if(thisTicket>0)
      {
         log_info("Opened order: "+thisTicket);
         exemptNumClose=0;//开仓后重置豁免权
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
            case 4110:
               log_err("longs  are not allowed in the expert properties");       //TODO 其他地方加上该异常处理     
               break; 
            case 4111:
               log_err("shorts are not allowed in the expert properties");            
               break;               
            default: 
               log_err("Occurred error :"+lastError);// Other alternatives         
               break;
         }
         break; // break the loop for critical errors
      }
   }
}
