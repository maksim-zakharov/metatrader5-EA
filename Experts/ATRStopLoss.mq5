//+------------------------------------------------------------------+
//|                                                  ATRStopLoss.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#include "ObjectService.mqh";
//+------------------------------------------------------------------+
//|              Настройки ATR                                       |
//+------------------------------------------------------------------+
input uint MA_Period = 15;               // Период ATR
input ENUM_TIMEFRAMES MA_Timeframe = PERIOD_D1;               // Таймфрейм ATR
int      ATRHandle;                    // Variable to store the handle of ATR
double   ATRValue[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   CreateATRHandle();
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
   MqlTick Latest_Price;
   SymbolInfoTick(NULL,Latest_Price);
   const double ATR = GetATRValue();
   CreateHLine(Latest_Price.bid + ATR, "ATR_SELL_STOPLOSS", "", clrRed, STYLE_DASH);
   CreateHLine(Latest_Price.bid - ATR, "ATR_BUY_STOPLOSS", "", clrRed, STYLE_DASH);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateATRHandle()
  {
   ATRHandle = iATR(NULL, MA_Timeframe,MA_Period); // returns a handle for ATR
   ArraySetAsSeries(ATRValue,true);       // Set the ATRValue to timeseries, 0 is the oldest.
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetATRValue()
  {
   int      Count = 1;                    // Amount to copy
   if(CopyBuffer(ATRHandle,0,0,Count,ATRValue) > 0)     // Copy value of ATR to ATRValue
     {
      return ATRValue[0];
     }

   return 0;
  }
//+------------------------------------------------------------------+
