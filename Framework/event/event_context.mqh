#ifndef FRAMEWORK_EVENT_CONTEXT_MQH
#define FRAMEWORK_EVENT_CONTEXT_MQH
#include "../launcher/launcher_bundle.mqh"
#include "../state/runtime_state.mqh"

enum EVENT_TYPE
{
   EVENT_TICK    = 0,
   EVENT_NEW_BAR = 1,
   EVENT_TIMER   = 2
};

enum EVENT_RESULT
{
   EVENT_CONTINUE = 0,
   EVENT_STOP     = 1,
   EVENT_ERROR    = 2
};

class CEventContext
{
public:
   CLauncherBundle* Bundle;  // non-owning
   CRuntimeState*   State;   // non-owning

   EVENT_TYPE      Type;
   datetime        Time;
   string          Symbol;
   ENUM_TIMEFRAMES Timeframe;

   int    Signal;
   double Price;
   string Message;

   CEventContext()
   {
      Bundle    = NULL;
      State     = NULL;
      Type      = EVENT_TICK;
      Time      = TimeCurrent();
      Symbol    = _Symbol;
      Timeframe = _Period;
      Signal    = 0;
      Price     = 0.0;
      Message   = "";
   }
};
#endif // FRAMEWORK_EVENT_CONTEXT_MQH
