//+------------------------------------------------------------------+
//|                                                      CBClose.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
#include <CBTradeCommon.mqh>
//take the profit when touch takeprofit
//stop the lose when touch stoplose

int touchStopDist=50;//distance point

void tradeTouch()
{

   //double ma=iMA(NULL,0,5,0,MODE_LWMA,PRICE_OPEN,0); 
   //double ma1=iMA(NULL,0,5,0,MODE_LWMA,PRICE_OPEN,1); 

   closeAll();
   
   if(Open[0] > Close[1] + 10*Point)
   {
      openTouch(10);//做多
   }else if(Open[0] + 10*Point < Close[1])
   {
      openTouch(-10);//做空
   }
   
}

void openTouch(double measure)
{
   //double lotToOpen=lotSpecify;
   double lotToOpen=analyseLotToOpen(measure);
   log_debug("try to open :"+lotToOpen);
   if(lotToOpen<=0)
   {
      return;
   }
   if(lotToOpen>0.04)
   {
      lotToOpen=0.04;
   }
   
   //交易前先刷新价格
   RefreshRates();
   int thisTicket=0;

   while(true)
   {
      log_info("The request was sent to the server. Waiting for reply...");
      if(measure>0)
      {

         thisTicket=OrderSend(Symbol(),OP_BUY,lotToOpen,Ask,slippage,Ask-touchStopDist*Point,Bid+(touchStopDist+30)*Point,"",MAGICNUMBER,0,Blue);
         //thisTicket=OrderSend(Symbol(),OP_SELL,lotToOpen,Bid,slippage,Bid+(touchStopDist+30)*Point,Ask-(touchStopDist)*Point,"",MAGICNUMBER,0,Red);
      }else if(measure<0)
      {
         thisTicket=OrderSend(Symbol(),OP_SELL,lotToOpen,Bid,slippage,Bid+touchStopDist*Point,Ask-(touchStopDist+30)*Point,"",MAGICNUMBER,0,Red);
         //thisTicket=OrderSend(Symbol(),OP_BUY,lotToOpen,Ask,slippage,Ask-(touchStopDist+30)*Point,Bid+(touchStopDist)*Point,"",MAGICNUMBER,0,Blue);
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
      }
   }
}
