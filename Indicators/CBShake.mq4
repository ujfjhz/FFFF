//+------------------------------------------------------------------+
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_chart_window 
#property indicator_buffers 2       // Number of buffers

//--------------------------------------------------------------- 2 --
int History    =666;        // Amount of bars in calculation history

extern int n=5;									  // 通过最近n个bar的数据计算当前的局部震荡程度
double   Line_0[];					  // Bar[n]的开盘与Bar[0]的收盘之差的绝对值 
double   Line_1[];					  // n bars的振幅之和
//Line1[i]与Line_0[i]的比值可用来描述局部震荡性，最小值为1(此时最具趋势性)


int init()                          // Special function init()  
{   
SetIndexBuffer(0,Line_0);        // Assigning an array to a buffer   
SetIndexBuffer(1,Line_1);        // Assigning an array to a buffer  
return;                          // Exit the special function init()  
}//--------------------------------------------------------------- 8 --

int start()                         // Special function start()  
{
int   i,                               // Bar index     
Counted_bars;                    // Amount of counted bars 
//-------------------------------------------------------------- 10 --   
Counted_bars=IndicatorCounted(); // Amount of counted bars    
i=Bars-Counted_bars-1-n;           // Index of the first uncounted   
if (i>History-1)                 // If too many bars ..      
i=History-1;                  // ..calculate specified amount
//-------------------------------------------------------------- 11 --   
while(i>=0)                      // Loop for uncounted bars     
{      
//-------------------------------------------------------- 13 --    
if((i+n-1)>(Bars-1)){
	Line_0[i]= 0;
}else{
	Line_0[i]= MathAbs(Open[i+n-1]-Close[i])/Point;  
}
       
//-------------------------------------------------------- 14 --       
double sum=0;
for(int j=0;j<n;j++){
	if((i+j)<=(Bars-1)){
		sum=MathAbs(High[i+j]-Low[i+j])/Point+sum;  
	}
}
Line_1[i]= sum;      // Value of 2nd rate line     

i--;                          // Calculating index of the next bar      
//-------------------------------------------------------- 19 --     
}   
return;                          // Exit the special function start()  
}//-------------------------------------------------------------- 