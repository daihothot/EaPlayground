#ifndef FRAMEWORK_LAUNCHER_MQH
#define FRAMEWORK_LAUNCHER_MQH
#include "launcher_bundle.mqh"
#include "../strategy/strategy_registry.mqh"
#include "../strategy/strategy_host.mqh"
#include "../dispatcher/event_dispatcher.mqh"

class CLauncher
{
private:
   CLauncherBundle   m_bundle;
   CStrategyRegistry m_registry;
   CStrategyHost     m_host;
   CEventDispatcher  m_dispatcher;

public:
   CLauncherBundle*   Bundle()     { return GetPointer(m_bundle); }
   CStrategyRegistry* Registry()   { return GetPointer(m_registry); }
   CEventDispatcher*  Dispatcher() { return GetPointer(m_dispatcher); }
   CStrategyHost*     Host()       { return GetPointer(m_host); }

   int Launch()
   {
      LogSetLevel(m_bundle.MinLogLevel);
      LogInfo("EaPlayground initializing");

      m_host.SetRegistry(GetPointer(m_registry));
      if(!m_host.Launch(m_bundle, GetPointer(m_dispatcher)))
         return INIT_FAILED;

      return INIT_SUCCEEDED;
   }

   void Teardown(const int reason)
   {
      m_dispatcher.Unregister(GetPointer(m_host));
      m_host.Deinit(reason);
   }
};
#endif // FRAMEWORK_LAUNCHER_MQH
