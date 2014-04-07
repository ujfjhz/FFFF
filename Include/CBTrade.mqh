//+------------------------------------------------------------------+
//|                                                      CBClose.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
#define MAGICNUMBER 34
extern int slippage=13; //单位为point(0.00001)

//趋势策略的变量们
int lastTrend=0;    //上一个趋势

//惯性策略的变量们
int inertiaPerioid=-1;   //受惯性影响的期限
int inertiaTakeprofit=10;  //惯性策略的主动take profit

//趋势策略的trade
void tradeTrend()
{
   //交易前先刷新价格
    RefreshRates();
   
   int trend = analyseTrend();
   
   if(trend==0)
   {
      modifyStopLevel();
   }else{
      if(lastTrend==0){
         checkForClose(trend);
         checkForOpen(trend);
      }else{
         if(trend*lastTrend < 0)
         {
            if(MathAbs(trend)>=8){
                checkForClose(trend);
                checkForOpen(trend);
            }else{
               modifyStopLevel();
            }
         }else{
            modifyStopLevel();
         }
      }
   }
   
   lastTrend=trend;
}

//收割上涨(看空时则是下跌)的尾巴
//原理：在连续3次上涨等条件后，仍然上涨的概率的期望大于50%；看空时同理。
//交易细节：在满足条件后，开单，设置较小的止盈止损点，让市场平仓。
//止损点最小为5。止损点设为前3bar的(open-low)的最大值;看空时为(high-open)的最大值。
//止盈点设为前3bar的利润点平均值
void tradeCutail()
{
   //交易前先刷新价格
   RefreshRates();
    
   int istail = analyseTail();//1为上涨的tail,-1为下跌的tail,0为非tail
   
   openTail(istail);
    
}

//惯性策略的trade
//在惯性的影响范围内，超过inertiaTakeprofit则自动平，否则在惯性的结尾强制平。
void tradeInertia()
{
   //交易前先刷新价格
    RefreshRates();
   
   int trend = analyseInertia();
   
   inertiaPerioid--;
   
   if(inertiaPerioid>=0){//大于0表示在惯性的影响范围内
      
      int total=OrdersTotal();
      for(int pos=0;pos<total;pos++)
       {
        if(OrderSelect(pos,SELECT_BY_POS)==true)
        {
         if(OrderSymbol() !=Symbol())// Don't handle other symbols.
         {
            continue;
         }
         
         double thisProfitPoint=OrderProfit()/OrderLots();

         if(OrderMagicNumber()==MAGICNUMBER){
            if(inertiaPerioid==0 || thisProfitPoint>=inertiaTakeprofit){
               closeCurrentTicket();
            }
         }

        }else
        {
            log_err("orderselect failed :"+GetLastError());
        }
       }
      
   }else if(inertiaPerioid<-5){//避开上个影响
      if(MathAbs(trend)>=8){
          checkForClose(trend);
          checkForOpen(trend);
          if(MathAbs(trend)>9){
            inertiaPerioid=5;
          }else{
            inertiaPerioid=3;
          }
      }
   }
   

   
}

//主动stop,否则修改其stoplevel
void modifyStopLevel()
{
int total=OrdersTotal();
for(int pos=0;pos<total;pos++)
 {
  if(OrderSelect(pos,SELECT_BY_POS)==true)
  {
   if(OrderSymbol() !=Symbol())// Don't handle other symbols.
   {
      continue;
   }
   
   if(isPositiveStop())
   {
      //主动止损
      closeCurrentTicket();
      log_info("I've stop level for "+OrderTicket()+" positively.");
   }else
   {
      double newStopLoss=analyseNewStopLoss();
      double newTakeProfit=analyseNewTakeProfit();
      
      if(newStopLoss!=OrderStopLoss() || newTakeProfit!=OrderTakeProfit())
      {
         if(OrderModify(OrderTicket(),OrderOpenPrice(),newStopLoss,newTakeProfit,0,Blue)==false)
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

//平掉当前仓
void closeCurrentTicket()
{
   //交易前先刷新价格
   RefreshRates();
   while(true)
   {    
      int lastError=0;
      
      if(OrderType()== OP_BUY  && OrderMagicNumber()==MAGICNUMBER){
             if(OrderClose(OrderTicket(),OrderLots(),Bid,slippage,Green)==false)
            {
               lastError=GetLastError();
            }else
            {
               log_info("Closed:"+OrderSymbol()+" ;Lots  "+OrderLots()+"; Price:"+Bid);
               break;
            }
      }
      
      if(OrderType()== OP_SELL && OrderMagicNumber()==MAGICNUMBER){
            if(OrderClose(OrderTicket(),OrderLots(),Ask,slippage,Red)==false)
            {
               lastError=GetLastError();
            }else
            {
               log_info("Closed:"+OrderSymbol()+" ;Lots  "+OrderLots()+"; Price:"+Ask);
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

//于trend，平需平之仓
//set the stop loss and take profit
void checkForClose(int trend)
{

int total=OrdersTotal();
for(int pos=0;pos<total;pos++)
 {
  if(OrderSelect(pos,SELECT_BY_POS)==true)
  {
   if(OrderSymbol() !=Symbol())// Don't handle other symbols.
   {
      continue;
   }

   if(OrderType()== OP_BUY  && OrderMagicNumber()==MAGICNUMBER){
      if(trend<0){
         closeCurrentTicket();
      }
   }
   
   if(OrderType()== OP_SELL && OrderMagicNumber()==MAGICNUMBER){
      if(trend>0){
         closeCurrentTicket();
      }
   }
  }else
  {
      log_err("orderselect failed :"+GetLastError());
  }
 }
}

//专为Cutail策略开仓
void openTail(int istail)
{
   if(istail!=0)
   {
      int trend=0;//Cuttail可以看做是一种局部趋势，故用trend的概念进行分析需要open的手数
      trend=maxTrend/2;//默认为最大趋势的一半
      double lotToOpen=analyseLotToOpen(trend);

      if(lotToOpen<=0)
      {
         return;
      }else{
         log_debug("try to open :"+lotToOpen);
      }

      int thisTicket=0;
      while(true)
      {
         //交易前先刷新价格
         RefreshRates();
         double stopLoss=0;
         double takeprofit=0;
         double maxSLDistance=40*Point;
         if(istail>0)
         {
            maxSLDistance=MathMax(maxSLDistance,(Open[1]-Low[1]));
            maxSLDistance=MathMax(maxSLDistance,(Open[2]-Low[2]));
            maxSLDistance=MathMax(maxSLDistance,(Open[3]-Low[3]));
            stopLoss=Ask-maxSLDistance;
            takeprofit=Ask+(Open[1]+Open[2]+Open[3]-Low[1]-Low[2]-Low[3])/3;
            //thisTicket=OrderSend(Symbol(),OP_BUY,lotToOpen,Ask,slippage,stopLoss,takeprofit,"",MAGICNUMBER,0,Blue);
            
            //反向交易
            
            takeprofit=Ask-maxSLDistance;
            if((Open[1]+Open[2]+Open[3]-Low[1]-Low[2]-Low[3])/3<maxSLDistance){
               stopLoss=Ask+maxSLDistance;
            }else{
               stopLoss=Ask+(Open[1]+Open[2]+Open[3]-Low[1]-Low[2]-Low[3])/3;
            }
            thisTicket=OrderSend(Symbol(),OP_SELL,lotToOpen,Bid,slippage,stopLoss,takeprofit,"",MAGICNUMBER,0,Blue);
            
         }else if(istail<0)
         {
            maxSLDistance=MathMax(maxSLDistance,(High[1]-Open[1]));
            maxSLDistance=MathMax(maxSLDistance,(High[2]-Open[2]));
            maxSLDistance=MathMax(maxSLDistance,(High[3]-Open[3]));
            stopLoss=Bid+maxSLDistance;
            takeprofit=Bid-(High[3]+High[2]+High[1]-Open[3]-Open[2]-Open[1])/3;
            //thisTicket=OrderSend(Symbol(),OP_SELL,lotToOpen,Bid,slippage,stopLoss,takeprofit,"",MAGICNUMBER,0,Red);
            
            //反向交易
            
            takeprofit=Bid+maxSLDistance;
            if((High[3]+High[2]+High[1]-Open[3]-Open[2]-Open[1])/3<maxSLDistance){
               stopLoss=Bid-maxSLDistance;
            }else{
               stopLoss=Bid-(High[3]+High[2]+High[1]-Open[3]-Open[2]-Open[1])/3;
            }
            thisTicket=OrderSend(Symbol(),OP_BUY,lotToOpen,Ask,slippage,stopLoss,takeprofit,"",MAGICNUMBER,0,Red);
            
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

//于trend下开仓
//All trades are performed at correct prices. The execution price for each trade is calculated on the basis of the correct price of a two-way quote.
//TODO pending(计划v2.0实现)
void checkForOpen(int trend)
{
   if(trend==0)
   {
      return;
   }else{
      if(checkIsShake()){
          log_info("It's shaking now,stop opening.");
          return;
      }
   }
   
   double lotToOpen=analyseLotToOpen(trend);
   log_debug("try to open :"+lotToOpen);
   if(lotToOpen<=0)
   {
      return;
   }

   int thisTicket=0;
   if(trend!=0)
   {
      //交易前先刷新价格
      RefreshRates();
      while(true)
      {
         log_info("The request was sent to the server. Waiting for reply...");
         if(trend>0)
         {
            thisTicket=OrderSend(Symbol(),OP_BUY,lotToOpen,Ask,slippage,analyseStopLoss(trend),analyseTakeProfit(trend),"",MAGICNUMBER,0,Blue);
         }else if(trend<0)
         {
            thisTicket=OrderSend(Symbol(),OP_SELL,lotToOpen,Bid,slippage,analyseStopLoss(trend),analyseTakeProfit(trend),"",MAGICNUMBER,0,Red);
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

//close all the positions in this Symbol.
void closeAll()
{
RefreshRates();
int total=OrdersTotal();
for(int pos=0;pos<total;pos++)
 {
  if(OrderSelect(pos,SELECT_BY_POS)==true)
  {
   if(OrderSymbol() !=Symbol())// Don't handle other symbols.
   {
      continue;
   }
   
   closeCurrentTicket();

  }else
  {
      log_err("orderselect failed :"+GetLastError());
  }
 }
 log_info("I've close all the tickets in "+Symbol());
}