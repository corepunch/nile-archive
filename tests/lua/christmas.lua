-- Verify that the Christmas map and prices support the complete earning/build loop.
local rules = require('rules')
local island = require('island')
local journey = require('journey')
local p = {level=0, seed=1, wallet=purse()}
local c = city.new()
island.island_setup(c)
assert(#island.catalogue == 37 and island.WONDERS == 10 and rules.LEVELS == 100)
-- Pip announces each region on the level the script gives it (docs/story.md#small-lines).
local opens = {[6]=1, [9]=2, [15]=3, [21]=4, [27]=5}
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
assert(c.open==63 and p.wallet[4]==3*rules.LEVELS and p.wallet[2]>0 and p.wallet[3]>0 and p.wallet[5]==0,
       'Stars open every region and spare matched goods are banked')
local before = p.wallet[1]
local replay = rules.game_start(0,50)
replay.won, replay.moves, replay.earnings = true, 0, {12, 3, 4}
assert(rules.progress_reward(p,replay,island.wonders))
assert(p.wallet[1]==before+12 and p.wallet[4]==3*rules.LEVELS and p.level==rules.LEVELS, 'Replays do not earn additional Stars')
for kind=10,11 do
    assert(island.can_buy(c,p.wallet,p.level,kind))
    local ok,spot = c:find_spot(kind,vec2(760,2010))
    assert(ok, 'Decorations must fit')
    before = p.wallet[1]
    c:begin_place(kind,spot)
    c:cancel()
    assert(p.wallet[1]==before and c.count==#island.ladder+kind-10, 'Cancelled purchase must be free')
    c:begin_place(kind,spot)
    assert(c:confirm(p.wallet,0).result==city.BUILT)
    assert(p.wallet[1]==before-island.catalogue[kind+1].cost[1])
end
assert(c.count==22 and island.wonder_count(c)==10 and island.campaign_count(c)==20, 'Decorations cannot advance the campaign')

local old_save = {}
rules.refill_lives(old_save, 100)
check(old_save.lives == 5 and old_save.life_at == 0, 'An older save starts with five lives')
local failed = {lost=true}
check(rules.lose_life(old_save, failed, 100) and old_save.lives == 4 and old_save.life_at == 1900,
      'A failed wish costs one life and starts the refill timer')
check(not rules.lose_life(old_save, failed, 101) and old_save.lives == 4, 'A failed wish can charge only once')
rules.refill_lives(old_save, 1899)
check(old_save.lives == 4, 'No life returns before thirty minutes')
rules.refill_lives(old_save, 1900)
check(old_save.lives == 5 and old_save.life_at == 0, 'A life returns after thirty minutes')

local first_wish = rules.game_start(0, 123478, {})
check(#first_wish.tool_slots == 4 and table.concat(first_wish.tools, ",") == "0,0,0,0",
      'locked boosters keep all four slots')
local star_wish = rules.game_start(2, 123478, {reindeer_stable=true})
check(star_wish.tools[4] == 1 and star_wish.tools[2] == 0 and next(star_wish.tool_meter) == nil,
      'the stable grants one Shooting Star on its first eligible wish')
local boosters = rules.game_start(19, 123478, {reindeer_stable=true, lumber=true, santa_workshop=true, candles=true})
local center = rules.hex_center()
check(boosters.tools[1] == 0 and boosters.tool_meter[1] == 0 and boosters.tool_meter[3] == 0
      and boosters.tools[2] == 1 and boosters.tools[4] == 1, 'banked and per-wish boosters use separate stock')
local wave = rules.new_match()
local function use_once(slot)
    local area = rules.game_tool_area(boosters, slot, center)
    check(area and area[center] and rules.game_tool(boosters, slot, center, wave), 'the booster targets the board')
    for cell in pairs(area) do check(wave.mask[cell], 'the effect follows its aiming preview') end
    check(not rules.game_tool(boosters, slot, center, wave), 'the per-wish booster has been spent')
end
use_once(1)
use_once(3)
check(rules.game_start(2, 123478, {reindeer_stable=true}).tools[4] == 1,
      'a fresh attempt starts with its own booster use')
