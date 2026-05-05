#ifndef STRATEGY_HANDLERS_DUMMY_EXECUTION_HANDLER_MQH
#define STRATEGY_HANDLERS_DUMMY_EXECUTION_HANDLER_MQH
#include "../../Framework/event/event_handler.mqh"

class CDummyExecutionHandler : public IEventHandler
{
public:
   virtual string Name() override { return "DummyExecutionHandler"; }

   virtual EVENT_RESULT Handle(CEventContext& context) override
   {
      LogInfo("DummyExecutionHandler skipped real execution");
      return EVENT_CONTINUE;
   }
};
#endif // STRATEGY_HANDLERS_DUMMY_EXECUTION_HANDLER_MQH
