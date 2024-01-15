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
//+------------------------------------------------------------------+
