//+------------------------------------------------------------------+
//|                        Copyright 2012, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_chart_window 
#property indicator_buffers 3       // Number of buffers

//--------------------------------------------------------------- 2 --
int History    =666;        // Amount of bars in calculation history

extern int n=51;									  // 通过最近n个bar的数据计算
extern int trend=0;

double   leftMaxDistance[];					  // n期间内与当前价格的最大价格差距
double   leftMaxDistance2[];					  // leftMaxDistance点左侧与leftMaxDistance的最大差距
double isFlat[];

int init()                          // Special function init()  
{
SetIndexBuffer(0,leftMaxDistance);
SetIndexBuffer(1,leftMaxDistance2);
SetIndexBuffer(2,isFlat);
return;                          // Exit the special function init()  
}//--------------------------------------------------------------- 8 --

int start()                         // Special function start()  
{
int   i,                               // Bar index     
Counted_bars;                    // Amount of counted bars 
//-------------------------------------------------------------- 10 --   
Counted_bars=IndicatorCounted(); // Amount of counted bars    
i=Bars-Counted_bars-1;           // Index of the first uncounted   
if (i>History-1)                 // If too many bars ..      
i=History-1;                  // ..calculate specified amount
//-------------------------------------------------------------- 11 --   
while(i>=0)                      // Loop for uncounted bars     
{       
//-------------------------------------------------------- 15 --      
double maxPointDistance=0;
double thisDistance=0;
int maxDistanceIndex=i; //最大距离的index
for(int k=0;k<n;k++){
	if((i+k)<=(Bars-1)){
		thisDistance=MathAbs(Open[i]-Open[i+k])/Point;
		if(thisDistance>maxPointDistance){
			maxPointDistance=thisDistance;
			maxDistanceIndex=i+k;
		}
	}	
}
leftMaxDistance[i]= maxPointDistance;      
//-------------------------------------------------------- 18 --      
maxPointDistance=0;
thisDistance=0;
for(int l=maxDistanceIndex;l<i+n;l++){
	if(l<=(Bars-1)){
		thisDistance=MathAbs(Open[maxDistanceIndex]-Open[l])/Point;
		if(thisDistance>maxPointDistance){
			maxPointDistance=thisDistance;
		}
	}	
}
leftMaxDistance2[i]= maxPointDistance; 
//-------
double isflatTmp=1;
thisDistance=0;
for(int m=0;m<n;m++){
	for(int q=m;q<n;q++){
		thisDistance=(Open[q+i]-Open[m+i])/Point;
		if(trend>0){
			if(thisDistance>550){
				isflatTmp=0;
				break;
			}
		}else if(trend<0){
			if(thisDistance<-550){
				isflatTmp=0;
				break;
			}
		}
	}
	if(isflatTmp==0){
		break;
	}
}
isFlat[i]=isflatTmp;

i--;                          // Calculating index of the next bar      
//-------------------------------------------------------- 19 --     
}   
return;                          // Exit the special function start()  
}//-------------------------------------------------------------- 