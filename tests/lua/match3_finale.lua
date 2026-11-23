-- A won board's leftover moves become line gems, five a round, and pay out.
local rules = require("rules")

local function total(g)
    local sum = 0
    for _, amount in ipairs(g.earnings) do sum = sum + amount end
    return sum
end

check(rules.FINALE_BATCH == 5, "a finale round arms five line gems")
local g = rules.game_start(0, 4242)
check(rules.game_finale_arm(g) == nil, "a board still in play has no finale")

g.won, g.moves = true, 7
local armed = rules.game_finale_arm(g)
check(#armed == 5 and g.moves == 2, "a round spends five moves on five pieces")
for _, cell in ipairs(armed) do
    check(g.tiles[cell].special == "striped", "an armed piece becomes a line gem of its own kind")
end
local m = rules.new_match()
check(rules.game_finale_fire(g, m, armed) and m.hits == 5, "the armed gems fire in one wave")
rules.game_apply(g, m)
rules.game_collapse(g, true)
local last = rules.game_finale_arm(g)
check(#last == 2 and g.moves == 0, "the last round arms only the moves that are left")
check(rules.game_finale_arm(g) == nil, "the finale ends with the moves")

local board = rules.game_start(0, 4242)
board.won, board.moves = true, 12
local earned = total(board)
rules.game_finale(board, m)
check(board.moves == 0 and board.won, "the whole finale spends every move and the board stays won")
check(total(board) > earned, "the pieces the line gems sweep away pay their resources")
