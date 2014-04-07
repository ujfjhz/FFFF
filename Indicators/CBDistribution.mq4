//+------------------------------------------------------------------+
//|                                                         test.mq4 |
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_chart_window 
#property indicator_buffers 5       // Number of buffers
#property indicator_color1 Yellow    // Line color of 0 buffer
#property indicator_color2 DarkOrange//Line color of the 1st buffer
#property indicator_color3 Green    // Line color of the 2nd buffer
#property indicator_color4 Brown    // Line color of the 3rd buffer
#property indicator_color5 Teal    // Line color of the 4rd buffer

//--------------------------------------------------------------- 2 --
//用于分析微观(1分钟尺度)的一段时间内的价格构成

//使用方法：iCustom(NULL,PERIOD_M1,"CBDistribution",mode,shift); 其中只允许设置参数mode,shift，否则错误
extern int History  =45;        // 所分析的历史宽度，默认为15分钟策略而设，固设为45个1分钟bar

double   Line_0[], Line_1[], Line_2[], Line_3[], Line_4[];    // Indicator array of rate lines    
//--------------------------------------------------------------- 4 --
int init()                          // Special function init()  
{   
SetIndexBuffer(0,Line_0);        // Assigning an array to a buffer   
SetIndexBuffer(1,Line_1);        // Assigning an array to a buffer   
SetIndexBuffer(2,Line_2);        // Assigning an array to a buffer   
SetIndexBuffer(3,Line_3);        // Assigning an array to a buffer   
SetIndexBuffer(4,Line_4);        // Assigning an array to a buffer   

SetIndexStyle (0,DRAW_LINE,STYLE_SOLID,1);// Line style
SetIndexStyle (1,DRAW_LINE,STYLE_SOLID,1);// Line style
SetIndexStyle (2,DRAW_LINE,STYLE_SOLID,1);// Line style
SetIndexStyle (3,DRAW_LINE,STYLE_SOLID,1);// Line style
SetIndexStyle (4,DRAW_LINE,STYLE_SOLID,1);// Line style

//--------------------------------------------------------------- 7 --   
return;                          // Exit the special function init()  
}//--------------------------------------------------------------- 8 --

int start()                         // Special function start()  
{
//--------------------------------------------------------------- 9 --   
int   i,                               // Bar index   
Counted_bars;                    // Amount of counted bars 
//-------------------------------------------------------------- 10 --   
Counted_bars=IndicatorCounted(); // Amount of counted bars    
i=Bars-Counted_bars-1;           // Index of the first uncounted   
if (i>History-1)                 // If too many bars ..      
i=History-1;                  // ..calculate specified amount

bool isUp = true;	//该区间是否close>open
if((Close[0]-Open[i])<0)
{
	isUp=false;
}

//-------------------------------------------------------------- 11 --   
while(i>=0)                      // Loop for uncounted bars     
{      
int q1=1;	//low-open之间的数量(下降行情则是high到open之间的数量)
int q2=1;	//open-close之间的数量
int q3=1;	//close-high之间的数量
int upCount=1;	//上涨的数目
int downCount=1;	//下降的数目

for(int j=1;j<=History;j++)
{
	if(isUp){
		if((Close[i+j]-Open[i+j])>=0){
			upCount++;
		}else{
			downCount++;
		}
		if(Close[i+j]<Open[i+History]){
			q1++;
		}else if(Close[i+j]<Close[i+1]){
			q2++;
		}else{
			q3++;
		}
	}else{
		if((Close[i+j]-Open[i+j])<0){
			upCount++;
		}else{
			downCount++;
		}
		if(Close[i+j]>Open[i+History]){
			q1++;
		}else if(Close[i+j]>Close[i+1]){
			q2++;
		}else{
			q3++;
		}
	}
}

//-------------------------------------------------------- 12 --      
Line_0[i]=q1;                   // Horizontal reference line    todo  
Line_1[i]=q2;         // Value of 1st rate line      
Line_2[i]=q3;         // Value of 2nd rate line         
Line_3[i]=upCount;         // Value of 3rd rate line      
Line_4[i]=downCount;
//-------------------------------------------------------- 18 --      
i--;                          // Calculating index of the next bar      
//-------------------------------------------------------- 19 --     
}   
return;                          // Exit the special function start()  
}//-------------------------------------------------------------- 