//+------------------------------------------------------------------+
//|                                                 EaPlayground.mq5 |
//|                                             Copyright 2026, DAI. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include "Framework/launcher/launcher.mqh"
#include "Framework/lifecycle/ea_lifecycle.mqh"
#include "Framework/strategy/strategy_host.mqh"
#include "Strategy/strategy_entry.mqh"

input LOG_LEVEL InpMinLogLevel    = LOG_INFO;
input int       InpTimerSeconds   = 5;
input int       InpMaxSpreadPoints = 300;
input long      InpMagicNumber    = 12345;

CLauncher    g_launcher;
CEaLifecycle g_lifecycle;
CStrategyRegistry g_registry;
CStrategyHost     g_host;

int OnInit()
{
   g_launcher.ConfigureInputs(InpMinLogLevel, InpTimerSeconds, InpMaxSpreadPoints, InpMagicNumber);

   // Configure the global container first — after this, any module can Resolve().
   g_lifecycle.Init(g_launcher.Bundle());

   if(Container() == NULL)
      return INIT_FAILED;

   LogInfo("EaPlayground initializing");

   RegisterStrategies(GetPointer(g_registry));
   g_host.SetRegistry(GetPointer(g_registry));

   if(!g_host.Launch(g_launcher.Bundle()))
      return INIT_FAILED;

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   g_lifecycle.OnDeinit(reason);

   CServiceContainer* container = Container();
   if(container != NULL)
   {
      CEventDispatcher* dispatcher = (CEventDispatcher*)container.Resolve(SVC_DISPATCHER);
      if(dispatcher != NULL)
         dispatcher.Unregister(GetPointer(g_host));
   }

   g_host.Deinit(reason);
   g_lifecycle.Shutdown();
}
void OnTick()                   { g_lifecycle.OnTick(); }
void OnTimer()                  { g_lifecycle.OnTimer(); }
