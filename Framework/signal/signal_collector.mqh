#ifndef FRAMEWORK_SIGNAL_COLLECTOR_MQH
#define FRAMEWORK_SIGNAL_COLLECTOR_MQH
#include <Object.mqh>
#include "signal_source.mqh"
#include "../event/event_context.mqh"
#include "../dispatcher/event_dispatcher.mqh"
#include "../launcher/launcher_bundle.mqh"
#include "../container/service_locator.mqh"
#include "../container/service_keys.mqh"

class CSignalCollector : public CObject
{
private:
   ISignalSource* m_sources[];
   int            m_count;

   void InsertSorted(ISignalSource* source)
   {
      ArrayResize(m_sources, m_count + 1);
      int i = m_count;
      while(i > 0 && m_sources[i-1].Priority() > source.Priority())
      {
         m_sources[i] = m_sources[i-1];
         i--;
      }
      m_sources[i] = source;
      m_count++;
   }

public:
   CSignalCollector() : m_count(0) { ArrayResize(m_sources, 0); }

   ~CSignalCollector()
   {
      for(int i = 0; i < m_count; i++)
         delete m_sources[i];
   }

   // Init remains for symmetry / future setup; dependencies resolved lazily.
   void Init() { }

   void Register(ISignalSource* source) { InsertSorted(source); }

   void Collect()
   {
      CRuntimeState*    state      = (CRuntimeState*)   Resolve(SVC_RUNTIME_STATE);
      CLauncherBundle*  bundle     = (CLauncherBundle*) Resolve(SVC_BUNDLE);
      CEventDispatcher* dispatcher = (CEventDispatcher*)Resolve(SVC_DISPATCHER);

      for(int i = 0; i < m_count; i++)
      {
         CSignal* signal = NULL;
         if(!m_sources[i].Check(signal) || signal == NULL)
            continue;

         m_sources[i].Project(*state, signal);

         CEventContext ctx;
         ctx.Bundle    = bundle;
         ctx.State     = state;
         ctx.SignalId  = signal.Id();
         ctx.Time      = TimeCurrent();
         ctx.Symbol    = bundle.Symbol;
         ctx.Timeframe = bundle.Timeframe;

         dispatcher.Dispatch(ctx);
         delete signal;
      }
   }
};
#endif // FRAMEWORK_SIGNAL_COLLECTOR_MQH
