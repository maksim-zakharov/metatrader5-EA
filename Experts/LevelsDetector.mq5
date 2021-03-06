//+------------------------------------------------------------------+
//|                                               LevelsDetector.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <ObjectService.mqh>;
#include <Utills.mqh>;

input const uint candlesCount = 1800; // Количество свечей для анализа

input uint precision = 2; // Точность (зависит от количества чисел после запятой)

input const uint maxLevelsCount = 3; // Количество уровней для отображения
input long magic_number=55555; // Уникальный номер советника

uint priceRoundPrecision = 1; // Точность округления цены уровней
int normolizeDigits = 3;
long lastTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   normolizeDigits = Digits() - precision;
   for(uint i = 0; i < precision; i++){
   priceRoundPrecision *= 10;
   }

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
