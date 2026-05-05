#ifndef FRAMEWORK_SIGNAL_BUILTIN_SIGNALS_MQH
#define FRAMEWORK_SIGNAL_BUILTIN_SIGNALS_MQH
#include "signal.mqh"

class CTickSignal : public CSignal
{
public:
   virtual string Id() override { return "tick"; }
};

class CNewBarSignal : public CSignal
{
public:
   datetime BarTime;
   CNewBarSignal() : BarTime(0) {}
   virtual string Id() override { return "new_bar"; }
};

class CTimerSignal : public CSignal
{
public:
   CTimerSignal() { Priority = 10; }
   virtual string Id() override { return "timer"; }
};
#endif // FRAMEWORK_SIGNAL_BUILTIN_SIGNALS_MQH
