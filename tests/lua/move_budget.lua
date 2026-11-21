-- Every tier uses the same base fit. Relic Rush scales that budget by 1.5.
-- Slow bot runs are diagnostics and do not increase the budget.
local M = {RATIO = 1.25}
function M.fit(samples, game)
    local ordered = {table.unpack(samples)}
    table.sort(ordered)
    local median = ordered[(#ordered + 1) // 2]
    assert(median and median < math.huge, 'bot cannot clear half its starts; inspect the bot or redesign the board')
    local fitted = math.ceil(median * M.RATIO)
    if game == 'relic-rush' then fitted = math.ceil(fitted * 1.5) end
    return fitted, median
end
return M
