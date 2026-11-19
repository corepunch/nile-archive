local game = require("games/relic-rush/lua/main")
local R, island, rules, quests = require("state"), require("island"), require("rules"), require("quests")
local init = game.init
local stage, frames, parked = 0, 0

local function press(overlay, form, id)
    if R.overlay ~= overlay or R.modal_for ~= overlay or not R.dialog_settled() then return false end
    local box = form.boxes[id]
    if not box then return false end
    app.inject_click(box:center() + vec2(0, R.drop / 2))
    return true
end

function game.init()
    init()
    R.quiet = true
    R.island_with(0)
    R.prog.level = 1
    assert(R.start_level(1) and #R.board_quest_items() == 0)
    parked = R.g
    parked.moves, parked.earnings[1] = parked.moves - 1, 15
    R.on_island = true
    assert(island.island_place_next(R.island, purse(10000, 10000, 10000), R.prog.level, 0))
    for _, beat in ipairs(require("journey").beats) do R.prog.story_seen[beat.key] = true end
    R.quiet = false
end

function R.smoke()
    frames = frames + 1
    assert(frames < 1000, "quest flow stalled at stage " .. stage)
    if R.diving() then return end
    if stage == 0 and press(R.OV_QUEST, R.quest_form, "action") then
        assert(R.quest_offer and R.quest_card == "chart" and R.quest_form:get("action") == "FIND CHART PAGES")
        assert(R.quest_state().introduced.chart and not R.quest_state().introduced.supper)
        R.quiet = true
        stage = 1
    elseif stage == 1 and not R.on_island and R.board_quest_bounds then
        assert(R.g == parked and R.g.moves == rules.level_of(parked).moves - 1 and R.g.earnings[1] == 15,
            "the well should leave a parked board's moves and earnings intact")
        local items = R.board_quest_items()
        assert(#items == 2 and items[1].id == "chart" and items[2].id == "supper",
            "Play from the chart card should resume with both quest pieces")
        assert(R.board_quest_bounds:max().y <= R.BOARD_CLIP.y,
            "the phone counter row should stay above the board")

        R.on_island, R.prog.level = true, rules.LEVELS
        R.quest_state().have.chart = quests.by_key.chart.need - 1
        assert(R.open_quest("chart"))
        stage = 2
    elseif stage == 2 and press(R.OV_QUEST, R.quest_form, "action") then
        assert(R.quest_form:get("action") == "REPLAY EXPEDITION " .. quests.REPLAY_LEVEL)
        stage = 3
    elseif stage == 3 and not R.on_island and R.overlay == R.OV_NONE then
        assert(R.g.level == quests.REPLAY_LEVEL - 1 and #R.board_quest_items() == 2)
        local banked = R.quest_state().have.chart
        R.g.items.chart = 3
        assert(R.board_quest_items()[1].amount == ("%d/%d"):format(banked + 1, banked + 1),
            "the board counter should include pending matches and cap at the target")
        assert(R.quest_state().have.chart == banked, "the counter must leave banked progress alone")
        assert(R.debug_skip_level())
        stage = 4
    elseif stage == 4 and press(R.OV_RESULT, R.result_form, "claim") then
        R.quiet = false
        stage = 5
    elseif stage == 5 and R.on_island and R.overlay == R.OV_QUEST then
        assert(R.prog.level == rules.LEVELS and R.quest_model("chart").ready,
            "a replay should bank request pieces without advancing the campaign")
        assert(R.quest_card == "chart" and R.quest_offer and R.quest_state().ready_seen.chart,
            "returning with enough pieces automatically offers the hand-in")
        stage = 6
    elseif stage == 6 and press(R.OV_QUEST, R.quest_form, "action") then
        stage = 7
    elseif stage == 7 and press(R.OV_QUEST_HANDOFF, R.quest_handoff_form, "continue") then
        assert(not R.quest_state().done.chart and texture.size(R.quest_model("chart").handoff.image).w == 768)
        R.quiet = false
        stage = 8
    elseif stage == 8 and R.quest_state().done.chart then
        assert(not R.quest_model("chart"), "the illustrated hand-in should deliver exactly once")
        assert(story.active() and R.story_current.key == "quest-chart", "Continue should play the chart dialogue")
        while story.active() do story.next() end
        R.story_tick()
        R.island_with(3)
        island.restore_quay(R.island, 0)
        R.prog.level, R.overlay = 9, R.OV_NONE
        local state = R.quest_state()
        state.done.trail, state.have.cable = true, quests.by_key.cable.need
        assert(not R.open_quest("shutter"), "finding all the coils alone must not unlock the shutter")
        assert(R.open_quest("cable"))
        stage = 9
    elseif stage == 9 and press(R.OV_QUEST, R.quest_form, "action") then
        stage = 10
    elseif stage == 10 and press(R.OV_QUEST_HANDOFF, R.quest_handoff_form, "continue") then
        stage = 11
    elseif stage == 11 and R.story_current and R.story_current.key == "quest-cable" then
        while story.active() do story.next() end
        stage = 12
    elseif stage == 12 and press(R.OV_QUEST, R.quest_form, "close") then
        assert(R.quest_offer and R.quest_card == "shutter", "Tomas must introduce the test after the cable dialogue")
        assert(R.quest_form:get("action") == "LIFT THE SHUTTER")
        stage = 13
    elseif stage == 13 and R.overlay == R.OV_NONE then
        assert(R.quest_state().introduced.shutter and not R.quest_state().done.shutter)
        assert(R.town.rail_targets.shutter and R.town.buttons.play and R.town.buttons.build)
        app.inject_click(R.town.rail_targets.shutter)
        stage = 14
    elseif stage == 14 and press(R.OV_QUEST, R.quest_form, "action") then
        stage = 15
    elseif stage == 15 and press(R.OV_QUEST_HANDOFF, R.quest_handoff_form, "continue") then
        assert(R.quest_handoff_form.boxes.detail and R.quest_handoff_form.boxes.observation)
        stage = 16
    elseif stage == 16 and R.quest_state().done.shutter then
        assert(story.active() and R.story_current.key == "quest-shutter")
        assert(R.prog.level == 9 and not R.open_quest("shutter"), "the field test resolves once without advancing a level")
        local steps
        for index, building in ipairs(R.island.items) do
            if building.type == island.kinds.quay_steps then steps = index - 1 end
        end
        assert(steps and R.building_words(steps):find("marks the reef in red", 1, true),
            "the quay should remember the result of the field test")
        -- Later ladder steps have no opening-epoch story request. The rail
        -- still has to route a funded purchase to its own placement card.
        while story.active() do story.next() end
        R.quiet = true
        R.island_with(0, 4)
        R.prog.level = island.ladder[5].after
        R.prog.wallet = purse(10000, 10000, 10000, R.prog.level)
        stage = 17
    elseif stage == 17 and R.town.rail_targets.build then
        assert(R.quest_rail()[1].value == "BUILD", "the island flags an affordable restoration")
        app.inject_click(R.town.rail_targets.build)
        stage = 18
    elseif stage == 18 and press(R.OV_WONDER, R.wonder_form, "action") then
        assert(R.inspect == island.ladder[5].kind and R.wonder_form:get("notice") == "READY TO BUILD")
        stage = 19
    elseif stage == 19 and R.island.placing == island.ladder[5].kind then
        app.quit()
    end
end

return game
