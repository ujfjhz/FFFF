//+------------------------------------------------------------------+
//|                                               CBFundsManager.mq4 |
//|                                                      ArchestMage |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "ArchestMage"
#property link      ""

//+------------------------------------------------------------------+
//如下参水将实际杠杆控制在10下。
//(在账户杠杆为200的前提下，人工指定如下参数。)
//注意，如下参数不可定义为extern,，以防不同的ea实例间产生不一致。
int costFund=1000;//本金，单位为$。本金的数量级间为2倍关系。if (equity >= costFund*2){costFund = costFund*2}。
int maxSymbolCount=5;//最大标的数
int symbolQuota=10; //每个标的的资金配额
//+------------------------------------------------------------------+

//获取当前标的的可用资金配额
double getQuota()
{
if(debug)
{
	symbolQuota=60;
}

double maxSymbolQuota=symbolQuota;

int total=OrdersTotal();
for(int pos=0;pos<total;pos++)
 {
  if(OrderSelect(pos,SELECT_BY_POS)==true)
  {
	if(OrderSymbol() !=Symbol())// Don't handle other symbols.
	{
	  continue;
	}
	
	maxSymbolQuota=maxSymbolQuota-OrderOpenPrice()*OrderLots()*100000/AccountLeverage();
	
  }else
  {
      log_err("orderselect failed :"+GetLastError());
	  maxSymbolQuota=-1;//计算配额失败，则返回配额为-1，从而防止错误交易。
  }
 }
 
 return(maxSymbolQuota);
}