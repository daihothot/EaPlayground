#ifndef FRAMEWORK_DISPATCHER_EVENT_SINK_MQH
#define FRAMEWORK_DISPATCHER_EVENT_SINK_MQH
#include "../event/event_context.mqh"

class IEventSink
{
public:
   virtual string Name()                              = 0;
   virtual void   OnEvent(CEventContext& context)     = 0;
};
#endif // FRAMEWORK_DISPATCHER_EVENT_SINK_MQH
