-- A deterministic, paused presentation fixture; mechanics use engine flags.
local game = testing.game
assert(game == "relic-rush" or game == "christmas-market")
local desc = require("games/" .. game .. "/lua/main")
local R, rules, match3 = require("state"), require("rules"), require("match3")
local init, frame = desc.init, desc.frame
function desc.init()
    init()
    R.g = rules.game_start(6, 123478)
    for i = 0, rules.CELLS - 1 do
        R.g.chain[i], R.g.ice[i], R.g.soil[i] = 0, 0, 0
        if R.g.active[i] then
            local q, r = rules.hex_q(i), rules.hex_r(i)
            R.g.tiles[i] = rules.tile((q + 2 * r + 12) % rules.COLORS)
            if app.arg("review-top-edge") or 2 * r + q >= 4 and math.abs(q) <= 1 then R.g.tiles[i] = rules.tile(-1) end
        end
    end
    R.g.obstacles, R.g.initial_obstacles = 0, 0
    if not app.arg("review-top-edge") then
        R.g.tiles[rules.hex_index(-1, 2)] = rules.tile(4, rules.BOMB)
        R.g.tiles[rules.hex_index(1, 1)] = rules.tile(5, rules.COLUMN)
    end
    R.pending = rules.new_match()
    R.old_tiles = rules.game_copy(R.g).tiles
    local flags = app.arg("review-gravity") == "vertical" and match3.NO_TRICKLE or 0
    local gravity = match3.new{flags=flags, colors=rules.COLORS, match_min=rules.MATCH_MIN}
    R.fall_from, R.fall_steps = gravity.game_collapse(R.g)
    R.phase, R.phase_time = R.PH_FALL, tonumber(app.arg("fall-time")) or .04
    R.on_island, R.art_review, R.toast_time = false, true, 0
end
function desc.frame(dt)
    if app.arg("review-top-edge") then R.phase_time = R.phase_time + dt end
    frame(dt)
end
return desc
