-- Run the archived town script through the engine's opt-in story mode.
require('game_config').campaign_dialogue = true
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
    for _, v in ipairs(beat.replies or {}) do
        local step = island.ladder[island.ladder_position[island.kinds[v.building]]]
        check(step and beat.level > step.after, "callback follows its purchase")
        check(journey.lines_for(beat, function() return false end) == beat.lines, "unbuilt callback uses the campaign line")
        local seen = {}
        if v.introduction then seen[v.introduction] = true end
        check(journey.lines_for(beat, function(key) return key == v.building end, seen)[v.index] == v.line, "eligible callback uses its reply")
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
check(R.story_lines(callback)[callback.replies[1].index] == callback.replies[1].line, "confirmation changes the next clear's dialogue")
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

-- A returning player may already have seen the old conversation at the site.
-- Let them meet the new resident before any queued level can give them a line.
local site = testing.game == "relic-rush" and "aviary" or "glassblower"
local arrival = journey.find("placed-" .. site)
local callback_count = 0
local function owns_site(building) return building == site end
save.write("pre-resident-town", function(s)
    s:int("narrative.v1." .. arrival.key, 2)
    s:int("narrative.v1." .. arrival.invitation, 1)
end)
local resident_save = {story_seen={}}
save.read("pre-resident-town", function(s) journey.serialize(s, resident_save) end)
check(not journey.next_arrival(resident_save, function() return false end), "an invitation alone never brings a resident")
check(journey.next_arrival(resident_save, owns_site) == arrival, "an existing owner receives the new introduction")
resident_save.story_seen[arrival.invitation] = false
check(not journey.next_arrival(resident_save, owns_site), "the introduction waits for the letter or invitation")
resident_save.story_seen[arrival.invitation] = true
R.island:add(vec2(0,0), island.kinds[site], 0)
R.prog = resident_save
R.prog.level = journey.find(arrival.invitation).level
R.story_tick()
check(R.story_current == arrival, "meeting the resident precedes the later campaign scenes")
while story.active() do story.next() end
R.story_tick()
check(resident_save.story_seen[arrival.key], "finishing the introduction welcomes the resident")
save.write("welcomed-resident", function(s) journey.serialize(s, resident_save) end)
resident_save = {story_seen={}}
save.read("welcomed-resident", function(s) journey.serialize(s, resident_save) end)
check(not journey.next_arrival(resident_save, owns_site), "reloading preserves the welcome")
for _, beat in ipairs(journey.beats) do
    for _, reply in ipairs(beat.replies or {}) do
        if reply.introduction == arrival.key then
            check(journey.lines_for(beat, owns_site, {}) == beat.lines, "resident cannot speak before the introduction")
            check(journey.lines_for(beat, owns_site, resident_save.story_seen)[reply.index][1] == arrival.resident,
                "the resident joins the later conversation after reload")
            callback_count = callback_count + 1
        end
    end
end
check(callback_count >= 2, "the resident returns in later level conversations")
