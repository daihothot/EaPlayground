#ifndef FRAMEWORK_TIMER_SCHEDULER_MQH
#define FRAMEWORK_TIMER_SCHEDULER_MQH
#include <Object.mqh>

class ITimerCallback
{
public:
   virtual void OnTimer() = 0;
};

struct STimerEntry
{
   ITimerCallback* Callback;
   int             IntervalTicks;
   int             Elapsed;
};

class CTimerScheduler : public CObject
{
private:
   STimerEntry m_entries[];
   int         m_count;

public:
   CTimerScheduler() : m_count(0) { ArrayResize(m_entries, 0); }

   void Register(ITimerCallback* cb, int intervalTicks)
   {
      ArrayResize(m_entries, m_count + 1);
      m_entries[m_count].Callback      = cb;
      m_entries[m_count].IntervalTicks = intervalTicks;
      m_entries[m_count].Elapsed       = 0;
      m_count++;
   }

   void Tick()
   {
      for(int i = 0; i < m_count; i++)
      {
         m_entries[i].Elapsed++;
         if(m_entries[i].Elapsed >= m_entries[i].IntervalTicks)
         {
            m_entries[i].Elapsed = 0;
            m_entries[i].Callback.OnTimer();
         }
      }
   }
};
#endif // FRAMEWORK_TIMER_SCHEDULER_MQH
