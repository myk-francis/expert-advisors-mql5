//+------------------------------------------------------------------+
//|                                                  TimeRangeEA.mq5 |
//|                                                      myk-francis |
//|                 https://myk-francis.github.io/michael-portfolio/ |
//+------------------------------------------------------------------+
#property copyright "myk-francis"
#property link      "https://myk-francis.github.io/michael-portfolio/"
#property version   "1.00"
#include <Trade/Trade.mqh>
#include <GraphicalPanel.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input int rangeStart = 600;      //range start time in minutes after midnight
input int rangeDuration = 120;   //range duration in minutes
input int rangeClose = 1200;     //range close time in minutes (-1=off)
input double lotSize = 0.01;     //lot size
input long magicNB = 55555;      //magic number
input int stopLoss = 150;        //stop loss in % of the range (0=off)
input int takeProfit = 200;      //take profit in % of the range (0=off)



//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
struct RANGE_STRUCT
  {
   datetime          start_time;          //start of the range
   datetime          end_time;            //end  of the range
   datetime          close_time;          //clost time
   double            high;                // high of the range
   double            low;                 //low of the range
   bool              f_entry;             //flag if we are inside the range
   bool              f_high_breakout;     //flag if a high breakout occured
   bool              f_low_breakout;      //flag if a low breakout occured

                     RANGE_STRUCT() : start_time(0), end_time(0), close_time(0), high(0), low(999999), f_entry(false), f_high_breakout(false), f_low_breakout(false) {};

  };

RANGE_STRUCT range;
MqlTick prevTick, lastTick;
CTrade trade;
CGraphicalPanel panel;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

//check user input
   if(rangeStart < 0 || rangeStart >= 1440)
     {
      Alert("Range start < 0 or >= 1440");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(rangeDuration < 0 || rangeDuration >= 1440)
     {
      Alert("Range duration <= 0 or >= 1440");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(rangeClose >= 1440 || (rangeStart + rangeDuration) % 1440 == rangeClose)
     {
      Alert("Close time < 0 or >= 1440 or end time == close time");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(magicNB <= 0)
     {
      Alert("magicNB <= 0");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(lotSize <= 0 || lotSize > 1)
     {
      Alert("lotSize <= 0 || lotSize > 1");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(stopLoss <= 0 || lotSize > 1000)
     {
      Alert("Stop loss < 0 or stop loss > 1000");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(takeProfit <= 0 || takeProfit > 1000)
     {
      Alert("Take profit <= 0 || Take profit > 1000");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(rangeClose < 0 && stopLoss == 0)
     {
      Alert("Close time and stop loss is off");
      return INIT_PARAMETERS_INCORRECT;
     }

//set magic number
   trade.SetExpertMagicNumber(magicNB);

// calculate new range if parameters change
   if(_UninitReason == REASON_PARAMETERS) // no open position
     {
      CalculateRange();
     }

//DrawObjects
   DrawObjects();

//create panel
   panel.OnInit();

   return(INIT_SUCCEEDED);
  }


//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(NULL, "range");
  }


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//Get current tick
   prevTick = lastTick;
   SymbolInfoTick(_Symbol, lastTick);

//range calculation
   if(lastTick.time >= range.start_time && lastTick.time < range.end_time)
     {
      //set flag
      range.f_entry = true;
      //new high
      if(lastTick.ask > range.high)
        {
         range.high = lastTick.ask;
         DrawObjects();
        }
      //new low
      if(lastTick.bid < range.low)
        {
         range.low = lastTick.bid;
         DrawObjects();
        }
     }

//close positions
   if(rangeClose >= 0 && lastTick.time >= range.close_time)
     {
      if(!ClosePositions())
        {
         return;
        }
     }

//Calculate new range if...
   if(((rangeClose >= 0 && lastTick.time > range.close_time)                               //close time reached
       || (range.f_high_breakout && range.f_low_breakout)                               //both breakout flags are true
       || (range.end_time == 0)                                                         //range not calculated
       || (range.end_time != 0 && lastTick.time > range.end_time && !range.f_entry))    //there was a range calculated but no tick inside
      && CountOpenPositions() == 0)
     {
      CalculateRange();
     }

//check for breakouts
   CheckBreakouts();

  }

//calculate a new range
void CalculateRange()
  {
//reset range variables
   range.start_time = 0;
   range.end_time = 0;
   range.close_time = 0;
   range.high = 0.0;
   range.low = 99999;
   range.f_entry = false;
   range.f_high_breakout = false;
   range.f_low_breakout = false;

//calculate range start time
   int time_cycle = 86400; // one day
   range.start_time = (lastTick.time - (lastTick.time % time_cycle)) + rangeStart * 60;

   for(int i=0; i<8; i++)
     {
      MqlDateTime tmp;
      TimeToStruct(range.start_time, tmp);
      int dow = tmp.day_of_week;
      if(lastTick.time >= range.start_time || dow == 6 || dow == 0)
        {
         range.start_time += time_cycle;
        }
     }

//calculate range end time
   range.end_time = range.start_time + rangeDuration * 60;

   for(int i=0; i<2; i++)
     {
      MqlDateTime tmp;
      TimeToStruct(range.start_time, tmp);
      int dow = tmp.day_of_week;
      if(dow == 6 || dow == 0)
        {
         range.end_time += time_cycle;
        }
     }

//calculate range close
   if(rangeClose >= 0)
     {
      range.close_time = (range.end_time - (range.end_time % time_cycle)) + rangeClose * 60;

      for(int i=0; i<3; i++)
        {
         MqlDateTime tmp;
         TimeToStruct(range.start_time, tmp);
         int dow = tmp.day_of_week;
         if(range.close_time <= range.end_time || dow == 6 || dow == 0)
           {
            range.close_time += time_cycle;
           }
        }
     }

//draw objects
   DrawObjects();
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountOpenPositions()
  {
   int counter = 0;
   int total = PositionsTotal();

   for(int i=total-1; i<0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      long magic_number;

      if(ticket <= 0)
        {
         Print("Failed to get open ticket!");
         return -1;
        }

      if(!PositionSelectByTicket(ticket))
        {
         Print("Failed to select position!");
         return -1;
        }

      if(!PositionGetInteger(POSITION_MAGIC, magic_number))
        {
         Print("Failed to get position magic number!");
         return -1;
        }

      if(magic_number == magicNB)
        {
         counter++;
        }
     }

   return counter;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckBreakouts()
  {
//check if we are after the range end
   if(lastTick.time >= range.end_time && range.end_time > 0 && range.f_entry)
     {

      //check for high breakout
      if(!range.f_high_breakout && lastTick.ask >= range.high)
        {
         range.f_high_breakout = true;

         //calculate stop loss and take profit
         double sl = stopLoss == 0 ? 0 : NormalizeDouble(lastTick.bid - ((range.high - range.low) * stopLoss * 0.01), _Digits);
         double tp = takeProfit == 0 ? 0 : NormalizeDouble(lastTick.bid + ((range.high - range.low) * takeProfit * 0.01), _Digits);

         //open buy position
         trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, lotSize, lastTick.ask, sl, tp, "Time range EA");
        }

      //check for low breakout
      if(!range.f_low_breakout && lastTick.bid >= range.low)
        {
         range.f_low_breakout = true;

         //calculate stop loss and take profit
         double sl = stopLoss == 0 ? 0 : NormalizeDouble(lastTick.ask + ((range.high - range.low) * stopLoss * 0.01), _Digits);
         double tp = takeProfit == 0 ? 0 : NormalizeDouble(lastTick.ask - ((range.high - range.low) * takeProfit * 0.01), _Digits);

         //open sell position
         trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, lotSize, lastTick.bid, sl, tp, "Time range EA");
        }

     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ClosePositions()
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

      if(magic_number == magicNB)
        {
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
//|                                                                  |
//+------------------------------------------------------------------+
void DrawObjects()
  {
//start time
   ObjectDelete(NULL, "range start");
   if(range.start_time > 0)
     {
      ObjectCreate(NULL, "range start", OBJ_VLINE, 0, range.start_time,0);
      ObjectSetString(NULL, "range start", OBJPROP_TOOLTIP, "start of range \n" + TimeToString(range.start_time, TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL, "range start", OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(NULL, "range start", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range start", OBJPROP_BACK, true);
     }

//end time
   ObjectDelete(NULL, "range end");
   if(range.end_time > 0)
     {
      ObjectCreate(NULL, "range end", OBJ_VLINE, 0, range.end_time,0);
      ObjectSetString(NULL, "range end", OBJPROP_TOOLTIP, "end of range \n" + TimeToString(range.end_time, TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL, "range end", OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(NULL, "range end", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range end", OBJPROP_BACK, true);
     }

//close time
   ObjectDelete(NULL, "range close");
   if(range.close_time > 0)
     {
      ObjectCreate(NULL, "range close", OBJ_VLINE, 0, range.close_time,0);
      ObjectSetString(NULL, "range close", OBJPROP_TOOLTIP, "close of range \n" + TimeToString(range.close_time, TIME_DATE|TIME_MINUTES));
      ObjectSetInteger(NULL, "range close", OBJPROP_COLOR, clrRed);
      ObjectSetInteger(NULL, "range close", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range close", OBJPROP_BACK, true);
     }

//high
   ObjectsDeleteAll(NULL, "range high");
   if(range.high > 0)
     {
      ObjectCreate(NULL, "range high", OBJ_TREND, 0, range.start_time, range.high, range.end_time, range.high);
      ObjectSetString(NULL, "range high", OBJPROP_TOOLTIP, "high of range \n" + DoubleToString(range.high, _Digits));
      ObjectSetInteger(NULL, "range high", OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(NULL, "range high", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range high", OBJPROP_BACK, true);

      ObjectCreate(NULL, "range high ", OBJ_TREND, 0, range.end_time, range.high, rangeClose >= 0 ? range.close_time : INT_MAX, range.high);
      ObjectSetString(NULL, "range high ", OBJPROP_TOOLTIP, "high of range \n" + DoubleToString(range.high, _Digits));
      ObjectSetInteger(NULL, "range high ", OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(NULL, "range high ", OBJPROP_BACK, true);
      ObjectSetInteger(NULL, "range high ", OBJPROP_STYLE, STYLE_DOT);
     }

//low
   ObjectsDeleteAll(NULL, "range low");
   if(range.low < 999999)
     {
      ObjectCreate(NULL, "range low", OBJ_TREND, 0, range.start_time, range.low, range.end_time, range.low);
      ObjectSetString(NULL, "range low", OBJPROP_TOOLTIP, "low of range \n" + DoubleToString(range.low, _Digits));
      ObjectSetInteger(NULL, "range low", OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(NULL, "range low", OBJPROP_WIDTH, 2);
      ObjectSetInteger(NULL, "range low", OBJPROP_BACK, true);

      ObjectCreate(NULL, "range low ", OBJ_TREND, 0, range.end_time, range.low, rangeClose >= 0 ? range.close_time : INT_MAX, range.low);
      ObjectSetString(NULL, "range low ", OBJPROP_TOOLTIP, "low of range \n" + DoubleToString(range.low, _Digits));
      ObjectSetInteger(NULL, "range low ", OBJPROP_COLOR, clrBlue);
      ObjectSetInteger(NULL, "range low ", OBJPROP_BACK, true);
      ObjectSetInteger(NULL, "range low ", OBJPROP_STYLE, STYLE_DOT);
     }
  }
//+------------------------------------------------------------------+
