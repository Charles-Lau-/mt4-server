//+------------------------------------------------------------------+
//| Module: MqlCommand.mqh                                           |
//| This file is part of the mt4-server project:                     |
//|     https://github.com/dingmaotu/mt4-server                      |
//|                                                                  |
//| Copyright 2017 Li Ding <dingmaotu@hotmail.com>                   |
//|                                                                  |
//| Licensed under the Apache License, Version 2.0 (the "License");  |
//| you may not use this file except in compliance with the License. |
//| You may obtain a copy of the License at                          |
//|                                                                  |
//|     http://www.apache.org/licenses/LICENSE-2.0                   |
//|                                                                  |
//| Unless required by applicable law or agreed to in writing,       |
//| software distributed under the License is distributed on an      |
//| "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,     |
//| either express or implied.                                       |
//| See the License for the specific language governing permissions  |
//| and limitations under the License.                               |
//+------------------------------------------------------------------+
#property strict
#include <Mql/Trade/FxSymbol.mqh>
#include <Mql/Trade/OrderPool.mqh>
#include <Mql/Trade/Account.mqh>
#include <Mql/Trade/Order.mqh>
#include <Mql/Format/Resp.mqh>
//+------------------------------------------------------------------+
//| Wraps a specific MQL command                                     |
//+------------------------------------------------------------------+
interface MqlCommand
  {
   RespValue        *call(const RespArray &command);
  };
//+------------------------------------------------------------------+
//| Get all orders in the Trade Pool                                 |
//| Syntax: ORDERS                                                   |
//| Results:                                                         |
//|   Success: Array of orders in string format                      |
//|   Success: Nil if no orders                                      |
//|   Fail:    RespError                                             |
//+------------------------------------------------------------------+

class HistoricalOrdersCommand: public MqlCommand
  {
private:
   HistoryPool       m_pool;
public:
   RespValue        *call(const RespArray &command)
     {
      int total= m_pool.total();
      if(total==0) return RespNil::getInstance();
      RespArray *res=new RespArray(total);
      for(int i=0; i<total;i++)
        {
         if(m_pool.select(i))
           {
            Order o;
            res.set(i,new RespString(o.toString()));
           }
         else
           {
            res.set(i,RespNil::getInstance());
           }
        }
      return res;
     }
  };
  

class OrdersCommand: public MqlCommand
  {
private:
   TradingPool       m_pool;
public:
   RespValue        *call(const RespArray &command)
     {
      int total=m_pool.total();
      if(total==0) return RespNil::getInstance();
      RespArray *res=new RespArray(total);
      for(int i=0; i<total;i++)
        {
         if(m_pool.select(i))
           {
            Order o;
            res.set(i,new RespString(o.toString()));
           }
         else
           {
            res.set(i,RespNil::getInstance());
           }
        }
      return res;
     }
  };
//+------------------------------------------------------------------+
//| Buy at market price                                              |
//| Syntax: BUY Symbol Lots  Stop  Profit                                        |
//| Results:                                                         |
//|   Success: Order id (RespInteger)                                |
//|   Fail:    RespError                                             |
//+------------------------------------------------------------------+
class BuyCommand: public MqlCommand
  {
public:
   RespValue        *call(const RespArray &command)
     {
     
      if(command.size()< 5) return new RespError("Invalid number of arguments for command BUY!");
      string symbol=dynamic_cast<RespBytes*>(command[1]).getValueAsString();
      double lots=StringToDouble(dynamic_cast<RespBytes*>(command[2]).getValueAsString());
      int stopPoints = StringToInteger(dynamic_cast<RespBytes*>(command[3]).getValueAsString());
      int profitPoints = StringToInteger(dynamic_cast<RespBytes*>(command[4]).getValueAsString());
      int id = -1;
      if(stopPoints == 0 && profitPoints == 0)
          id=OrderSend(symbol,OP_BUY,lots,FxSymbol::getAsk(symbol),3,0,0,NULL,0,0,clrNONE);
      else if(profitPoints == 0) 
           id=OrderSend(symbol,OP_BUY,lots,FxSymbol::getAsk(symbol),3, FxSymbol::getAsk(symbol) - stopPoints*Point,0,NULL,0,0,clrNONE);
      else
          id=OrderSend(symbol,OP_BUY,lots,FxSymbol::getAsk(symbol),3, FxSymbol::getAsk(symbol) - stopPoints*Point, FxSymbol::getAsk(symbol) + profitPoints*Point ,NULL,0,0,clrNONE);
      
      if(id==-1)
        {
         int ec=Mql::getLastError();
         return new RespError(StringFormat("Failed to buy at market with error id (%d): %s",
                              ec,Mql::getErrorMessage(ec)));
        }
      else
        {
         return new RespInteger(id);
        }
     }
  };
//+------------------------------------------------------------------+
//| Sell at market price                                             |
//| Syntax: SELL Symbol Lots                                         |
//| Results:                                                         |
//|   Success: Order id (RespInteger)                                |
//|   Fail:    RespError                                             |
//+------------------------------------------------------------------+
class SellCommand: public MqlCommand
  {
public:
   RespValue        *call(const RespArray &command)
     {
      if(command.size() < 5) return new RespError("Invalid number of arguments for command SELL!");
      string symbol=dynamic_cast<RespBytes*>(command[1]).getValueAsString();
      double lots=StringToDouble(dynamic_cast<RespBytes*>(command[2]).getValueAsString());
      int stopPoints = StringToInteger(dynamic_cast<RespBytes*>(command[3]).getValueAsString());
      int profitPoints = StringToInteger(dynamic_cast<RespBytes*>(command[4]).getValueAsString());
      int id = -1;
      
      if(stopPoints == 0 && profitPoints == 0)
          id=OrderSend(symbol,OP_SELL,lots,FxSymbol::getBid(symbol),3,0,0,NULL,0,0,clrNONE);
      else if(profitPoints == 0) 
           id=OrderSend(symbol,OP_SELL,lots,FxSymbol::getBid(symbol),3, FxSymbol::getBid(symbol) + stopPoints*Point,0,NULL,0,0,clrNONE);
      else
          id=OrderSend(symbol,OP_SELL,lots,FxSymbol::getBid(symbol),3, FxSymbol::getBid(symbol) + stopPoints*Point, FxSymbol::getBid(symbol) - profitPoints*Point ,NULL,0,0,clrNONE);
       
      if(id==-1)
        {
         int ec=Mql::getLastError();
         return new RespError(StringFormat("Failed to sell at market with error id (%d): %s",
                              ec,Mql::getErrorMessage(ec)));
        }
      else
        {
         return new RespInteger(id);
        }
     }
  };
//+------------------------------------------------------------------+
//| Close a market order                                             |
//| Syntax: CLOSE Ticket Lots                                        |
//| Results:                                                         |
//|   Success: Order id (RespInteger)                                |
//|   Fail:    RespError                                             |
//+------------------------------------------------------------------+
class CloseCommand: public MqlCommand
{
private:
     TradingPool *m_pool; 

public:
   CloseCommand(){
      m_pool  = new TradingPool(); 
   }
   ~CloseCommand(){
     SafeDelete(m_pool); 
   }
   RespValue *call(const RespArray &command)
     {
      if(command.size() < 2  || command.size() > 4) return new RespError("Invalid number of arguments for command CLOSE!");
      //check whether it is integer or all
      string actor = dynamic_cast<RespBytes*>(command[1]).getValueAsString(); 
    

      if(StringCompare(actor, "all", false) == 0){ 
            for(int i=0;i < m_pool.total();){
                RefreshRates();
                if(!m_pool.select(i)|| !OrderClose(Order::Ticket(),Order::Lots(),FxSymbol::priceForClose(Order::Symbol(), Order::Type()),3,clrNONE))
                  {
                        int ec=Mql::getLastError();
                        return new RespError(StringFormat("Failed to close market order  with error id (%d): %s",
                                ec,Mql::getErrorMessage(ec)));
                  }   
            }                             
              
      }
      else if(StringCompare(actor, "sell", false) == 0 || StringCompare(actor, "buy", false) == 0){ 
           int type = 0;
           if(StringCompare(actor, "sell", false) == 0)
               type =  OP_SELL;
           else if(StringCompare(actor, "buy", false) == 0) 
               type  = OP_BUY;
           for(int i=0;i < m_pool.total();){
                if(m_pool.select(i))
                  {  
                  
                   //skip order type not in targe
                   if(Order::Type() != type) {
                     i++;
                     continue;  
                   }
                   //skip symbol not in target
                   if(command.size() >= 3){
                     string requireSymbol = dynamic_cast<RespBytes*>(command[2]).getValueAsString();
                     if(StringCompare(requireSymbol, "all", false) == 0) ;
                     else{
                        if(StringCompare(Order::Symbol(), requireSymbol, false) != 0) {
                           i++;
                           continue;
                        }
                     }
                   }
                   //skip orders of which profitable is not with required
                   if(command.size() == 4){
                       string modifier = dynamic_cast<RespBytes*>(command[3]).getValueAsString();
                       Print("the profit is ", Order::Profit());
                       if(StringCompare(modifier, "loss", false) == 0 && Order::Profit() > 0) {i++;continue;}
                       else if(StringCompare(modifier, "profit", false) == 0  && Order::Profit() < 0) {i++;continue;}
                   }
                   RefreshRates();
                   if(OrderClose(Order::Ticket(),Order::Lots(),FxSymbol::priceForClose(Order::Symbol(), Order::Type()),3,clrNONE));
                   else
                     {
                        int ec=Mql::getLastError();
                        return new RespError(StringFormat("Failed to close market order   with error id (%d): %s",
                             ec,Mql::getErrorMessage(ec)));
                     }
                  }
                else
                    {
                       int ec=Mql::getLastError();
                        return new RespError(StringFormat("Failed to close market order with error id (%d): %s",
                              ec,Mql::getErrorMessage(ec)));
                  
                    }   
            }   
      }
      else{
        int ticket=(int)StringToInteger(actor);
        if(!Order::Select(ticket))
         {
          return new RespError("Order does not exist!");
         }
         string symbol=Order::Symbol();
         int op=Order::Type();
         double lots= Order::Lots();
       /*if(command.size()==2)
        {
         lots=Order::Lots();
        }
       else
        {
         lots=StringToDouble(dynamic_cast<RespBytes*>(command[2]).getValueAsString());
        }*/
         RefreshRates();
         if(!OrderClose(ticket,lots,FxSymbol::priceForClose(symbol,op),3,clrNONE))
          {
           int ec=Mql::getLastError();
           return new RespError(StringFormat("Failed to close market order #%d with error id (%d): %s",
                              ticket,ec,Mql::getErrorMessage(ec)));
          }
         
       }
       
      return new RespString("Ok");
  }
 };
//+------------------------------------------------------------------+
//| Quit server connection                                           |
//| Syntax: QUIT                                                     |
//| Results:                                                         |
//|   The server will close the connection                           |
//+------------------------------------------------------------------+
class QuitCommand: public MqlCommand
  {
public:
   RespValue        *call(const RespArray &command)
     {
      return NULL;
     }
  };
//+------------------------------------------------------------------+
