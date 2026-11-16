local rules = require("rules")
local island = require("island")

-- Even if the spare resources have all been spent, a story delivery covers a
-- first clear's shortfall. All three reserve slots survive catalogue purchases.
local p = {level=0, seed=1, wallet=purse()}
local c = city.new()
island.island_setup(c)
for i = 0, rules.LEVELS - 1 do
    local g = rules.game_start(i, i + 1)
    g.won, g.moves = true, 0
    check(rules.progress_reward(p, g, island.wonders), "first clear pays")
    check(not rules.progress_reward(p, g, island.wonders), "result pays once")
    local reserved = island.reserved_cost(c, p.level)
    check(p.wallet:covers(reserved), "first clear funds every slot of the earned stall")
    for slot = 1, 3 do p.wallet[slot] = reserved[slot] end
    for z = 1, 5 do c:unlock(z, p.wallet) end
    check(island.island_place_next(c, p.wallet, p.level, 0) == (rules.wonder_at(i + 1) ~= nil),
          "each earned stall can be placed")
end
check(c.open == 63 and p.wallet[rules.STARS] == 90, "first clears open the full market")

local g = rules.game_start(0, 7)
g.earnings, g.moves = {9, 6, 7}, 999
check(not rules.progress_reward(p, g, island.wonders), "a failed wish banks nothing")
local bonus = rules.reward_breakdown(g, island.wonders, p)
check(bonus.bonus == 40 and bonus.delivery[1] == 0, "replay bonus caps at 40 Gold")
g.won = true
check(rules.progress_reward(p, g, island.wonders), "replay can bank resources")
check(p.wallet[1] == 49 and p.wallet[2] == 6 and p.wallet[3] == 7 and p.wallet[4] == 90,
      "replay banks the actual matches without additional Stars")
g = rules.game_start(1, 99)
g.won = true
check(not rules.progress_reward({level=0}, g, island.wonders), "future wish cannot be claimed")
