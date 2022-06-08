//+------------------------------------------------------------------+
//|                                                ObjectService.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
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
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectDeleteAllByType(ENUM_OBJECT  type)
  {
   const int objectTotal = ObjectsTotal(0, 0, type);

   for(int i= objectTotal-1; i>=0; i--)
     {
      const string objectName = ObjectName(0, i, 0, type);
      ObjectDelete(0, objectName);
     }
  }
//+------------------------------------------------------------------+
