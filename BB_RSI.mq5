//+------------------------------------------------------------------+
//|                                                       BB_RSI.mq5 |
//|                                                      myk-francis |
//|                 https://myk-francis.github.io/michael-portfolio/ |
//+------------------------------------------------------------------+
#property copyright "myk-francis"
#property link      "https://myk-francis.github.io/michael-portfolio/"
#property version   "1.00"
#property script_show_inputs
#include <CustomFunctions01.mqh>
#include <Trade/Trade.mqh>

static input long magicNB = 55555;
input int bbPeriod = 50;

input double bandStdEntry = 2;
input int bandStdProfitExit = 1;
input int bandStdLossExit = 6;
int rsiPeriod = 14;
input double riskPerTrade = 0.02;
input int rsiLowerLevel = 40;
input int rsiUpperLevel = 60;

//Entry level bb
int handle;
double upper[],lower[],middle[];

//Profit Exit level bb
int handleProfitExt;
double upperProfitExt[],lowerProfitExt[],middleProfitExt[];

//Loss Exit level bb
int handleLossExt;
double upperLossExt[],lowerLossExt[],middleLossExt[];

int handleRSI;
double rsi_buffer[];

int openOrderID;

MqlTick currentTick;
CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("");
   Print("Starting Strategy BB_RSI...");

   trade.SetExpertMagicNumber(magicNB);

//--- create entry handle of the indicator iBands
   handle = iBands(Symbol(), Period(), bbPeriod, 0, bandStdEntry, PRICE_CLOSE);

//--- create profit handle of the indicator iBands
   handleProfitExt = iBands(Symbol(), Period(), bbPeriod, 0, bandStdProfitExit, PRICE_CLOSE);

//--- create loss handle of the indicator iBands
   handleLossExt = iBands(Symbol(), Period(), bbPeriod, 0, bandStdLossExit, PRICE_CLOSE);

//--- create handle of the indicator RSI
   handleRSI = iRSI(NULL, 0, rsiPeriod, PRICE_CLOSE);

//--- if the handle is not created
   if(handle==INVALID_HANDLE || handleProfitExt==INVALID_HANDLE || handleLossExt==INVALID_HANDLE || handleRSI ==INVALID_HANDLE)
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
   ArraySetAsSeries(upper,true);
   ArraySetAsSeries(lower,true);
   ArraySetAsSeries(middle,true);

//set profit exit buffers as series
   ArraySetAsSeries(upperProfitExt,true);
   ArraySetAsSeries(lowerProfitExt,true);
   ArraySetAsSeries(middleProfitExt,true);

//set loss exit buffers as series
   ArraySetAsSeries(upperLossExt,true);
   ArraySetAsSeries(lowerLossExt,true);
   ArraySetAsSeries(middleLossExt,true);

//set RSI buffers as series
   ArraySetAsSeries(rsi_buffer,true);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("Stopping Strategy BB_RSI");

   Comment("");

   if(handle != INVALID_HANDLE)
      IndicatorRelease(handle);
   if(handleProfitExt != INVALID_HANDLE)
      IndicatorRelease(handleProfitExt);
   if(handleLossExt != INVALID_HANDLE)
      IndicatorRelease(handleLossExt);
   if(handleRSI != INVALID_HANDLE)
      IndicatorRelease(handleRSI);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//get current tick
   if(!SymbolInfoTick(Symbol(), currentTick))
     {
      Print("Failed to get current tick!");
      return;
     }

//double askPrice = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   double askPrice = currentTick.ask;
   double   open  = iOpen(Symbol(),Period(), 0);

   int values = CopyBuffer(handle, 0, 0, 1, middle) + CopyBuffer(handle, 1, 0, 1, upper) + CopyBuffer(handle, 2, 0, 1, lower);
   if(values != 3)
     {
      Alert("Failed to get indicator values");
      return;
     }

   double bbLowerEntry = lower[0];
   double bbUpperEntry = upper[0];
   double bbMid = middle[0];

   int valuesProfitExit = CopyBuffer(handleProfitExt, 0, 0, 1, middleProfitExt) + CopyBuffer(handleProfitExt, 1, 0, 1, upperProfitExt) + CopyBuffer(handleProfitExt, 2, 0, 1, lowerProfitExt);
   if(valuesProfitExit != 3)
     {
      Alert("Failed to get indicator values");
      return;
     }

   double bbLowerProfitExit = lowerProfitExt[0];
   double bbUpperProfitExit = upperProfitExt[0];

   int valuesLossExit = CopyBuffer(handleLossExt, 0, 0, 1, middleLossExt) + CopyBuffer(handleLossExt, 1, 0, 1, upperLossExt) + CopyBuffer(handleLossExt, 2, 0, 1, lowerLossExt);
   if(valuesLossExit != 3)
     {
      Alert("Failed to get indicator values");
      return;
     }

   double bbLowerLossExit = lowerLossExt[0];
   double bbUpperLossExit = upperLossExt[0];

   int rsiValue = CopyBuffer(handleRSI,0,0,1,rsi_buffer);
   if(valuesLossExit != 1)
     {
      Alert("Failed to get RSI indicator values");
      return;
     }

   int cntBuy, cntSell;
   if(!CountOpenPositions(cntBuy, cntSell, magicNB))
      return;

   if(cntBuy==0 && cntSell==0)
     {
      if(askPrice < bbLowerEntry && askPrice > open && rsi_buffer[0] < rsiLowerLevel)
        {
         Print("Price is below bbLower and rsiValue is lower than " + DoubleToString(rsi_buffer[0], 2) + " Sending Buy Order!");

         double stopLossPrice = NormalizeDouble(bbLowerLossExit, _Digits);
         double takeProfitPrice = NormalizeDouble(bbUpperProfitExit, _Digits);

         Print("Entry Price: " + askPrice);
         Print("Stop Loss Price: " + stopLossPrice);
         Print("Take Profit Price: " + takeProfitPrice);

         double lotSize = OptimalLotSize(riskPerTrade, askPrice, stopLossPrice);

         trade.PositionOpen(Symbol(), ORDER_TYPE_BUY_LIMIT, lotSize, askPrice, stopLossPrice, takeProfitPrice, "BB_RSI EA");

        }
      else
         if(currentTick.bid < bbUpperEntry && open < bbUpperEntry && rsi_buffer[0] > rsiUpperLevel) //shorting
           {
            Print("Price is above bbUpper and rsiValue is above " + DoubleToString(rsi_buffer[0], 2) + " Sending Sell/Short Order!");

            double stopLossPrice = NormalizeDouble(bbUpperLossExit, _Digits);
            double takeProfitPrice = NormalizeDouble(bbLowerProfitExit, _Digits);

            Print("Entry Price: " + currentTick.bid);
            Print("Stop Loss Price: " + stopLossPrice);
            Print("Take Profit Price: " + takeProfitPrice);

            double lotSize = OptimalLotSize(riskPerTrade, currentTick.bid, stopLossPrice);

            trade.PositionOpen(Symbol(), ORDER_TYPE_SELL_LIMIT, lotSize, currentTick.bid, stopLossPrice, takeProfitPrice, "BB_RSI EA");
           }
     }
   else // if we already have a position open
     {
      double optimalTakeProfit;

      if(cntBuy > 1)
        {
         optimalTakeProfit = NormalizeDouble(bbUpperProfitExit, _Digits);
        }
      else
         if(cntSell > 1)
           {
            optimalTakeProfit = NormalizeDouble(bbLowerProfitExit, _Digits);
           }
           
      double TP = GetOrderTakeProfit(magicNB);
      double TPdistance = MathAbs(TP - optimalTakeProfit);
      
      if(TP != optimalTakeProfit && TPdistance > 0.0001)
        {
         //Modify order
         bool result = ModifyOrderForTicket(optimalTakeProfit, magicNB);
         if(result == true)
           {
            Print("Order Modified Successfully!");
           }
           else
             {
              Print("Order Modified Failed!");
             }
        }
     }
  }
  
  
  bool ModifyOrderForTicket(double newTakeProfit, long magic_number)
  {
   int total = PositionsTotal();
   bool result = false;

   for(int i=total-1; i<0; i--)
     {
      long ticket = PositionGetTicket(i);
      long magic;

      if(ticket <= 0)
        {
         Print("Failed to get open ticket!");
         result = false; 
         
        }

      if(!PositionSelectByTicket(ticket))
        {
         Print("Failed to select position!");
         result = false; 
         
        }

      if(!PositionGetInteger(POSITION_MAGIC, magic))
        {
         Print("Failed to get position magic number!");
         result = false; 
        }

      if(magic == magic_number)
        {
         double price = PositionGetDouble(POSITION_PRICE_CURRENT);
         double orderStopLoss = PositionGetDouble(POSITION_SL);
         trade.OrderModify(ticket, price, orderStopLoss, newTakeProfit, ORDER_TIME_GTC, NULL);
         
         result = true; 
         
        }
     }
     
     return result;
  }
//+------------------------------------------------------------------+
