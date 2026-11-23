-- Decoration kinds standing in town add a diminishing percentage to a won board's resources.
local rules = require("rules")
local island = require("island")
local R = require("state")
require("main")

local c = city.new()
island.island_setup(c)
local shop
for i, d in ipairs(island.buildings) do
    if d.decoration and not shop and d.cost[1] > 0 then shop = i - 1 end
end
local project = island.ladder[1].kind
check(math.abs(island.decoration_gain(c, shop) - 10 * math.log(1.1)) < 1e-9, "the first kind adds about one percent")
check(island.decoration_gain(c, project) == 0, "campaign projects add no decoration bonus")

local base = island.decoration_bonus(c)
local gain = island.decoration_gain(c, shop)
local ok, spot = c:find_spot(shop, vec2(900, 1900))
check(ok, "room for the decoration")
c:add(spot, shop, 0)
check(math.abs(island.decoration_bonus(c) - base - gain) < 1e-9, "a placed decoration adds the gain its card showed")
check(island.decoration_gain(c, shop) == 0, "a kind already standing offers nothing more")
spot = select(2, c:find_spot(shop, spot))
c:add(spot, shop, 0)
check(math.abs(island.decoration_bonus(c) - base - gain) < 1e-9, "a second copy of the same kind adds nothing")

local saved = R.island
R.island = c
local percent = island.decoration_bonus(c)
local g = rules.game_start(3, 7)
g.won, g.earnings = true, {400, 200, 0}
local p = {level=3, seed=1, wallet=purse()}
local breakdown = testing.game == "relic-rush" and rules.reward_breakdown(g, p)
    or rules.reward_breakdown(g, island.wonders, p)
local bonus = breakdown.decoration
check(bonus[1] == math.floor(400 * percent / 100 + .5) and bonus[2] == math.floor(200 * percent / 100 + .5)
    and bonus[3] == 0, "the bonus is the percent of what the board collected, in each currency")
check(breakdown.total[1] >= 400 + bonus[1] and breakdown.total[2] >= 200 + bonus[2], "the win's total includes it")
R.island = saved
