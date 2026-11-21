-- Use the same town confirmation and story queue that a player sees.
local R, island, journey = require("state"), require("island"), require("journey")
require("main")
R.test_mode, R.quiet, R.overlay, R.on_island = true, false, R.OV_NONE, true
R.island = city.new()
island.island_setup(R.island)
R.wonders, R.buildings = island.wonders, island.buildings
R.prog = {level=6, seed=1, wallet=purse(9999,9999,9999,6), story_seen={}}
for _, beat in ipairs(journey.beats) do
    if beat.level <= 6 then R.prog.story_seen[beat.key] = true end
end
R.town_setup()

local callbacks = {}
for _, beat in ipairs(journey.beats) do
    local v = beat.variant
    if v then
        local step = island.ladder[island.ladder_position[island.kinds[v.building]]]
        check(step and beat.level > step.after, "callback follows its purchase")
        check(journey.lines_for(beat, function() return false end) == beat.lines, "unbuilt callback uses the campaign line")
        check(journey.lines_for(beat, function(key) return key == v.building end)[v.index] == v.line, "built callback uses the reply")
        callbacks[v.building] = true
    end
end
for _, step in ipairs(island.ladder) do
    local key = step.unlock.building
    if not step.story then
        check(journey.find("placed-" .. key) and callbacks[key], key .. " has a purchase conversation and a later callback")
    end
end

check(R.debug_advance_town(), "confirm the first story building")
local kind = island.next_step(R.island, R.prog.level)
local key = "placed-" .. island.buildings[kind + 1].key
local callback = journey.find("after-07")
check(R.story_lines(callback) == callback.lines, "waiting to build preserves the original exchange")
check(R.town:begin(kind, false), "preview the next purchase")
check(not journey.next_placement(R.prog), "preview has no conversation")
check(R.town:confirm(), "confirm the purchase")
check(R.story_lines(callback)[callback.variant.index] == callback.variant.line, "confirmation changes the next clear's dialogue")
R.story_tick()
check(R.story_current and R.story_current.key == key, "the town plays the confirmed building's exchange")
story.next()
save.write("town-story-interrupted", function(s) journey.serialize(s, R.prog) end)
while story.active() do story.next() end
R.story_current, R.prog.story_seen = nil, {}
save.read("town-story-interrupted", function(s) journey.serialize(s, R.prog) end)
R.story_tick()
check(R.story_current and R.story_current.key == key, "reload resumes the interrupted conversation")
while story.active() do story.next() end
R.story_tick()
check(R.prog.story_seen[key] and not journey.next_placement(R.prog), "finishing clears the pending conversation")
