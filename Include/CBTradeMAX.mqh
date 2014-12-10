//+------------------------------------------------------------------+
//|                                                      CBClose.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""
#include <CBTradeCommon.mqh>
//基于快速MA慢速MA的交叉进行交易
//以简单的规则进行交易。若无单，凡快速MA高于慢速MA则做多，反之做空。若有单，只做TP/SL修改，不主动平仓。
//前1个固定时间主动平仓，后期自动平仓，着重这么处理。
//SL 最高为慢速MA
//MAX追求利润最大化
extern int periodFast=8;//快速MA的period
extern int periodSlow=26;//慢速MA的period
double maDiff=0.0004;//如果maFast与maSlow之间的距离小于该值，那么粗略的认为他们是相等的
//double maDiff=40*Point;//用point，考虑JPY 
//TODO JPY在不用Point时表现比用时好很多，考虑优化这几个数的取值
double minRateFast=0.0005;//fastma必须即时增长0.0005以上
//double minRateFast=50*Point;
double minRateSlow=0.0001;//slowma的即时增长必须大于-0.0001  似乎这个影响
//double minRateSlow=10*Point;
extern double lotSpecify=0.01;//指定手，开固定的大小
int exemptNumClose=0;//豁免在交叉后强制close的机会数。豁免权在maslow与mafast重合后获取。该属性只属于已有仓位。每bar自动减1
void tradeMAX()
{
   //this bar
   double maFast=iMA(NULL,0,periodFast,0,MODE_LWMA,PRICE_OPEN,0);    
   double maSlow=iMA(NULL,0,periodSlow,0,MODE_LWMA,PRICE_OPEN,0);  
   
   //last bar
   double maFast1=iMA(NULL,0,periodFast,0,MODE_LWMA,PRICE_OPEN,1);    
   double maSlow1=iMA(NULL,0,periodSlow,0,MODE_LWMA,PRICE_OPEN,1);  

   int posLiveTime = getPosLiveTime();//该货币对已有仓位的存在时间，0表示无仓位
   int posType=getPosType();//该货币对已有仓位的类别
   
   //double devDown=0;//最近periodSlow内价格下跌的方差
   //for(int i=0;i<periodSlow;i++)
   //{
   //   devDown=devDown+(Open[i]-Low[i])*(Open[i]-Low[i]);
   //}
   //devDown=devDown/periodSlow;
   //double stdDevDown=MathSqrt(devDown);
   double stdDev=iStdDev(NULL,0,26,0,MODE_LWMA,PRICE_MEDIAN,0);
   
   //double devUp=0;//最近periodSlow内价格上涨的方差
   //for(int j=0;j<periodSlow;j++)
   //{
   //   devUp=devUp+(Open[j]-High[j])*(Open[j]-High[j]);
   //}
   //devUp=devUp/periodSlow;
   //double stdDevUp=MathSqrt(devUp);
   
   if(maFast>maSlow+maDiff)
   {
      if(posLiveTime>0)
      {
         if(posType<0 && exemptNumClose<=0)
         {
            closeAll();
            if((maFast-maFast1)>=minRateFast && (maSlow1-maSlow)<=minRateSlow)
            {
               openMAX(10);//做多
            }
         }else if(posType>0)
         {
            if(posLiveTime>(4*periodFast*Period()*60))
            {
               modifyStopLoseMAX(maSlow);
            }else if(posLiveTime>(2*periodFast*Period()*60))
            {
               modifyStopLoseMAX(maSlow-1*stdDev);
            }else if(posLiveTime>(periodFast*Period()*60))
            {
               modifyStopLoseMAX(maSlow-2*stdDev);
            }else
            {
               modifyStopLoseMAX(maSlow-3*stdDev);
            }
         }
      }else if(posLiveTime==0)
      {
         if((maFast-maFast1)>=minRateFast && (maSlow1-maSlow)<=minRateSlow)
         {
            openMAX(10);//做多
         }
      }
      
      if(exemptNumClose>0)
      {
         exemptNumClose=exemptNumClose-1;
      }
   }else if(maFast<maSlow-maDiff)
   {
      if(posLiveTime>0)
      {
         if(posType>0 && exemptNumClose<=0)
         {
            closeAll();
            if((maFast1-maFast)>=minRateFast && (maSlow-maSlow1)<=minRateSlow)
            {
               openMAX(-10);//做空
            }
         }else if(posType<0)
         {
            if(posLiveTime>(4*periodFast*Period()*60))
            {
               modifyStopLoseMAX(maSlow);
            }else if(posLiveTime>(2*periodFast*Period()*60))
            {
               modifyStopLoseMAX(maSlow+1*stdDev);
            }else if(posLiveTime>(periodFast*Period()*60))
            {
               modifyStopLoseMAX(maSlow+2*stdDev);
            }else
            {
               modifyStopLoseMAX(maSlow+3*stdDev);
            }
         }
      }else if(posLiveTime==0)
      {
         if((maFast1-maFast)>=minRateFast && (maSlow-maSlow1)<=minRateSlow)
         {
            openMAX(-10);//做空
         }
      }
      
      if(exemptNumClose>0)
      {
         exemptNumClose=exemptNumClose-1;
      }
   }else{
      //不需要修改stoplose
      
      if(posLiveTime>0)
      {
         exemptNumClose=4+exemptNumClose;//在maslow与mafast重合后获得豁免权4
         if(exemptNumClose>10){
            exemptNumClose=10;
         }
      }
   }
}

//修改其stoplose为maSlow
void modifyStopLoseMAX(double maSlow)
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
         
         if(maSlow!=OrderStopLoss())
         {
            if(OrderModify(OrderTicket(),OrderOpenPrice(),maSlow,OrderTakeProfit(),0,Blue)==false)
            {
               log_err("Error: set new stop level for "+OrderTicket()+" failed! errorcode:"+GetLastError());    
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
   double lotToOpen=lotSpecify;
   //double lotToOpen=analyseLotToOpen(measure);
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
         thisTicket=OrderSend(Symbol(),OP_BUY,lotToOpen,Ask,slippage,NULL,NULL,"",MAGICNUMBER,0,Blue);
      }else if(measure<0)
      {
         thisTicket=OrderSend(Symbol(),OP_SELL,lotToOpen,Bid,slippage,NULL,NULL,"",MAGICNUMBER,0,Red);
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
