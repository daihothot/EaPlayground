#ifndef FRAMEWORK_EVENT_CHAIN_MQH
#define FRAMEWORK_EVENT_CHAIN_MQH
#include "event_handler.mqh"

class CEventChain
{
private:
   IEventHandler* m_handlers[];
   int            m_count;

public:
   CEventChain() : m_count(0) { ArrayResize(m_handlers, 0); }

   ~CEventChain()
   {
      for(int i = 0; i < m_count; i++)
         delete m_handlers[i];
   }

   void Add(IEventHandler* handler)
   {
      ArrayResize(m_handlers, m_count + 1);
      m_handlers[m_count++] = handler;
   }

   EVENT_RESULT Dispatch(CEventContext& context)
   {
      for(int i = 0; i < m_count; i++)
      {
         EVENT_RESULT r = m_handlers[i].Handle(context);
         if(r != EVENT_CONTINUE) return r;
      }
      return EVENT_CONTINUE;
   }
};
#endif // FRAMEWORK_EVENT_CHAIN_MQH
