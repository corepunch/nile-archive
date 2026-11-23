-- The shared portrait match-3 game (engine/lua/match3/game.lua): each game's
-- lua/game_config.lua reaches the engine, and its journey content keeps the
-- story's meaning as data. Runs in Relic Rush and Christmas Market.
local game = require("match3.game")
local journey = require("journey")

local W = game.config()
check(W.app.id == testing.game, "game_config.lua is read at load time and names its game")
check(#W.packs >= 1 and #W.catalogue.categories >= 3, "packs and shop categories come from the game")
for _, cat in ipairs(W.catalogue.categories) do check(#cat == 2, "a category is {key, label}") end
check(W.notices.reward_building ~= game.DEFAULTS.notices.reward_building, "the game words replace the engine defaults")
check(W.confirm.cancel == game.DEFAULTS.confirm.cancel, "words a game leaves out keep the engine default")

local R = require("state")
require("main")
check(not R.wonder_form.nodes.unlock and not R.wonder_form.nodes.upgrade and not R.result_form.nodes.next_step,
    "reward icons and essential figures carry the popup without extra unlock or next-project copy")

local merged = game.config({catalogue = {categories = {{"all", "All"}}}, speech = {scale = 2}})
check(#merged.catalogue.categories == 1 and merged.catalogue.title == game.DEFAULTS.catalogue.title,
      "arrays replace, objects merge field by field")
check(merged.speech.scale == 2 and merged.speech.name == game.DEFAULTS.speech.name, "nested defaults survive")

-- Tap lines: the latest authored line the player has reached, else the catalogue's.
check(journey.building_about(99, 30, "fallback") == "fallback", "an unlisted building keeps its catalogue line")
for _, line in ipairs(journey.about) do
    check(journey.building_about(line[1], line[2] - 1, "x") ~= line[3], "a line waits for its level")
    check(journey.building_about(line[1], 100, "x") ~= "x", "a listed building has a line by the end")
end
if journey.has_recap then
    local recap = journey.recap(0)
    check(#recap >= 2 and recap[1] == journey.recap(100)[1], "a recap opens with the same line at every level")
    check(#journey.recap(100) >= #recap, "a later recap says at least as much")
end
for _, beat in ipairs(journey.beats) do check(journey.find(beat.key) == beat, "beats are found by key") end
