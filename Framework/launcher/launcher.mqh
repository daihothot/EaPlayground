#ifndef FRAMEWORK_LAUNCHER_MQH
#define FRAMEWORK_LAUNCHER_MQH
#include "launcher_bundle.mqh"

class CLauncher
{
private:
   CLauncherBundle m_bundle;

public:
   void ConfigureInputs(
      const LOG_LEVEL minLogLevel,
      const int timerSeconds,
      const int maxSpreadPoints,
      const long magicNumber
   )
   {
      m_bundle.MinLogLevel     = minLogLevel;
      m_bundle.TimerSeconds    = timerSeconds;
      m_bundle.MaxSpreadPoints = maxSpreadPoints;
      m_bundle.MagicNumber     = magicNumber;
      m_bundle.Symbol          = _Symbol;
      m_bundle.Timeframe       = _Period;
   }

   CLauncherBundle* Bundle() { return GetPointer(m_bundle); }
};
#endif // FRAMEWORK_LAUNCHER_MQH
