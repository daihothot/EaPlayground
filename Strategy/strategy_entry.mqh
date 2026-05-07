#ifndef STRATEGY_ENTRY_MQH
#define STRATEGY_ENTRY_MQH
#include "../Framework/strategy/strategy_interface.mqh"
#include "../Framework/strategy/strategy_registry.mqh"
#include "../Framework/event/event_chain.mqh"
#include "handlers/event_log_handler.mqh"
#include "handlers/spread_filter_handler.mqh"
#include "handlers/dummy_signal_handler.mqh"
#include "handlers/dummy_execution_handler.mqh"

class CDummyStrategy : public IStrategy
{
private:
   CEventChain m_chain;

public:
   CDummyStrategy()
   {
      m_chain.Add(new CEventLogHandler());
      m_chain.Add(new CSpreadFilterHandler());
      m_chain.Add(new CDummySignalHandler());
      m_chain.Add(new CDummyExecutionHandler());
   }

   virtual string Name() override { return "DummyStrategy"; }

   virtual bool Init() override { return true; }

   virtual void Deinit(const int reason) override {}

   virtual void OnEvent(CEventContext& context) override
   {
      m_chain.Dispatch(context);
   }
};

class CDummyStrategyFactory : public IStrategyFactory
{
public:
   virtual string Id() override { return "dummy"; }

   virtual bool SelfTest(CLauncherBundle* bundle, string& reason) override
   {
      return true;
   }

   virtual IStrategy* Create(CLauncherBundle* bundle) override
   {
      return new CDummyStrategy();
   }
};

void RegisterStrategies(CStrategyRegistry* registry)
{
   CStrategyDescriptor desc;
   desc.Id      = "dummy";
   desc.Name    = "DummyStrategy";
   desc.Version = "1.0";
   registry.Register(desc, new CDummyStrategyFactory());
}
#endif // STRATEGY_ENTRY_MQH
