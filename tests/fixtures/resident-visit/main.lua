-- Tap the actual building before and after meeting its resident, then revisit.
local game = assert(app.arg("visit-game"))
local desc = require("games/" .. game .. "/lua/main")
local R, island = require("state"), require("island")
local site = game == "relic-rush" and "aviary" or "glassblower"
local kind = island.kinds[site]
local init, frame = desc.init, desc.frame
local item, tick = nil, 0

function desc.init()
    init()
    R.island_with(0, island.ladder_position[kind])
    for i = 1, R.island.count do
        if R.island.items[i].type == kind then item = i end
    end
    assert(item, "resident building should be placed")
    R.on_island, R.overlay = true, R.OV_NONE
    R.island_focus(R.island.items[item].pos - vec2(0, 80), .8)
end

local function tap()
    local c = R.island
    local bounds = c.cam:rect_to_screen(c:sprite_rect(c.items[item]))
    for y = 2, 8 do
        for x = 2, 8 do
            local point = bounds:point(vec2(x / 10, y / 10))
            if app.screen():contains(point) and c:building_at(c.cam:to_world(point)) == item - 1 then
                app.inject_click(point)
                return
            end
        end
    end
    error("resident needs an exposed tap target")
end

function desc.frame(dt)
    tick = tick + 1
    if app.arg("visit-marker") then
        R.prog.story_seen["placed-" .. site] = true
        frame(dt)
        return
    end
    if tick == 30 then tap() end
    if tick == 35 then
        assert(not story.active() and R.town.bubble and R.town.bubble.item == item - 1, "unmet resident uses ordinary building bubble")
        R.prog.story_seen["placed-" .. site] = true
        assert(R.town.hooks.unheard_visit(kind), "meeting the resident unlocks the first marker")
    elseif tick == 37 then
        local box = assert(R.town:visit_marker_bounds(item - 1), "marker must be on screen")
        app.inject_click(box:center())
    elseif tick == 40 then
        assert(story.active() and R.story_current.phase == "visit", "tapping the marker opens the visit")
        assert(R.town.hooks.unheard_visit(kind), "an unfinished conversation is still unheard")
        while story.active() do story.next() end
    elseif tick == 45 then
        assert(not R.town.hooks.unheard_visit(kind), "finishing the conversation clears its marker")
        local stage = app.arg("visit-stage")
        R.prog.story_seen[stage] = true
        assert((not not R.town.hooks.unheard_visit(kind)) == (stage ~= "placed-" .. site), "only new dialogue restores the marker")
        tap()
    elseif tick == 50 then
        assert(story.active() and R.story_current.phase == "visit", "the building remains tappable on repeat visits")
    end
    frame(dt)
end
return desc
