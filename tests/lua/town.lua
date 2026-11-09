-- The shared town screen's configuration: the JSON decoder and the merge of a
-- game's town.json over the engine defaults (engine/json.lua, engine/town.lua).
local json = require("json")
local town = require("town")

local v = json.decode('{"a": [1, 2.5, -3e2], "b": {"c": "x\\"y\\u00e9"}, "t": true, "f": false, "n": null}')
check(v.a[1] == 1 and v.a[2] == 2.5 and v.a[3] == -300, "numbers decode")
check(v.b.c == 'x"y\u{e9}', "strings unescape, including \\u")
check(v.t == true and v.f == false and v.n == json.null, "literals decode")
check(not pcall(json.decode, '{"a": 1,}'), "a trailing comma is an error")
check(not pcall(json.decode, '[1] 2'), "trailing characters are an error")

local cfg = town.config(json.decode('{"header": {"align": "right", "role": null}, "bottom": {"middle": {"kind": "custom"}}}'))
check(cfg.header.align == "right" and cfg.header.role == nil, "a game overrides one field and null clears a default")
check(cfg.header.width == 110 and cfg.bottom.build == 132, "untouched defaults survive")
check(cfg.bottom.middle.kind == "custom" and cfg.bottom.middle.diameter == 64, "nested objects merge field by field")
for _, game in ipairs({"relic-rush", "christmas-market", "nile-archive"}) do
    local text = app.read_text("../../" .. game .. "/data/town.json") or app.read_text("games/" .. game .. "/data/town.json")
    check(text and json.decode(text).texts.placing, game .. " ships a town.json with its wording")
end
