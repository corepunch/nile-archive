-- luacheck: globals testing

-- Exercise the visible walkthrough buttons with real injected pointer events.
local game = testing.game
local desc = require('games/' .. game .. '/lua/main')
local R, island = require('state'), require('island')
local init = desc.init
local stage, wait, frames = 0, 0, 0
function desc.init()
    init()
    R.quiet, R.on_island, R.overlay = true, false, R.OV_NONE
    R.story_current = nil
end
function R.smoke()
    frames = frames + 1
    assert(frames < 1500, 'walkthrough pointer smoke timed out at stage ' .. stage)
    if R.diving() then return end
    if wait > 0 then wait = wait - 1; return end
    wait = 4
    if stage == 0 then
        app.inject_click(vec2(394, R.hud_rect.y - 30)); stage = 1
    elseif stage == 1 and R.overlay == R.OV_RESULT and R.dialog_settled() then
        assert(R.g.won and R.prog.level == 0, 'skip must open results before paying')
        app.inject_click(vec2(240, 688 + R.drop / 2)); stage = 2
    elseif stage == 2 and R.on_island and R.overlay == R.OV_NONE then
        assert(R.prog.level == 1 and island.wonder_count(R.island) == 0, 'result must pay before placement')
        app.inject_click(vec2(394, 136)); stage = 3
    elseif stage == 3 and island.wonder_count(R.island) == 1 then
        assert(R.island.placing < 0, 'town action must confirm placement')
        print('walkthrough pointer smoke passed: skip, reward and confirmed building')
        app.quit()
    end
end
return desc
