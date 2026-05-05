#ifndef FRAMEWORK_CONTAINER_SERVICE_CONTAINER_MQH
#define FRAMEWORK_CONTAINER_SERVICE_CONTAINER_MQH
#include <Object.mqh>
#include "../log/logger.mqh"

class IServiceFactory
{
public:
   virtual CObject* Create() = 0;
};

struct SServiceEntry
{
   string   Key;
   CObject* Instance;
   bool     OwnInstance;
};

class CServiceContainer
{
private:
   SServiceEntry       m_entries[];
   int                 m_count;
   CServiceContainer*  m_parent;        // non-owning
   CServiceContainer*  m_children[];    // owned
   int                 m_childCount;

   int FindIndex(const string key)
   {
      for(int i = 0; i < m_count; i++)
         if(m_entries[i].Key == key) return i;
      return -1;
   }

   void AddEntry(const string key, CObject* instance, bool own)
   {
      int idx = FindIndex(key);
      if(idx >= 0)
      {
         if(m_entries[idx].OwnInstance && m_entries[idx].Instance != NULL)
            delete m_entries[idx].Instance;
         m_entries[idx].Instance    = instance;
         m_entries[idx].OwnInstance = own;
         return;
      }
      ArrayResize(m_entries, m_count + 1);
      m_entries[m_count].Key         = key;
      m_entries[m_count].Instance    = instance;
      m_entries[m_count].OwnInstance = own;
      m_count++;
   }

   int FindChildIndex(CServiceContainer* child)
   {
      for(int i = 0; i < m_childCount; i++)
         if(m_children[i] == child) return i;
      return -1;
   }

public:
   CServiceContainer() : m_count(0), m_parent(NULL), m_childCount(0)
   {
      ArrayResize(m_entries, 0);
      ArrayResize(m_children, 0);
   }

   ~CServiceContainer()
   {
      // Dispose child scopes first (LIFO), then own services (reverse registration order).
      for(int i = m_childCount - 1; i >= 0; i--)
         if(m_children[i] != NULL) delete m_children[i];

      for(int j = m_count - 1; j >= 0; j--)
         if(m_entries[j].OwnInstance && m_entries[j].Instance != NULL)
            delete m_entries[j].Instance;
   }

   void SetParent(CServiceContainer* parent) { m_parent = parent; }

   // owned instance — container will delete on destruction
   void Register(const string key, CObject* instance)    { AddEntry(key, instance, true);  }
   // non-owning reference
   void RegisterRef(const string key, CObject* instance) { AddEntry(key, instance, false); }
   // factory creates an owned instance immediately, factory is consumed
   void RegisterFactory(const string key, IServiceFactory* factory)
   {
      CObject* instance = factory.Create();
      delete factory;
      AddEntry(key, instance, true);
   }

   // Resolve locally, fall back to parent chain.
   CObject* Resolve(const string key)
   {
      int idx = FindIndex(key);
      if(idx >= 0) return m_entries[idx].Instance;
      if(m_parent != NULL) return m_parent.Resolve(key);
      LogError(StringFormat("Container: service not found: %s", key));
      return NULL;
   }

   // -------- Scope API --------
   // Create a child scope. The parent owns the child — it will be disposed
   // when this container is destroyed, or when DisposeChildScope is called.
   CServiceContainer* CreateChildScope()
   {
      CServiceContainer* child = new CServiceContainer();
      child.SetParent(GetPointer(this));
      ArrayResize(m_children, m_childCount + 1);
      m_children[m_childCount] = child;
      m_childCount++;
      return child;
   }

   // Dispose a previously created child scope early. After this call, `child`
   // is invalid. Safe no-op if `child` is not a direct child of this container.
   void DisposeChildScope(CServiceContainer* child)
   {
      if(child == NULL) return;
      int idx = FindChildIndex(child);
      if(idx < 0) { LogError("Container: DisposeChildScope: not a direct child"); return; }

      delete m_children[idx];
      for(int i = idx; i < m_childCount - 1; i++)
         m_children[i] = m_children[i + 1];
      m_childCount--;
      ArrayResize(m_children, m_childCount);
   }
};
#endif // FRAMEWORK_CONTAINER_SERVICE_CONTAINER_MQH
