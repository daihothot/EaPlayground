#ifndef FRAMEWORK_TIME_BAR_MQH
#define FRAMEWORK_TIME_BAR_MQH

class CBarDetector
{
private:
   datetime m_lastBarTime;

public:
   CBarDetector() : m_lastBarTime(0) {}

   bool IsNewBar()
   {
      datetime current = iTime(_Symbol, _Period, 0);
      if(current != m_lastBarTime)
      {
         m_lastBarTime = current;
         return true;
      }
      return false;
   }
};
#endif // FRAMEWORK_TIME_BAR_MQH
