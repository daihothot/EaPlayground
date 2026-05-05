#ifndef FRAMEWORK_STATE_RUNTIME_STATE_MQH
#define FRAMEWORK_STATE_RUNTIME_STATE_MQH

class CRuntimeState
{
public:
   // --- derived / historical state (must be recorded) ---
   datetime LastTickTime;
   datetime LastBarTime;

   CRuntimeState() : LastTickTime(0), LastBarTime(0) {}

   // --- market state (real-time query) ---
   double   Bid()          { return SymbolInfoDouble(_Symbol, SYMBOL_BID); }
   double   Ask()          { return SymbolInfoDouble(_Symbol, SYMBOL_ASK); }
   int      SpreadPoints() { return (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD); }

   // --- account state (real-time query) ---
   double   Balance()      { return AccountInfoDouble(ACCOUNT_BALANCE); }
   double   Equity()       { return AccountInfoDouble(ACCOUNT_EQUITY); }
   double   FreeMargin()   { return AccountInfoDouble(ACCOUNT_MARGIN_FREE); }
   long     AccountId()    { return AccountInfoInteger(ACCOUNT_LOGIN); }
   string   AccountName()  { return AccountInfoString(ACCOUNT_NAME); }
};
#endif // FRAMEWORK_STATE_RUNTIME_STATE_MQH
