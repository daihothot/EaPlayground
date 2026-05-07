#ifndef FRAMEWORK_STRATEGY_HOST_MQH
#define FRAMEWORK_STRATEGY_HOST_MQH
#include "strategy_registry.mqh"
#include "../dispatcher/event_sink.mqh"
#include "../dispatcher/event_dispatcher.mqh"
#include "../container/service_locator.mqh"
#include "../container/service_keys.mqh"

class CStrategyHost : public IEventSink
{
private:
   IStrategy*         m_strategy;
   CStrategyRegistry* m_registry;  // non-owning

public:
   CStrategyHost() : m_strategy(NULL), m_registry(NULL) {}

   ~CStrategyHost()
   {
      if(m_strategy != NULL)
      {
         delete m_strategy;
         m_strategy = NULL;
      }
   }

   void SetRegistry(CStrategyRegistry* registry) { m_registry = registry; }

   bool Launch(CLauncherBundle* bundle)
   {
      if(bundle == NULL)
      {
         LogError("StrategyHost: bundle is NULL");
         return false;
      }

      if(m_registry == NULL || m_registry.Count() == 0)
      {
         LogError("StrategyHost: no strategies registered");
         return false;
      }

      CStrategyDescriptor desc;
      m_registry.GetDescriptor(0, desc);

      IStrategyFactory* factory = m_registry.Find(desc.Id);
      if(factory == NULL) { LogError("StrategyHost: factory not found"); return false; }

      string reason = "";
      if(!factory.SelfTest(bundle, reason))
      {
         LogError(StringFormat("StrategyHost: self-test failed: %s", reason));
         return false;
      }
      LogInfo("Strategy self-test passed");

      m_strategy = factory.Create(bundle);
      if(m_strategy == NULL) { LogError("StrategyHost: Create returned NULL"); return false; }

      if(!m_strategy.Init())
      {
         LogError("StrategyHost: Init failed");
         delete m_strategy;
         m_strategy = NULL;
         return false;
      }
      LogInfo(StringFormat("Strategy initialized: %s", m_strategy.Name()));

      CEventDispatcher* dispatcher = (CEventDispatcher*)Resolve(SVC_DISPATCHER);
      if(dispatcher == NULL) { LogError("StrategyHost: dispatcher not in container"); return false; }
      dispatcher.Register(GetPointer(this));
      return true;
   }

   void Deinit(const int reason)
   {
      if(m_strategy != NULL)
      {
         m_strategy.Deinit(reason);
         delete m_strategy;
         m_strategy = NULL;
      }
   }

   virtual string Name() override { return "StrategyHost"; }

   virtual void OnEvent(CEventContext& context) override
   {
      if(m_strategy != NULL)
         m_strategy.OnEvent(context);
   }
};
#endif // FRAMEWORK_STRATEGY_HOST_MQH
