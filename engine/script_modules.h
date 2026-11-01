/* Private Lua module boundary; independent of app callbacks and generated API. */
#ifndef ENGINE_SCRIPT_MODULES_H
#define ENGINE_SCRIPT_MODULES_H
#include "third_party/lua/lua.h"

/* Copy the ordered, semicolon-separated roots into this state's require closure. */
void script_modules_open(lua_State *S, const char *roots);
/* Register an embedded module, consuming its value from the top of the stack. */
void script_modules_register(lua_State *S, const char *name);
#endif
