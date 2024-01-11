//+------------------------------------------------------------------+
//|                                            HighLowBreakoutEA.mq5 |
//|                                                      myk-francis |
//|                 https://myk-francis.github.io/michael-portfolio/ |
//+------------------------------------------------------------------+
#property copyright "myk-francis"
#property link      "https://myk-francis.github.io/michael-portfolio/"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
double high = 0;                                                        //highest price of the last N bars
double low = 0;                                                         //lowest price of the last N bars
MqlTick currentTick, previousTick;
CTrade trade;

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
static input long       InpMagicNumber = 55555;                         //magic number
static input double     InpLots = 0.01;                                 //lots
input int               InpBars = 20;                                   //bars for high/low
input int               InpStopLoss = 200;                              //stop loss in points (0=off)
input int               InpTakeProfit = 0;                              //take profit in points (0=off)
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!CheckInputs())
     {
      return INIT_PARAMETERS_INCORRECT;
     }

//set magic number to trade object
   trade.SetExpertMagicNumber(InpMagicNumber);

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {


  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//get current tick
   if(!SymbolInfoTick(_Symbol, currentTick))
     {
      Print("Failed to get current tick");
      return;
     }

   previousTick = currentTick;
   
   //count open positions
    int cntBuy, cntSell;
    if(!CountOpenPositions(cntBuy, cntSell))
      {
       return;
      }
      
    //check for buy position
    if(cntBuy == 0 && high != 0 && previousTick.ask < high && currentTick.ask >= high)
      {
      Print("Open buy position!!!");
      }
      
    //check for sell position
    if(cntSell == 0 && low != 0 && previousTick.bid > low && currentTick.bid <= low)
      {
      Print("Open sell position!!!");
      }
      
    //calculate high and low
    high = iHigh(_Symbol, PERIOD_CURRENT, iHighest(_Symbol, PERIOD_CURRENT,MODE_HIGH, InpBars, 0));
    low = iLow(_Symbol, PERIOD_CURRENT, iLowest(_Symbol, PERIOD_CURRENT, MODE_LOW, InpBars, 0));
    
    //DrawObjects meaning lines
    DrawObjects();

  }


//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
bool CheckInputs()
  {
   if(InpMagicNumber <= 0)
     {
      Alert("Magic number <= 0");
      return false;
     }

   if(InpLots <= 0 || InpLots > 10)
     {
      Alert("InpLotSize <= 0 or InpLotSize > 10");
      return false;
     }

   if(InpStopLoss < 0)
     {
      Alert("InpStopLoss < 0");
      return false;
     }

   if(InpTakeProfit < 0)
     {
      Alert("InpTakeProfit < 0");
      return false;
     }

   return true;
  }
  
bool CountOpenPositions(int &cntBuy, int &cntSell)
  {
   cntBuy = 0;
   cntSell = 0;
   int total = PositionsTotal();

   for(int i=total-1; i<0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      long magic;
      
      if(ticket == 0)
        {
         return true;
        }

      if(ticket <= 0)
        {
         Print("Failed to get open ticket!");
         return false;
        }

      if(!PositionSelectByTicket(ticket))
        {
         Print("Failed to select position!");
         return false;
        }

      if(!PositionGetInteger(POSITION_MAGIC, magic))
        {
         Print("Failed to get position magic number!");
         return false;
        }

      if(magic == InpMagicNumber)
        {
         long type;

         if(!PositionGetInteger(POSITION_TYPE, type))
           {
            Print("Failed to get position type!");
            return false;
           }

         if(type==POSITION_TYPE_BUY)
           {
            cntBuy++;
           }
         if(type==POSITION_TYPE_SELL)
           {
            cntSell++;
           }
        }
     }

   return true;
  }
  
//normalize price
bool NormalizePrice(double &price)
{
   double tickSize = 0;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE, tickSize))
     {
      Print("Failed to get tick size!");
      return false;
     }
     
   price = NormalizeDouble(MathRound(price / tickSize) * tickSize, _Digits);
   
   return true;
}

//close open positions
bool ClosePositions(int all_buy_sell)
  {
   int total = PositionsTotal();
   for(int i=total - 1; i>=0; i--)
     {

      if(total != PositionsTotal())
        {
         total = PositionsTotal();
         i = total;
         continue;
        }

      ulong ticket = PositionGetTicket(i); //select position
      if(ticket <= 0)
        {
         Print("Failed to get position ticket");
         return false;
        }

      if(!PositionSelectByTicket(ticket))
        {
         Print("Failed to select position!");
         return false;
        }

      long magic_number;
      if(!PositionGetInteger(POSITION_MAGIC, magic_number))
        {
         Print("Failed to get position magic number!");
         return false;
        }

      if(magic_number == InpMagicNumber)
        {
         long type;

         if(!PositionGetInteger(POSITION_TYPE, type))
           {
            Print("Failed to get position type!");
            return false;
           }

         if(all_buy_sell == 1 && type==POSITION_TYPE_BUY)
           {
            continue;
           }
           
         if(all_buy_sell == 2 && type==POSITION_TYPE_SELL)
           {
            continue;
           }
           
         trade.PositionClose(ticket);

         if(trade.ResultRetcode() != TRADE_RETCODE_DONE)
           {
            Print("Failed to close position. Result: " + (string)trade.ResultRetcode() + "+" + trade.ResultRetcodeDescription());
            return false;
           }
        }
     }

   return true;
  }
  
void DrawObjects()
  {
  
  datetime time = iTime(_Symbol, PERIOD_CURRENT, 20);
//high
   ObjectDelete(NULL, "high");
   ObjectCreate(NULL, "high", OBJ_TREND, 0, time, high, TimeCurrent(), high);
   ObjectSetInteger(NULL, "high", OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(NULL, "high", OBJPROP_WIDTH, 2);

//low
   ObjectDelete(NULL, "low");
   ObjectCreate(NULL, "low", OBJ_TREND, 0, time, low, TimeCurrent(), low);
   ObjectSetInteger(NULL, "low", OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(NULL, "low", OBJPROP_WIDTH, 2);
  }
//+------------------------------------------------------------------+
