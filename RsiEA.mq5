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
//| Global variables                                                 |
//+------------------------------------------------------------------+
int handle;
double buffer[];
MqlTick currentTick;
CTrade trade;
datetime openTimeBuy = 0;
datetime openTimeSell = 0;

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
static input long InpMagicNumber = 55555;             //magic number
static input double InpLotSize = 0.01;                //lot size
input int InpRSIPeriod = 21;                          //rsi period
input int InpRSILevel = 70;                           //rsi level (upper)
input int InpStopLoss = 200;                          // stop loss in points (0=off)
input int InpTakeProfit = 100;                        // take profit in points (0=off)
input bool InpCloseSignal = false;                    //close trades opposite signal


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
     
   if(InpRSIPeriod <= 1)
     {
      Alert("InpRSIPeriod <= 1");
      return INIT_PARAMETERS_INCORRECT;
     }
     
   if(InpRSILevel >= 100 || InpRSILevel <= 50)
     {
      Alert("InpRSILevel >= 100 || InpRSILevel <= 50");
      return INIT_PARAMETERS_INCORRECT;
     }
     
   if(InpStopLoss < 0)
     {
      Alert("InpStopLoss < 0");
      return INIT_PARAMETERS_INCORRECT;
     }
     
   if(InpTakeProfit < 0)
     {
      Alert("InpTakeProfit < 0");
      return INIT_PARAMETERS_INCORRECT;
     }
     
   //set magic number to trade object
   trade.SetExpertMagicNumber(InpMagicNumber);
   
   //create rsi handle
   handle = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_CLOSE);
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
   ArraySetAsSeries(buffer,true);
     
     
   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //release indicator handle
   if(handle != INVALID_HANDLE)
      IndicatorRelease(handle);
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
     
   //get rsi values 
   int values = CopyBuffer(handle, 0, 0, 2, buffer);
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
      
    //check for buy position
    if(cntBuy == 0 && buffer[1] >= (100 - InpRSILevel) && buffer[0] < (100 - InpRSILevel) && openTimeBuy != iTime(_Symbol, PERIOD_CURRENT,0))
      {
      openTimeBuy = iTime(_Symbol, PERIOD_CURRENT,0);
      
       if(InpCloseSignal)
         {
          if(!ClosePositions(2))
            {
             return;
            }
         }
         
       double sl = InpStopLoss == 0 ? 0 : currentTick.bid - InpStopLoss * _Point;
       double tp = InpTakeProfit == 0 ? 0 : currentTick.bid + InpTakeProfit * _Point;
       if(!NormalizePrice(sl)) {return;}
       if(!NormalizePrice(tp)) {return;}
       
       trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLotSize, currentTick.ask, sl, tp, "RSI EA");
      }
      
    //check for sell position
    if(cntSell == 0 && buffer[1] <= InpRSILevel && buffer[0] > InpRSILevel && openTimeSell != iTime(_Symbol, PERIOD_CURRENT,0))
      {
      openTimeSell = iTime(_Symbol, PERIOD_CURRENT,0);
      
       if(InpCloseSignal)
         {
          if(!ClosePositions(1))
            {
             return;
            }
         }
         
       double sl = InpStopLoss == 0 ? 0 : currentTick.ask + InpStopLoss * _Point;
       double tp = InpTakeProfit == 0 ? 0 : currentTick.ask - InpTakeProfit * _Point;
       if(!NormalizePrice(sl)) {return;}
       if(!NormalizePrice(tp)) {return;}
       
       trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, InpLotSize, currentTick.bid, sl, tp, "RSI EA");
      }
  }
  
//+------------------------------------------------------------------+
//| Custom functions                                                 |
//+------------------------------------------------------------------+
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