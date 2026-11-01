-- The engine's Lua API and UI, in the C tests' one start of build/test/engine. See docs/TESTING.md.
rules("injections")
rules("modules", "tests/fixtures/modules/first;;tests/fixtures/modules/second;")
rules("match3")
rules("city_transactions")
if match3_root then rules("engine_match3", match3_root) end
rules("api")
rules("tween")
rules("forms", "games/relic-rush/lua")
rules("ui_skin", "games/relic-rush/lua")
rules("clayfight", "games/clayfight/lua")
