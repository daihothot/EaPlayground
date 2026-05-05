#ifndef FRAMEWORK_SIGNAL_SIGNAL_MQH
#define FRAMEWORK_SIGNAL_SIGNAL_MQH

class CSignal
{
public:
   datetime ReceivedTime;
   int      Priority;

   CSignal() : ReceivedTime(0), Priority(0) {}

   virtual string Id() = 0;
};
#endif // FRAMEWORK_SIGNAL_SIGNAL_MQH
