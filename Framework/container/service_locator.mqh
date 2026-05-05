#ifndef FRAMEWORK_CONTAINER_SERVICE_LOCATOR_MQH
#define FRAMEWORK_CONTAINER_SERVICE_LOCATOR_MQH
#include "service_container.mqh"
#include "service_keys.mqh"

// The locator owns the root container. Call InitContainer() once at startup,
// ShutdownContainer() once on deinit. Any module may Container() / Resolve().
CServiceContainer* g_container = NULL;

void InitContainer()
{
   if(g_container != NULL) { LogError("Container: already initialized"); return; }
   g_container = new CServiceContainer();
}

void ShutdownContainer()
{
   if(g_container == NULL) return;
   delete g_container;
   g_container = NULL;
}

CServiceContainer* Container() { return g_container; }

// Typed helper — callers cast to the expected type.
CObject* Resolve(const string key)
{
   if(g_container == NULL) { LogError("Container: not initialized"); return NULL; }
   return g_container.Resolve(key);
}

#endif // FRAMEWORK_CONTAINER_SERVICE_LOCATOR_MQH
