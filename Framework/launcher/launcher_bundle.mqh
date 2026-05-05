#ifndef FRAMEWORK_LAUNCHER_BUNDLE_MQH
#define FRAMEWORK_LAUNCHER_BUNDLE_MQH
#include "../log/logger.mqh"

class CLauncherBundle
{
public:
   LOG_LEVEL MinLogLevel;
   int       TimerSeconds;
   int       MaxSpreadPoints;
   long      MagicNumber;
   string    Symbol;
   ENUM_TIMEFRAMES Timeframe;

   CLauncherBundle()
   {
      MinLogLevel    = LOG_INFO;
      TimerSeconds   = 5;
      MaxSpreadPoints = 300;
      MagicNumber    = 0;
      Symbol         = _Symbol;
      Timeframe      = _Period;
   }
};
#endif // FRAMEWORK_LAUNCHER_BUNDLE_MQH
