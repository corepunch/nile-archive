-- Exercise the real require boundary, without a window or filesystem stubs.
local function fails(name, expected)
    local ok, message = pcall(require, name)
    check(not ok and tostring(message):find(expected, 1, true), tostring(message))
    return message
end

local identity = require("loader.identity", "ignored extra argument")
check(identity == require("loader/identity"), "dot and slash names share one module instance")
check(identity.name == "loader.identity", "modules receive their canonical name")
check(require("loader.precedence") == "first", "the first matching script root wins")
check(require("loader.fallback") == "second", "missing modules fall through to later roots")
check(require("match3/frames") == require("match3.frames"), "aliases also share embedded modules")

local state = require("loader.state")
check(require("loader.no_value") == true and require("loader/no_value") == true, "nil modules return true")
check(state.no_value == 1, "nil modules run once")
check(require("loader.false_value") == false and require("loader/false_value") == false, "false is a cached value")
check(state.false_value == 1, "false modules run once")

local runtime_error = fails("loader.retry", "loader runtime failure")
check(runtime_error:find("stack traceback:", 1, true), "runtime errors retain the module traceback")
check(require("loader.retry") == state and state.attempts == 2, "failed modules can be retried")
fails("loader.cycle_a", "circular dependency loading module 'loader.cycle_a'")
state.break_cycle = true
check(require("loader.cycle_a") == state, "cycle failures clear every in-progress import")
local ok, object = pcall(require, "loader.error_object")
check(not ok and object == state, "runtime error objects are preserved")

local syntax_ok, syntax_error = pcall(require, "loader.syntax")
check(not syntax_ok and syntax_error:find("loader/syntax.lua:", 1, true) and
    not syntax_error:find("not found", 1, true), "syntax errors retain file and line without root fallback")
fails("loader.missing", "not found in configured script roots")
fails(string.rep("a", 2000), "not found in configured script roots")
for _, name in ipairs{"", ".", "..", "../support", "/support", "loader/", "loader..state",
    "loader//state", "loader./state", "loader\\state", "C:/state", "loader state", "loader\0.state"} do
    fails(name, "bad argument #1")
end
fails(12, "string expected")
check(require("loader.identity") == identity, "rejected imports leave the cache intact")
