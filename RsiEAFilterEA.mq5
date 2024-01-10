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
int handleRSI;
int handleMA;
double bufferRSI[];
double bufferMA[];
MqlTick currentTick;
CTrade trade;
datetime openTimeBuy = 0;  //Delete
datetime openTimeSell = 0; //Delete

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
static input long InpMagicNumber = 55555;             //magic number
static input double InpLotSize = 0.01;                //lot size
input int InpRSIPeriod = 21;                          //rsi period
input int InpRSILevel = 70;                           //rsi level (upper)
input int InpMAPeriod =  21;                          //moving average
input ENUM_TIMEFRAMES InpMATimefame = PERIOD_H1;      //ma timeframe
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
     
   if(InpMAPeriod <= 1)
     {
      Alert("MS period <= 1");
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
   
   //create indicator handles
   handleRSI = iRSI(_Symbol, PERIOD_CURRENT, InpRSIPeriod, PRICE_OPEN);
   //--- if the handleRSI is not created
   if(handleRSI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handleRSI of the indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());

      Print("Failed to create handler...");
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
     
   //create indicator handles
   handleMA = iMA(_Symbol, InpMATimefame, InpMAPeriod, 0, MODE_SMA, PRICE_OPEN);
   //--- if the handleRSI is not created
   if(handleMA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create MA of the indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());

      Print("Failed to create handler...");
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
     
   //set entry buffers as series
   ArraySetAsSeries(bufferRSI,true);
   ArraySetAsSeries(bufferMA,true);
     
     
   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //release indicator handles
   if(handleRSI != INVALID_HANDLE)
      IndicatorRelease(handleRSI);
   if(handleRSI != INVALID_HANDLE)
      IndicatorRelease(handleMA);
  }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   //check if current tick is a new bar open tick
   if(!IsNewBar())
     {
      return;
     }
   
   //get current tick
   if(!SymbolInfoTick(_Symbol, currentTick)) 
     {
      Print("Failed to get current tick");
      return;
     }
     
   //get rsi values 
   int values = CopyBuffer(handleRSI, 0, 0, 2, bufferRSI);
   if(values != 2)
     {
      Print("Failed to get rsi indicator values");
      return;
     }
     
   //get MA values 
   values = CopyBuffer(handleMA, 0, 0, 1, bufferMA);
   if(values != 1)
     {
      Print("Failed to get ma indicator values");
      return;
     }
     
    //count open positions
    int cntBuy, cntSell;
    if(!CountOpenPositions(cntBuy, cntSell))
      {
       return;
      }
      
    //check for buy position
    if(cntBuy == 0 && bufferRSI[1] >= (100 - InpRSILevel) && bufferRSI[0] < (100 - InpRSILevel) && currentTick.ask > bufferMA[0])
      {
      
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
       
       trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLotSize, currentTick.ask, sl, tp, "RSI MA Filter EA");
      }
      
    //check for sell position
    if(cntSell == 0 && bufferRSI[1] <= InpRSILevel && bufferRSI[0] > InpRSILevel && currentTick.bid < bufferMA[0])
      {
      
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