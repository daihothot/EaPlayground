#ifndef FRAMEWORK_EVENT_HANDLER_MQH
#define FRAMEWORK_EVENT_HANDLER_MQH
#include "event_context.mqh"

class IEventHandler
{
public:
   virtual string       Name()                          = 0;
   virtual EVENT_RESULT Handle(CEventContext& context)  = 0;
};
#endif // FRAMEWORK_EVENT_HANDLER_MQH
