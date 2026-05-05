#ifndef FRAMEWORK_EVENT_CONTEXT_MQH
#define FRAMEWORK_EVENT_CONTEXT_MQH
#include "../launcher/launcher_bundle.mqh"
#include "../state/runtime_state.mqh"

enum EVENT_RESULT
{
   EVENT_CONTINUE = 0,
   EVENT_STOP     = 1,
   EVENT_ERROR    = 2
};

class CEventContext
{
public:
   CLauncherBundle* Bundle;    // non-owning
   CRuntimeState*   State;     // non-owning
   string           SignalId;
   datetime         Time;
   string           Symbol;
   ENUM_TIMEFRAMES  Timeframe;
   string           Message;

   CEventContext()
   {
      Bundle    = NULL;
      State     = NULL;
      SignalId  = "";
      Time      = TimeCurrent();
      Symbol    = _Symbol;
      Timeframe = _Period;
      Message   = "";
   }
};
#endif // FRAMEWORK_EVENT_CONTEXT_MQH
