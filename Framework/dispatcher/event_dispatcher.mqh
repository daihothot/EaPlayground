#ifndef FRAMEWORK_DISPATCHER_EVENT_DISPATCHER_MQH
#define FRAMEWORK_DISPATCHER_EVENT_DISPATCHER_MQH
#include <Object.mqh>
#include "event_sink.mqh"

class CEventDispatcher : public CObject
{
private:
   IEventSink* m_sinks[];
   string      m_ids[];
   int         m_count;

public:
   CEventDispatcher() : m_count(0) { ArrayResize(m_sinks, 0); ArrayResize(m_ids, 0); }

   void Register(IEventSink* sink, const string signalId = "")
   {
      ArrayResize(m_sinks, m_count + 1);
      ArrayResize(m_ids,   m_count + 1);
      m_sinks[m_count] = sink;
      m_ids[m_count]   = signalId;
      m_count++;
      LogInfo(StringFormat("Dispatcher sink registered: %s", sink.Name()));
   }

   void Unregister(IEventSink* sink)
   {
      for(int i = 0; i < m_count; i++)
      {
         if(m_sinks[i] == sink)
         {
            for(int j = i; j < m_count - 1; j++)
            {
               m_sinks[j] = m_sinks[j + 1];
               m_ids[j]   = m_ids[j + 1];
            }
            m_count--;
            ArrayResize(m_sinks, m_count);
            ArrayResize(m_ids,   m_count);
            return;
         }
      }
   }

   void Dispatch(CEventContext& context)
   {
      for(int i = 0; i < m_count; i++)
      {
         if(m_ids[i] == "" || m_ids[i] == context.SignalId)
            m_sinks[i].OnEvent(context);
      }
   }
};
#endif // FRAMEWORK_DISPATCHER_EVENT_DISPATCHER_MQH
