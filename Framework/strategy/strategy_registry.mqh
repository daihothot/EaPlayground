#ifndef FRAMEWORK_STRATEGY_REGISTRY_MQH
#define FRAMEWORK_STRATEGY_REGISTRY_MQH
#include "strategy_factory.mqh"

class CStrategyDescriptor
{
public:
   string Id;
   string Name;
   string Version;
   string Description;
   bool   EnabledByDefault;

   CStrategyDescriptor() : EnabledByDefault(true) {}
};

class CStrategyRegistry
{
private:
   CStrategyDescriptor m_descriptors[];
   IStrategyFactory*   m_factories[];
   int                 m_count;

public:
   CStrategyRegistry() : m_count(0) {}

   ~CStrategyRegistry()
   {
      for(int i = 0; i < m_count; i++)
         delete m_factories[i];
   }

   bool Register(CStrategyDescriptor& desc, IStrategyFactory* factory)
   {
      if(factory == NULL) { LogError("Registry: factory is NULL"); return false; }
      for(int i = 0; i < m_count; i++)
         if(m_descriptors[i].Id == desc.Id) { LogError(StringFormat("Registry: duplicate id '%s'", desc.Id)); return false; }

      ArrayResize(m_descriptors, m_count + 1);
      ArrayResize(m_factories,   m_count + 1);
      m_descriptors[m_count] = desc;
      m_factories[m_count]   = factory;
      m_count++;
      LogInfo(StringFormat("Strategy registered: %s", desc.Id));
      return true;
   }

   IStrategyFactory* Find(const string id)
   {
      for(int i = 0; i < m_count; i++)
         if(m_descriptors[i].Id == id) return m_factories[i];
      return NULL;
   }

   int Count() const { return m_count; }

   bool GetDescriptor(int index, CStrategyDescriptor& out)
   {
      if(index < 0 || index >= m_count) return false;
      out = m_descriptors[index];
      return true;
   }
};
#endif // FRAMEWORK_STRATEGY_REGISTRY_MQH
