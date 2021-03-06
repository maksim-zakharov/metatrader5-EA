//+------------------------------------------------------------------+
//|                                  PriceActionPatternsDetector.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
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
//---
   
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BearishEngulfing()
  {
   const int left = 2; // candles[0]; // Материнская свеча
   const int right = 1; // candles[1]; // inside bar

   return isBullish(left)
          && isBearish(right)
// && right.h - right.l >= 0.5 // потестить на AAPL
          && iClose(NULL, 0, right) < iOpen(NULL, 0, left)
          && iLow(NULL, 0, right) < iLow(NULL, 0, left);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BullishEngulfing()
  {
   const int left = 2; // candles[0]; // Материнская свеча
   const int right = 1; // candles[1]; // inside bar

   return isBearish(left)
          && isBullish(right)
// && right.h - right.l >= 0.5 // потестить на AAPL
          && iClose(NULL, 0, right) > iOpen(NULL, 0, left) && iHigh(NULL, 0, right) > iHigh(NULL, 0, left);
  };

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BullishInsideBar()
  {

   const int left = 2; // candles[0]; // Материнская свеча
   const int right = 1; // candles[1]; // inside bar
   const int confirmed = 0; // candles[2]; // рыночная свеча, проверяем пошла ли цена уже за пределы материнской (актуален ли вход)


   const double ATR = GetATRValue(); // magic number
   const double percent = spread(right) * 100 / spread(left);

   return spread(left) > ATR // зависит от ТФ и от ATR
          && spread(right) > ATR // зависит от ТФ и от ATR
          && isBearish(left)
          && isBullish(right)
// Второй бар (внутренний) должен иметь противоположное направление и быть минимум в 2 раза меньше материнской свечи
// && (spread(left) / spread(right)) >= 2
// минимум и максимум первого бара не должны перекрываться экстремумами второго
          && iHigh(NULL, 0, left) >= iHigh(NULL, 0, right) && iLow(NULL, 0, left) <= iLow(NULL, 0, right)
// Если материнская свеча слишком большая, то лучше всего такой сетап пропустить
// && percent > 20 // 20%, скорее всего убыток
// && percent < 80 // 80%, входить слишком поздно, чтоб не было большого стопа и маленького тейка
// Подтверждаем что отката к стоп-лоссу и тейку не было (опционально)
          && (!confirmed|| (iHigh(NULL, 0, confirmed) < iHigh(NULL, 0, left) && iLow(NULL, 0, confirmed) > iLow(NULL, 0, left)))
          ;
  };
