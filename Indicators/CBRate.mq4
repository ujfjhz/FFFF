//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_chart_window 
#property indicator_buffers 4       // Number of buffers
#property indicator_color1 Yellow    // Line color of 0 buffer
#property indicator_color2 DarkOrange//Line color of the 1st buffer
#property indicator_color3 Green    // Line color of the 2nd buffer
#property indicator_color4 Brown    // Line color of the 3rd buffer

//--------------------------------------------------------------- 2 --
int History    =888;        // Amount of bars in calculation history
int Period_MA_0=5;          // 当前时间尺度上的MA的快速计算期间(计算期间的单位为bar数)
int Period_Rate_1     =8;          //当前时间尺度上的比率的计算期间
//--------------------------------------------------------------- 3 --
int   Period_MA_2,  Period_MA_3,       // 比当前时间尺度高一阶及两阶上的MA的计算期间  
K2, K3;                          // 当前时间尺度向高阶时间尺度转换的转换系数
double   Line_0[],                        // Indicator array of support MA   
Line_1[], Line_2[], Line_3[];    // Indicator array of rate lines    

int Period_Rate_2,Period_Rate_3;                // Amount of bars for rates calc.
//--------------------------------------------------------------- 4 --
int init()                          // Special function init()  
{   
SetIndexBuffer(0,Line_0);        // Assigning an array to a buffer   
SetIndexBuffer(1,Line_1);        // Assigning an array to a buffer   
SetIndexBuffer(2,Line_2);        // Assigning an array to a buffer   
SetIndexBuffer(3,Line_3);        // Assigning an array to a buffer   

SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,1);// Line style
SetIndexStyle (1,DRAW_LINE,STYLE_SOLID,1);// Line style
SetIndexStyle (2,DRAW_LINE,STYLE_SOLID,1);// Line style
SetIndexStyle (3,DRAW_LINE,STYLE_SOLID,1);// Line style

//--------------------------------------------------------------- 5 --   
switch(Period())                 // Calculating coefficient for..     
{                              // .. different timeframes      
case     1: K2=5;K3=15; break;// Timeframe M1     
case     5: K2=3;K3= 6; break;// Timeframe M5      
case    15: K2=2;K3= 4; break;// Timeframe M15      
case    30: K2=2;K3= 8; break;// Timeframe M30      
case    60: K2=4;K3=24; break;// Timeframe H1      
case   240: K2=6;K3=42; break;// Timeframe H4      
case  1440: K2=7;K3=30; break;// Timeframe D1      
case 10080: K2=4;K3=12; break;// Timeframe W1      
case 43200: K2=3;K3=12; break;// Timeframe MN     
}
//--------------------------------------------------------------- 6 --   
Period_Rate_2=K2*Period_Rate_1;                    // Calc. period for nearest TF   
Period_Rate_3=K3*Period_Rate_1;                    // Calc. period for next TF   
Period_MA_2 =K2*Period_MA_0;     // Calc. period of MA for nearest TF   
Period_MA_3 =K3*Period_MA_0;     // Calc. period of MA for next TF
//--------------------------------------------------------------- 7 --   
return;                          // Exit the special function init()  
}//--------------------------------------------------------------- 8 --

int start()                         // Special function start()  
{
//--------------------------------------------------------------- 9 --   
double   MA_c, MA_p,                      // Current and previous MA values   
Sum;                             // Technical param. for sum accumul.   
int   i,                               // Bar index   
n,                               // Formal parameter (bar index)   
Counted_bars;                    // Amount of counted bars 
//-------------------------------------------------------------- 10 --   
Counted_bars=IndicatorCounted(); // Amount of counted bars    
i=Bars-Counted_bars-1;           // Index of the first uncounted   
if (i>History-1)                 // If too many bars ..      
i=History-1;                  // ..calculate specified amount
//-------------------------------------------------------------- 11 --   
while(i>=0)                      // Loop for uncounted bars     
{      
//-------------------------------------------------------- 12 --      
Line_0[i]=iMA(NULL,0,Period_MA_0,0,MODE_LWMA,PRICE_TYPICAL,i);                   // Horizontal reference line    todo  
//-------------------------------------------------------- 13 --      
MA_c=iMA(NULL,0,Period_MA_0,0,MODE_LWMA,PRICE_TYPICAL,i);      
MA_p=iMA(NULL,0,Period_MA_0,0,MODE_LWMA,PRICE_TYPICAL,i+Period_Rate_1);      
Line_1[i]= MA_c-MA_p;         // Value of 1st rate line      
//-------------------------------------------------------- 14 --      
MA_c=iMA(NULL,0,Period_MA_2,0,MODE_LWMA,PRICE_TYPICAL,i);      
MA_p=iMA(NULL,0,Period_MA_2,0,MODE_LWMA,PRICE_TYPICAL,i+Period_Rate_2);      
Line_2[i]= MA_c-MA_p;         // Value of 2nd rate line      
//-------------------------------------------------------- 15 --      
MA_c=iMA(NULL,0,Period_MA_3,0,MODE_LWMA,PRICE_TYPICAL,i);      
MA_p=iMA(NULL,0,Period_MA_3,0,MODE_LWMA,PRICE_TYPICAL,i+Period_Rate_3);      
Line_3[i]= MA_c-MA_p;         // Value of 3rd rate line       
//-------------------------------------------------------- 18 --      
i--;                          // Calculating index of the next bar      
//-------------------------------------------------------- 19 --     
}   
return;                          // Exit the special function start()  
}//-------------------------------------------------------------- 