-- Verify that the Christmas map and prices support the complete earning/build loop.
local rules = require('rules')
local island = require('island')
local journey = require('journey')
local p = {level=0, seed=1, wallet=purse()}
local c = city.new()
island.island_setup(c)
assert(#island.catalogue == 40 and island.WONDERS == 10 and rules.LEVELS == 100)
-- Pip announces each region on the level the script gives it (docs/story.md#small-lines).
local opens = {[15]=1, [30]=2, [50]=3, [70]=4, [85]=5}
for level=0,rules.LEVELS-1 do
    local g = rules.game_start(level,100+level)
    assert(rules.game_hint(g), 'Christmas opening needs a legal move')
    -- The clear pays for every ladder stall it opens.
    local cost = purse()
    for _, step in ipairs(island.ladder) do
        if step.after == level + 1 then cost = cost + island.buildings[step.kind + 1].cost end
    end
    g.won, g.moves, g.earnings = true, 0, {cost[1] + 50, cost[2] + 12, cost[3] + 18}
    assert(rules.progress_reward(p,g,island.wonders), 'First clear must pay')
    local before = p.wallet[1]
    assert(not rules.progress_reward(p,g,island.wonders) and p.wallet[1]==before, 'Cannot pay twice')
    local zone = opens[p.level]
    if zone then
        assert(c:unlock(zone,p.wallet), ('Region %d opens at level %d'):format(zone,p.level))
    else
        local z = c:next_zone(p.wallet)
        assert(z < 0 or not c:zone_available(z,p.wallet), ('No region opens early at level %d'):format(p.level))
    end
    local kind = journey.wonder_at(p.level)
    if kind then assert(island.reserved_cost(c,p.level):covers(island.wonders[kind].cost)) end
    local due = 0
    for _, step in ipairs(island.ladder) do if step.after <= p.level then due = due + 1 end end
    while island.island_place_next(c,p.wallet,p.level,0) do end
    assert(island.campaign_count(c)==due, 'Every funded stall must fit the land open by then, in ladder order')
    assert(island.wonder_count(c)==journey.earned(p.level), 'Story stalls keep their schedule')
end
assert(c.open==63 and p.wallet[4]==rules.LEVELS and p.wallet[2]>0 and p.wallet[3]>0 and p.wallet[5]==0,
       'A hundred cleared wishes open all five new regions and spare matched goods are banked')
local before = p.wallet[1]
local replay = rules.game_start(0,50)
replay.won, replay.moves, replay.earnings = true, 0, {12, 3, 4}
assert(rules.progress_reward(p,replay,island.wonders))
assert(p.wallet[1]==before+12 and p.wallet[4]==rules.LEVELS and p.level==rules.LEVELS, 'Replays do not count as cleared wishes')
local stall_count = c.count
for kind=10,11 do
    assert(island.can_buy(c,p.wallet,p.level,kind))
    local ok,spot = c:find_spot(kind,vec2(760,2010))
    assert(ok, 'Decorations must fit')
    before = p.wallet[1]
    c:begin_place(kind,spot)
    c:cancel()
    assert(p.wallet[1]==before and c.count==stall_count+kind-10, 'Cancelled purchase must be free')
    c:begin_place(kind,spot)
    assert(c:confirm(p.wallet,0).result==city.BUILT)
    assert(p.wallet[1]==before-island.catalogue[kind+1].cost[1])
end
assert(c.count==stall_count+2 and island.wonder_count(c)==island.WONDERS and island.campaign_count(c)==stall_count,
       'Decorations cannot advance the campaign')

local first_wish = rules.game_start(0, 123478, {})
check(#first_wish.tool_slots == 4 and table.concat(first_wish.tools, ",") == "0,0,0,0",
      'locked boosters keep all four slots')
local B = require("economy").bonuses
local hammer_wish = rules.game_start(6, 123478, {reindeer_stable=true})
check(hammer_wish.tool_slots[1] == B.hammer and hammer_wish.tools[1] == 0,
      'the stable unlocks an empty Hammer')
local restored = {reindeer_stable=true, firework_stall=true, bonus_charge={180}}
local bomb = rules.game_start(16, 123478, restored)
local slot = B.bomb.tool
local center, wave = rules.hex_center(), rules.new_match()
check(bomb.tool_slots[slot] == B.bomb and bomb.bonus == B.bomb and bomb.tools[slot] == 1,
      'the firework stall replaces the charging piece and clamps its inherited stock')
local area = rules.game_tool_area(bomb, slot - 1, center)
check(area and area[center] and rules.game_tool(bomb, slot - 1, center, wave), 'the bomb targets the board')
for cell in pairs(area) do check(wave.mask[cell], 'the effect follows its aiming preview') end
check(bomb.tool_meter[slot] == 0 and not rules.game_tool(bomb, slot - 1, center, wave),
      'the bomb spends its only use')
restored.bonus_charge = {37}
local next_wish = rules.game_start(17, 123478, restored)
check(next_wish.tool_meter[slot] == 37 and next_wish.tools[slot] == 0, 'a partial charge carries without a free use')
