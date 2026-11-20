-- A single 25% allowance over a typical clear. Slow bot runs are diagnostics,
-- not another source of moves; tiers describe the authored board's difficulty.
local M = {RATIO = 1.25}
function M.fit(samples)
    local ordered = {table.unpack(samples)}
    table.sort(ordered)
    local median = ordered[(#ordered + 1) // 2]
    assert(median and median < math.huge, 'bot cannot clear half its starts; inspect the bot or redesign the board')
    return math.ceil(median * M.RATIO), median
end
return M
