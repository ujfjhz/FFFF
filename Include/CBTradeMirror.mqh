//+------------------------------------------------------------------+
//|                                                                  CBClose.mq4 |
//|                                                                   ArchestMage |
//|                                                                                      |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
#include <CBTradeCommon.mqh>

extern double mirror_position = 0.02;
int origTicket = 0; //The mirrored original ticket. 0 indicated nothing was mirrored yet.
int origType; //The position type of original ticket.

void tradeMirror()
{
   if(origTicket==0)
   {
      //check new opening original ticket
      int total=OrdersTotal();
      for(int pos=0;pos<total;pos++)
      {
        if(OrderSelect(pos,SELECT_BY_POS)==true)
        {
            if(OrderSymbol() !=Symbol() || OrderMagicNumber()!=MAGICNUMBER)// Don't handle other symbols and other timeframes.
            {
               continue;
            }
            origTicket=OrderTicket();
            origType = OrderType();
            break;
         }else
        {
            log_err("orderselect failed :"+GetLastError());
         }
      }
      if(origTicket>0)
      {
         //open hedge
         openMirror();
      }
   }else
   {
      //check new closed/sl/tp ticket
      int hstTotal=OrdersHistoryTotal();
      for(int i=hstTotal-1;i>=0;i--)
      {
        if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)==false)
	    {
			log_err("orderselect failed :"+GetLastError());
			break;
	    }
        if(origTicket==OrderTicket())
        {
            //close the mirror position
            closeMirror();
            origTicket=0;
        }
      }
   }
}



void openMirror()
{
   double lotToOpen=mirror_position;
 
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
      if(origType==OP_BUY)
      {
         thisTicket=OrderSend(Symbol(),OP_SELL,lotToOpen,Bid,slippage,NULL,NULL,"",MAGICNUMBERMIRROR,0,Red);
      }else if(origType==OP_SELL)
      {
         thisTicket=OrderSend(Symbol(),OP_BUY,lotToOpen,Ask,slippage,NULL,NULL,"",MAGICNUMBERMIRROR,0,Blue);
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

//close all the positions in mirror
void closeMirror()
{
RefreshRates();
int total=OrdersTotal();
for(int pos=0;pos<total;pos++)
 {
  if(OrderSelect(pos,SELECT_BY_POS)==true)
  {
   if(OrderSymbol() !=Symbol() || OrderMagicNumber()!=MAGICNUMBERMIRROR)// Don't handle other symbols and other timeframes.
   {
      continue;
   }
   
   closeSelectedTicket();

  }else
  {
      log_err("orderselect failed :"+GetLastError());
  }
 }
}
