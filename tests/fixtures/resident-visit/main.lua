-- Tap the actual building before and after meeting its resident, then revisit.
local game = assert(app.arg("visit-game"))
local desc = require("games/" .. game .. "/lua/main")
local R, island = require("state"), require("island")
local site = game == "relic-rush" and "aviary" or "glassblower"
local kind = island.kinds[site]
local init, frame = desc.init, desc.frame
local item, tick = nil, 0
local stage = app.arg("visit-stage")
local first = "placed-" .. site

local function select_question(id)
    assert(R.overlay == R.OV_STORY_CHOICE and not story.active(), "resident questions should be open")
    app.inject_click(assert(R.choice_form.boxes[id]):center())
end

local function finish_answer(index)
    local visit = require("journey").visit(R.prog, site)
    local answer = visit.choices[index]
    assert(story.active() and R.story_current.key == answer.key and R.story_current.lines == answer.lines,
        "the tapped question plays its own answer")
    assert(not R.prog.story_seen[answer.key], "an unfinished answer is still new")
    while story.active() do story.next() end
end

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
    if app.arg("visit-questions") and stage == first and tick >= 52 then
        assert(R.overlay == R.OV_STORY_CHOICE and R.town.hooks.unheard_visit(kind))
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
    elseif tick == 52 then
        select_question("cancel")
    elseif tick == 68 then
        assert(R.overlay == R.OV_NONE and R.town.hooks.unheard_visit(kind), "leaving keeps the marker")
        tap()
    elseif tick == 88 then
        select_question("2")
    elseif tick == 108 then
        finish_answer(2)
    elseif tick == 112 then
        assert(R.town.hooks.unheard_visit(kind), "the other question keeps the bubble")
        tap()
    elseif tick == 134 then
        select_question("1")
    elseif tick == 155 then
        finish_answer(1)
    elseif tick == 160 then
        assert(not R.town.hooks.unheard_visit(kind), "hearing both answers clears the marker")
        R.prog.story_seen[stage] = true
        assert(R.town.hooks.unheard_visit(kind) == (stage ~= first), "a new checkpoint restores the marker")
        tap()
    elseif tick == 180 then
        select_question(app.arg("visit-questions") and "1" or "2")
    elseif tick == 200 and app.arg("visit-questions") then
        finish_answer(1)
    elseif tick == 205 and app.arg("visit-questions") then
        assert(R.town.hooks.unheard_visit(kind), "the later story answer is still new")
        tap()
    elseif tick == 225 then
        if app.arg("visit-questions") then
            assert(R.overlay == R.OV_STORY_CHOICE)
        else
            assert(story.active() and R.story_current.phase == "visit", "a heard answer can be replayed")
        end
    end
    frame(dt)
end
return desc
