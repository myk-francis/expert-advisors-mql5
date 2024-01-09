//+------------------------------------------------------------------+
//|                                             BollingerBandsEA.mq5 |
//|                                                      myk-francis |
//|                 https://myk-francis.github.io/michael-portfolio/ |
//+------------------------------------------------------------------+
#property copyright "myk-francis"
#property link      "https://myk-francis.github.io/michael-portfolio/"
#property version   "1.00"
#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
static input long inpMagicNumber = 55555;          //magic number
static input double inpLotSize = 0.01;             //lot size
input int inpPeriod = 21;                          //period
input double inpDeviation = 2.0;                   //deviation
input int inpStopLoss = 100;                       //stop loss
input int inpTakeProfit = 200;                     //take profit


//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
int handle;
double upperBuffer[];
double baseBuffer[];
double lowerBuffer[];
MqlTick currentTick;
CTrade trade;
datetime openBuyTime = 0;
datetime openSellTime = 0;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//check user input
   if(inpMagicNumber <= 0)
     {
      Alert("Magic Number <= 0 ");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(inpLotSize <= 0)
     {
      Alert("Lot size <= 0 ");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(inpPeriod <= 1)
     {
      Alert("Period <= 1 ");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(inpDeviation <= 0)
     {
      Alert("Deviation <= 0 ");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(inpStopLoss <= 0)
     {
      Alert("Stop loss <= 0 ");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(inpTakeProfit < 0)
     {
      Alert("Take profit < 0 ");
      return INIT_PARAMETERS_INCORRECT;
     }

//set magic number
   trade.SetExpertMagicNumber(inpMagicNumber);

//--- create entry handle of the indicator iBands
   handle = iBands(Symbol(), PERIOD_CURRENT, inpPeriod, 1, inpDeviation, PRICE_CLOSE);

//--- if the handle is not created
   if(handle==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iBands indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());

      Alert("Failed to create handler...");
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }

//set entry buffers as series
   ArraySetAsSeries(upperBuffer,true);
   ArraySetAsSeries(baseBuffer,true);
   ArraySetAsSeries(lowerBuffer,true);


   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

// release indicator handle
   if(handle != INVALID_HANDLE)
      IndicatorRelease(handle);
  }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

//check if current tick is above a bar open tick
   if(!IsNewBar())
     {
      return;
     }

//Get current tick
   if(!SymbolInfoTick(_Symbol, currentTick))
     {
      Print("Failed to get tick");
      return;
     }

//Get indicator values
   int values = CopyBuffer(handle, 0, 0, 1, baseBuffer) + CopyBuffer(handle, 1, 0, 1, upperBuffer) + CopyBuffer(handle, 2, 0, 1, lowerBuffer);
   if(values != 3)
     {
      Alert("Failed to get indicator values");
      return;
     }

//Count open positons
   int cntBuy, cntSell;
   if(!CountOpenPositions(cntBuy, cntSell))
      return;

//check for lower band cross to open a buy position
   if(cntBuy == 0 && currentTick.ask <= lowerBuffer[0] && openBuyTime != iTime(_Symbol, PERIOD_CURRENT, 0))
     {
      openBuyTime = iTime(_Symbol, PERIOD_CURRENT, 0);
      double sl = currentTick.bid - inpStopLoss * _Point;
      double tp = inpTakeProfit == 0 ? 0 : currentTick.bid + inpTakeProfit * _Point;
      if(!NormalizePrice(sl, sl))
        {
         return;
        }
      if(!NormalizePrice(tp, tp))
        {
         return;
        }

      //open buy position
      trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, inpLotSize, currentTick.ask, sl, tp, "Bollinger Band EA");
     }


//check for upper band cross to open a sell position
   if(cntSell == 0 && currentTick.bid <= upperBuffer[0] && openSellTime != iTime(_Symbol, PERIOD_CURRENT, 0))
     {
      openSellTime = iTime(_Symbol, PERIOD_CURRENT, 0);
      double sl = currentTick.ask + inpStopLoss * _Point;
      double tp = inpTakeProfit == 0 ? 0 : currentTick.ask - inpTakeProfit * _Point;
      if(!NormalizePrice(sl, sl))
        {
         return;
        }
      if(!NormalizePrice(tp, tp))
        {
         return;
        }

      //open buy position
      trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, inpLotSize, currentTick.bid, sl, tp, "Bollinger Band EA");
     }

//check for close at cross with base band
   if(!CountOpenPositions(cntBuy, cntSell))
      return;

   if(cntBuy > 0 && currentTick.bid >= baseBuffer[0])
     {
      ClosePositions(1);
     }

   if(cntSell > 0 && currentTick.ask <= baseBuffer[0])
     {
      ClosePositions(2);
     }
  }

//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
//check if we have a bar open tick
bool IsNewBar()
  {
   static datetime previousTime = 0;
   datetime currentTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(previousTime != currentTime)
     {
      previousTime = currentTime;
      return true;
     }

   return false;
  }

//count open positions
bool CountOpenPositions(int &cntBuy, int &cntSell)
  {
   cntBuy = 0;
   cntSell = 0;
   int total = PositionsTotal();

   for(int i=total-1; i<0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      long magic;

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

      if(magic == inpMagicNumber)
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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool NormalizePrice(double price, double &normalizedPrice)
  {
   double tickSize = 0;
   if(!SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE, tickSize))
     {
      Print("Failed to get tick size");
      return false;
     }

   normalizedPrice = NormalizeDouble(MathRound(price/tickSize)*tickSize, _Digits);


   return true;
  }

//close open positions
bool ClosePositions(int all_buy_sell)
  {
   int total = PositionsTotal();

   for(int i=total-1; i<0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      long magic;

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

      if(magic == inpMagicNumber)
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
//+------------------------------------------------------------------+
