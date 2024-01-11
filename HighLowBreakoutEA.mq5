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
double high = 0;
double low = 0;
MqlTick currentTick;
CTrade trade;

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
static input long InpMagicNumber = 55555;                //magic number
static input double InpLots = 0.01;                      //lots
input int InpBars = 20;                                  //bars for high/low
input int InpStopLoss = 200;                             //stop loss in points (0=off)
input int InpTakeProfit = 0;                             //take profit in points (0=off)
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

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

   
  }
//+------------------------------------------------------------------+
