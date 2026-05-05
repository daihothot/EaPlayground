#ifndef FRAMEWORK_STRATEGY_INTERFACE_MQH
#define FRAMEWORK_STRATEGY_INTERFACE_MQH
#include "../event/event_context.mqh"

class IStrategy
{
public:
   virtual string Name()                          = 0;
   virtual bool   Init()                          = 0;
   virtual void   Deinit(const int reason)        = 0;
   virtual void   OnEvent(CEventContext& context) = 0;
};
#endif // FRAMEWORK_STRATEGY_INTERFACE_MQH
