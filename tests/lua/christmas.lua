-- Verify that the Christmas map and prices support the complete earning/build loop.
local rules = require('rules')
local island = require('island')
local p = {level=0, seed=1, wallet=purse()}
local c = city.new()
island.island_setup(c)
assert(#island.catalogue == 37 and island.WONDERS == 10)
for level=0,9 do
    local g = rules.game_start(level,100+level)
    assert(rules.game_hint(g), 'Christmas opening needs a legal move')
    g.won, g.moves = true, 0
    assert(rules.progress_reward(p,g,island.wonders), 'First clear must fund construction')
    local before = p.wallet[1]
    assert(not rules.progress_reward(p,g,island.wonders) and p.wallet[1]==before, 'Cannot pay twice')
    assert(island.reserved_gold(c,p.level)==island.wonders[level+1].cost[1])
    for zone=1,5 do c:unlock(zone,p.wallet) end
    assert(island.island_place_next(c,p.wallet,p.level,0), 'Every funded building must fit')
    assert(island.wonder_count(c)==level+1)
end
assert(c.open==63 and p.wallet[4]==30 and p.wallet[5]==0, 'Full campaign opens every region')
local before = p.wallet[1]
local replay = rules.game_start(0,50)
replay.won, replay.moves = true, 0
assert(rules.progress_reward(p,replay,island.wonders))
assert(p.wallet[1]==before+60 and p.wallet[4]==30 and p.level==10, 'Replay must pay only Gold')
for kind=10,11 do
    assert(island.can_buy(c,p.wallet,p.level,kind))
    local ok,spot = c:find_spot(kind,vec2(760,2010))
    assert(ok, 'Decorations must fit')
    before = p.wallet[1]
    c:begin_place(kind,spot)
    c:cancel()
    assert(p.wallet[1]==before and c.count==kind, 'Cancelled purchase must be free')
    c:begin_place(kind,spot)
    assert(c:confirm(p.wallet,0).result==city.BUILT)
    assert(p.wallet[1]==before-island.catalogue[kind+1].cost[1])
end
assert(c.count==12 and island.wonder_count(c)==10, 'Decorations cannot advance the campaign')
