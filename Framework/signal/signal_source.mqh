#ifndef FRAMEWORK_SIGNAL_SOURCE_MQH
#define FRAMEWORK_SIGNAL_SOURCE_MQH
#include "signal.mqh"
#include "../state/runtime_state.mqh"

class ISignalSource
{
public:
   virtual int     Priority()                                    = 0;
   virtual bool    Check(CSignal*& out)                          = 0;
   virtual void    Project(CRuntimeState& state, CSignal* signal) = 0;
};
#endif // FRAMEWORK_SIGNAL_SOURCE_MQH
