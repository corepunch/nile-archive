/* test_lua.c — Lua's side of the test build, included by script.c under ENGINE_TEST:
 * check() and near() for tests, and the reader for tests/games/<suite>.lua. */

static int l_test_check(lua_State *S)
{
    if (lua_toboolean(S, 1)) { test_pass(); return 0; }
    luaL_where(S, 1);
    test_fail(lua_tostring(S, -1), 0, "%s", luaL_optstring(S, 2, "check failed"));
    return 0;
}

static int l_test_near(lua_State *S)
{
    double a = luaL_checknumber(S, 1), b = luaL_checknumber(S, 2);
    if (fabs(a - b) < 1e-3) { test_pass(); return 0; }
    luaL_where(S, 1);
    test_fail(lua_tostring(S, -1), 0, "%s (%g vs %g)", luaL_optstring(S, 3, "near failed"), a, b);
    return 0;
}

static void test_lua_open(lua_State *S)
{
    lua_register(S, "check", l_test_check);
    lua_register(S, "near", l_test_near);
}

static const char test_spec_prelude[] =
    "jobs = {}\n"
    "default_frames = 4\n"
    "local function add(j) jobs[#jobs + 1] = j end\n"
    "local function picture(kind, name, size, opts)\n"
    "    opts = opts or ''\n"
    "    if not opts:find('--frames', 1, true) then opts = opts .. ' --frames ' .. default_frames end\n"
    "    add{kind = kind, name = name, size = size, opts = opts}\n"
    "end\n"
    "function rules(file, roots) add{kind = 'rules', name = file, file = file, roots = roots} end\n"
    "function smoke(opts, name) add{kind = 'smoke', name = name or 'game', opts = '--smoke ' .. (opts or '')} end\n"
    "function shot(name, size, opts) picture('shot', name, size, opts) end\n"
    "function frame(name, size, opts) picture('frame', name, size, opts) end\n"
    "function reel(name, count, step, size, opts)\n"
    "    add{kind = 'reel', name = name, size = size, opts = opts, count = count, step = step}\n"
    "end\n"
    "function hold(name, size, press, opts)\n"
    "    add{kind = 'hold', name = name, size = size, press = press, opts = opts}\n"
    "end\n";

static void test_copy_field(lua_State *S, const char *field, char *out, size_t size)
{
    lua_getfield(S, -1, field);
    snprintf(out, size, "%s", lua_isstring(S, -1) ? lua_tostring(S, -1) : "");
    lua_pop(S, 1);
}

int test_read_jobs(const char *path, test_job *jobs, int max)
{
    lua_State *S = luaL_newstate(), *game = L;
    L = S;   /* open_libs works on the script state */
    open_libs();
    L = game;
    if (luaL_dostring(S, test_spec_prelude) != LUA_OK || luaL_dofile(S, path) != LUA_OK) {
        fprintf(stderr, "tests: %s\n", lua_tostring(S, -1));
        lua_close(S);
        return -1;
    }
    lua_getglobal(S, "jobs");
    int n = (int)luaL_len(S, -1);
    if (n > max) n = max;
    for (int i = 0; i < n; i++) {
        test_job *j = &jobs[i];
        lua_rawgeti(S, -1, i + 1);
        test_copy_field(S, "kind", j->kind, sizeof j->kind);
        test_copy_field(S, "name", j->name, sizeof j->name);
        test_copy_field(S, "file", j->file, sizeof j->file);
        test_copy_field(S, "roots", j->roots, sizeof j->roots);
        test_copy_field(S, "size", j->size, sizeof j->size);
        test_copy_field(S, "press", j->press, sizeof j->press);
        test_copy_field(S, "opts", j->opts, sizeof j->opts);
        lua_getfield(S, -1, "count"), j->count = (int)lua_tointeger(S, -1), lua_pop(S, 1);
        lua_getfield(S, -1, "step"), j->step = (int)lua_tointeger(S, -1), lua_pop(S, 1);
        lua_pop(S, 1);
    }
    lua_close(S);
    return n;
}
