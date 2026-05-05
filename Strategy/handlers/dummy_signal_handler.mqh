#ifndef STRATEGY_HANDLERS_DUMMY_SIGNAL_HANDLER_MQH
#define STRATEGY_HANDLERS_DUMMY_SIGNAL_HANDLER_MQH
#include "../../Framework/event/event_handler.mqh"

class CDummySignalHandler : public IEventHandler
{
public:
   virtual string Name() override { return "DummySignalHandler"; }

   virtual EVENT_RESULT Handle(CEventContext& context) override
   {
      if(context.SignalId == "new_bar" || context.SignalId == "timer")
         LogDebug("DummySignalHandler: no signal");
      return EVENT_CONTINUE;
   }
};
#endif // STRATEGY_HANDLERS_DUMMY_SIGNAL_HANDLER_MQH
