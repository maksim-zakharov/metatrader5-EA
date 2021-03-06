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

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input uint precision = 2; // Точность (зависит от количества чисел после запятой)
input const uint maxLevelsCount = 3; // Количество уровней для отображения
input uint takeProfit = 3; // Коэффициент Тейк-Профита
input double riskPerTradePercent = 2; // Размер лота
input bool tradingEnable = true; // Включить торговлю
//+------------------------------------------------------------------+
//|              Настройки MA                                        |
//+------------------------------------------------------------------+
input int MA_Period = 300;               // Период MA
input ENUM_TIMEFRAMES MA_Timeframe = PERIOD_H1;     // Таймфрейм MA
//+------------------------------------------------------------------+
//|              Настройки ATR                                       |
//+------------------------------------------------------------------+
input uint ATR_Period = 14;               // Период ATR
input ENUM_TIMEFRAMES ATR_Timeframe = PERIOD_D1;               // Таймфрейм ATR

input long magic_number=55555; // Уникальный номер советника

uint priceRoundPrecision = 1; // Точность округления цены уровней
int normolizeDigits = 3;
long lastTime = 0;
int      ATRHandle;                    // Variable to store the handle of ATR
double   ATRValue[];

int      MAHandle;                    // Variable to store the handle of ATR
double   MAValue[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   EventSetTimer(5);
   normolizeDigits = Digits() - precision;
   for(uint i = 0; i < precision; i++)
     {
      priceRoundPrecision *= 10;
     }

   CreateMAHandle();
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
   CancelAllStopOrder(magic_number);
   EventKillTimer();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(!isNewBar())
     {
      return;
     }

   CloseOldOrders();

   MqlTick Latest_Price;
   SymbolInfoTick(NULL,Latest_Price);
   const double MA = GetMAValue();
   const double ATR = GetATRValue();
// Если Цена под МА но оч близко, то закрываем все отложки
   if(MA > Latest_Price.bid && MA - ATR < Latest_Price.bid)
     {
      CancelAllStopOrder(magic_number);
     }
   else
      // Если Цена над МА но оч близко, то закрываем все отложки
      if(MA < Latest_Price.bid && MA + ATR > Latest_Price.bid)
        {
         CancelAllStopOrder(magic_number);
        }
      else
        {
         CheckLevels();
        }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseOldOrders()
  {

   MqlTick Latest_Price;
   SymbolInfoTick(NULL,Latest_Price);
   const double ATR = GetATRValue();
   const double high = Latest_Price.ask - ATR;
   const double low = Latest_Price.bid + ATR;

   for(int i = 0; i< OrdersTotal(); i++)
     {
      const int ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket))
        {
         continue;
        }

      const int magic = OrderGetInteger(ORDER_MAGIC);
      const string symbol = OrderGetString(ORDER_SYMBOL);

      if(magic != magic_number || symbol != Symbol())
        {
         continue;
        }

      const string openPrice = OrderGetDouble(ORDER_PRICE_OPEN);

      if(openPrice > high && openPrice < low)
        {
         continue;
        }
      const ENUM_ORDER_TYPE orderType = (ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      const double MA = GetMAValue();
      if(MA > Latest_Price.bid && (orderType == ORDER_TYPE_SELL_LIMIT || orderType == ORDER_TYPE_SELL_STOP))
        {
         continue;
        }

      if(MA < Latest_Price.ask && (orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP))
        {
         continue;
        }

      CancelStopOrder(i, magic_number);
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
// Calculate Max Lot Size based on Maximum Risk
double CalculateLotSize(double dbStopLoss, double dbRiskRatio)
  {
   double
   dbLotsMinimum  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN),
   dbLotsMaximum  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX),
   dbLotsStep     = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP),
   dbTickSize     = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE),
   dbTickValue    = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE),
   dbValueAccount = fmin(fmin(
                            AccountInfoDouble(ACCOUNT_EQUITY),
                            AccountInfoDouble(ACCOUNT_BALANCE)),
                         AccountInfoDouble(ACCOUNT_MARGIN_FREE)),
                    dbValueRisk    = dbValueAccount * dbRiskRatio / 100,
                    dbLossOrder    = dbStopLoss * dbTickValue / dbTickSize,
                    dbCalcLot      = fmin(dbLotsMaximum,                    // Prevent too greater volume
                                          fmax(dbLotsMinimum,                    // Prevent too smaller volume
                                                round(dbValueRisk / dbLossOrder        // Calculate stop risk
                                                      / dbLotsStep) * dbLotsStep));          // Align to step value

   Print(dbCalcLot);

   return dbCalcLot;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawLevels(double& prices[], int& pricesCount[])
  {

   MqlTick Latest_Price;
   SymbolInfoTick(NULL,Latest_Price);

   for(int i = candlesCount - 1; i >= 0; i--)
     {
      AddPrice(prices, pricesCount, iH(i));
      AddPrice(prices, pricesCount, iL(i));
      AddPrice(prices, pricesCount, iO(i));
      AddPrice(prices, pricesCount, iC(i));
     }

   SortArray(prices, pricesCount, false);

   int pricesLenght = ArraySize(prices);

   for(int i = 0; i < maxLevelsCount && i < pricesLenght; i++)
   //for(int i = 0; i < pricesLenght; i++)
     {
      /**
       if(pricesCount[i] < priceRoundPrecision)
         {
          continue;
         }

         **/
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
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckLevels()
  {

   double prices[];
   int pricesCount[];

   DrawLevels(prices, pricesCount);

   const int positionAndOrders = GetPositionsTotal(NULL, magic_number) + GetOrdersTotal(NULL, magic_number);

   if(!tradingEnable || positionAndOrders >= maxLevelsCount)
     {
      return;
     }

   MqlTick Latest_Price;
   SymbolInfoTick(NULL,Latest_Price);

   int pricesLenght = ArraySize(prices);

   for(int i = 0; i < maxLevelsCount && i < pricesLenght; i++)
     {
      const double price = prices[i];
      const double ATR = GetATRValue();
      const double MA = GetMAValue();
      // SELL
      if(MA > Latest_Price.ask)
        {
         const double sl = price + ATR;
         const double lotSize = CalculateLotSize(MathAbs(price - sl), riskPerTradePercent);
         const double tp = price - (sl - price) * takeProfit;
         if(price > Latest_Price.ask)
           {

            if(Latest_Price.bid + ATR > price || OrderFind(price, ORDER_TYPE_SELL_LIMIT, normolizeDigits) || PositionFind(price, POSITION_TYPE_SELL, normolizeDigits))
              {
               continue;
              }
            OrderSellLimit(price, sl, tp, lotSize);
           }
         else
           {

            if(OrderFind(price, ORDER_TYPE_SELL_STOP))
              {
               continue;
              }
            OrderSellStop(price, sl, tp, lotSize);
           }
        }
      // BUY
      else
        {
         const double sl = price - ATR;
         const double lotSize = CalculateLotSize(MathAbs(price - sl), riskPerTradePercent);
         const double tp = price + (price - sl) * takeProfit;
         if(price < Latest_Price.ask)
           {

            if(Latest_Price.ask - ATR < price || OrderFind(price, ORDER_TYPE_BUY_LIMIT, normolizeDigits) || PositionFind(price, POSITION_TYPE_BUY, normolizeDigits))
              {
               continue;
              }
            OrderBuyLimit(price, sl, tp, lotSize);
           }
         else
           {
            if(OrderFind(price, ORDER_TYPE_BUY_STOP))
              {
               continue;
              }
            OrderBuyStop(price, sl, tp, lotSize);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateATRHandle()
  {
   ATRHandle = iATR(NULL, ATR_Timeframe,ATR_Period); // returns a handle for ATR
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
void CreateMAHandle()
  {
   MAHandle = iMA(NULL, MA_Timeframe,MA_Period, 0, MODE_SMA, PRICE_CLOSE); // returns a handle for ATR
   ArraySetAsSeries(MAValue,true);       // Set the ATRValue to timeseries, 0 is the oldest.
   if(MQLInfoInteger(MQL_DEBUG) || MQLInfoInteger(MQL_VISUAL_MODE))
     {
      ChartIndicatorAdd(0,0,MAHandle);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetMAValue()
  {
   int      Count = 1;                    // Amount to copy
   if(CopyBuffer(MAHandle,0,0,Count,MAValue) > 0)     // Copy value of ATR to ATRValue
     {
      return MAValue[0];
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
