#ifndef FRAMEWORK_SIGNAL_BUILTIN_SOURCES_MQH
#define FRAMEWORK_SIGNAL_BUILTIN_SOURCES_MQH
#include "signal_source.mqh"
#include "builtin_signals.mqh"
#include "../time/bar.mqh"

class CTickSignalSource : public ISignalSource
{
public:
   virtual int  Priority() override { return 0; }
   virtual bool Check(CSignal*& out) override
   {
      out = new CTickSignal();
      out.ReceivedTime = TimeCurrent();
      return true;
   }
   virtual void Project(CRuntimeState& state, CSignal* signal) override
   {
      state.LastTickTime = signal.ReceivedTime;
   }
};

class CNewBarSignalSource : public ISignalSource
{
private:
   CBarDetector m_detector;
public:
   virtual int  Priority() override { return 5; }
   virtual bool Check(CSignal*& out) override
   {
      if(!m_detector.IsNewBar()) return false;
      CNewBarSignal* s = new CNewBarSignal();
      s.ReceivedTime = TimeCurrent();
      s.BarTime      = iTime(_Symbol, _Period, 0);
      out = s;
      return true;
   }
   virtual void Project(CRuntimeState& state, CSignal* signal) override
   {
      state.LastBarTime = ((CNewBarSignal*)signal).BarTime;
   }
};
#endif // FRAMEWORK_SIGNAL_BUILTIN_SOURCES_MQH
