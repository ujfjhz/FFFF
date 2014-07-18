//+------------------------------------------------------------------+
// Period_converter_auto
// automatically converts M1-data to M5/M15/M30/H1/H4/D1 in a single run
//
// to be used for importing M1-market data into Metatrader
//+------------------------------------------------------------------+
#property copyright "ps"
#property link      "http://www.tradingscape.com"
#property show_inputs
#include <WinUser32.mqh>

int        ExtHandle=-1;
//+------------------------------------------------------------------+
//| script program start function                                    |
//+------------------------------------------------------------------+
int start() {
   writeHistory(PERIOD_M5);
   writeHistory(PERIOD_M15);
   writeHistory(PERIOD_M30);
   writeHistory(PERIOD_H1);
   writeHistory(PERIOD_H4);
   writeHistory(PERIOD_D1);
   return(0);
}

int writeHistory(int histPeriod)
  {
   int    i, start_pos, i_time, time0, last_fpos, periodseconds;
   double d_open, d_low, d_high, d_close, d_volume, last_volume;
   int    hwnd=0,cnt=0;
//---- History header
   
   int    version=400;
   string c_copyright;
   string c_symbol=Symbol();
   int    i_period=Period()*histPeriod;
   int    i_digits=Digits;
   int    i_unused[13];
//----  
   
   ExtHandle=FileOpenHistory(c_symbol+i_period+".hst", FILE_BIN|FILE_WRITE);
   if(ExtHandle < 0) return(-1);
//---- write history file header
   c_copyright="(C)opyright 2003, MetaQuotes Software Corp.";
   FileWriteInteger(ExtHandle, version, LONG_VALUE);
   FileWriteString(ExtHandle, c_copyright, 64);
   FileWriteString(ExtHandle, c_symbol, 12);
   FileWriteInteger(ExtHandle, i_period, LONG_VALUE);
   FileWriteInteger(ExtHandle, i_digits, LONG_VALUE);
   FileWriteInteger(ExtHandle, 0, LONG_VALUE);       //timesign
   FileWriteInteger(ExtHandle, 0, LONG_VALUE);       //last_sync
   FileWriteArray(ExtHandle, i_unused, 0, 13);
//---- write history file
   periodseconds=i_period*60;
   start_pos=Bars-1;
   d_open=Open[start_pos];
   d_low=Low[start_pos];
   d_high=High[start_pos];
   d_volume=Volume[start_pos];
   //---- normalize open time
   i_time=Time[start_pos]/periodseconds;
   i_time*=periodseconds;
   for(i=start_pos-1;i>=0; i--)
     {
      time0=Time[i];
      if(time0>=i_time+periodseconds || i==0)
        {
         if(i==0 && time0<i_time+periodseconds)
           {
            d_volume+=Volume[0];
            if (Low[0]<d_low)   d_low=Low[0];
            if (High[0]>d_high) d_high=High[0];
            d_close=Close[0];
           }
         last_fpos=FileTell(ExtHandle);
         last_volume=Volume[i];
         FileWriteInteger(ExtHandle, i_time, LONG_VALUE);
         FileWriteDouble(ExtHandle, d_open, DOUBLE_VALUE);
         FileWriteDouble(ExtHandle, d_low, DOUBLE_VALUE);
         FileWriteDouble(ExtHandle, d_high, DOUBLE_VALUE);
         FileWriteDouble(ExtHandle, d_close, DOUBLE_VALUE);
         FileWriteDouble(ExtHandle, d_volume, DOUBLE_VALUE);
         FileFlush(ExtHandle);
         cnt++;
         if(time0>=i_time+periodseconds)
           {
            i_time=time0/periodseconds;
            i_time*=periodseconds;
            d_open=Open[i];
            d_low=Low[i];
            d_high=High[i];
            d_close=Close[i];
            d_volume=last_volume;
           }
        }
       else
        {
         d_volume+=Volume[i];
         if (Low[i]<d_low)   d_low=Low[i];
         if (High[i]>d_high) d_high=High[i];
         d_close=Close[i];
        }
     } 
   FileFlush(ExtHandle);
   Alert("Period:"+histPeriod+" | "+cnt," records written");
   if(ExtHandle>=0) { FileClose(ExtHandle); ExtHandle=-1; }

//----
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deinit()
  {
   Alert("Finished.");
  }
//+------------------------------------------------------------------+