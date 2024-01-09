//+------------------------------------------------------------------+
//|                                              MovingAverageEA.mq5 |
//|                                                      myk-francis |
//|                 https://myk-francis.github.io/michael-portfolio/ |
//+------------------------------------------------------------------+
#property copyright "myk-francis"
#property link      "https://myk-francis.github.io/michael-portfolio/"
#property version   "1.00"
#include <Trade/Trade.mqh>
//+------------------------------------------------------------------+
//| Variables                                                        |
//+------------------------------------------------------------------+
input int fastPeriod=14; //fast period
input int slowPeriod=21;  //slow period
input int stopLoss = 200;  // loss in points
input int takeProfit = 400;  // take profit in points
bool isTradeOpen = false;
CTrade trade;

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
int fastHandle;
int slowHandle;
double fastBuffer[];
double slowBuffer[];
datetime openTimeBuy = 0;
datetime openTimeSell = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//check user input
   if(fastPeriod <= 0)
     {
      Alert("Fast period <= 0");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(slowPeriod <= 0)
     {
      Alert("Slow period <= 0");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(fastPeriod >= slowPeriod)
     {
      Alert("Fast period >= Slow period");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(stopLoss <= 0)
     {
      Alert("Stop loss <= 0");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(takeProfit <= 0)
     {
      Alert("Take profit <= 0");
      return INIT_PARAMETERS_INCORRECT;
     }

//create handles
   fastHandle = iMA(_Symbol, PERIOD_CURRENT, fastPeriod, 0, MODE_SMA, PRICE_CLOSE);
   if(fastHandle == INVALID_HANDLE)
     {
      Alert("Failed to create fast handle!");
     }

   slowHandle = iMA(_Symbol, PERIOD_CURRENT, slowPeriod, 0, MODE_SMA, PRICE_CLOSE);
   if(slowHandle == INVALID_HANDLE)
     {
      Alert("Failed to create slow handle!");
     }

   ArraySetAsSeries(fastBuffer, true);
   ArraySetAsSeries(slowBuffer, true);


   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(fastHandle != INVALID_HANDLE)
      IndicatorRelease(fastHandle);
   if(slowHandle != INVALID_HANDLE)
      IndicatorRelease(slowHandle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int result = CopyBuffer(fastHandle, 0, 0, 2, fastBuffer);
   if(result != 2)
     {
      Print("Not enough data for fast moving average!");
      return;
     }

   result = CopyBuffer(slowHandle, 0, 0, 2, slowBuffer);
   if(result != 2)
     {
      Print("Not enough data for slow moving average!");
      return;
     }


   Comment("fast[0]:", fastBuffer[0], "\n",
           "fast[1]:", fastBuffer[1], "\n",
           "slow[0]:", slowBuffer[0], "\n",
           "slow[1]:", slowBuffer[1]);

//check for buy signal
   if(fastBuffer[1] >= slowBuffer[1] && fastBuffer[0] < slowBuffer[0] && openTimeBuy != iTime(_Symbol, PERIOD_CURRENT,0))
     {

      openTimeBuy = iTime(_Symbol, PERIOD_CURRENT,0);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl = ask - stopLoss * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double tp = ask + takeProfit * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      trade.PositionOpen(_Symbol, ORDER_TYPE_BUY,1.0, ask, sl, tp, "MovingAverageEA");
     }

//check for sell signal
   if(fastBuffer[1] <= slowBuffer[1] && fastBuffer[0] > slowBuffer[0] && openTimeSell != iTime(_Symbol, PERIOD_CURRENT,0))
     {

      openTimeSell = iTime(_Symbol, PERIOD_CURRENT,0);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      
      double sl = bid + stopLoss * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double tp = bid - takeProfit * SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      trade.PositionOpen(_Symbol, ORDER_TYPE_SELL,1.0, bid, sl, tp, "MovingAverageEA");
     }
  }

//+------------------------------------------------------------------+
