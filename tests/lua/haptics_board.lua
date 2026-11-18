-- The real presentation adapter, run once in each portrait game's suite.
local rules, R = require('rules'), require('board')
local H = require('support')
local function setup()
    testing.reset()
    local g = H.board(rules)
    g.level = H.plain_level(rules)
    g.oil[rules.hex_index(0, -2)], g.oil_left = 1, 1   -- the synthetic board starts unfinished, clear of the test rows
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

do
    local source, target = rules.hex_index(0, -1), rules.hex_center()
    local g = setup()
    local from, to = R.cell_pos(source), R.cell_pos(target)
    for i = 0, rules.CELLS - 1 do g.active[i] = i == source or i == target end
    R.board_input{released=true, press_pos=from, pos=to}
    local count, effect, strength = testing.haptics()
    check(count == 1 and effect == haptic.ERROR, 'a swap without a match gives one error pulse')

    -- A chain, ice or a carved stone in the far cell: the free gem slides
    -- halfway to it and back, on a swipe and on two taps.
    for _, block in ipairs({"chain", "ice", "stone_hp"}) do
        for _, reduced in ipairs({false, true}) do
            g = setup()
            R.reduced_motion = reduced
            g[block][target] = 1
            if block == "stone_hp" then g.tiles[target] = rules.tile(-1) end
            local moving, held, moves = g.tiles[source], g.tiles[target], g.moves
            if reduced then R.board_input{released=true, press_pos=from, pos=from} end
            R.board_input{released=true, press_pos=reduced and to or from, pos=to}
            local pulses, block_effect, block_strength = testing.haptics()
            check(pulses == 1 and block_effect == effect and block_strength == strength,
                block .. ' gives the normal reject pulse on a swipe or two taps')

            local leg = reduced and .16 * .35 or .16
            R.board_update(leg)
            local _, moving_at = R.piece_pose(source, 0)
            local _, held_at = R.piece_pose(target, 0)
            local halfway = from:lerp(to, .5)
            near(moving_at:dist(halfway), 0, 'the moving gem reaches the ' .. block)
            near(held_at:dist(to), 0, 'the blocked cell stays in its slot')
            R.board_update(leg / 2)
            _, moving_at = R.piece_pose(source, 0)
            check(moving_at:dist(from) < halfway:dist(from), 'the moving gem heads back')
            testing.advance(2 * leg)
            R.board_update(leg / 2 + .001)
            _, moving_at = R.piece_pose(source, 0)
            near(moving_at:dist(from), 0, 'the moving gem returns to its slot')
            check(R.phase == R.PH_IDLE and g.moves == moves and g[block][target] == 1
                and g.tiles[source] == moving and g.tiles[target] == held, 'the rejection preserves the board and moves')
            check(testing.haptics() == 1, 'the return does not play a second pulse')
        end
    end

    -- A held gem cannot set off: it refuses with the pulse and the notice, and nothing slides.
    local notices
    local function swipe_with(prepare)
        g = setup()
        notices = 0
        R.notice = function() notices = notices + 1 end
        prepare(g)
        R.board_input{released=true, press_pos=from, pos=to}
        return testing.haptics()
    end
    local pulses, held_effect = swipe_with(function(board) board.chain[source] = 1 end)
    check(pulses == 1 and held_effect == effect and notices == 1 and R.phase == R.PH_IDLE,
        'a swipe from a chained gem pulses and explains without moving')

    -- A hole or an empty cell is no swap: no pulse, no notice, no motion.
    check(swipe_with(function(board) board.active[target] = false end) == 0 and notices == 0 and R.phase == R.PH_IDLE,
        'a swipe into a hole is ignored')
    check(swipe_with(function(board) board.tiles[target] = rules.tile(-1) end) == 0 and notices == 0 and R.phase == R.PH_IDLE,
        'a swipe into an empty cell is ignored')
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
for q=-2,1 do g.tiles[rules.hex_index(q,0)] = rules.tile(0) end
g.ice[rules.hex_index(0,0)] = 1
rules.game_matches(g,R.pending,-1)
R.finish_wave()
check(g.ice[rules.hex_index(0,0)] == 0, 'the match breaks the ice')
local _, broke_effect, broke_strength = testing.haptics()
check(broke_effect == haptic.COMBO and broke_strength == 1, 'breaking a layer lands harder than a plain match')

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
R.present_board()
R.board_update(.01)
R.board_input{released=true}
for _=1,180 do
    testing.advance(1/60)
    R.board_update(1/60)
    testing.haptics() -- flush each real frame, including the cooldown
end
check(testing.haptics() >= 2, 'entrance repeats trickle feedback across real frames after the opening release')
setup()
R.g.ice[rules.hex_center()] = 1
R.present_board()
R.board_update(3)
pulse(haptic.MATCH, 'blocker landing takes precedence over gem ticks')
setup()
local diving = R.diving
R.diving = function() return true end
R.present_board()
R.board_update(3)
check(R.intro.t == 0 and testing.haptics() == 0, 'the entrance waits for the town transition')
R.diving = diving
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
