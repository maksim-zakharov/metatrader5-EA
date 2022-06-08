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
void CreateHLine(double price, string name, string descr = "", color objColor = clrRed, ENUM_LINE_STYLE levelStyle = STYLE_SOLID)
  {
   if(ObjectFind(0, name) < 0)
     {
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
     }
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetString(0,name,OBJPROP_TEXT,descr);
   ObjectSetInteger(0, name, OBJPROP_COLOR, objColor);
   ObjectSetInteger(0, name, OBJPROP_STYLE, levelStyle);
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
