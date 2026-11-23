-- A won board's leftover moves become bombs, five a round, and pay a little, logarithmically.
local rules = require("rules")

local function total(g)
    local sum = 0
    for _, amount in ipairs(g.earnings) do sum = sum + amount end
    return sum
end

check(rules.FINALE_BATCH == 5, "a finale round arms five bombs")
local g = rules.game_start(0, 4242)
check(rules.game_finale_arm(g) == nil, "a board still in play has no finale")

g.won, g.moves = true, 7
local armed = rules.game_finale_arm(g)
check(#armed == 5 and g.moves == 2, "a round spends five moves on five pieces")
check(math.abs(g.finale_share - rules.FINALE_SHARE * math.log(6) / 5) < 1e-9,
    "the first five moves are worth ln 6 of the share together")
local m = rules.new_match()
check(rules.game_finale_fire(g, m, armed) and m.hits >= 5, "the armed bombs go off in one wave")
for _, cell in ipairs(armed) do
    for other = 0, rules.CELLS - 1 do
        local near_q = math.abs(rules.hex_q(other) - rules.hex_q(cell)) <= 1
        local near_r = math.abs(rules.hex_r(other) - rules.hex_r(cell)) <= 1
        if rules.game_cell_active(g, other) and near_q and near_r then
            check(m.mask[other] and m.swept[other], "a bomb hits and pays for the 3×3 square around it")
        end
    end
end
rules.game_apply(g, m)
rules.game_collapse(g, true)
local last = rules.game_finale_arm(g)
check(#last == 2 and g.moves == 0, "the last round arms only the moves that are left")
check(math.abs(g.finale_share - rules.FINALE_SHARE * math.log(8 / 6) / 2) < 1e-9,
    "later moves are worth less: moves six and seven add ln(8/6)")
check(rules.game_finale_arm(g) == nil, "the finale ends with the moves")

local board = rules.game_start(0, 4242)
board.won, board.moves = true, 12
local earned = total(board)
rules.game_finale(board, m)
check(board.moves == 0 and board.won, "the whole finale spends every move and the board stays won")
check(total(board) > earned, "the pieces the bombs blast away pay a share of their resources")
