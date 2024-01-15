//+------------------------------------------------------------------+
//|                                              CandlePatternEA.mq5 |
//|                                                      myk-francis |
//|                 https://myk-francis.github.io/michael-portfolio/ |
//+------------------------------------------------------------------+
#property copyright "myk-francis"
#property link      "https://myk-francis.github.io/michael-portfolio/"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Defines                                                          |
//+------------------------------------------------------------------+
#define NR_CONDITIONS 2                                              // number of conditions

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
enum MODE {
   OPEN = 0,                                                         //open
   HIGH = 1,                                                         //high   
   LOW = 2,                                                          //low
   CLOSE = 3,                                                        //close
   RANGE = 4,                                                        //range (points)
   BODY = 5,                                                         //body (points)
   RATIO = 6,                                                        //ratio (body/range)
   VALUES = 7,                                                       //value
};

enum INDEX {
   INDEX_0 = 0,                                                      //index 0
   INDEX_1 = 1,                                                      //index 1
   INDEX_2 = 2,                                                      //index 2
   INDEX_3 = 3                                                       //index 3
};

enum COMPARE
  {
   GREATER,                                                          //greater
   LESS                                                              //less
  };


struct CONDITION{
   bool active;                                                      //condition active?
   MODE modeA;                                                       //mode A
   INDEX idxA;                                                       //index A
   COMPARE comp;                                                     //compare 
   MODE modeB;                                                       //mode B
   INDEX idxB;                                                       //index B
   double value;                                                     //value
   
   CONDITION(): active(false){};
};

CONDITION con[NR_CONDITIONS];                                       //condition array
MqlTick prevTick, lastTick;                                          //current tick of the symbol
CTrade trade;                                                        //object to open/close positons

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== General ===="
static input long       InpMagicNumber = 55555;                      //magic number
static input double     InpLots        = 0.01;                       //lots
input int               InpStopLoss    = 200;                        //stop loss in points (0=off)
input int               InpTakeProfit  = 0;                          //take profit in points (0=off)

input group "==== Condition 1 ===="
input bool InpCon1Active         = true;                            //active
input MODE InpCon1ModeA          = OPEN;                             //mode A
input INDEX InpCon1IndexA        = INDEX_1;                          //index A
input COMPARE InpCon1Compare     = GREATER;                          //compare
input MODE InpCon1ModeB          = CLOSE;                            //mode B
input INDEX InpCon1IndexB        = INDEX_1;                          //index B
input double InpCon1Value        = 0;                                //value

input group "==== Condition 2 ===="
input bool InpCon2Active         = false;                            //active
input MODE InpCon2ModeA          = OPEN;                             //mode A
input INDEX InpCon2IndexA        = INDEX_1;                          //index A
input COMPARE InpCon2Compare     = GREATER;                          //compare
input MODE InpCon2ModeB          = CLOSE;                            //mode B
input INDEX InpCon2IndexB        = INDEX_1;                          //index B
input double InpCon2Value        = 0;                                //value

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   //set inputs 
   SetInputs();
   
   //check inputs
   if(!CheckInputs()){return INIT_PARAMETERS_INCORRECT;}
   
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

   
  }
  
//+------------------------------------------------------------------+
//| Custom Functions                                                 |
//+------------------------------------------------------------------+
void SetInputs(){
   //condition 1
   con[0].active        = InpCon1Active;
   con[0].modeA         = InpCon1ModeA;
   con[0].idxA          = InpCon1IndexA;
   con[0].comp          = InpCon1Compare;
   con[0].modeB         = InpCon1ModeB;
   con[0].idxB          = InpCon1IndexB;
   con[0].value         = InpCon1Value;
   
   //condition 2
   con[1].active        = InpCon2Active;
   con[1].modeA         = InpCon2ModeA;
   con[1].idxA          = InpCon2IndexA;
   con[1].comp          = InpCon2Compare;
   con[1].modeB         = InpCon2ModeB;
   con[1].idxB          = InpCon2IndexB;
   con[1].value         = InpCon2Value;
}

bool CheckInputs(){
   
   if(InpMagicNumber <= 0)
     {
      Alert("Wrong input: MagicNumber <= 0");
      return false;
     }
     
   if(InpLots <= 0)
     {
      Alert("Wrong input: Lots <= 0");
      return false;
     }
     
   if(InpStopLoss < 0)
     {
      Alert("Wrong input: InpStopLoss < 0");
      return false;
     }
     
   if(InpTakeProfit < 0)
     {
      Alert("Wrong input: InpTakeProfit < 0");
      return false;
     }
     
   //check conditions +++
   
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
//+------------------------------------------------------------------+
