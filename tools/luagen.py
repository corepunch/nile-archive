#!/usr/bin/env python3
"""luagen - the engine's Lua glue, reference and editor annotations from engine/api.xml.

    tools/luagen.py                 write engine/api_lua.c, api_lua.h, docs/LUA_API.md, engine/engine.d.lua
    tools/luagen.py --check         exit 1 if any of them is out of date (make test, CI)

No binding is written by hand: every function, struct field, handle field,
enum and constant comes from the XML, in the way wayland-scanner turns a
protocol XML into C glue and documentation. Functions that need a body a
generator cannot write (callbacks, visitors) are declared with impl="..." and
implemented in engine/script.c; they still get their checks, registration and
documentation from here.
"""
import argparse
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / 'engine' / 'api.xml'
OUTPUTS = {
    'c': ROOT / 'engine' / 'api_lua.c',
    'h': ROOT / 'engine' / 'api_lua.h',
    'md': ROOT / 'docs' / 'LUA_API.md',
    'dlua': ROOT / 'engine' / 'engine.d.lua',
}
MAX_ARRAY = 512

SCALARS = {
    # xml type: (C type, Lua type name, check expression, push expression, lenient get expression)
    'float': ('float', 'number', '(float)luaL_checknumber(L, {i})', 'lua_pushnumber(L, {v})', '(float)lua_tonumber(L, {i})'),
    'double': ('double', 'number', 'luaL_checknumber(L, {i})', 'lua_pushnumber(L, {v})', 'lua_tonumber(L, {i})'),
    'int': ('int', 'integer', '(int)luaL_checkinteger(L, {i})', 'lua_pushinteger(L, {v})', '(int)lua_tonumber(L, {i})'),
    'uint': ('unsigned', 'integer', '(unsigned)luaL_checkinteger(L, {i})', 'lua_pushinteger(L, (lua_Integer){v})', '(unsigned)lua_tonumber(L, {i})'),
    'u8': ('uint8_t', 'integer', '(uint8_t)luaL_checkinteger(L, {i})', 'lua_pushinteger(L, {v})', '(uint8_t)clampi((int)lua_tonumber(L, {i}), 0, 255)'),
    'bool': ('bool', 'boolean', 'lua_toboolean(L, {i})', 'lua_pushboolean(L, {v})', 'lua_toboolean(L, {i})'),
    'string': ('const char *', 'string', 'luaL_checkstring(L, {i})', 'lua_pushstring(L, {v})', 'lua_tostring(L, {i})'),
    'ptr': ('void *', 'userdata', 'lua_touserdata(L, {i})', 'api_push_ptr(L, {v})', 'lua_touserdata(L, {i})'),
}


class Api:
    def __init__(self, root):
        self.root = root
        self.structs = {s.get('name'): s for s in root.iter('struct')}
        self.handles = {h.get('name'): h for h in root.iter('handle')}
        self.modules = list(root.iter('module'))
        self.types = {}  # type name -> module that owns its methods
        for m in self.modules:
            if m.get('type'):
                self.types[m.get('type')] = m

    def ctype(self, t):
        if t in SCALARS:
            return SCALARS[t][0]
        if t in self.structs:
            return self.structs[t].get('c')
        if t in self.handles:
            h = self.handles[t]
            return h.get('c') if h.get('light') or h.get('owned') else h.get('c')
        raise ValueError('unknown type ' + t)

    def luatype(self, t):
        if t.endswith('[]'):
            return self.luatype(t[:-2]) + '[]'
        if t in SCALARS:
            return SCALARS[t][1]
        if t in ('table', 'function', 'bytes'):
            return {'table': 'table', 'function': 'function', 'bytes': 'string'}[t]
        return t


def doc_of(el):
    """The doc attribute or text content of an element, one line."""
    d = el.get('doc') or (el.text or '')
    return ' '.join(d.split())


def lua_name(fn):
    return fn.get('lua') or fn.get('name')


def c_name(fn):
    return fn.get('c') or fn.get('name')


def is_method(api, module, fn):
    args = fn.findall('arg')
    return bool(module.get('type')) and args and args[0].get('type') == module.get('type')


def lua_args(fn):
    """Argument names as a Lua signature (counts and outs are not arguments)."""
    out = []
    for a in fn.findall('arg'):
        if a.get('type') == 'count' or a.get('ref') == 'out':
            continue
        name = a.get('name')
        if a.get('optional') == 'true' or a.get('default') is not None:
            name += '?'
        out.append(name)
    return out


# ------------------------------------------------------------------- C glue

def gen_get(api, t, idx, default=None):
    """Expression reading a value of type t at stack index idx leniently (nil -> zero)."""
    if t in SCALARS:
        e = SCALARS[t][4].format(i=idx)
        if default is not None:
            return f'(lua_isnoneornil(L, {idx}) ? ({SCALARS[t][0]}){default} : {e})'
        return e
    if t in api.structs:
        return f'api_get_{t}(L, {idx})'
    if t in api.handles:
        h = api.handles[t]
        if h.get('light'):
            return f'({h.get("c")})lua_touserdata(L, {idx})'
        return f'api_check_{t}(L, {idx})'
    raise ValueError(t)


def gen_push(api, t, v):
    if t in SCALARS:
        return SCALARS[t][3].format(v=v)
    if t in api.structs:
        return f'api_push_{t}(L, {v})'
    if t in api.handles:
        return f'api_push_{t}(L, {v})'
    raise ValueError(t)


def gen_struct(api, s):
    name, c = s.get('name'), s.get('c')
    mt = f'"engine.{name}"'
    out = []
    fields = s.findall('field')
    if s.get('array'):   # a struct that is one array (purse)
        et, n = s.get('array'), s.get('count')
        out += [f'void api_push_{name}(lua_State *L, {c} v)', '{',
                f'    lua_createtable(L, {n}, 0);',
                f'    for (int i = 0; i < {n}; i++) {{ {gen_push(api, et, "v.v[i]")}; lua_rawseti(L, -2, i + 1); }}',
                f'    luaL_setmetatable(L, {mt});', '}', '',
                f'{c} api_get_{name}(lua_State *L, int i)', '{',
                f'    {c} v;', '    memset(&v, 0, sizeof v);',
                '    if (!lua_istable(L, i)) return v;', '    i = lua_absindex(L, i);',
                f'    for (int k = 0; k < {n}; k++) {{ lua_rawgeti(L, i, k + 1); v.v[k] = {gen_get(api, et, -1)}; lua_pop(L, 1); }}',
                '    return v;', '}', '',
                f'void api_store_{name}(lua_State *L, int i, {c} v)', '{',
                '    i = lua_absindex(L, i);',
                f'    for (int k = 0; k < {n}; k++) {{ {gen_push(api, et, "v.v[k]")}; lua_rawseti(L, i, k + 1); }}',
                '}', '']
    else:
        out += [f'void api_push_{name}(lua_State *L, {c} v)', '{', f'    lua_createtable(L, 0, {len(fields)});']
        for f in fields:
            out.append(f'    {gen_push(api, f.get("type"), "v." + (f.get("c") or f.get("name")))}; lua_setfield(L, -2, "{f.get("name")}");')
        out += [f'    luaL_setmetatable(L, {mt});', '}', '']
        out += [f'{c} api_get_{name}(lua_State *L, int i)', '{', f'    {c} v;', '    memset(&v, 0, sizeof v);',
                '    if (!lua_istable(L, i)) return v;   /* nil is the zero value, whatever the defaults */', '    i = lua_absindex(L, i);']
        for f in fields:
            if f.get('default'):
                out.append(f'    v.{f.get("c") or f.get("name")} = {f.get("default")};')
        for f in fields:
            fn, ft, fc = f.get('name'), f.get('type'), f.get('c') or f.get('name')
            out.append(f'    lua_getfield(L, i, "{fn}");')
            if f.get('pos'):
                out.append(f'    if (lua_isnil(L, -1)) {{ lua_pop(L, 1); lua_rawgeti(L, i, {f.get("pos")}); }}')
            if f.get('default'):
                out.append(f'    if (!lua_isnil(L, -1)) v.{fc} = {gen_get(api, ft, -1)};')
            else:
                out.append(f'    v.{fc} = {gen_get(api, ft, -1)};')
            out.append('    lua_pop(L, 1);')
        out += ['    return v;', '}', '']
        out += [f'void api_store_{name}(lua_State *L, int i, {c} v)', '{', '    i = lua_absindex(L, i);']
        for f in fields:
            out.append(f'    {gen_push(api, f.get("type"), "v." + (f.get("c") or f.get("name")))}; lua_setfield(L, i, "{f.get("name")}");')
        out += ['}', '']
    out += [f'{c} api_check_{name}(lua_State *L, int i)', '{',
            f'    luaL_argexpected(L, lua_istable(L, i), i, "{name}");', f'    return api_get_{name}(L, i);', '}', '']
    # constructor: module(...) -> value
    out += [f'static int l_{name}_new(lua_State *L)', '{',
            f'    if (lua_istable(L, 2)) {{ lua_settop(L, 2); luaL_setmetatable(L, {mt}); return 1; }}']
    if s.get('array'):
        et, n = s.get('array'), s.get('count')
        out += [f'    {c} v;', '    memset(&v, 0, sizeof v);',
                f'    for (int k = 0; k < {n} && k + 2 <= lua_gettop(L); k++) v.v[k] = {gen_get(api, et, "k + 2")};']
    elif s.get('ctor'):
        out += [f'    {c} v;', '    memset(&v, 0, sizeof v);']
        for k, fname in enumerate(s.get('ctor').split(',')):
            f = next(x for x in fields if x.get('name') == fname)
            out.append(f'    v.{f.get("c") or fname} = {gen_get(api, f.get("type"), k + 2, f.get("default") or "0")};')
    else:
        out += ['    lua_newtable(L);', f'    luaL_setmetatable(L, {mt});', '    return 1;', '}', '']
        return out
    out += [f'    api_push_{name}(L, v);', '    return 1;', '}', '']
    if s.get('ctor'):
        fmt = ', '.join('%g' if f.get('type') in ('float', 'double') else '%d' for f in fields if f.get('name') in s.get('ctor').split(','))
        vals = ', '.join(('(double)' if f.get('type') in ('float', 'double') else '(int)') + 'v.' + (f.get('c') or f.get('name'))
                         for f in fields if f.get('name') in s.get('ctor').split(','))
        out += [f'static int l_{name}_tostring(lua_State *L)', '{', f'    {c} v = api_get_{name}(L, 1);',
                f'    lua_pushfstring(L, "{name}(" "{fmt}" ")", {vals});'.replace('%g', '%f'), '    return 1;', '}', '']
    return out


def gen_handle(api, h):
    name, c = h.get('name'), h.get('c')
    out = []
    if h.get('light'):
        out += [f'void api_push_{name}(lua_State *L, {c} p)', '{', '    if (p) lua_pushlightuserdata(L, (void *)p); else lua_pushnil(L);', '}', '']
        return out
    mt = f'"engine.{name}"'
    if h.get('owned'):
        out += [f'{c} *api_check_{name}(lua_State *L, int i)', '{', f'    return ({c} *)luaL_checkudata(L, i, {mt});', '}', '',
                f'void api_push_{name}(lua_State *L, const {c} *p)', '{', '    api_handle_lookup(L, p);', '}', '',
                f'static int l_{name}_new(lua_State *L)', '{',
                f'    {c} *p = ({c} *)lua_newuserdatauv(L, sizeof *p, 1);', '    memset(p, 0, sizeof *p);',
                '    lua_newtable(L);', '    lua_setiuservalue(L, -2, 1);', f'    luaL_setmetatable(L, {mt});',
                '    api_handle_register(L, p, -1);', '    return 1;', '}', '']
        # __gc frees allocated arrays
        allocs = [f for f in h.findall('field') if f.get('alloc')]
        out += [f'static int l_{name}_gc(lua_State *L)', '{', f'    {c} *p = api_check_{name}(L, 1);']
        for f in allocs:
            out.append(f'    free(p->{f.get("name")});')
            out.append(f'    p->{f.get("name")} = NULL;')
        out += ['    api_handle_register(L, p, 0);', '    return 0;', '}', '']
        out += gen_handle_fields(api, h)
    else:
        out += [f'{c} api_check_{name}(lua_State *L, int i)', '{', f'    return *({c} *)luaL_checkudata(L, i, {mt});', '}', '',
                f'void api_push_{name}(lua_State *L, {c} p)', '{',
                f'    *({c} *)lua_newuserdatauv(L, sizeof p, 0) = p;', f'    luaL_setmetatable(L, {mt});', '}', '']
    return out


def gen_handle_fields(api, h):
    name, c = h.get('name'), h.get('c')
    out = [f'static int l_{name}_index(lua_State *L)', '{',
           f'    {c} *p = api_check_{name}(L, 1);',
           '    lua_pushvalue(L, 2);', '    lua_rawget(L, lua_upvalueindex(1));',
           '    if (!lua_isnil(L, -1)) return 1;', '    lua_pop(L, 1);',
           '    const char *k = lua_tostring(L, 2);', '    if (!k) return 0;']
    for f in h.findall('field'):
        fn, ft = f.get('name'), f.get('type')
        if ft == 'callback':
            out.append(f'    if (!strcmp(k, "{fn}")) {{ lua_getiuservalue(L, 1, 1); lua_getfield(L, -1, "{fn}"); return 1; }}')
        elif ft.endswith('[]'):
            et, cnt = ft[:-2], f.get('count')
            out.append(f'    if (!strcmp(k, "{fn}")) {{')
            out.append(f'        lua_createtable(L, p->{cnt}, 0);')
            out.append(f'        for (int i = 0; i < p->{cnt}; i++) {{ {gen_push(api, et, f"p->{fn}[i]")}; lua_rawseti(L, -2, i + 1); }}')
            out.append('        return 1;')
            out.append('    }')
        else:
            out.append(f'    if (!strcmp(k, "{fn}")) {{ {gen_push(api, ft, "p->" + fn)}; return 1; }}')
    out += [f'    return luaL_error(L, "{name} has no field \'%s\'", k);', '}', '']
    out += [f'static int l_{name}_newindex(lua_State *L)', '{',
            f'    {c} *p = api_check_{name}(L, 1);',
            '    const char *k = lua_tostring(L, 2);',
            f'    if (!k) return luaL_error(L, "{name}: bad field");']
    for f in h.findall('field'):
        fn, ft = f.get('name'), f.get('type')
        if ft == 'callback':
            out.append(f'    if (!strcmp(k, "{fn}")) {{')
            out.append('        if (!lua_isnoneornil(L, 3)) luaL_checktype(L, 3, LUA_TFUNCTION);')
            out.append(f'        lua_getiuservalue(L, 1, 1); lua_pushvalue(L, 3); lua_setfield(L, -2, "{fn}"); lua_pop(L, 1);')
            out.append(f'        p->{fn} = lua_isnoneornil(L, 3) ? NULL : {f.get("tramp")};')
            out.append('        return 0;')
            out.append('    }')
            continue
        if f.get('access') != 'rw':
            continue
        if ft.endswith('[]'):
            et, cnt = ft[:-2], f.get('count')
            out.append(f'    if (!strcmp(k, "{fn}")) {{')
            out.append('        luaL_checktype(L, 3, LUA_TTABLE);')
            out.append('        int n = (int)luaL_len(L, 3);')
            if f.get('alloc'):
                out.append(f'        free(p->{fn});')
                out.append(f'        p->{fn} = calloc((size_t)(n > 0 ? n : 1), sizeof *p->{fn});')
            else:
                out.append(f'        luaL_argcheck(L, n <= {f.get("max")}, 3, "too many");')
            out.append(f'        for (int i = 0; i < n; i++) {{ lua_rawgeti(L, 3, i + 1); p->{fn}[i] = {gen_get(api, et, -1)}; lua_pop(L, 1); }}')
            out.append(f'        p->{cnt} = n;')
            if f.get('anchor'):
                out.append(f'        lua_getiuservalue(L, 1, 1); lua_pushvalue(L, 3); lua_setfield(L, -2, "{fn}"); lua_pop(L, 1);')
            out.append('        return 0;')
            out.append('    }')
        else:
            out.append(f'    if (!strcmp(k, "{fn}")) {{ p->{fn} = {gen_get(api, ft, 3)}; return 0; }}')
    out += [f'    return luaL_error(L, "{name}: cannot set field \'%s\'", k);', '}', '']
    return out


def gen_function(api, module, fn):
    """One lua_CFunction wrapper, or nothing for impl="..." functions."""
    if fn.get('impl'):
        return []
    args = fn.findall('arg')
    name = f'l_{module.get("name")}_{fn.get("name")}'
    out = [f'/* {module.get("name")}.{lua_name(fn)}({", ".join(lua_args(fn))}) */', f'static int {name}(lua_State *L)', '{']
    idx = 0
    call, after, returns = [], [], 0
    minlen = []
    for a in args:
        an, at, ref = a.get('name'), a.get('type'), a.get('ref')
        v = 'a_' + an
        if at == 'count':
            call.append('n_' + a.get('of'))
            continue
        if ref == 'out':
            out.append(f'    {api.ctype(at)} {v};')
            out.append(f'    memset(&{v}, 0, sizeof {v});')
            call.append('&' + v)
            after.append(f'    {gen_push(api, at, v)};')
            returns += 1
            continue
        idx += 1
        if at.endswith('[]'):
            et = at[:-2]
            out.append(f'    {api.ctype(et)} {v}[API_MAX_ARRAY];')
            out.append(f'    int n_{an} = api_array_len(L, {idx}, API_MAX_ARRAY);')
            out.append(f'    for (int k = 0; k < n_{an}; k++) {{ lua_rawgeti(L, {idx}, k + 1); {v}[k] = {gen_get(api, et, -1)}; lua_pop(L, 1); }}')
            call.append(v)
            if ref == 'inout':
                after.append(f'    for (int k = 0; k < n_{an}; k++) {{ {gen_push(api, et, v + "[k]")}; lua_rawseti(L, {idx}, k + 1); }}')
                after.append(f'    lua_pushvalue(L, {idx});')
                returns += 1
            continue
        if at == 'bytes':
            out.append(f'    size_t len_{an};')
            out.append(f'    const char *{v} = luaL_checklstring(L, {idx}, &len_{an});')
            if a.get('minlen'):
                minlen.append((an, a.get('minlen'), idx))
            call.append(v)
            continue
        if at in ('table', 'function'):
            out.append(f'    luaL_checktype(L, {idx}, LUA_T{at.upper()});')
            continue
        ct = api.ctype(at)
        if at in SCALARS:
            if a.get('default') is not None:
                d = a.get('default')
                if at in ('float', 'double'):
                    e = f'({ct})luaL_optnumber(L, {idx}, {d})'
                elif at == 'bool':
                    e = f'(lua_isnoneornil(L, {idx}) ? {d} : lua_toboolean(L, {idx}))'
                else:
                    e = f'({ct})luaL_optinteger(L, {idx}, {d})'
            elif a.get('optional') == 'true':
                e = f'luaL_optstring(L, {idx}, NULL)' if at == 'string' else f'(lua_isnoneornil(L, {idx}) ? ({ct})0 : {SCALARS[at][2].format(i=idx)})'
            else:
                e = SCALARS[at][2].format(i=idx)
        elif at in api.structs:
            e = f'(lua_isnoneornil(L, {idx}) ? api_get_{at}(L, {idx}) : api_check_{at}(L, {idx}))' if a.get('optional') == 'true' else f'api_check_{at}(L, {idx})'
        elif at in api.handles:
            h = api.handles[at]
            if h.get('light'):
                e = f'({ct})lua_touserdata(L, {idx})'
                ct = ct
            else:
                e = f'api_check_{at}(L, {idx})'
                if h.get('owned'):
                    ct = ct + ' *'
        else:
            raise ValueError(at)
        out.append(f'    {ct} {v} = {e};')
        if ref == 'inout':
            call.append('&' + v)
            if at in api.structs:
                after.append(f'    api_store_{at}(L, {idx}, {v});')
                after.append(f'    lua_pushvalue(L, {idx});')
                returns += 1
            else:
                after.append(f'    {gen_push(api, at, v)};')
                returns += 1
        else:
            call.append(v)
    for an, expr, i in minlen:
        e = re.sub(r'\b([a-z_][a-z_0-9]*)\b', lambda m: 'a_' + m.group(1) if m.group(1) != 'len' else m.group(1), expr)
        out.append(f'    luaL_argcheck(L, (size_t)({e}) <= len_{an}, {i}, "too few bytes");')
    ret = fn.find('returns')
    expr = f'{c_name(fn)}({", ".join(call)})'
    if ret is None:
        out.append(f'    {expr};')
    else:
        rt = ret.get('type')
        if rt in api.structs and (ret.get('optional') == 'true' or ret.get('ptr') == 'true'):
            out.append(f'    const {api.ctype(rt)} *r = {expr};')
            out.append(f'    if (r) api_push_{rt}(L, *r); else lua_pushnil(L);')
        else:
            ct = api.ctype(rt)
            if rt in api.handles and not api.handles[rt].get('light') and api.handles[rt].get('owned'):
                ct += ' *'
            out.append(f'    {ct} r = {expr};')
            out.append(f'    {gen_push(api, rt, "r")};')
        returns += 1
        # keep the main result first: outs were queued after
    out += after
    out += [f'    return {returns};', '}', '']
    return out


def gen_module_open(api, m):
    """Registration of one module: functions, enums, consts, metatables."""
    mn = m.get('name')
    out = [f'static void open_{mn}(lua_State *L)', '{']
    regs = []
    for fn in m.findall('function'):
        cf = fn.get('impl') or f'l_{mn}_{fn.get("name")}'
        regs.append(f'        {{"{lua_name(fn)}", {cf}}},')
    t = m.get('type')
    if t in api.handles and api.handles[t].get('owned'):
        regs.append(f'        {{"new", l_{t}_new}},')
    out += ['    static const luaL_Reg funcs[] = {'] + regs + ['        {NULL, NULL}', '    };', '    luaL_newlib(L, funcs);']
    for e in m.findall('enum'):
        for v in e.findall('value'):
            out.append(f'    lua_pushinteger(L, {v.get("c") or e.get("prefix") + v.get("name")}); lua_setfield(L, -2, "{v.get("name")}");')
    for k in m.findall('const'):
        out.append(f'    {gen_push(api, k.get("type"), k.get("c"))}; lua_setfield(L, -2, "{k.get("name")}");')
    if t:
        mt = f'"engine.{t}"'
        if t in api.structs:
            s = api.structs[t]
            out += [f'    luaL_newmetatable(L, {mt});', '    lua_pushvalue(L, -2); lua_setfield(L, -2, "__index");']
            for fn in m.findall('function'):
                if fn.get('op'):
                    out.append(f'    lua_pushcfunction(L, l_{mn}_{fn.get("name")}); lua_setfield(L, -2, "{fn.get("op")}");')
            if s.get('ctor'):
                out.append(f'    lua_pushcfunction(L, l_{t}_tostring); lua_setfield(L, -2, "__tostring");')
            out += ['    lua_pop(L, 1);',
                    '    lua_newtable(L);', f'    lua_pushcfunction(L, l_{t}_new); lua_setfield(L, -2, "__call");', '    lua_setmetatable(L, -2);']
        elif t in api.handles and not api.handles[t].get('light'):
            h = api.handles[t]
            out += [f'    luaL_newmetatable(L, {mt});']
            if h.get('owned'):
                out += ['    lua_pushvalue(L, -2);', f'    lua_pushcclosure(L, l_{t}_index, 1); lua_setfield(L, -2, "__index");',
                        f'    lua_pushcfunction(L, l_{t}_newindex); lua_setfield(L, -2, "__newindex");',
                        f'    lua_pushcfunction(L, l_{t}_gc); lua_setfield(L, -2, "__gc");']
            else:
                out += ['    lua_pushvalue(L, -2); lua_setfield(L, -2, "__index");']
            out += ['    lua_pop(L, 1);']
    # structs without a module of their own still need a metatable for their constructor
    out += [f'    lua_setglobal(L, "{mn}");', '}', '']
    return out


def gen_c(api):
    o = ['/* Generated by tools/luagen.py from engine/api.xml; do not edit. */',
         '#include "api_lua.h"', '', '#include <stdlib.h>', '#include <string.h>', '',
         f'#define API_MAX_ARRAY {MAX_ARRAY}', '',
         'static void api_push_ptr(lua_State *L, const void *p)', '{', '    if (p) lua_pushlightuserdata(L, (void *)p); else lua_pushnil(L);', '}', '',
         'static int api_array_len(lua_State *L, int i, int max)', '{',
         '    luaL_checktype(L, i, LUA_TTABLE);', '    int n = (int)luaL_len(L, i);',
         '    luaL_argcheck(L, n <= max, i, "too many elements");', '    return n;', '}', '',
         '/* Owned handles are found again from their C pointer (callbacks get a const pointer). */',
         'static void api_handle_register(lua_State *L, const void *p, int idx)   /* idx 0 forgets p */', '{',
         '    if (idx) idx = lua_absindex(L, idx);',
         '    lua_getfield(L, LUA_REGISTRYINDEX, "engine.handles");',
         '    lua_pushlightuserdata(L, (void *)p);',
         '    if (idx) lua_pushvalue(L, idx); else lua_pushnil(L);',
         '    lua_rawset(L, -3);', '    lua_pop(L, 1);', '}', '',
         'static void api_handle_lookup(lua_State *L, const void *p)', '{',
         '    lua_getfield(L, LUA_REGISTRYINDEX, "engine.handles");', '    lua_pushlightuserdata(L, (void *)p);',
         '    lua_rawget(L, -2);', '    lua_remove(L, -2);', '}', '',
         '/* ---------------------------------------------------------------- structs */', '']
    for s in api.structs.values():
        o += gen_struct(api, s)
    o += ['/* ---------------------------------------------------------------- handles */', '']
    for h in api.handles.values():
        o += gen_handle(api, h)
    o += ['/* -------------------------------------------------------------- functions */', '']
    for m in api.modules:
        for fn in m.findall('function'):
            o += gen_function(api, m, fn)
    o += ['/* ----------------------------------------------------------- registration */', '']
    for m in api.modules:
        o += gen_module_open(api, m)
    o += ['void api_open(lua_State *L)', '{',
          '    lua_newtable(L);', '    lua_newtable(L);', '    lua_pushstring(L, "v"); lua_setfield(L, -2, "__mode");',
          '    lua_setmetatable(L, -2);', '    lua_setfield(L, LUA_REGISTRYINDEX, "engine.handles");']
    # structs that have no module still get a metatable + constructor global
    for s in api.structs.values():
        if s.get('name') not in api.types:
            n = s.get('name')
            o += [f'    luaL_newmetatable(L, "engine.{n}"); lua_pop(L, 1);',
                  f'    lua_newtable(L); lua_newtable(L); lua_pushcfunction(L, l_{n}_new); lua_setfield(L, -2, "__call"); lua_setmetatable(L, -2);',
                  f'    lua_setglobal(L, "{n}");']
    for m in api.modules:
        o.append(f'    open_{m.get("name")}(L);')
    o += ['}', '']
    return '\n'.join(o)


def gen_h(api):
    o = ['/* Generated by tools/luagen.py from engine/api.xml; do not edit. */',
         '#ifndef API_LUA_H', '#define API_LUA_H', '', '#include "engine.h"', '#include "third_party/lua/lauxlib.h"',
         '#include "third_party/lua/lua.h"', '#include "third_party/lua/lualib.h"', '',
         '/* Registers every module as a global table. */', 'void api_open(lua_State *L);', '',
         '/* Value types: push creates a table, get reads one leniently (nil = zero),',
         ' * check insists on a table, store writes the fields into an existing table. */']
    for s in api.structs.values():
        n, c = s.get('name'), s.get('c')
        o += [f'void api_push_{n}(lua_State *L, {c} v);', f'{c} api_get_{n}(lua_State *L, int i);',
              f'{c} api_check_{n}(lua_State *L, int i);', f'void api_store_{n}(lua_State *L, int i, {c} v);']
    o += ['', '/* Handles. */']
    for h in api.handles.values():
        n, c = h.get('name'), h.get('c')
        if h.get('light'):
            o.append(f'void api_push_{n}(lua_State *L, {c} p);')
        elif h.get('owned'):
            o += [f'{c} *api_check_{n}(lua_State *L, int i);', f'void api_push_{n}(lua_State *L, const {c} *p);   /* nil if unknown */']
        else:
            o += [f'{c} api_check_{n}(lua_State *L, int i);', f'void api_push_{n}(lua_State *L, {c} p);']
    o += ['', '/* Implemented by hand in script.c (declared with impl="..." in api.xml). */']
    for m in api.modules:
        for fn in m.findall('function'):
            if fn.get('impl'):
                o.append(f'int {fn.get("impl")}(lua_State *L);')
    o += ['', '/* Trampolines for callback fields of handles. */']
    for h in api.handles.values():
        for f in h.findall('field'):
            if f.get('type') == 'callback':
                o.append(f.get('decl') + ';')
    o += ['', '#endif', '']
    return '\n'.join(o)


# ------------------------------------------------------------------- docs

def md_type(api, a):
    t = api.luatype(a.get('type'))
    if a.get('optional') == 'true' or a.get('default') is not None:
        t += '?'
    return t


def gen_md(api):
    root = api.root
    o = ['# Lua API reference', '', '<!-- Generated by tools/luagen.py from engine/api.xml; do not edit. -->', '',
         ' '.join(root.findtext('description', '').split()), '',
         'Argument types: `number`, `integer`, `boolean`, `string`, the value types below, `T[]` for a sequence. '
         'A `?` marks an optional argument. Functions whose first argument is the module\'s own type are also methods: `rect.inflate(r, 4)` is `r:inflate(4)`.', '']
    o += ['## Modules', '']
    for m in api.modules:
        o.append(f'- [`{m.get("name")}`](#{m.get("name")}) - {doc_of(m) or ""}'.rstrip(' -'))
    o.append('')
    documented = set()
    for m in api.modules:
        mn, t = m.get('name'), m.get('type')
        o += [f'## {mn}', '']
        if doc_of(m):
            o += [doc_of(m), '']
        if t:
            documented.add(t)
            o += struct_md(api, t)
        for e in m.findall('enum'):
            o += [f'**{mn}.{{{", ".join(v.get("name") for v in e.findall("value"))}}}** - {doc_of(e)}', '']
            rows = [f'| `{mn}.{v.get("name")}` | {doc_of(v)} |' for v in e.findall('value') if doc_of(v)]
            if rows:
                o += ['| Value | |', '|---|---|'] + rows + ['']
        for k in m.findall('const'):
            o += [f'- `{mn}.{k.get("name")}` ({api.luatype(k.get("type"))}) {doc_of(k)}'.rstrip(), '']
        for fn in m.findall('function'):
            args = lua_args(fn)
            sig = f'{mn}.{lua_name(fn)}({", ".join(args)})'
            if is_method(api, m, fn):
                sig += f'  ·  {args[0].rstrip("?")}:{lua_name(fn)}({", ".join(args[1:])})'
            o += [f'### `{sig}`', '']
            if doc_of(fn):
                o += [doc_of(fn), '']
            rows = []
            for a in fn.findall('arg'):
                if a.get('type') == 'count' or a.get('ref') == 'out':
                    continue
                note = doc_of(a)
                if a.get('default') is not None:
                    note = (note + f' Default {a.get("default")}.').strip()
                if a.get('ref') == 'inout' and a.get('type') not in api.structs:
                    note = (note + ' Returned updated.').strip()
                elif a.get('ref') == 'inout':
                    note = (note + ' Updated in place and returned.').strip()
                rows.append(f'| `{a.get("name")}` | `{md_type(api, a)}` | {note} |')
            if rows:
                o += ['| Argument | Type | |', '|---|---|---|'] + rows + ['']
            rets = []
            r = fn.find('returns')
            if r is not None:
                rets.append(f'`{api.luatype(r.get("type"))}{"?" if r.get("optional") == "true" else ""}`' + (f' - {doc_of(r)}' if doc_of(r) else ''))
            for a in fn.findall('arg'):
                if a.get('ref') == 'out':
                    rets.append(f'`{api.luatype(a.get("type"))}` - {a.get("name")}')
                elif a.get('ref') == 'inout':
                    rets.append(f'`{api.luatype(a.get("type"))}` - {a.get("name")}, updated')
            if rets:
                o += ['**Returns:** ' + '; '.join(rets), '']
    o += ['## Other value types', '', 'Plain tables with these fields; each has a constructor of the same name taking a table (`input{pos = p}`).', '']
    for s in api.structs.values():
        if s.get('name') not in documented:
            o += [f'### {s.get("name")}', ''] + struct_md(api, s.get('name'))
    return '\n'.join(o) + '\n'


def struct_md(api, t):
    o = []
    if t in api.structs:
        s = api.structs[t]
        if doc_of(s):
            o += [doc_of(s), '']
        if s.get('array'):
            return o
        o += ['| Field | Type | |', '|---|---|---|']
        for f in s.findall('field'):
            o.append(f'| `{f.get("name")}` | `{api.luatype(f.get("type"))}` | {doc_of(f)} |')
        o.append('')
    elif t in api.handles:
        h = api.handles[t]
        if doc_of(h):
            o += [doc_of(h), '']
        fields = h.findall('field')
        if fields:
            o += ['| Field | Type | Access | |', '|---|---|---|---|']
            for f in fields:
                ft = f.get('type')
                lt = 'function' if ft == 'callback' else api.luatype(ft)
                acc = 'read/write' if f.get('access') == 'rw' or ft == 'callback' else 'read'
                o.append(f'| `{f.get("name")}` | `{lt}` | {acc} | {doc_of(f)} |')
            o.append('')
    return o


# ------------------------------------------------------------- annotations

def gen_dlua(api):
    o = ['---@meta engine', '-- Generated by tools/luagen.py from engine/api.xml; do not edit.', '-- Load this file in your Lua language server for completion and checks.', '']
    for s in api.structs.values():
        n = s.get('name')
        o.append(f'---@class {n} {doc_of(s)}'.rstrip())
        if s.get('array'):
            o[-1] = f'---@alias {n} integer[] {doc_of(s)}'.rstrip()
        else:
            for f in s.findall('field'):
                o.append(f'---@field {f.get("name")} {api.luatype(f.get("type"))} {doc_of(f)}'.rstrip())
        o.append('')
    for h in api.handles.values():
        n = h.get('name')
        o.append(f'---@class {n} {doc_of(h)}'.rstrip())
        for f in h.findall('field'):
            lt = 'function' if f.get('type') == 'callback' else api.luatype(f.get('type'))
            o.append(f'---@field {f.get("name")} {lt} {doc_of(f)}'.rstrip())
        o.append('')
    for m in api.modules:
        mn, t = m.get('name'), m.get('type')
        o.append(f'---@class {mn}lib')
        for e in m.findall('enum'):
            for v in e.findall('value'):
                o.append(f'---@field {v.get("name")} integer {doc_of(v)}'.rstrip())
        for k in m.findall('const'):
            o.append(f'---@field {k.get("name")} {api.luatype(k.get("type"))} {doc_of(k)}'.rstrip())
        if t in api.structs:
            s = api.structs[t]
            if s.get('ctor'):
                params = ', '.join(f'{f}?: number' for f in s.get('ctor').split(','))
                o.append(f'---@overload fun({params}): {t}')
            o.append(f'---@overload fun(t?: table): {t}')
        o.append(f'{mn} = {{}}')
        o.append('')
        for fn in m.findall('function'):
            if doc_of(fn):
                o.append('---' + doc_of(fn))
            names = []
            for a in fn.findall('arg'):
                if a.get('type') == 'count' or a.get('ref') == 'out':
                    continue
                opt = '?' if a.get('optional') == 'true' or a.get('default') is not None else ''
                o.append(f'---@param {a.get("name")}{opt} {api.luatype(a.get("type"))} {doc_of(a)}'.rstrip())
                names.append(a.get('name'))
            r = fn.find('returns')
            if r is not None:
                o.append(f'---@return {api.luatype(r.get("type"))}{"?" if r.get("optional") == "true" else ""} {r.get("name") or ""} {doc_of(r)}'.rstrip())
            for a in fn.findall('arg'):
                if a.get('ref') in ('out', 'inout'):
                    o.append(f'---@return {api.luatype(a.get("type"))} {a.get("name")}')
            o.append(f'function {mn}.{lua_name(fn)}({", ".join(names)}) end')
            o.append('')
    return '\n'.join(o)


def validate(api):
    seen = set()
    for m in api.modules:
        for fn in m.findall('function'):
            key = (m.get('name'), lua_name(fn))
            if key in seen:
                raise ValueError('duplicate function %s.%s' % key)
            seen.add(key)
            if not fn.get('c') and not fn.get('impl'):
                raise ValueError('%s.%s needs c= or impl=' % key)
            for a in fn.findall('arg'):
                if a.get('type') == 'count' and a.get('of') not in {x.get('name') for x in fn.findall('arg')}:
                    raise ValueError('%s.%s: count of unknown array' % key)


def main():
    p = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    p.add_argument('--check', action='store_true', help='fail if the generated files are out of date')
    p.add_argument('--source', type=Path, default=SOURCE)
    args = p.parse_args()
    api = Api(ET.parse(args.source).getroot())
    validate(api)
    outputs = {'c': gen_c(api), 'h': gen_h(api), 'md': gen_md(api), 'dlua': gen_dlua(api)}
    stale = []
    for k, text in outputs.items():
        path = OUTPUTS[k]
        if args.check:
            if not path.exists() or path.read_text(encoding='utf-8') != text:
                stale.append(path)
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text, encoding='utf-8')
            print('wrote', path.relative_to(ROOT))
    if stale:
        sys.exit('out of date (run tools/luagen.py): ' + ', '.join(str(s.relative_to(ROOT)) for s in stale))


if __name__ == '__main__':
    main()
