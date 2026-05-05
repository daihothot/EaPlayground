#ifndef STRATEGY_HANDLERS_EVENT_LOG_HANDLER_MQH
#define STRATEGY_HANDLERS_EVENT_LOG_HANDLER_MQH
#include "../../Framework/event/event_handler.mqh"

class CEventLogHandler : public IEventHandler
{
public:
   virtual string Name() override { return "EventLogHandler"; }

   virtual EVENT_RESULT Handle(CEventContext& context) override
   {
      string typeName;
      switch(context.Type)
      {
         case EVENT_TICK:    typeName = "TICK";    break;
         case EVENT_NEW_BAR: typeName = "NEW_BAR"; break;
         case EVENT_TIMER:   typeName = "TIMER";   break;
         default:            typeName = "UNKNOWN"; break;
      }
      LogDebug(StringFormat("[%s] %s", typeName, context.Message));
      return EVENT_CONTINUE;
   }
};
#endif // STRATEGY_HANDLERS_EVENT_LOG_HANDLER_MQH
