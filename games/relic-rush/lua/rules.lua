-- Game content, piece identities and restoration economy. Mechanics are shared.
local match3 = require("match3")
local campaign = require("campaign")
local economy = require("economy")
local reference=app.arg("homescapes") and assert(require("match3.reference")[app.arg("homescapes")],"unknown Homescapes reference level")
local M = match3.new{flags=match3.LINE_MATCHES, radius=reference and reference.radius or 4, colors=campaign.colors, match_min=3,
    levels=reference and {reference.level} or campaign.levels, level_shapes=campaign.shapes,
    kind_flags={[0]=match3.GOAL,  [2]=match3.WOOD, [4]=match3.STONE}}
local start = M.game_start
function M.game_start(level, seed, restored)
    local spec = M.levels[math.max(0, math.min(level, M.LEVELS-1)) + 1]
    return start(level, seed, not reference and economy.board_yields(spec, restored))
end
M.RELIC_IDOL, M.RELIC_FLAME, M.RELIC_LEAF, M.RELIC_SCARAB, M.RELIC_CRYSTAL, M.RELIC_AMPHORA = 0, 1, 2, 3, 4, 5
local LEVELS = M.LEVELS
M.wonder_levels=campaign.wonder_levels
M.wonder_at=require("journey").wonder_at

------------------------------------------------------------------- economy

M.GOLD, M.PROVISIONS, M.SUPPLIES, M.STARS = economy.GOLD, economy.PROVISIONS, economy.SUPPLIES, economy.STARS
M.COMPASSES = 5   -- reserved slot retained in old saves
M.MOVE_GOLD, M.MAX_MOVE_GOLD = 2, 40
M.LIVES, M.LIFE_INTERVAL = 5, 1800
function M.refill_lives(p, now)
    p.lives=num.clampi(p.lives or M.LIVES,0,M.LIVES)
    if p.lives==M.LIVES then p.life_at=0;return end
    if not p.life_at or p.life_at<=0 then p.life_at=now+M.LIFE_INTERVAL end
    if now>=p.life_at then
        local count=math.floor((now-p.life_at)/M.LIFE_INTERVAL)+1
        p.lives=math.min(M.LIVES,p.lives+count)
        p.life_at=p.lives==M.LIVES and 0 or p.life_at+count*M.LIFE_INTERVAL
    end
end
function M.lose_life(p,g,now)
    if not g.lost or g.life_paid then return false end
    M.refill_lives(p,now);g.life_paid=true
    if p.lives>0 then p.lives=p.lives-1;if not p.life_at or p.life_at==0 then p.life_at=now+M.LIFE_INTERVAL end end
    return true
end

function M.reward_breakdown(g, wonders, progress)
    local first = not progress or g.level == progress.level
    local bonus = math.min(M.MAX_MOVE_GOLD, math.max(0, g.moves) * M.MOVE_GOLD)
    local kind=M.wonder_at(g.level+1)
    local w=kind and wonders[kind]
    local matched = purse(table.unpack(g.earnings or {}))
    local reward = matched + purse(bonus, 0, 0, first and 3 or 0)
    local delivery = purse()
    if first and w then
        local available = (progress and progress.wallet or purse()) + reward
        for slot in ipairs(economy.currencies) do delivery[slot] = math.max(0, w.cost[slot] - available[slot]) end
    end
    return {first=first, wonder=w, matched=matched, delivery=delivery, bonus=bonus, total=reward+delivery}
end

function M.level_reward(g, wonders, progress)
    return M.reward_breakdown(g,wonders,progress).total
end

function M.progress_reward(p, g, wonders)
    if reference then return false end
    if not g.won or g.reward_claimed or g.level < 0 or g.level >= LEVELS or g.level > p.level then return false end
    local reward = M.reward_breakdown(g,wonders,p)
    p.wallet = p.wallet + reward.total
    if reward.first then p.level = p.level + 1 end
    p.seed = g.rng
    p.completed = nil
    g.reward_claimed = true
    return true, reward.first
end

return M
