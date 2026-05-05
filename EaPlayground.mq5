//+------------------------------------------------------------------+
//|                                                 EaPlayground.mq5 |
//|                                             Copyright 2026, DAI. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#include "Framework/launcher/launcher.mqh"
#include "Framework/lifecycle/ea_lifecycle.mqh"
#include "Strategy/strategy_entry.mqh"

input LOG_LEVEL InpMinLogLevel    = LOG_INFO;
input int       InpTimerSeconds   = 5;
input int       InpMaxSpreadPoints = 300;
input long      InpMagicNumber    = 12345;

CLauncher    g_launcher;
CEaLifecycle g_lifecycle;

int OnInit()
{
   g_launcher.Bundle().MinLogLevel      = InpMinLogLevel;
   g_launcher.Bundle().TimerSeconds     = InpTimerSeconds;
   g_launcher.Bundle().MaxSpreadPoints  = InpMaxSpreadPoints;
   g_launcher.Bundle().MagicNumber      = InpMagicNumber;

   RegisterStrategies(g_launcher.Registry());

   // Configure the global container first — after this, any module can Resolve().
   g_lifecycle.Init(g_launcher.Bundle());

   return g_launcher.Launch();
}

void OnDeinit(const int reason)
{
   g_lifecycle.OnDeinit(reason);
   g_launcher.Teardown(reason);
   g_lifecycle.Shutdown();
}
void OnTick()                   { g_lifecycle.OnTick(); }
void OnTimer()                  { g_lifecycle.OnTimer(); }
