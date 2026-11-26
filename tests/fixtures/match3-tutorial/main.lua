-- luacheck: globals testing
local desc = require("games/" .. testing.game .. "/lua/main")
local R, rules = require("state"), require("rules")
local init, frame = desc.init, desc.frame
local preview = tonumber(app.arg("tutorial-lesson"))
local lesson, moves, opening, expected, tracked, stage, frames, queued

local function start(level)
    R.prog.level = level - 1
    assert(R.start_level())
    R.layout()
    moves, opening, stage = R.g.moves, R.tutorial.move, "opening"
    if level <= 4 then assert(opening, "the campaign needs a playable lesson at level " .. level) end
end

local function start_bonus()
    -- Set up the board earned after purchasing the first tool building.
    local unlock = require("economy").unlocks[2]
    assert(unlock.bonus.action == "hit")
    R.board_context = function()
        return {[unlock.building]=true, bonus_charge={[1]=R.g.tool_threshold - unlock.bonus.amount}}
    end
    start(unlock.first_level)
    assert(R.g.bonus == unlock.bonus)
    stage = "charging"
end

function desc.init()
    init()
    R.smoke = function() end
    R.tutorial.enabled, R.quiet, R.reduced_motion = true, true, true
    lesson, frames = preview or 1, 0
    if lesson == 5 then start_bonus() else start(lesson) end
    local preview_moves = preview and tonumber(app.arg("moves"))
    if preview_moves then R.g.moves, R.reduced_motion = preview_moves, false end
end

local function other_swap(predicate)
    for a = 0, rules.CELLS - 1 do
        for axis = 0, rules.AXES - 1 do
            local b = rules.hex_neighbor(a, axis)
            if rules.game_swap_matches(R.g, a, b) and predicate(a, b) then return a, b end
        end
    end
    error("no swap for tutorial regression")
end

local function swap(a, b)
    app.inject_click(R.cell_pos(a))
    queued = b
end

local function independent(a, b)
    return not R.tutorial:allows_swap(a, b)
end

local function leaves_targets(a, b)
    local trial, wave = rules.game_copy(R.g), rules.new_match()
    assert(rules.game_swap(trial, a, b, wave))
    repeat
        rules.game_apply(trial, wave)
        rules.game_collapse(trial, true)
        rules.game_matches(trial, wave)
    until wave.hits == 0
    return trial.oil_left > 0
end

local function charge(a, b)
    local trial, wave = rules.game_copy(R.g), rules.new_match()
    assert(rules.game_swap(trial, a, b, wave))
    rules.game_apply(trial, wave)
    return trial.tools[1] == 1
end

function desc.frame(dt)
    frame(dt)
    if preview then return end
    frames = frames + 1
    assert(frames < 900, "tutorial timed out in " .. stage)
    if queued then
        app.inject_click(R.cell_pos(queued))
        queued = nil
        return
    end
    if stage == "opening" then
        if lesson == 1 then
            local a, b = other_swap(independent)
            swap(a, b)
            stage = "reject"
        else
            tracked = lesson == 4 and R.g.obstacles or nil
            swap(opening.a, opening.b)
            stage = "made"
        end
    elseif stage == "reject" then
        assert(R.g.moves == moves and R.tutorial.move == opening, "the lesson accepts only the highlighted swap")
        app.inject_press(R.cell_pos(opening.a))
        stage = "drag"
    elseif stage == "drag" then
        app.inject_move(R.cell_pos(opening.b))
        stage = "release"
    elseif stage == "release" then
        app.inject_release(R.cell_pos(opening.b))
        stage = "made"
    elseif stage == "made" and R.g.moves == moves - 1 and R.phase == R.PH_IDLE then
        if lesson == 2 or lesson == 3 then
            local follow = assert(R.tutorial.move, "the lesson must teach how to use the newly made gem")
            expected = lesson == 2 and "striped" or "color_bomb"
            for cell in pairs(follow.cells) do
                if R.g.tiles[cell].special == expected then tracked = cell end
            end
            assert(tracked, "the actual cascade must leave the tutorial gem in a highlighted cell")
            swap(follow.b, follow.a)   -- a two-tap swap may enter either end first
            stage = "fired"
        else
            assert(not R.tutorial.move, "finished opening moves return control to the player")
            if lesson == 4 then
                assert(R.g.obstacles < tracked, "the highlighted match must break a tie or chain")
                start(2)
                stage = "skip"
            elseif testing.game == "christmas-market" then
                assert(not story.active(), "Noelle waits beyond the opening swap")
                swap(other_swap(leaves_targets))
                stage = "second"
            else
                lesson = lesson + 1
                start(lesson)
            end
        end
    elseif stage == "second" and R.g.moves == moves - 2 and R.phase == R.PH_IDLE then
        assert(not story.active(), "Noelle waits beyond the second move")
        swap(other_swap(leaves_targets))
        stage = "third"
    elseif stage == "third" and R.g.moves == moves - 3 and R.phase == R.PH_IDLE then
        assert(story.active(), "Noelle reminds the player to clear blue tiles after three moves")
        story.next()
        stage = "resume"
    elseif stage == "resume" then
        assert(not story.active(), "the reminder plays once and the board resumes")
        lesson = 2
        start(lesson)
    elseif stage == "fired" and R.g.moves == moves - 2 and R.phase == R.PH_CLEAR then
        local effects = R.pending.special_effects
        assert(effects and effects[1].name == expected and not R.tutorial.move, "the guided swap must fire the special")
        tracked = nil
        lesson = lesson + 1
        start(lesson)
    elseif stage == "skip" then
        app.inject_click(R.tutorial.skip.boxes.skip:center())
        stage = "skipped"
    elseif stage == "skipped" and not R.tutorial.move then
        assert(R.g.moves == moves, "Skip does not move a piece or spend a turn")
        start_bonus()
    elseif stage == "charging" then
        assert(R.tutorial.tip and R.tutorial.tip.cells, "matching pieces should show which tool they charge")
        local a, b = other_swap(charge)
        swap(a, b)
        stage = "charged"
    elseif stage == "charged" and R.phase == R.PH_IDLE and R.tutorial.tip and not R.tutorial.tip.cells then
        assert(R.g.tools[1] == 1 and R.prog.tutorial_tools == 1, "the ready lesson replaces the charging lesson")
        app.inject_click(R.board_tool_bounds(0):center())
        stage = "using"
    elseif stage == "using" and R.tool == 0 then
        assert(R.prog.tutorial_tools == 3 and not R.tutorial.tip, "selecting the charged tool acknowledges its lesson")
        for cell = 0, rules.CELLS - 1 do
            if R.g.oil[cell] > 0 then app.inject_click(R.cell_pos(cell)); break end
        end
        stage = "used"
    elseif stage == "used" and R.g.tools[1] == 0 then
        app.quit()
    end
end

return desc
