-- Every tier gets 25% over a typical clear. Relic Rush adds three more moves.
-- Slow bot runs are diagnostics and do not increase the budget.
local M = {RATIO = 1.25}
function M.fit(samples, game)
    local ordered = {table.unpack(samples)}
    table.sort(ordered)
    local median = ordered[(#ordered + 1) // 2]
    assert(median and median < math.huge, 'bot cannot clear half its starts; inspect the bot or redesign the board')
    local extra = game == 'relic-rush' and 3 or 0
    return math.ceil(median * M.RATIO) + extra, median
end
return M
