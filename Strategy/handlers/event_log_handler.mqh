#ifndef STRATEGY_HANDLERS_EVENT_LOG_HANDLER_MQH
#define STRATEGY_HANDLERS_EVENT_LOG_HANDLER_MQH
#include "../../Framework/event/event_handler.mqh"

class CEventLogHandler : public IEventHandler
{
public:
   virtual string Name() override { return "EventLogHandler"; }

   virtual EVENT_RESULT Handle(CEventContext& context) override
   {
      LogDebug(StringFormat("[%s] %s", context.SignalId, context.Message));
      return EVENT_CONTINUE;
   }
};
#endif // STRATEGY_HANDLERS_EVENT_LOG_HANDLER_MQH
