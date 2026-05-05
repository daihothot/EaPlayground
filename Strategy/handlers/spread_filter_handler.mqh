#ifndef STRATEGY_HANDLERS_SPREAD_FILTER_HANDLER_MQH
#define STRATEGY_HANDLERS_SPREAD_FILTER_HANDLER_MQH
#include "../../Framework/event/event_handler.mqh"

class CSpreadFilterHandler : public IEventHandler
{
public:
   virtual string Name() override { return "SpreadFilterHandler"; }

   virtual EVENT_RESULT Handle(CEventContext& context) override
   {
      if(context.Bundle == NULL) return EVENT_CONTINUE;
      int spread = (int)SymbolInfoInteger(context.Symbol, SYMBOL_SPREAD);
      if(spread > context.Bundle.MaxSpreadPoints)
      {
         LogWarning(StringFormat("SpreadFilter: spread %d > max %d, skipping", spread, context.Bundle.MaxSpreadPoints));
         return EVENT_STOP;
      }
      return EVENT_CONTINUE;
   }
};
#endif // STRATEGY_HANDLERS_SPREAD_FILTER_HANDLER_MQH
