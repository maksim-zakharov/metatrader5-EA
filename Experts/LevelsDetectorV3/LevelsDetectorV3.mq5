//+------------------------------------------------------------------+
//|                                             LevelsDetectorV2.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "OrderService.mqh";
#include "ObjectService.mqh";
#include "Utills.mqh";

input const uint candlesCount = 1800; // Количество свечей для анализа

input uint precision = 2; // Точность (зависит от количества чисел после запятой)

input const uint maxLevelsCount = 3; // Количество уровней для отображения
input uint takeProfit = 3; // Коэффициент Тейк-Профита
input double order_lot = 0.01; // Размер лота
input bool tradingEnable = true; // Включить торговлю
//+------------------------------------------------------------------+
//|              Настройки ATR                                       |
//+------------------------------------------------------------------+
input uint MA_Period = 15;               // Период ATR
input ENUM_TIMEFRAMES MA_Timeframe = PERIOD_D1;               // Таймфрейм ATR

input long magic_number=55555; // Уникальный номер советника

uint priceRoundPrecision = 1; // Точность округления цены уровней
int normolizeDigits = 3;
long lastTime = 0;
int      ATRHandle;                    // Variable to store the handle of ATR
double   ATRValue[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   normolizeDigits = Digits() - precision;
   for(uint i = 0; i < precision; i++){
   priceRoundPrecision *= 10;
   }

   CreateATRHandle();
   CheckLevels();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectDeleteAllByType(OBJ_HLINE);
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
// CloseOutsideOrders();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseOutsideOrders()
  {
   const int ordersTotal = OrdersTotal();
   const double high = iH(iHighest(NULL, 0, MODE_HIGH, candlesCount));
   const double low = iL(iLowest(NULL, 0, MODE_LOW, candlesCount));

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
            || !IsNearPrice(openPrice)
         )
           {
            CancelStopOrder(i);
           }

         if(orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP && isBearishTrend(candlesCount))
           {
            CancelStopOrder(i);
           }

         if(orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_SELL_STOP && isBullishTrend(candlesCount))
           {
            CancelStopOrder(i);
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNearPrice(double price)
  {
   const double high = iH(iHighest(NULL, 0, MODE_HIGH, candlesCount));
   const double low = iL(iLowest(NULL, 0, MODE_LOW, candlesCount));

   const double chartSpread = high - low;
   const double middlePrice = chartSpread / 2;

   MqlTick Latest_Price;
   SymbolInfoTick(NULL,Latest_Price);

   return (Latest_Price.ask - middlePrice < price)
          || (Latest_Price.ask + middlePrice > price)
          ;
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

   int pricesLenght = ArraySize(prices);

   for(int i = 0; i < maxLevelsCount; i++)
     {
      if(pricesCount[i] < priceRoundPrecision)
        {
         continue;
        }
      const string name = magic_number + " " + i;
      if(pricesLenght > i && !MQLInfoInteger(MQL_OPTIMIZATION))
        {
         const string descr = StringFormat("Index: %.0f, Price: %." + normolizeDigits + "f, Count: %.0f", i, prices[i], pricesCount[i]);
         Print(descr);
         long objColor = -1;
         if(pricesCount[i] > 5 * priceRoundPrecision)
           {
            objColor = clrRed;
           }
         else
            if(pricesCount[i] > 3 * priceRoundPrecision)
              {
               objColor = clrOrange;
              }
            else
               if(pricesCount[i] > priceRoundPrecision)
                 {
                  objColor = clrGold;
                 }
               else
                  if(pricesCount[i] > 0.1 * priceRoundPrecision)
                    {
                     objColor = clrYellow;
                    }
                  else
                     if(pricesCount[i] > 0.01 * priceRoundPrecision)
                       {
                        objColor = clrLightYellow;
                       }
                     else
                       {
                        objColor = clrGray;
                       }
         CreateHLine(prices[i], name, descr, objColor);
        }
     }

   const int positionAndOrders = PositionsTotal() + OrdersTotal();

   if(positionAndOrders > maxLevelsCount)
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
      if(!IsNearPrice(price))
        {
         continue;
        }
      if(price > Latest_Price.ask)// && isBearishTrend(candlesCount / 2))
        {
         const double sl = price + GetATRValue() / 2;
         const double tp = price - (sl - price) * takeProfit;

         if(OrderFind(price, ORDER_TYPE_SELL_LIMIT, normolizeDigits) || PositionFind(price, POSITION_TYPE_SELL, normolizeDigits))
           {
            continue;
           }
         OrderSellLimit(price, sl, tp);
        }
      if(price < Latest_Price.ask)// && isBullishTrend(candlesCount / 2))
        {
         const double sl = price - GetATRValue() / 2;
         const double tp = price + (price - sl) * takeProfit;

         if(OrderFind(price, ORDER_TYPE_BUY_LIMIT, normolizeDigits) || PositionFind(price, POSITION_TYPE_BUY, normolizeDigits))
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
void AddPrice(
   double& srcPrices[],
   int& srcPricesCount[],
   double price
)
  {

   Round(price, normolizeDigits);

   const double high = iH(iHighest(NULL, 0, MODE_HIGH, candlesCount));
   const double low = iL(iLowest(NULL, 0, MODE_LOW, candlesCount));

   const double chartSpread = high - low;
   const double middlePrice = chartSpread / 2;

   int searchIndex = TrueArraySearch(srcPrices, price);
// Если уровень уже есть в списке, усиляем его
   if(searchIndex > -1)
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
