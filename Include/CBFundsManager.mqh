//+------------------------------------------------------------------+
//|                                               CBFundsManager.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""

//fixed position. Only if it's set(greater or equal than 0), we'll use it as the position; else we'll caculate the position in runtime.
extern const double position=-1; 

extern double fundPropotion = 0.1;	// fund propotion for this symbol, comparing to other symbols
extern double defaultMaB = 1;	// default moving average profit/lose
extern double defaultMaP = 0.5;	// default moving average probability of profit
double maB = defaultMaB;
double maP = defaultMaP;

//fund management by kelly formula
double kellyFormula()
{
   double kelly = ((maB+1)*maP-1)/maB;
   if( kelly<=0 || kelly >= 1){
   		log_fatal("Wrong maB("+maB+") or maP("+maP+"), cause wrong kelly result("+kelly+").");
		kelly = 0;
   }
   return(kelly);
}

//获取当前标的的可用资金配额
double getSymbolFreeMargin()
{
double totalFreeMargin=AccountFreeMargin( ) ;	
double symbolFreeMargin=totalFreeMargin*fundPropotion;

int total=OrdersTotal();
for(int pos=0;pos<total;pos++)
 {
  if(OrderSelect(pos,SELECT_BY_POS)==true)
  {
	if(OrderSymbol() !=Symbol() || OrderMagicNumber()!=MAGICNUMBER)// Don't handle other symbols and other timeframes.
	{
	  continue;
	}
	
	symbolFreeMargin=symbolFreeMargin-OrderLots()*MarketInfo(Symbol(),MODE_MARGINREQUIRED);
	
  }else
  {
      log_err("orderselect failed :"+GetLastError());
	  symbolFreeMargin=-1;//计算配额失败，则返回配额为-1，从而防止错误交易。
  }
 }
 
 return(symbolFreeMargin);
}

//calculate position for this symbol
double calculatePosition()
{
	//if user specify the position, we'll use the fixed position
	if(position>=0)
	{
		return(position);
	}
	
	double lot=0;

	double minLot=MarketInfo(Symbol(),MODE_MINLOT);// Min. volume     
	double step=MarketInfo(Symbol(),MODE_LOTSTEP);//Step to change lots        
	double lotCost=MarketInfo(Symbol(),MODE_MARGINREQUIRED);//Cost per 1 lot    
	double symbolFreeMargin=getSymbolFreeMargin();
	
	//position shouldnot be too sensitive to free margin, thus we passivate it.
	double quotaFundBase = MathFloor(symbolFreeMargin/1000)*1000;
	if(symbolFreeMargin>=(quotaFundBase+500)){
		quotaFundBase=symbolFreeMargin;
	}
	if(quotaFundBase<500)
	{
		quotaFundBase=500;
	}
	
	double quotaFund=quotaFundBase*kellyFormula();

	lot=MathFloor((quotaFund/lotCost)/step)*step;
	log_debug("quotaFund:"+quotaFund+"--costPerLot:"+lotCost+"---step:"+step+"thisLot:"+lot);
	if(lot<minLot)
	{
		return(0);
	}
	return(lot);
}

//update profile for this symbol periodically
void updateProfile()
{
//TODO
	//NewYork Close Time 16:00 , Friday
	if(TimeHour(Time[0])==16 && TimeMinute(Time[0])==0 && TimeDayOfWeek(Time[0])==5)	
	{
		//get trade history 
		//if data is enough, statist and update the profile, such as maB, maP, etc.
	}
}