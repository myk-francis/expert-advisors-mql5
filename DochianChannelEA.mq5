//+------------------------------------------------------------------+
//|                                                        RsiEA.mq5 |
//|                                                      myk-francis |
//|                 https://myk-francis.github.io/michael-portfolio/ |
//+------------------------------------------------------------------+
#property copyright "myk-francis"
#property link      "https://myk-francis.github.io/michael-portfolio/"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#define INDICATOR_NAME "MyDonchianChannel"
//+------------------------------------------------------------------+
//| Global variables                                                 |
//+------------------------------------------------------------------+
int handle;

double upperBuffer[];
double lowerBuffer[];
MqlTick currentTick;
CTrade trade;
datetime openTimeBuy = 0;
datetime openTimeSell = 0;

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "===== General ====";
static input long          InpMagicNumber = 55555;                      //magic number
static input double        InpLotSize = 0.01;                           //lot size
enum SL_TP_MODE_ENUM {        
   SL_TP_MODE_PCT,                                                      //sl and tp in %
   SL_TP_MODE_POINTS                                                    //sl and tp in points
};
input SL_TP_MODE_ENUM      InpSLTPMode = SL_TP_MODE_PCT;                //sl and tp mode
input int                  InpStopLoss = 200;                           // stop loss in %/points (0=off)
input int                  InpTakeProfit = 100;                         // take profit in %/points (0=off)
input bool                 InpCloseSignal = false;                      //close trades opposite signal
input int                  InpSizeFilter = 0;                           //Input size filter in points (0=off)

input group "===== Donchian Channel ====";
input int                  InpPeriod = 20;                              //period
input int                  InpOffset = 0;                               //offset in % of the channel (0 -> 49)
input color                InpColor = clrBlue;                          //color


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //check user inputs
   if(InpMagicNumber <= 0)
     {
      Alert("Magic number <= 0");
      return INIT_PARAMETERS_INCORRECT;
     }
     
   if(InpLotSize <= 0 || InpLotSize > 10)
     {
      Alert("InpLotSize <= 0 or InpLotSize > 10");
      return INIT_PARAMETERS_INCORRECT;
     }
     
   if(InpStopLoss < 0)
     {
      Alert("InpStopLoss < 0");
      return INIT_PARAMETERS_INCORRECT;
     }
     
   if(InpSizeFilter < 0)
     {
      Alert("InpSizeFilter < 0");
      return INIT_PARAMETERS_INCORRECT;
     }
     
   if(InpTakeProfit < 0)
     {
      Alert("InpTakeProfit < 0");
      return INIT_PARAMETERS_INCORRECT;
     }
     
   if(InpStopLoss == 0 && !InpCloseSignal)
     {
      Alert("No stop loss and no close signal");
      return INIT_PARAMETERS_INCORRECT;
     }
     
   if(InpPeriod <= 1)
     {
      Alert("Donchian period <= 1");
      return INIT_PARAMETERS_INCORRECT;
     }
     
   if(InpOffset < 0 || InpOffset >= 50)
     {
      Alert("Offset should be between 0 -> 49");
      return INIT_PARAMETERS_INCORRECT;
     }
     
   //set magic number to trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   
   //create indicator handle
   handle = iCustom(_Symbol, PERIOD_CURRENT, INDICATOR_NAME, InpPeriod, InpOffset, InpColor );
   //--- if the handle is not created
   if(handle==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());

      Print("Failed to create handler...");
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
     
   //set entry buffers as series
   ArraySetAsSeries(upperBuffer,true);
   ArraySetAsSeries(lowerBuffer,true);
   
   //draw indicator on chart
   ChartIndicatorDelete(NULL, 0, "Donchian(" + IntegerToString(InpPeriod) +")");
   ChartIndicatorAdd(NULL, 0, handle);
     
     
   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //release indicator handle
   if(handle != INVALID_HANDLE)
   {  
      ChartIndicatorDelete(NULL, 0, "Donchian(" + IntegerToString(InpPeriod) +")");
      IndicatorRelease(handle);
   }
  }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   //check if current tick is a new bar open tick
   if(!IsNewBar()) {return;}
  
   //get current tick
   if(!SymbolInfoTick(_Symbol, currentTick)) 
     {
      Print("Failed to get current tick");
      return;
     }
     
   //get donchian channel values 
   int values = CopyBuffer(handle, 0, 0, 1, upperBuffer) + CopyBuffer(handle, 1, 0, 1, lowerBuffer);
   if(values != 2)
     {
      Print("Failed to get indicator values");
      return;
     }
     
    //count open positions
    int cntBuy, cntSell;
    if(!CountOpenPositions(cntBuy, cntSell))
      {
       return;
      }
      
    //check size filter
    if(InpSizeFilter > 0 && (upperBuffer[0] - lowerBuffer[0]) < InpSizeFilter * _Point)
      {
       return;
      }
      
    //check for buy position
    if(cntBuy == 0 && currentTick.ask <= lowerBuffer[0] && openTimeBuy != iTime(_Symbol, PERIOD_CURRENT,0))
      {
      openTimeBuy = iTime(_Symbol, PERIOD_CURRENT,0);
      
       if(InpCloseSignal)
         {
          if(!ClosePositions(2))
            {
             return;
            }
         }
         
       double sl = 0;
       double tp = 0;
       if(InpSLTPMode == SL_TP_MODE_PCT)
         {
          sl = InpStopLoss == 0 ? 0 : currentTick.bid - (upperBuffer[0] - lowerBuffer[0]) * InpStopLoss * 0.01;
          tp = InpTakeProfit == 0 ? 0 : currentTick.bid + (upperBuffer[0] - lowerBuffer[0]) * InpTakeProfit * 0.01;
         }
       else
         {
          sl = InpStopLoss == 0 ? 0 : currentTick.bid - InpStopLoss * _Point;
          tp = InpTakeProfit == 0 ? 0 : currentTick.bid + InpTakeProfit * _Point;
         }
         
       
       if(!NormalizePrice(sl)) {return;}
       if(!NormalizePrice(tp)) {return;}
       
       trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLotSize, currentTick.ask, sl, tp, "Donchian channel EA");
      }
      
    //check for sell position
    if(cntSell == 0 && currentTick.bid >= upperBuffer[0] && openTimeSell != iTime(_Symbol, PERIOD_CURRENT,0))
      {
      openTimeSell = iTime(_Symbol, PERIOD_CURRENT,0);
      
       if(InpCloseSignal)
         {
          if(!ClosePositions(1))
            {
             return;
            }
         }
         
       double sl = 0;
       double tp = 0;
       if(InpSLTPMode == SL_TP_MODE_PCT)
         {
          sl = InpStopLoss == 0 ? 0 : currentTick.ask + (upperBuffer[0] - lowerBuffer[0]) * InpStopLoss * 0.01;
          tp = InpTakeProfit == 0 ? 0 : currentTick.ask - (upperBuffer[0] - lowerBuffer[0]) * InpTakeProfit * 0.01;
         }
       else
         {
          sl = InpStopLoss == 0 ? 0 : currentTick.ask + InpStopLoss * _Point;
          tp = InpTakeProfit == 0 ? 0 : currentTick.ask - InpTakeProfit * _Point;
         }
       
       if(!NormalizePrice(sl)) {return;}
       if(!NormalizePrice(tp)) {return;}
       
       trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, InpLotSize, currentTick.bid, sl, tp, "Donchian channel EA");
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