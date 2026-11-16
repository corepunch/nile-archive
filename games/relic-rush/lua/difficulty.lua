-- The campaign's difficulty curve, the one authored input to level tuning.
-- tools/tune_levels.py simulates every board against these targets and writes
-- lua/level_tuning.lua (blockers and move budget). Edit this curve, rerun the
-- tuner, and review docs/level-tuning.md. Never hand-edit the generated file.
--
-- moves: the budget the player sees. It grows slowly and smoothly.
-- win:   the share of seeded starts the reference bot should win within it.
--   Blockers (chains, then double chains) are added until it falls to this
--   share. A board too hard with none gains moves; one too easy with every
--   blocker loses moves, down to min_moves.
--
-- The bot plays the highest-valued legal swap and uses no tools. Its rates
-- order and space the levels; they are not measured human win rates.
local tiers = {
    tutorial = {win=1.00, blockers=false},
    easy     = {win=0.92},
    normal   = {win=0.80},
    hard     = {win=0.62},
    boss     = {win=0.50},
}

-- A five-board rhythm: two normal, a hard spike, an easy breather, normal.
-- Every tenth board is a boss. The first two boards teach the swap.
local rhythm = {"normal", "normal", "hard", "easy", "normal"}

local M = {tiers=tiers}

function M.tier(level)
    if level <= 2 then return "tutorial" end
    if level % 10 == 0 then return "boss" end
    return rhythm[(level - 1) % #rhythm + 1]
end

-- Budgets grow from 22 to 33 moves across thirty boards.
function M.target(level)
    local name = M.tier(level)
    local tier = tiers[name]
    local moves = 22 + math.floor((level - 1) * 0.4)
    return {tier=name, moves=moves, min_moves=math.floor(moves * 0.6), win=tier.win,
        blockers=tier.blockers ~= false}
end

return M
