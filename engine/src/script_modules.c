/* Module resolution owns names, roots, caching and dependency cycles. All
 * mutable state lives in Lua, so closing a script also discards its loader. */
#include "script_modules.h"
#include "third_party/lua/lauxlib.h"
#include <stdbool.h>
#include <string.h>

static const char modules_cache_key;

/* A protected import must capture the module's stack before unwinding it.
 * Preserve non-string error objects so callers can still identify them. */
static int module_traceback(lua_State *S)
{
    if (lua_type(S, 1) != LUA_TSTRING) return 1;
    luaL_traceback(S, S, lua_tostring(S, 1), 1);
    return 1;
}

/* Dots and slashes are aliases, not separate module identities. Restrict names
 * to nonempty ASCII segments so paths cannot escape or alias a script root. */
static const char *module_name(lua_State *S)
{
    size_t length;
    luaL_checktype(S, 1, LUA_TSTRING);
    const char *name = lua_tolstring(S, 1, &length);
    bool segment = false;
    for (size_t i = 0; i < length; i++) {
        unsigned char c = (unsigned char)name[i];
        if (c == '.' || c == '/') {
            luaL_argcheck(S, segment, 1, "expected nonempty module name segments");
            segment = false;
        } else {
            luaL_argcheck(S, (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                (c >= '0' && c <= '9') || c == '_' || c == '-', 1, "invalid module name character");
            segment = true;
        }
    }
    luaL_argcheck(S, segment, 1, "expected nonempty module name segments");
    return luaL_gsub(S, name, "/", ".");
}

/* Upvalues: configured roots, completed modules, modules currently executing. */
static int module_require(lua_State *S)
{
    lua_settop(S, 1);
    const char *name = module_name(S); /* canonical name at stack index 2 */
    lua_getfield(S, lua_upvalueindex(2), name);
    if (!lua_isnil(S, -1)) return 1;
    lua_pop(S, 1);
    lua_getfield(S, lua_upvalueindex(3), name);
    if (lua_toboolean(S, -1)) return luaL_error(S, "circular dependency loading module '%s'", name);
    lua_pop(S, 1);

    const char *relative = luaL_gsub(S, name, ".", "/"); /* index 3 */
    const char *roots = lua_tostring(S, lua_upvalueindex(1));
    int status = LUA_ERRFILE;
    for (const char *root = roots; root && status == LUA_ERRFILE;) {
        size_t length = strcspn(root, ";");
        if (length) {
            lua_settop(S, 3);
            lua_pushlstring(S, root, length);
            lua_pushfstring(S, "%s/%s.lua", lua_tostring(S, -1), relative);
            status = luaL_loadfile(S, lua_tostring(S, -1));
        }
        root = root[length] ? root + length + 1 : NULL;
    }
    if (status == LUA_ERRFILE)
        return luaL_error(S, "module '%s' not found in configured script roots", name);
    if (status != LUA_OK) return lua_error(S); /* preserve file, line and syntax error */

    lua_pushboolean(S, 1);
    lua_setfield(S, lua_upvalueindex(3), name);
    lua_pushcfunction(S, module_traceback);
    lua_insert(S, -2);
    int handler = lua_gettop(S) - 1;
    lua_pushstring(S, name);
    status = lua_pcall(S, 1, 1, handler);
    lua_pushnil(S);
    lua_setfield(S, lua_upvalueindex(3), name);
    if (status != LUA_OK) return lua_error(S); /* a failed module can be retried */
    if (lua_isnil(S, -1)) lua_pop(S, 1), lua_pushboolean(S, 1);
    lua_pushvalue(S, -1);
    lua_setfield(S, lua_upvalueindex(2), name);
    return 1;
}

void script_modules_open(lua_State *S, const char *roots)
{
    lua_pushstring(S, roots ? roots : ".");
    lua_newtable(S);
    lua_pushvalue(S, -1);
    lua_rawsetp(S, LUA_REGISTRYINDEX, &modules_cache_key);
    lua_newtable(S);
    lua_pushcclosure(S, module_require, 3);
    lua_setglobal(S, "require");
}

void script_modules_register(lua_State *S, const char *name)
{
    lua_rawgetp(S, LUA_REGISTRYINDEX, &modules_cache_key);
    lua_pushvalue(S, -2);
    lua_setfield(S, -2, name);
    lua_pop(S, 2);
}
