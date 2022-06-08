//+------------------------------------------------------------------+
//|                                                        Utils.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBearishTrend(int candlesCount)
  {
   return iC(0) - iO(candlesCount) < 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBullishTrend(int candlesCount)
  {
   return iC(0) - iO(candlesCount) > 0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Round(double& value, int digits)
  {
   if(digits > -1)
     {
      value = NormalizeDouble(value, digits);
     }
   else
     {
      for(int i = 0; i > digits; i--)
        {
         value /= 10;
        }
      value = NormalizeDouble(value, -digits);
      for(int i = 0; i > digits; i--)
        {
         value *= 10;
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int TrueArraySearch(double& array[], double value)
  {
   const int arraySize = ArraySize(array);
   for(int i = 0; i<arraySize; i++)
     {
      if(array[i] == value)
        {
         return i;
        }
     }
   return -1;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/**
{
[1.03]: 1,
[1.04]: 5,
[1.05]: 4,
[1.06]: 3,
[1.07]: 6,
[1.08]: 5,
[1.09]: 9,
}
**/
void SortArray(double& arrayKeys[], int& arrayValues[], bool desc)
  {
   const int arraySize = ArraySize(arrayValues);
   bool swapped = true;
   do
     {
      swapped = false;
      for(int i = 0; i < arraySize - 1; i++)
        {
         const bool descSort = desc && arrayValues[i + 1] > arrayValues[i];
         const bool ascSort = !desc && arrayValues[i + 1] < arrayValues[i];
         if(ascSort || descSort)
           {
            double temp = arrayKeys[i];
            arrayKeys[i] = arrayKeys[i + 1];
            arrayKeys[i + 1] = temp;

            int tempInt = arrayValues[i];
            arrayValues[i] = arrayValues[i + 1];
            arrayValues[i + 1] = tempInt;

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
