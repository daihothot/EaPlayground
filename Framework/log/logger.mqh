#ifndef FRAMEWORK_LOG_LOGGER_MQH
#define FRAMEWORK_LOG_LOGGER_MQH

enum LOG_LEVEL
{
   LOG_DEBUG   = 0,
   LOG_INFO    = 1,
   LOG_WARNING = 2,
   LOG_ERROR   = 3
};

static LOG_LEVEL g_MinLogLevel = LOG_INFO;

void LogSetLevel(LOG_LEVEL level) { g_MinLogLevel = level; }

void LogDebug(const string msg)   { if(g_MinLogLevel <= LOG_DEBUG)   Print("[DEBUG] ", msg); }
void LogInfo(const string msg)    { if(g_MinLogLevel <= LOG_INFO)    Print("[INFO] ",  msg); }
void LogWarning(const string msg) { if(g_MinLogLevel <= LOG_WARNING) Print("[WARN] ",  msg); }
void LogError(const string msg)   { if(g_MinLogLevel <= LOG_ERROR)   Print("[ERROR] ", msg); }
#endif // FRAMEWORK_LOG_LOGGER_MQH
