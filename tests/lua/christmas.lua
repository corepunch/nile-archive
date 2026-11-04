-- Verify that the Christmas map and prices support the complete earning/build loop.
local rules = require('rules')
local island = require('island')
local journey = require('journey')
local p = {level=0, seed=1, wallet=purse()}
local c = city.new()
island.island_setup(c)
assert(#island.catalogue == 37 and island.WONDERS == 10 and rules.LEVELS == 30)
-- Pip announces each region on the level the script gives it (docs/story.md#small-lines).
local opens = {[6]=1, [9]=2, [15]=3, [21]=4, [27]=5}
for level=0,rules.LEVELS-1 do
    local g = rules.game_start(level,100+level)
    assert(rules.game_hint(g), 'Christmas opening needs a legal move')
    g.won, g.moves = true, 0
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
    if kind then
        assert(island.reserved_gold(c,p.level)==island.wonders[kind].cost[1])
        assert(island.island_place_next(c,p.wallet,p.level,0), 'Every funded building must fit the land open by then')
        assert(island.wonder_count(c)==kind)
    else
        assert(not island.island_place_next(c,p.wallet,p.level,0), 'A story-only wish funds no stall')
    end
end
assert(c.open==63 and p.wallet[4]==90 and p.wallet[2]==0 and p.wallet[3]==0 and p.wallet[5]==0,
       'Stars open every region and the campaign awards no legacy materials or bells')
local before = p.wallet[1]
local replay = rules.game_start(0,50)
replay.won, replay.moves = true, 0
assert(rules.progress_reward(p,replay,island.wonders))
assert(p.wallet[1]==before+60 and p.wallet[4]==90 and p.level==30, 'Replay must pay only Gold')
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

-- Extended: the greedy bot, without tools, wins every winter wish at least once.
if testing.extended then
    local m = rules.new_match()
    local function resolve(g)
        for _ = 1, 200 do
            rules.game_apply(g, m); rules.game_collapse(g); rules.game_matches(g, m, -1)
            if m.hits == 0 then rules.game_check_end(g); return end
        end
    end
    for level = 0, rules.LEVELS - 1 do
        local wins = 0
        for seed = 1, 4 do
            local g = rules.game_start(level, seed)
            for _ = 1, 100 do
                if g.won or g.lost then break end
                local best, a, b = -1, -1, -1
                for i = 0, rules.CELLS - 1 do
                    for d = 0, 2 do
                        local j = rules.hex_neighbor(i, d)
                        local v = rules.game_evaluate_move(g, i, j)
                        if v > best then best, a, b = v, i, j end
                    end
                end
                if a < 0 then rules.game_shuffle(g) else rules.game_swap(g, a, b, m); resolve(g) end
            end
            if g.won then wins = wins + 1 end
        end
        check(wins >= 1, ("the greedy bot wins winter wish %d at least once"):format(level + 1))
    end
end
