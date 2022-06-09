//+------------------------------------------------------------------+
//|                                                 OrderService.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CancelAllStopOrder(int order_magic = -1)
  {
   const int ordersTotal = OrdersTotal();

   for(int i = 0; i< ordersTotal; i++)
     {
      CancelStopOrder(i, order_magic);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CancelStopOrder(int index, int order_magic = -1)
  {
//-- объявление и инициализация запроса и результата
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
//--- перебор всех установленных отложенных ордеров
   ulong  order_ticket=OrderGetTicket(index);                   // тикет ордера
   ulong  magic=OrderGetInteger(ORDER_MAGIC);               // MagicNumber ордера
//--- если MagicNumber совпадает
   if(order_magic > -1 && magic!=order_magic)
     {
      return;
     }
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
void OrderSellLimit(double price, double sl, double tp, double volume)
  {
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
//--- параметры запроса
   request.action   =TRADE_ACTION_PENDING;                     // тип торговой операции
   request.symbol   =Symbol();                              // символ
   request.volume   =volume;                                   // объем в 0.2 лот
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
void OrderBuyLimit(double price, double sl, double tp, double volume)
  {
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
//--- параметры запроса
   request.action   =TRADE_ACTION_PENDING;                     // тип торговой операции
   request.symbol   =Symbol();                              // символ
   request.volume   =volume;                                   // объем в 0.1 лот
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
void OrderSellStop(double price, double sl, double tp, double volume)
  {
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
//--- параметры запроса
   request.action   =TRADE_ACTION_PENDING;                     // тип торговой операции
   request.symbol   =Symbol();                              // символ
   request.volume   =volume;                                   // объем в 0.2 лот
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
void OrderBuyStop(double price, double sl, double tp, double volume)
  {
   MqlTradeRequest request= {};
   MqlTradeResult  result= {};
//--- параметры запроса
   request.action   =TRADE_ACTION_PENDING;                     // тип торговой операции
   request.symbol   =Symbol();                              // символ
   request.volume   =volume;                                   // объем в 0.1 лот
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
bool OrderFind(double openPrice, ENUM_ORDER_TYPE orderType, int digits = -1)
  {
   const int ordersTotal = OrdersTotal();
   for(int i = 0; i < ordersTotal; i++)
     {
      const int orderTicket = OrderGetTicket(i);
      if(OrderSelect(orderTicket))
        {
         double orderOpenPrice = OrderGetDouble(ORDER_PRICE_OPEN);
         if(digits > -1)
           {
            orderOpenPrice = NormalizeDouble(orderOpenPrice, digits);
            openPrice = NormalizeDouble(openPrice, digits);
           }
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
uint GetOrdersTotal(string symbol, int magicNumber)
  {
   uint resultTotal = 0;

   if(symbol == NULL)
     {
      symbol = _Symbol;
     }

   const int total = OrdersTotal();
   for(int i = 0; i < total; i++)
     {
      const int ticket = OrderGetTicket(i);
      if(!OrderSelect(ticket))
        {
         continue;
        }

      const int positionMagic = OrderGetInteger(ORDER_MAGIC);
      const string positionSymbol = OrderGetString(ORDER_SYMBOL);
      if(positionMagic == magicNumber && positionSymbol == symbol)
        {
         resultTotal++;
        }
     }

   return resultTotal;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
uint GetPositionsTotal(string symbol, int magicNumber)
  {
   uint resultTotal = 0;

   if(symbol == NULL)
     {
      symbol = _Symbol;
     }

   const int total = PositionsTotal();
   for(int i = 0; i < total; i++)
     {
      const int ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket))
        {
         continue;
        }

      const int positionMagic = PositionGetInteger(POSITION_MAGIC);
      const string positionSymbol = PositionGetSymbol(i);
      if(positionMagic == magicNumber && positionSymbol == symbol)
        {
         resultTotal++;
        }
     }

   return resultTotal;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PositionFind(double openPrice, ENUM_POSITION_TYPE orderType, int digits = -1)
  {

   const int ordersTotal = PositionsTotal();
   for(int i = 0; i < ordersTotal; i++)
     {
      const int orderTicket = PositionGetTicket(i);
      if(PositionSelect(orderTicket))
        {
         double orderOpenPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         if(digits > -1)
           {
            orderOpenPrice = NormalizeDouble(orderOpenPrice, digits);
            openPrice = NormalizeDouble(openPrice, digits);
           }

         const ENUM_POSITION_TYPE orderOpenType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(orderOpenType == orderType && openPrice == orderOpenPrice)
           {
            return true;
           }
        }
     }

   return false;
  }
//+------------------------------------------------------------------+
