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
    assert(R.open_quest("chart"))
end

function R.smoke()
    frames = frames + 1
    assert(frames < 1000, "quest flow stalled at stage " .. stage)
    if R.diving() then return end
    if stage == 0 and press(R.OV_QUEST, R.quest_form, "action") then
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
        stage = 5
    elseif stage == 5 and R.on_island and R.overlay == R.OV_NONE then
        assert(R.prog.level == rules.LEVELS and R.quest_model("chart").ready,
            "a replay should bank request pieces without advancing the campaign")
        assert(R.open_quest("chart"))
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
        app.quit()
    end
end

return game
