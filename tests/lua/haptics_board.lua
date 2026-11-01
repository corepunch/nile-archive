-- The real presentation adapter, run once in each portrait game's suite.
local rules, R = require('rules'), require('board')
local H = require('support')
local function setup()
    testing.reset()
    local g = H.board(rules)
    for i=0,rules.CELLS-1 do g.tiles[i] = rules.tile(i % rules.COLORS) end
    R.reset_board(g)
    R.overlay, R.on_island, R.art_review = R.OV_NONE, false, false
    R.tone, R.vfx_wave, R.notice = function() end, function() end, function() end
    R.reduced_motion = false
    return g
end
local function pulse(expected, message)
    local count, effect = testing.haptics()
    check(count == 1 and effect == expected, message)
end

local g = setup()
local m = rules.new_match()
rules.game_matches(g,m,-1)
rules.game_hint(g)
rules.game_collapse(rules.game_copy(g))
check(testing.haptics() == 0, 'matching, hints and gravity simulations stay silent')
for q=-2,1 do g.tiles[rules.hex_index(q,0)] = rules.tile(0) end
rules.game_matches(g,R.pending,-1)
R.finish_wave()
pulse(haptic.MATCH, 'first visible match pulses')
testing.reset()
for q=-2,1 do g.tiles[rules.hex_index(q,0)] = rules.tile(0) end
rules.game_matches(g,R.pending,-1)
R.finish_wave()
pulse(haptic.COMBO, 'cascade escalates feedback')

g = setup()
local center = rules.hex_center()
g.tiles[center] = rules.tile(0, rules.BOMB)
R.pending.mask[center], R.pending.hits = true, 1
R.finish_wave()
pulse(haptic.COMBO, 'special activation escalates the first wave')

setup()
R.phase, R.phase_time, R.fall_steps, R.fall_landed = R.PH_FALL, 0, {{}, {}, {}}, 0
R.board_update(rules.FALL_STEP + .001)
pulse(haptic.TICK, 'simultaneous landing produces one trickle tick')
R.board_update(.001)
check(testing.haptics() == 1, 'same landing never retriggers')
R.overlay = R.OV_PAUSE
testing.advance(1)
R.board_update(1)
check(testing.haptics() == 1, 'paused gravity stays silent')
R.overlay = R.OV_NONE
R.on_island = true
R.board_update(1)
check(testing.haptics() == 1, 'off-screen gravity stays silent')
R.on_island, R.reduced_motion = false, true
R.board_update(.04)
local count, effect = testing.haptics()
check(count == 2 and effect == haptic.TICK, 'reduced motion keeps tactile landings')
testing.reset()

if R.intro_haptics then
    setup()
    R.vfx_emit, R.vfx_slam = function() end, function() end
    R.present_board()
    R.overlay = R.OV_PAUSE
    R.board_update(2)
    check(testing.haptics()==0, 'paused entrance stays silent')
    R.overlay = R.OV_NONE
    R.board_update(1)
    pulse(haptic.TICK, 'entrance coalesces simultaneous gem landings')
    testing.reset()
    R.board_update(.001)
    check(testing.haptics()==0, 'entrance does not repeat landed gems')
    setup()
    R.g.ice[rules.hex_center()] = 1
    R.present_board()
    R.board_update(3)
    pulse(haptic.MATCH, 'blocker landing takes precedence over gem ticks')
    setup()
    R.reduced_motion = true
    R.present_board()
    R.board_update(1)
    check(testing.haptics()==0, 'reduced entrance omits landing effects')
    setup()
    R.present_board()
    R.intro:skip()
    R.board_update(.01)
    check(testing.haptics()==0, 'skipping an entrance emits no delayed pulses')
end
