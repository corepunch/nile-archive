-- luacheck: globals testing

-- Exercise the visible walkthrough buttons with real injected pointer events.
local game = testing.game
local desc = require('games/' .. game .. '/lua/main')
local R, island, economy = require('state'), require('island'), require('economy')
local init = desc.init
local stage, wait, frames = 0, 0, 0
local function finish()
    print('walkthrough pointer smoke passed: skip, reward, confirmed building and next board reward')
    app.quit()
end
function desc.init()
    init()
    R.on_island, R.overlay = false, R.OV_NONE
end
function R.smoke()
    frames = frames + 1
    assert(frames < 1500, 'walkthrough pointer smoke timed out at stage ' .. stage)
    if R.diving() then return end
    assert(not story.active() and not R.story_current, "opening, win and purchase must never start dialogue")
    if wait > 0 then wait = wait - 1; return end
    wait = 4
    if stage == 0 then
        app.inject_click(vec2(394, R.hud_rect.y - 30)); stage = 1
    elseif stage == 1 and R.overlay == R.OV_RESULT and R.dialog_settled() then
        assert(R.g.won and R.prog.level == 0, 'skip must open results before paying')
        app.inject_click(R.result_form.boxes.claim:center() + vec2(0, R.drop / 2)); stage = 2
    elseif stage == 2 and R.on_island and R.overlay == R.OV_NONE then
        assert(R.prog.level == 1 and island.wonder_count(R.island) == 0, 'result must pay before placement')
        app.inject_click(vec2(394, 136)); stage = 3
    elseif stage == 3 and island.wonder_count(R.island) == 1 then
        assert(R.island.placing < 0, 'town action must confirm placement')
        local reward = R.building_reward(island.kinds[game == "relic-rush" and "well" or "arch"])
        assert(R.toast == "Unlocked: " .. reward.name, "placement names its board reward")
        app.inject_click(vec2(394, 136)); stage = 4
    elseif stage == 4 and not R.on_island then
        assert(R.g.level == 1, 'town action must start the next board')
        if game == 'relic-rush' then
            local water = economy.unlock_of("well")
            assert(R.g.resource_yields[water.kind] == water and next(R.g.tool_meter) == nil,
                'the well adds water buckets to the second board')
            finish()
        else
            local wine = economy.unlock_of('arch').kind
            assert(R.g.resource_yields[wine] == economy.pieces[wine], 'the arch adds mulled wine to the second board')
            assert(R.g.backdrop == "welcome-arch", "the confirmed arch changes the board's backdrop")
            assert(R.intro and R.intro:showing_backdrop(), "the new painting opens before the board")
            assert(not (R.prog.backdrops_seen or {})["welcome-arch"], "the hold is acknowledged after viewing")
            app.inject_click(app.screen():center())
            stage = 5
        end
    elseif stage == 5 and not R.intro then
        assert(R.prog.backdrops_seen["welcome-arch"], "tapping skips and acknowledges the scene")
        R.start_level(1)
        assert(R.intro and not R.intro:showing_backdrop(), "retrying skips the already seen painting")
        finish()
    end
end
return desc
