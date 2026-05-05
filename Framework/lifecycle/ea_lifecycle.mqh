#ifndef FRAMEWORK_LIFECYCLE_EA_LIFECYCLE_MQH
#define FRAMEWORK_LIFECYCLE_EA_LIFECYCLE_MQH
#include "../launcher/launcher_bundle.mqh"
#include "../dispatcher/event_dispatcher.mqh"
#include "../state/runtime_state.mqh"

class CEaLifecycle
{
private:
   CLauncherBundle*  m_bundle;      // non-owning
   CEventDispatcher* m_dispatcher;  // non-owning
   CRuntimeState     m_state;       // owned

   void DispatchEvent(EVENT_TYPE type, const string msg)
   {
      m_state.LastTickTime = TimeCurrent();
      CEventContext ctx;
      ctx.Bundle    = m_bundle;
      ctx.State     = GetPointer(m_state);
      ctx.Type      = type;
      ctx.Time      = TimeCurrent();
      ctx.Symbol    = m_bundle.Symbol;
      ctx.Timeframe = m_bundle.Timeframe;
      ctx.Message   = msg;
      m_dispatcher.Dispatch(ctx);
   }

public:
   CEaLifecycle() : m_bundle(NULL), m_dispatcher(NULL) {}

   void Init(CLauncherBundle* bundle, CEventDispatcher* dispatcher)
   {
      m_bundle     = bundle;
      m_dispatcher = dispatcher;
      EventSetTimer(m_bundle.TimerSeconds);
   }

   void OnTick()  { DispatchEvent(EVENT_TICK,  "tick"); }

   void OnTimer()
   {
      DispatchEvent(EVENT_TIMER, "timer");
      LogInfo("EVENT_TIMER dispatched");
   }

   void OnDeinit(const int reason) { EventKillTimer(); }
};
#endif // FRAMEWORK_LIFECYCLE_EA_LIFECYCLE_MQH
