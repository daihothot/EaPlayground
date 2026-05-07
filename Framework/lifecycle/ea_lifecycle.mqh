#ifndef FRAMEWORK_LIFECYCLE_EA_LIFECYCLE_MQH
#define FRAMEWORK_LIFECYCLE_EA_LIFECYCLE_MQH
#include "../launcher/launcher_bundle.mqh"
#include "../dispatcher/event_dispatcher.mqh"
#include "../state/runtime_state.mqh"
#include "../signal/signal_collector.mqh"
#include "../signal/builtin_sources.mqh"
#include "../timer/timer_scheduler.mqh"
#include "../container/service_container.mqh"
#include "../container/service_locator.mqh"
#include "../container/service_keys.mqh"

class CEaLifecycle
{
public:
   void Init(CLauncherBundle* bundle)
   {
      if(bundle == NULL) { LogError("Lifecycle: bundle is NULL"); return; }

      LogSetLevel(bundle.MinLogLevel);

      // Root container is owned by the locator — just ask it to come up.
      InitContainer();
      CServiceContainer* root = Container();

      root.RegisterRef(SVC_BUNDLE, bundle);
      root.Register(SVC_RUNTIME_STATE, new CRuntimeState());
      root.Register(SVC_DISPATCHER,    new CEventDispatcher());
      root.Register(SVC_COLLECTOR,     new CSignalCollector());
      root.Register(SVC_SCHEDULER,     new CTimerScheduler());

      // Wire collector with built-in signal sources.
      CSignalCollector* collector = (CSignalCollector*)Resolve(SVC_COLLECTOR);
      collector.Init();
      collector.Register(new CTickSignalSource());
      collector.Register(new CNewBarSignalSource());

      EventSetTimer(bundle.TimerSeconds);
   }

   void OnTick()  { ((CSignalCollector*)Resolve(SVC_COLLECTOR)).Collect(); }
   void OnTimer() { ((CTimerScheduler*) Resolve(SVC_SCHEDULER)).Tick();    }

   void OnDeinit(const int reason)
   {
      EventKillTimer();
   }

   void Shutdown()
   {
      ShutdownContainer();
   }
};
#endif // FRAMEWORK_LIFECYCLE_EA_LIFECYCLE_MQH
