-- luacheck: globals testing
local desc = require("games/" .. testing.game .. "/lua/main")
local R, rules = require("state"), require("rules")
local journey, island = require("journey"), require("island")
local stage, frames = 0, 0
local started, expected_wallet
-- The first board's own scene, when the game plays one.
local function first_clear()
    return R.dialogue_on() and journey.find("after-01") and "after-01" or nil
end

function R.smoke()
    local clear = first_clear()
    frames = frames + 1
    assert(frames < 360, "debug skip stalled at stage " .. stage)
    if stage == 3 and R.on_island then
        assert(R.g.reward_claimed and R.prog.level == 1, "claim advances the campaign")
        for i = 1, 4 do
            assert(R.prog.wallet[i] == expected_wallet[i], "claim banks the earned resources")
        end
        if not journey.clear_before_result then
            local kind = assert(island.next_step(R.island, R.prog.level))
            assert(R.town:begin(kind, false) and R.town:confirm(), "the reward funds the story's first stall")
        end
        stage = 4
    end
    if stage == 4 and (not clear or R.prog.story_seen[clear]) then
        app.quit()
        return
    end
    if R.diving() then return end
    if story.active() then
        if stage > 0 then
            assert(R.g.won and R.story_current.key == clear, "the bot's win opens the normal clear scene")
        end
        story.next()
        return
    end
    if stage == 0 and R.debug_skip_button then
        assert(not R.on_island and R.g.score == 0, "test begins on the first live board")
        R.g.moves = 1
        started = app.time()
        app.inject_click(R.debug_skip_button:center())
        stage = 1
    elseif stage == 1 and R.g.won then
        assert(R.overlay == R.OV_RESULT and R.prog.level == 0, "claiming must still be a separate action")
        assert(R.g.score > 0 and R.g.oil_left == 0 and R.g.moves == 0, "legal matches clear the goals past the last move")
        assert(R.prog.completed and R.prog.completed.score == R.g.score, "the normal win stashes the reward")
        local seconds = app.time() - started
        assert(seconds < 1, "the opening board takes less than one second at 60 FPS")
        print(("debug skip cleared in %.2f game seconds"):format(seconds))
        expected_wallet = R.prog.wallet + rules.level_reward(R.g, R.wonders, R.prog)
        stage = 2
    elseif stage == 2 and (not journey.clear_before_result or not clear or R.g.story_clear == clear)
        and R.result_form.boxes.claim and R.dialog_settled() then
        app.inject_click(R.result_form.boxes.claim:center() + vec2(0, R.drop / 2))
        stage = 3
    end
end

return desc
