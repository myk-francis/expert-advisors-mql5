//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+

#property copyright "myk-francis"
#property link      "https://myk-francis.github.io/michael-portfolio/"
#property version   "1.00"
#include <Trade/Trade.mqh>
//+------------------------------------------------------------------+
//| Variables                                                        |
//+------------------------------------------------------------------+
input int openHour=10;
input int closeHour=10;
bool isTradeOpen = false;
CTrade trade;



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //check for user input
   if(openHour == closeHour)
     {
      Alert("OpenHour and CloseHour must be different!!!");
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//get current time
   MqlDateTime timeNow;
   TimeToStruct(TimeCurrent(), timeNow);

//check if trade is open
   if(openHour == timeNow.hour && !isTradeOpen)
     {
      //position open
      trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, 1, SymbolInfoDouble(_Symbol, SYMBOL_ASK), 0, 0, "FirstEA");
      isTradeOpen = true;
     }
     
 //check for trade close
   if(closeHour == timeNow.hour && isTradeOpen)
     {
      //position open
      trade.PositionClose(_Symbol);
      isTradeOpen = false;
     }

  }
//+------------------------------------------------------------------+
