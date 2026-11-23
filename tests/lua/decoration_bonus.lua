-- Decorations standing in town pay a gold bonus on every won board.
local rules = require("rules")
local island = require("island")

local c = city.new()
island.island_setup(c)
local shop
for i, d in ipairs(island.buildings) do
    if d.decoration and not shop and d.cost[1] > 0 then shop = i - 1 end
end
local project = island.ladder[1].kind
local dividend, cost = island.decoration_dividend(shop), island.buildings[shop + 1].cost
check(dividend == math.ceil((cost[1] + cost[2] + cost[3]) / 20), "a decoration pays a twentieth of its price")
check(island.decoration_dividend(project) == 0, "campaign projects pay no decoration bonus")

local base = island.decoration_bonus(c)
local ok, spot = c:find_spot(shop, vec2(900, 1900))
check(ok, "room for the decoration")
c:add(spot, shop, 0)
check(island.decoration_bonus(c) == base + dividend, "a placed decoration adds its dividend")
spot = select(2, c:find_spot(shop, spot))
c:add(spot, shop, 0)
check(island.decoration_bonus(c) == base + dividend, "a second copy of the same kind adds nothing")

rules.decoration_income = function() return island.decoration_bonus(c) end
local g = rules.game_start(3, 7)
g.won, g.earnings = true, {10, 0, 0}
local p = {level=3, seed=1, wallet=purse()}
local breakdown = rules.reward_breakdown(g, island.wonders, p)
if testing.game == "relic-rush" then breakdown = rules.reward_breakdown(g, p) end
check(breakdown.decoration == base + dividend and breakdown.total[1] >= 10 + base + dividend,
    "the win's gold includes the decoration bonus")
rules.decoration_income = nil
