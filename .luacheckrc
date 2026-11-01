-- luacheck configuration, run by `make lint` (apt: lua-check, or luarocks).
--
-- The engine's Lua API (engine/api.xml, docs/LUA_API.md) is a fixed set of
-- global tables; everything else a script touches must be local, so a typo
-- or a forgotten import shows up as an undefined global.
std = "lua54"
max_line_length = false
unused_args = false
-- Deliberately malformed fixture: the loader must retain its compiler diagnostic.
exclude_files = {"tests/fixtures/modules/first/loader/syntax.lua"}
read_globals = {
    -- modules
    "app", "input", "gfx", "texture", "camera", "fx", "font", "style", "text", "sfx", "ui", "save", "story", "city",
    "sprite", "nav", "board_intro",
    -- value types
    "vec2", "size2", "rect", "color", "purse", "num", "ease", "tween",
    -- descriptors
    "story_style", "ui_theme", "building", "building_def", "character", "city_event", "city_zone", "nav_blocker",
    "sprite_frame", "story_line", "ui_state",
}
files["engine/tween.lua"] = {globals = {"ease", "tween"}}         -- defines the easing catalogue and the tween module
files["engine/ui_forms.lua"] = {globals = {"ui"}}            -- defines ui.form, ui.modals and ui.modal_dismiss
files["engine/ui_skin.lua"] = {globals = {"ui"}}             -- defines ui.skin
files["games/clayfight/lua"] = {read_globals = {"clay"}}     -- Clayfight's host extension
files["tests/lua/clayfight.lua"] = {globals = {"clay", "font", "app", "input", "gfx", "ui"}}   -- stubs the engine
files["engine/city_smoke.lua"] = {globals = {"city"}}         -- defines city.move_test
files["tests/lua"] = {read_globals = {"check", "near", "testing"}}   -- from the test build
files["tests/games"] = {read_globals = {"rules", "smoke", "shot", "frame", "reel", "hold", "match3_root"}, globals = {"default_frames"}}

files["tests/lua/injections.lua"] = {read_globals = {"check", "near", "testing"}, globals = {"print"}}

files["tests/fixtures/trickling"] = {read_globals = {"testing"}} -- test-build presentation fixture

files["engine/board_intro.lua"] = {globals = {"board_intro"}}
