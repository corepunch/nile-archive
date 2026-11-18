/* lua_lib.c — Lua 5.4 as one translation unit, after Lua's own onelua.c, with
 * only the libraries the sandbox opens: base, table, string, math, utf8 and
 * coroutine. io, os, package and debug are left out of the build entirely. */
#define LUA_CORE
#define LUA_LIB
#define luaall_c

#include "third_party/lua/lprefix.h"

#include <assert.h>
#include <ctype.h>
#include <errno.h>
#include <float.h>
#include <limits.h>
#include <locale.h>
#include <math.h>
#include <setjmp.h>
#include <stdarg.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "third_party/lua/lzio.c"
#include "third_party/lua/lctype.c"
#include "third_party/lua/lopcodes.c"
#include "third_party/lua/lmem.c"
#include "third_party/lua/lundump.c"
#include "third_party/lua/ldump.c"
#include "third_party/lua/lstate.c"
#include "third_party/lua/lgc.c"
#include "third_party/lua/llex.c"
#include "third_party/lua/lcode.c"
#include "third_party/lua/lparser.c"
#include "third_party/lua/ldebug.c"
#include "third_party/lua/lfunc.c"
#include "third_party/lua/lobject.c"
#include "third_party/lua/ltm.c"
#include "third_party/lua/lstring.c"
#include "third_party/lua/ltable.c"
#include "third_party/lua/ldo.c"
#include "third_party/lua/lvm.c"
#include "third_party/lua/lapi.c"

#include "third_party/lua/lauxlib.c"
#include "third_party/lua/lbaselib.c"
#include "third_party/lua/lcorolib.c"
#include "third_party/lua/lmathlib.c"
#include "third_party/lua/lstrlib.c"
#include "third_party/lua/ltablib.c"
#include "third_party/lua/lutf8lib.c"
