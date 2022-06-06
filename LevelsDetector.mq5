//+------------------------------------------------------------------+
//|                                               LevelsDetector.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

long chartId = 0;
int subWindow = 0;
int candle=1800;
input long magic_number=55555;
input double order_lot = 0.01;
input double takeProfit = 3;
input double stopLoss = 2;
input double firstBarSize = 40;

long lastTime = 0;

//+------------------------------------------------------------------+
//|              Настройки ATR                                       |
//+------------------------------------------------------------------+
int      ATRHandle;                    // Variable to store the handle of ATR
double   ATRValue[];                   // Variable to store the value of ATR

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//EventSetTimer(15);
//ClearOutsideHLine();

//CreateMaxHighLine();
//CreateMinLowLine();

   CheckLevels();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

   if(!isNewBar())
     {
      return;
     }

   CheckLevels();

   /**
      for(int i = 0; i < OrdersTotal(); i++)
        {
         if(!OrderSelect(i))
           {
            continue;
           }

         MqlTick Latest_Price;
         SymbolInfoTick(Symbol(),Latest_Price);
         const double tp = OrderGetDouble(ORDER_TP);
         if(tp > Latest_Price.ask)
           {
            CancelStopOrder(i);
           }
        }

      if(PositionsTotal() > 0)
        {
         for(int i = 0; i < OrdersTotal(); i++)
           {
            CancelStopOrder(i);
           }
         return;
        }
        **/

   /*if(BullishInsideBar()) {
   const double stop = spread(2);
   const double take = stop * takeProfit;
   OrderBuy(stop, take);
   }*/

   /**
   if(BullishEngulfing()) {
   const double stop = spread(1) * stopLoss;
   const double take = stop * takeProfit;
   // OrderBuy(stop, take);

   const double buyPrice = iH(1) + GetATRNumber();
   const double sellPrice = iL(1) - GetATRNumber();
   OrderBuyStop(buyPrice, sellPrice, buyPrice + (buyPrice - sellPrice) * takeProfit);
   OrderSellStop(sellPrice, buyPrice, sellPrice - (buyPrice - sellPrice) * takeProfit);

   }
   **/

   const double leftBar = iClose(NULL, 0, 2) - iOpen(NULL, 0, 2);
   const double rightBar = iOpen(NULL, 0, 1) - iClose(NULL, 0, 1);

   if(
      leftBar > firstBarSize * 0.00001
      && rightBar / 2 >= leftBar
      && BearishEngulfing()
   )
     {
      //const double stop = spread(1) * stopLoss;
      //const double take = stop * takeProfit;
      //OrderSell(stop, take);

      //const double buyPrice = iH(1) + GetATRNumber();
      //const double sellPrice = iL(1) - GetATRNumber();

      const double openPrice = iH(1) - spread(1) / 2; // iL(2);
      const double sl = iH(1) + GetATRValue();
      const double tp = openPrice - (sl - openPrice) * takeProfit;

      OrderSellLimit(openPrice, sl, tp);

      // OrderBuyStop(buyPrice, sellPrice, buyPrice + (buyPrice - sellPrice) * takeProfit);
      // OrderSellStop(sellPrice, buyPrice, sellPrice - (buyPrice - sellPrice) * takeProfit);
     }

   /**for(int i = 0; i< OrdersTotal(); i++){
   const orderTicket = OrderGetTicket(i);

   }
   /**
   Каждые 15 сек берем последние 1800 свеч, пересчет идет с конца.

   - Рисуем строчку только если ее нет в по цене в созданных строчек
   - Если линия находится вне максимума и минимума 1800 свечек, она удаляется (за пределами графика).

   **/

//CreateMaxHighLine();
//CreateMinLowLine();
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckLevels()
  {

   double prices[];
   double pricesCount[];

   for(int i = 0; i < 1800; i++)
     {
      AddPrice(prices, pricesCount, iH(i));
      AddPrice(prices, pricesCount, iL(i));
      AddPrice(prices, pricesCount, iO(i));
      AddPrice(prices, pricesCount, iC(i));
     }
     
     int maxIndex = ArrayMaximum(prices,WHOLE_ARRAY,0);
     Print(maxIndex);
     Print(prices[maxIndex]);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AddPrice(double& prices[], double& pricesCount[], double price)
  {

   int searchIndex = ArrayBsearch(prices, price);
// Если уровень уже есть в списке, усиляем его
   if(searchIndex > 0)
     {
      pricesCount[searchIndex]++;
     }
// Если уровня еще нет, получаем размер массива, добавляем уровень
   else
     {
      int newIndex=ArraySize(prices);
      ArrayResize(prices,newIndex + 1);
      ArrayResize(pricesCount,newIndex + 1);
      prices[newIndex] = price;
      pricesCount[newIndex] = 1;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isNewBar()
  {
   const double time = iTime(NULL, 0, 0);
   if(lastTime != time)
     {
      lastTime = time;
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iO(int index)
  {
   return iOpen(NULL, 0, index);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iC(int index)
  {
   return iClose(NULL, 0, index);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iL(int index)
  {
   return iLow(NULL, 0, index);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double iH(int index)
  {
   return iHigh(NULL, 0, index);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double spread(int index)
  {
   return MathAbs(iHigh(NULL, 0, index) - iLow(NULL, 0, index));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double isBearish(int index)
  {
   return iOpen(Symbol(), PERIOD_CURRENT, index) > iClose(Symbol(), PERIOD_CURRENT, index);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double isBullish(int index)
  {
   return iOpen(Symbol(), PERIOD_CURRENT, index) < iClose(Symbol(), PERIOD_CURRENT, index);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CancelStopOrder(int index)
  {
//-- объявление и инициализация запроса и результата
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
//--- перебор всех установленных отложенных ордеров
   ulong  order_ticket=OrderGetTicket(index);                   // тикет ордера
   ulong  magic=OrderGetInteger(ORDER_MAGIC);               // MagicNumber ордера
//--- если MagicNumber совпадает
//if(magic==magic_number)
//{
//--- установка параметров операции
   request.action=TRADE_ACTION_REMOVE;                   // тип торговой операции
   request.order = order_ticket;                         // тикет ордера
//--- отправка запроса
   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());  // если отправить запрос не удалось, вывести код ошибки
//--- информация об операции
   PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
//}
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


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateATRHandle()
  {
   int      MA_Period = 15;               // The value of the averaging period for the indicator calculation
   ATRHandle = iATR(_Symbol,PERIOD_D1,MA_Period); // returns a handle for ATR
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
//|                                                                  |
//+------------------------------------------------------------------+
void OrderSellLimit(double price, double sl, double tp)
  {
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
//--- параметры запроса
   request.action   =TRADE_ACTION_PENDING;                     // тип торговой операции
   request.symbol   =Symbol();                              // символ
   request.volume   =order_lot;                                   // объем в 0.2 лот
   request.sl = sl;
   request.tp = tp;
   request.type     =ORDER_TYPE_SELL_LIMIT;                       // тип ордера
   request.price    =price; // цена для открытия
   request.deviation=5;                                     // допустимое отклонение от цены
   request.magic    =magic_number;                          // MagicNumber ордера
//--- отправка запроса
   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());     // если отправить запрос не удалось, вывести код ошибки
//--- информация об операции
   PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderSellStop(double price, double sl, double tp)
  {
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
//--- параметры запроса
   request.action   =TRADE_ACTION_PENDING;                     // тип торговой операции
   request.symbol   =Symbol();                              // символ
   request.volume   =order_lot;                                   // объем в 0.2 лот
   request.sl = sl;
   request.tp = tp;
   request.type     =ORDER_TYPE_SELL_STOP;                       // тип ордера
   request.price    =price; // цена для открытия
   request.deviation=5;                                     // допустимое отклонение от цены
   request.magic    =magic_number;                          // MagicNumber ордера
//--- отправка запроса
   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());     // если отправить запрос не удалось, вывести код ошибки
//--- информация об операции
   PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderBuyStop(double price, double sl, double tp)
  {
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
//--- параметры запроса
   request.action   =TRADE_ACTION_PENDING;                     // тип торговой операции
   request.symbol   =Symbol();                              // символ
   request.volume   =order_lot;                                   // объем в 0.1 лот
   request.sl = sl;
   request.tp = tp;
   request.type     =ORDER_TYPE_BUY_STOP;                        // тип ордера
   request.price    =price; // цена для открытия
   request.deviation=5;                                     // допустимое отклонение от цены
   request.magic    =magic_number;                          // MagicNumber ордера
//--- отправка запроса
   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());     // если отправить запрос не удалось, вывести код ошибки
//--- информация об операции
   PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderSell(double sl, double tp)
  {
   double price = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
//--- параметры запроса
   request.action   =TRADE_ACTION_DEAL;                     // тип торговой операции
   request.symbol   =Symbol();                              // символ
   request.volume   =order_lot;                                   // объем в 0.2 лот
   request.sl = price + sl;
   request.tp = price - tp;
   request.type     =ORDER_TYPE_SELL;                       // тип ордера
   request.price    =price; // цена для открытия
   request.deviation=5;                                     // допустимое отклонение от цены
   request.magic    =magic_number;                          // MagicNumber ордера
//--- отправка запроса
   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());     // если отправить запрос не удалось, вывести код ошибки
//--- информация об операции
   PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OrderBuy(double sl, double tp)
  {
   double price = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
//--- параметры запроса
   request.action   =TRADE_ACTION_DEAL;                     // тип торговой операции
   request.symbol   =Symbol();                              // символ
   request.volume   =order_lot;                                   // объем в 0.1 лот
   request.sl = price - sl;
   request.tp = price + tp;
   request.type     =ORDER_TYPE_BUY;                        // тип ордера
   request.price    =price; // цена для открытия
   request.deviation=5;                                     // допустимое отклонение от цены
   request.magic    =magic_number;                          // MagicNumber ордера
//--- отправка запроса
   if(!OrderSend(request,result))
      PrintFormat("OrderSend error %d",GetLastError());     // если отправить запрос не удалось, вывести код ошибки
//--- информация об операции
   PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateMaxHighLine()
  {
   string symbol = Symbol();

   double lowest_price[];
   ArrayResize(lowest_price,candle);

   for(int i=0; i<candle; i++)
     {
      lowest_price[i]=iHigh(symbol,PERIOD_CURRENT,i);
     }

   int minLowIndex=ArrayMaximum(lowest_price,0,WHOLE_ARRAY);
   Print("candle "+(minLowIndex+1)+": is Highest High from Last "+ candle +" Candles = "+(string)lowest_price[minLowIndex]);

   if(!HasHLineByPrice(lowest_price[minLowIndex]))
     {
      CreateHLine(lowest_price[minLowIndex]);
     }
   else
     {
      Print("HLine already exist at price:", lowest_price[minLowIndex]);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateMinLowLine()
  {
   string symbol = Symbol();

   double lowest_price[];
   ArrayResize(lowest_price,candle);

   for(int i=0; i<candle; i++)
     {
      lowest_price[i]=iLow(symbol,PERIOD_CURRENT,i);
     }

   int minLowIndex=ArrayMinimum(lowest_price,0,WHOLE_ARRAY);
   Print("candle "+(minLowIndex+1)+": is Lowest Low from Last "+ candle +" Candles = "+(string)lowest_price[minLowIndex]);

   if(!HasHLineByPrice(lowest_price[minLowIndex]))
     {
      CreateHLine(lowest_price[minLowIndex]);
     }
   else
     {
      Print("HLine already exist at price:", lowest_price[minLowIndex]);
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ClearOutsideHLine()
  {
   string symbol = Symbol();
   int objType = OBJ_HLINE;
   const int objectTotal = ObjectsTotal(chartId, subWindow, objType);

   for(int i= objectTotal-1; i>=0; i--)
     {
      const string objectName = ObjectName(chartId, i, subWindow, objType);
      datetime when = (datetime)ObjectGetInteger(chartId, objectName, OBJPROP_TIME, 0);
      Print(when);
      int shift = iBarShift(symbol, PERIOD_CURRENT, when, true);
      Print(shift);
      if(shift > candle)
        {
         ObjectDelete(chartId, objectName);
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateHLine(double price)
  {
   ObjectCreate(chartId, TimeCurrent(), OBJ_HLINE, subWindow, 0, price);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HasHLineByPrice(double price)
  {
   int objType = OBJ_HLINE;
   const int objectTotal = ObjectsTotal(chartId, subWindow, objType);

   for(int i= objectTotal-1; i>=0; i--)
     {
      const string objectName = ObjectName(chartId, i, subWindow, objType);
      const double existPrice = ObjectGetDouble(chartId, objectName, OBJPROP_PRICE);
      if(price == existPrice)
        {
         return true;
        }
      continue;
     }

   return false;
  }

/**
double c_candle[];
ArrayResize(c_candle,candle);

for(int i=0;i<candle;i++) {
   c_candle[i]=iLow(symbol,PERIOD_CURRENT,i);
}

int minLowIndex=ArrayMinimum(c_candle,0,WHOLE_ARRAY);
**/

//
// void OnTick()
//  {
//   Print("OnTick");
//  }
