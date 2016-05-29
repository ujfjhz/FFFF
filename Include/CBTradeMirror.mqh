//+------------------------------------------------------------------+
//|                                                                  CBClose.mq4 |
//|                                                                   ArchestMage |
//|                                                                                      |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
#include <CBTradeCommon.mqh>

/*
Mirror stratedgy is a generous stratedgy for hedging other stratedgies.
Mirror should run on 1 minute timeframe chart.
Mirror should set a fixed postion.
Mirror shouldnot mirror mirror.
*/

extern string mirrorTarget = ""; //only used when stratedy is set to "mirror"
void tradeMirror()
{
   //check mirror timeframe
   
   //check position
   
   
}



void openMirror()
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
