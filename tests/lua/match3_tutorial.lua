local rules = require("rules")
local Tutorial = require("match3.tutorial")
local R = {prog={}}
local tutorial = Tutorial.new(R, rules, "Match through the blocker.")
tutorial.enabled = true

local expected = {[1]="striped", [2]="color_bomb"}
local restored = {}
local function make(level, seed) return rules.game_start(level, seed, restored) end

local function settle(g, wave)
    repeat
        rules.game_apply(g, wave)
        rules.game_collapse(g)
        rules.game_matches(g, wave)
    until wave.hits == 0
end

for _, seed in ipairs{1, 12345, 782341, 215794, 0x7FFFFFFF, 0xFFFFFFFF} do
    for level = 0, 3 do
        R.prog.level = level
        local g = tutorial:start(level, seed, make)
        local move, wave = tutorial.move, rules.new_match()
        check(move, ("seed %d level %d offers a guided move"):format(seed, level + 1))
        local blockers, targets = g.obstacles, g.oil_left
        check(rules.game_swap(g, move.b, move.a, wave), "two taps can start at either endpoint")
        check(wave.hits == (level == 3 and 3 or level + 3), "the opening swap makes the lesson's match")
        local _, award = next(wave.special_awards or {})
        check((award and award.name) == expected[level], "the opening swap makes the intended gem")
        tutorial:swapped()
        settle(g, wave)
        if expected[level] then
            local use = tutorial.move
            check(g.oil_left > 0 and use, "the first cascade leaves a second move")
            check(rules.game_swap(g, use.a, use.b, wave), "the guided activation is legal after animated gravity")
            rules.game_apply(g, wave)
            check(wave.special_effects and wave.special_effects[1].name == expected[level],
                "the follow-up actually fires the newly made special")
            tutorial:swapped()
        elseif level == 3 then
            check(g.obstacles < blockers, "the lesson match breaks a blocker")
        else
            check(g.oil_left < targets, "the match of three clears a target")
        end
        check(not tutorial.move, "the lesson releases the board after its moves")
    end
end

tutorial:start(0, 782341, make)
check(not tutorial.move, "replays of cleared levels do not repeat guided moves")

local unlock = require("economy").unlocks[2]
local bonus = unlock.bonus
restored[unlock.building] = true
local level = unlock.first_level - 1
local seed = 782341 + level * 7919
restored.bonus_charge = {[bonus.tool]=require("match3.bonuses").THRESHOLD - bonus.amount}
R.g = make(level, seed)
R.tool = -1
R.bonus_display_charge = function(tool) return R.g.tool_meter[tool] end
R.save_progress = function() end
tutorial.tip = tutorial:tool_tip()
check(tutorial.tip and tutorial.tip.cells and tutorial.tip.tool == bonus.tool, "the purchased tool's pieces are highlighted")
local charged
for a = 0, rules.CELLS - 1 do
    for axis = 0, rules.AXES - 1 do
        local b = rules.hex_neighbor(a, axis)
        if rules.game_swap_matches(R.g, a, b) then
            local trial, wave = rules.game_copy(R.g), rules.new_match()
            rules.game_swap(trial, a, b, wave)
            rules.game_apply(trial, wave)
            if trial.tool_meter[bonus.tool] == R.g.tool_threshold then charged = trial; break end
        end
    end
    if charged then break end
end
check(charged, "the tool lesson's test board has a charging match")
R.g = charged
check(tutorial:charge_changed(), "a real meter change acknowledges the charging lesson")
tutorial.tip = tutorial:tool_tip()
check(tutorial.tip and not tutorial.tip.cells and tutorial.tip.tool == bonus.tool, "full charge highlights the toolbar")
tutorial:tool_selected(bonus.tool)
check(not tutorial:tool_tip(), "an acknowledged use lesson stays dismissed")
