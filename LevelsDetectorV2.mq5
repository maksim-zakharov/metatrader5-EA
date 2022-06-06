//+------------------------------------------------------------------+
//|                                             LevelsDetectorV2.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

input const int candlesCount = 1800;
int normolizeDigits = 3;
input const int maxLevelsCount = 5;
input double takeProfit = 3;
input long magic_number=55555;
input double order_lot = 0.01;
input bool tradingEnable = true;
input int MA_Period = 15;               // The value of the averaging period for the indicator calculation
input ENUM_TIMEFRAMES MA_Timeframe = PERIOD_D1;               // The value of the averaging period for the indicator calculation
long lastTime = 0;
//+------------------------------------------------------------------+
//|              Настройки ATR                                       |
//+------------------------------------------------------------------+
int      ATRHandle;                    // Variable to store the handle of ATR
double   ATRValue[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   normolizeDigits = Digits() - 2;
   CreateATRHandle();
   CheckLevels();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ClearHLines();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!isNewBar())
     {
      return;
     }

   CheckLevels();
   CloseOutsideOrders();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseOutsideOrders()
  {
   const int ordersTotal = OrdersTotal();
   const double high = iH(iHighest(NULL, 0, MODE_HIGH, candlesCount));
   const double low = iL(iLowest(NULL, 0, MODE_LOW, candlesCount));

   const double chartSpread = high - low;
   const double middlePrice = chartSpread / 2;

   MqlTick Latest_Price;
   SymbolInfoTick(NULL,Latest_Price);

   for(int i = 0; i< ordersTotal; i++)
     {
      const int orderTicket = OrderGetTicket(i);
      if(OrderSelect(orderTicket))
        {
         const double openPrice = OrderGetDouble(ORDER_PRICE_OPEN);
         const ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if(
            openPrice > high
            || openPrice < low
            || (Latest_Price.ask - middlePrice > openPrice)
            || (Latest_Price.ask + middlePrice < openPrice)
         )
           {
            CancelStopOrder(i);
           }

         if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP && isBearishTrend())
           {
            CancelStopOrder(i);
           }

         if(orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_SELL_STOP && isBullishTrend())
           {
            CancelStopOrder(i);
           }
        }
     }
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
void OrderBuyLimit(double price, double sl, double tp)
  {
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
//--- параметры запроса
   request.action   =TRADE_ACTION_PENDING;                     // тип торговой операции
   request.symbol   =Symbol();                              // символ
   request.volume   =order_lot;                                   // объем в 0.1 лот
   request.sl = sl;
   request.tp = tp;
   request.type     =ORDER_TYPE_BUY_LIMIT;                        // тип ордера
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
void ClearHLines()
  {
   const int objectTotal = ObjectsTotal(0, 0, OBJ_HLINE);

   for(int i= objectTotal-1; i>=0; i--)
     {
      const string objectName = ObjectName(0, i, 0, OBJ_HLINE);
      ObjectDelete(0, objectName);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBearishTrend()
  {
   return iC(0) - iO(candlesCount) < 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBullishTrend()
  {
   return iC(0) - iO(candlesCount) > 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckLevels()
  {

   double prices[];
   int pricesCount[];

   for(int i = 0; i < candlesCount; i++)
     {
      AddPrice(prices, pricesCount, iH(i));
      AddPrice(prices, pricesCount, iL(i));
      AddPrice(prices, pricesCount, iO(i));
      AddPrice(prices, pricesCount, iC(i));
     }

   SortArray(prices, pricesCount, true);

   const int pricesLenght = ArraySize(prices);
   for(int i = 0; i < pricesLenght; i++)
     {
      const string name = magic_number + " " + i;
      const string descr = StringFormat("Index: %.0f, Price: %." + normolizeDigits + "f, Count: %.0f", i, prices[i],pricesCount[i]);
      Print(descr);
      if(pricesLenght > i && !MQLInfoInteger(MQL_OPTIMIZATION))
        {
         long objColor = -1;
         if(pricesCount[i] > 1000)
           {
            objColor = clrRed;
           }
         else if(pricesCount[i] > 100)
              {
               objColor = clrYellow;
              }
            else if(pricesCount[i] > 10)
                 {
                  objColor = clrBlue;
                 }
               else
                 {
                  objColor = clrGray;
                 }
         CreateHLine(prices[i], name, descr, objColor);
        }
     }

   if(OrdersTotal() > maxLevelsCount || PositionsTotal() > 0)
     {
      return;
     }

   if(!tradingEnable)
     {
      return;
     }

   MqlTick Latest_Price;
   SymbolInfoTick(NULL,Latest_Price);

   for(int i = 0; i < maxLevelsCount; i++)
     {
      if(pricesLenght <= i)
        {
         continue;
        }
      const double price = prices[i];
      if(price > Latest_Price.ask && isBearishTrend())
        {
         const double sl = price + GetATRValue() / 2;
         const double tp = price - (sl - price) * takeProfit;

         if(OrderFind(price, ORDER_TYPE_SELL_LIMIT))
           {
            continue;
           }
         OrderSellLimit(price, sl, tp);
        }
      if(price < Latest_Price.ask && isBullishTrend())
        {
         const double sl = price - GetATRValue() / 2;
         const double tp = price + (price - sl) * takeProfit;

         if(OrderFind(price, ORDER_TYPE_BUY_LIMIT))
           {
            continue;
           }
         OrderBuyLimit(price, sl, tp);
        }
      /**
      if(price < Latest_Price.ask && isBearishTrend())
        {
         const double sl = price + GetATRValue();
         const double tp = price - (sl - price) * takeProfit;

         if(OrderFind(price, ORDER_TYPE_SELL_STOP))
           {
            continue;
           }
         OrderSellStop(price, sl, tp);
        }
      if(price > Latest_Price.ask && isBullishTrend())
        {
         const double sl = price - GetATRValue();
         const double tp = price + (price - sl) * takeProfit;

         if(OrderFind(price, ORDER_TYPE_BUY_STOP))
           {
            continue;
           }
         OrderBuyStop(price, sl, tp);
        }
        **/
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool OrderFind(double openPrice, ENUM_ORDER_TYPE orderType)
  {
   const int ordersTotal = OrdersTotal();
   for(int i = 0; i < ordersTotal; i++)
     {
      const int orderTicket = OrderGetTicket(i);
      if(OrderSelect(orderTicket))
        {
         const double orderOpenPrice = OrderGetDouble(ORDER_PRICE_OPEN);
         const ENUM_ORDER_TYPE orderOpenType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
         if(orderOpenType == orderType && openPrice == orderOpenPrice)
           {
            return true;
           }
        }
     }

   return false;
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
//|                                                                  |
//+------------------------------------------------------------------+
void CreateHLine(double price, string name, string descr, color objColor)
  {
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetString(0,name,OBJPROP_TEXT,descr);
   ObjectSetInteger(0, name, OBJPROP_COLOR, objColor);
  }
//+------------------------------------------------------------------+
void AddPrice(
   double& srcPrices[],
   int& srcPricesCount[],
   double price
)
  {

   if(normolizeDigits > -1)
     {
      price = NormalizeDouble(price, normolizeDigits);
     }
   else
     {
      for(int i = 0; i > normolizeDigits; i--)
        {
         price /= 10;
        }
      price = NormalizeDouble(price, -normolizeDigits);
      for(int i = 0; i > normolizeDigits; i--)
        {
         price *= 10;
        }
     }


   const double high = iH(iHighest(NULL, 0, MODE_HIGH, candlesCount));
   const double low = iL(iLowest(NULL, 0, MODE_LOW, candlesCount));

   const double chartSpread = high - low;
   const double middlePrice = chartSpread / 2;

   ArraySort(srcPrices);

   int searchIndex = ArrayBsearch(srcPrices, price);
// Если уровень уже есть в списке, усиляем его
   if(searchIndex > 0)
     {
      srcPricesCount[searchIndex]++;
     }
// Если уровня еще нет, получаем размер массива, добавляем уровень
   else
     {
      int newIndex=ArraySize(srcPrices);
      ArrayResize(srcPrices,newIndex + 1);
      ArrayResize(srcPricesCount,newIndex + 1);
      srcPrices[newIndex] = price;
      srcPricesCount[newIndex] = 1;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SortArray(double& array[], int& arrayIndex[], bool desc)
  {
   const int arraySize = ArraySize(arrayIndex);
   bool swapped = true;
   do
     {
      swapped = false;
      for(int i = 0; i < arraySize - 1; i++)
        {
         const bool descSort = desc && arrayIndex[i + 1] > arrayIndex[i];
         const bool ascSort = !desc && arrayIndex[i + 1] < arrayIndex[i];
         if(ascSort || descSort)
           {
            double temp = array[i];
            array[i] = array[i + 1];
            array[i + 1] = temp;

            int tempInt = arrayIndex[i];
            arrayIndex[i] = arrayIndex[i + 1];
            arrayIndex[i + 1] = tempInt;

            swapped = true;
           }
        }
     }
   while(swapped);
  }
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
