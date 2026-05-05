#ifndef FRAMEWORK_DISPATCHER_EVENT_DISPATCHER_MQH
#define FRAMEWORK_DISPATCHER_EVENT_DISPATCHER_MQH
#include "event_sink.mqh"

class CEventDispatcher
{
private:
   IEventSink* m_sinks[];
   int         m_count;

public:
   CEventDispatcher() : m_count(0) { ArrayResize(m_sinks, 0); }

   void Register(IEventSink* sink)
   {
      ArrayResize(m_sinks, m_count + 1);
      m_sinks[m_count++] = sink;
      LogInfo(StringFormat("Dispatcher sink registered: %s", sink.Name()));
   }

   void Unregister(IEventSink* sink)
   {
      for(int i = 0; i < m_count; i++)
      {
         if(m_sinks[i] == sink)
         {
            for(int j = i; j < m_count - 1; j++)
               m_sinks[j] = m_sinks[j + 1];
            m_count--;
            ArrayResize(m_sinks, m_count);
            return;
         }
      }
   }

   void Dispatch(CEventContext& context)
   {
      for(int i = 0; i < m_count; i++)
         m_sinks[i].OnEvent(context);
   }
};
#endif // FRAMEWORK_DISPATCHER_EVENT_DISPATCHER_MQH
