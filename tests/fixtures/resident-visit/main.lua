-- Tap the actual building before and after meeting its resident, then revisit.
local game = assert(app.arg("visit-game"))
local desc = require("games/" .. game .. "/lua/main")
local R, island = require("state"), require("island")
local journey = require("journey")
local site = app.arg("visit-site") or (game == "relic-rush" and "aviary" or "glassblower")
local kind = island.kinds[site]
local init, frame = desc.init, desc.frame
local item, tick = nil, 0
local stage = app.arg("visit-stage")
local first = "placed-" .. site
local meeting = app.arg("visit-meeting") and assert(journey.find(app.arg("visit-meeting")))
local ending = app.arg("visit-ending") and assert(journey.find(stage).recall)
local full_menu = app.arg("visit-full-menu")
local heard_at = app.arg("heard-at")
local selected

local function select_question(id)
    assert(R.overlay == R.OV_STORY_CHOICE and not story.active(), "resident questions should be open")
    app.inject_click(assert(R.choice_form.boxes[id]):center())
end

local function finish_answer(index)
    local visit = journey.visit(R.prog, site)
    local answer = visit.choices[index]
    assert(story.active() and R.story_current.key == answer.key and R.story_current.lines == answer.lines,
        "the tapped question plays its own answer")
    assert(not R.prog.story_seen[answer.key], "an unfinished answer is still new")
    while story.active() do story.next() end
end

function desc.init()
    init()
    local position = island.ladder_position[kind]
    if meeting then
        for _, home in ipairs(meeting.sites) do
            position = math.max(position, island.ladder_position[island.kinds[home]])
            R.prog.story_seen["placed-" .. home] = true
        end
        if full_menu then
            for _, beat in ipairs(journey.beats) do
                if beat.level <= journey.find(stage).level then R.prog.story_seen[beat.key] = true end
            end
        end
        R.prog.story_seen[stage] = true
        if not full_menu then
            for _, answer in ipairs(journey.visit(R.prog, site).choices) do R.prog.story_seen[answer.key] = true end
        end
        journey.acknowledge(R.prog, meeting)
        if ending then
            if not full_menu then
                for _, answer in ipairs(meeting.followups) do R.prog.story_seen[answer.key] = true end
            end
            journey.acknowledge(R.prog, ending)
        end
        if heard_at then
            local source = full_menu and meeting or ending or meeting
            R.prog.story_seen[source.key .. "." .. heard_at] = true
        end
    end
    R.island_with(0, position)
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

local function tap_marker()
    local box = assert(R.town:visit_marker_bounds(item - 1), "marker must be on screen")
    app.inject_click(box:center())
end

local function direct_answer(key)
    assert(R.overlay == R.OV_NONE and not R.story_choice_beat and story.active()
        and R.story_current.key == key and R.prog.pending_answer.key == key, "the selected answer must be playing")
end

local function remaining_question(index)
    local beat = R.story_choice_beat
    assert(R.overlay == R.OV_STORY_CHOICE and not story.active() and not R.prog.pending_answer,
        "finishing an answer must wait for the player")
    assert(beat and #beat.choices == 1 and beat.choices[1] == journey.visit(R.prog, site).choices[index],
        "the same resident offers their remaining question")
    assert(R.choice_form.boxes.cancel, "the player can leave the visit")
end

function desc.frame(dt)
    tick = tick + 1
    if meeting then
        if tick == 30 then
            assert(R.town.hooks.unheard_visit(kind), "the meeting restores the marker")
            if ending then tap_marker() else tap() end
        elseif full_menu then
            if tick == 52 then
                assert(R.story_choice_beat and #R.story_choice_beat.choices == 5, "all five distinct questions fit in one visit")
                local screen, skin = app.screen(), require("skin")
                local bottom = screen.y
                for _, node in ipairs(R.choice_form.root.children) do
                    if node.kind == "button" then
                        local box = assert(R.choice_form.boxes[node.id])
                        assert(box.x >= screen.x and box.x + box.w <= screen.x + screen.w
                            and box.y >= bottom and box.y + box.h <= screen.y + screen.h,
                            "visit options must fit separately inside the safe screen")
                        assert(text.measure(skin:measure_style(node), node.text).w <= box.w - 16,
                            "visit caption needs more room: " .. node.text)
                        bottom = box.y + box.h
                    end
                end
                select_question("cancel")
            elseif tick == 80 then
                assert(R.overlay == R.OV_NONE and R.town.hooks.unheard_visit(kind), "leaving preserves every question")
                tap_marker()
            elseif tick == 100 then
                assert(R.story_choice_beat and #R.story_choice_beat.choices == 5, "reopening restores all five questions")
            end
        elseif tick == 52 then
            local key = (ending or meeting).key .. "." .. site .. (heard_at and not ending and ".reply" or "")
            if heard_at and not ending then
                assert(R.overlay == R.OV_STORY_CHOICE and #R.story_choice_beat.choices == 2)
                for index, answer in ipairs(R.story_choice_beat.choices) do
                    if answer.key == key then
                        selected = answer
                        assert(R.choice_form.boxes[tostring(index)], "question must have a tap target")
                        if not app.arg("visit-questions") then select_question(tostring(index)) end
                    end
                end
                assert(selected, "meeting question must be available")
            else
                direct_answer(key)
                selected = R.prog.pending_answer
            end
        elseif tick == 80 and not app.arg("visit-questions") then
            assert(story.active() and R.story_current.key == selected.key)
            story.next() -- the resident's reply
        elseif tick == 85 and not app.arg("visit-questions") then
            app.inject_click(app.screen():center()) -- reveal the full line
        end
        frame(dt)
        return
    end
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
    if app.arg("visit-continue") and tick >= 124 then
        remaining_question(1)
        frame(dt)
        return
    end
    if stage == first and tick >= 108 then
        assert(story.active() and R.story_current.key == journey.visit(R.prog, site).choices[2].key)
        frame(dt)
        return
    end
    if tick == 30 then tap() end
    if tick == 35 then
        assert(not story.active() and R.town.bubble and R.town.bubble.item == item - 1, "unmet resident uses ordinary building bubble")
        R.prog.story_seen["placed-" .. site] = true
        assert(R.town.hooks.unheard_visit(kind), "meeting the resident unlocks the first marker")
    elseif tick == 37 then
        tap_marker()
    elseif tick == 52 then
        select_question("cancel")
    elseif tick == 68 then
        assert(R.overlay == R.OV_NONE and R.town.hooks.unheard_visit(kind), "leaving keeps the marker")
        tap()
    elseif tick == 88 then
        select_question("2")
    elseif tick == 108 then
        finish_answer(2)
    elseif tick == 124 then
        remaining_question(1)
        select_question("1")
    elseif tick == 147 then
        direct_answer(journey.visit(R.prog, site).choices[1].key)
    elseif tick == 155 then
        finish_answer(1)
    elseif tick == 160 then
        assert(not R.town.hooks.unheard_visit(kind), "hearing both answers clears the marker")
        tap()
    elseif tick == 168 then
        assert(R.overlay == R.OV_NONE and R.town.bubble and R.town.bubble.item == item - 1,
            "a building with no questions shows its ordinary description")
        R.prog.story_seen[stage] = true
        assert(R.town.hooks.unheard_visit(kind), "a new checkpoint restores the marker")
        tap()
    elseif tick == 190 then
        select_question(app.arg("visit-questions") and "1" or "2")
    elseif tick == 210 and app.arg("visit-questions") then
        finish_answer(1)
    elseif tick == 225 and app.arg("visit-questions") then
        remaining_question(2)
        select_question("cancel")
    elseif tick == 244 and app.arg("visit-questions") then
        assert(R.overlay == R.OV_NONE and not story.active() and R.town.hooks.unheard_visit(kind),
            "Back to town leaves the unasked question on the roof")
        tap_marker()
    elseif tick == 250 then
        if app.arg("visit-questions") then
            direct_answer(journey.visit(R.prog, site).choices[2].key)
            app.inject_click(app.screen():center()) -- reveal the question for the capture
        else
            assert(story.active() and R.story_current.phase == "visit", "the next stage has a fresh answer")
        end
    end
    frame(dt)
end
return desc
