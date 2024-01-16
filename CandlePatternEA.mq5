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
#include <CandlePatternGUI.mqh>

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
   VALUE = 7,                                                       //value
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

CONDITION con[NR_CONDITIONS];                                        //condition array
MqlTick currentTick;                                                 //current tick of the symbol
CTrade trade;                                                        //object to open/close positons
CGraphicalPanel panel;                                               //object to create panel

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "==== General ===="
static input long       InpMagicNumber = 55555;                      //magic number
static input double     InpLots        = 0.01;                       //lots
input int               InpStopLoss    = 200;                        //stop loss in points (0=off)
input int               InpTakeProfit  = 300;                          //take profit in points (0=off)

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
   
   //create panel
   if(!panel.Oninit())
     {
      return INIT_FAILED;
     }
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   //destroy panel
   panel.Destroy(reason);
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  
   //check if current tick is a new bar open tick
   if(!IsNewBar()){return;}
   
   //get current tick
   if(!SymbolInfoTick(_Symbol, currentTick)) 
     {
      Print("Failed to get current tick");
      return;
     }
     
   //count open positions
    int cntBuy, cntSell;
    if(!CountOpenPositions(cntBuy, cntSell))
      {
       Print("Failed to count open positons");
       return;
      }
      
   //check for new buy position
   if(cntBuy==0 && CheckAllConditions(true))
     {
         
       double sl = InpStopLoss == 0 ? 0 : currentTick.bid - InpStopLoss * _Point;
       double tp = InpTakeProfit == 0 ? 0 : currentTick.bid + InpTakeProfit * _Point;
       
       if(!NormalizePrice(sl)) {return;}
       if(!NormalizePrice(tp)) {return;}
       
       trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, InpLots, currentTick.ask, sl, tp, "CandlePatternEA");
     }
     
   //check for new sell position
   if(cntBuy==0 && CheckAllConditions(false))
     {
         
       double sl = InpStopLoss == 0 ? 0 : currentTick.ask + InpStopLoss * _Point;
       double tp = InpTakeProfit == 0 ? 0 : currentTick.ask - InpTakeProfit * _Point;
       
       if(!NormalizePrice(sl)) {return;}
       if(!NormalizePrice(tp)) {return;}
       
       trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, InpLots, currentTick.bid, sl, tp, "CandlePatternEA");
     }
   
   //update panel
   panel.Update();
  }
  
  
void OnChartEvent(const int id,const long& lparam,const double& dparam,const string& sparam)
  {
   panel.ChartEvent(id,lparam,dparam,sparam);
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

//check for conditions
bool CheckAllConditions(bool buy_sell){
   
   //check each condition
   for(int i=0;i<NR_CONDITIONS;i++)
     {
      if(!CheckOneCondition(buy_sell, i)){return false;}
     }
   
   return true;
}

//check one condition
bool CheckOneCondition(bool buy_sell, int idx){
   //return true if condition is not active
   if(!con[idx].active){return true;}
   
   //get bar data
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol,PERIOD_CURRENT,0,4,rates);
   
   if(copied!=4){
      Print("Failed to get bar data. copied ",GetLastError()); 
      return false;
   }
   
   //set values to a and b
   double a= 0;
   double b = 0;
   
   switch(con[idx].modeA)
     {
      case OPEN: a = rates[con[idx].idxA].open;
        break;
      case HIGH: a = buy_sell ? rates[con[idx].idxA].high : rates[con[idx].idxA].low;
        break;
      case LOW: a = buy_sell ? rates[con[idx].idxA].low : rates[con[idx].idxA].high;
        break;
      case CLOSE: a = rates[con[idx].idxA].close;
        break;
      case RANGE: a = (rates[con[idx].idxA].high - rates[con[idx].idxA].low) / _Point;
        break;
      case BODY: a = MathAbs(rates[con[idx].idxA].open - rates[con[idx].idxA].close) / _Point;
        break;
      case RATIO: a = MathAbs(rates[con[idx].idxA].open - rates[con[idx].idxA].close) / (rates[con[idx].idxA].high - rates[con[idx].idxA].low);
        break;
      case VALUE: a = con[idx].value;
        break;
      default:
        return false;
     }
     
   switch(con[idx].modeB)
     {
      case OPEN: b = rates[con[idx].idxB].open;
        break;
      case HIGH: b = buy_sell ? rates[con[idx].idxB].high : rates[con[idx].idxB].low;
        break;
      case LOW: b = buy_sell ? rates[con[idx].idxB].low : rates[con[idx].idxB].high;
        break;
      case CLOSE: b = rates[con[idx].idxB].close;
        break;
      case RANGE: b = (rates[con[idx].idxB].high - rates[con[idx].idxB].low) / _Point;
        break;
      case BODY: b = MathAbs(rates[con[idx].idxB].open - rates[con[idx].idxB].close) / _Point;
        break;
      case RATIO: b = MathAbs(rates[con[idx].idxB].open - rates[con[idx].idxB].close) / (rates[con[idx].idxB].high - rates[con[idx].idxB].low);
        break;
      case VALUE: b = con[idx].value;
        break;
      default:
        return false;
     }
     
   //compare values
   if(buy_sell || (!buy_sell && con[idx].modeA >= 4))
     {
      if(con[idx].comp == GREATER && a > b) {return true;}
      if(con[idx].comp == LESS && a < b) {return true;}
     }
   else
     {
      if(con[idx].comp == GREATER && a < b) {return true;}
      if(con[idx].comp == LESS && a > b) {return true;}
     }
    
   return false;
}

//check for inputs
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

//count open positions
bool CountOpenPositions(int &cntBuy, int &cntSell)
  {
   cntBuy = 0;
   cntSell = 0;
   int total = PositionsTotal();
   
   if(total == 0)
      {
       Print("No open positions");
       return true;
      }

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
