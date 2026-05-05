#ifndef FRAMEWORK_STRATEGY_FACTORY_MQH
#define FRAMEWORK_STRATEGY_FACTORY_MQH
#include "strategy_interface.mqh"
#include "../launcher/launcher_bundle.mqh"

class IStrategyFactory
{
public:
   virtual string    Id()                                              = 0;
   virtual bool      SelfTest(CLauncherBundle& bundle, string& reason) = 0;
   virtual IStrategy* Create(CLauncherBundle& bundle)                  = 0;
};
#endif // FRAMEWORK_STRATEGY_FACTORY_MQH
