-- Game content, piece identities and restoration economy. Mechanics are shared.
local match3 = require("match3")
local campaign = require("campaign")
local economy = require("economy")
local island = require("island")
local reference=app.arg("homescapes") and assert(require("match3.reference")[app.arg("homescapes")],"unknown Homescapes reference level")
local flags = match3.LINE_MATCHES
if not reference then flags = flags | match3.NO_SPECIALS | match3.NO_RHOMBI | match3.COLOR_TOOL end
local M = match3.new{flags=flags, radius=reference and reference.radius or 4, colors=campaign.colors, match_min=3,
    levels=reference and {reference.level} or campaign.levels, level_shapes=campaign.shapes,
    kind_flags={[0]=match3.GOAL,  [2]=match3.WOOD, [4]=match3.STONE}}
local start = M.game_start
function M.game_start(level, seed, restored)
    if reference then return start(level, seed) end
    local number = math.max(0, math.min(level, M.LEVELS-1)) + 1
    local spec = M.levels[number]
    local yields, tools = economy.board_loadout(spec, number, restored)
    local g = start(level, seed, yields)
    if spec.opening then
        -- Authored kind slots use the current restoration art and yields.
        -- The engine's seeded RNG still drives cascades and refills.
        for i = 0, M.CELLS - 1 do
            if g.active[i] then g.tiles[i] = M.tile(tonumber(spec.opening:sub(i + 1, i + 1))) end
        end
    end
    g.tools, g.starting_tools = {table.unpack(tools)}, tools
    return g
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

function M.reward_breakdown(g, wonders, progress, town)
    local first = not progress or g.level == progress.level
    local bonus = math.min(M.MAX_MOVE_GOLD, math.max(0, g.moves) * M.MOVE_GOLD)
    local kind=M.wonder_at(g.level+1)
    local w=kind and wonders[kind]
    local matched = purse(table.unpack(g.earnings or {}))
    local happiness = island.happiness_gold(town)
    local reward = matched + purse(bonus + happiness, 0, 0, first and 3 or 0)
    if first and w and app.arg("debug-walkthrough") then
        reward = reward + economy.shortfall(w.cost, (progress and progress.wallet or purse()) + reward)
    end
    return {first=first, bonus=bonus, happiness=happiness, total=reward}
end

function M.level_reward(g, wonders, progress, town)
    return M.reward_breakdown(g,wonders,progress,town).total
end

function M.progress_reward(p, g, wonders, town)
    if reference then return false end
    if not g.won or g.reward_claimed or g.level < 0 or g.level >= LEVELS or g.level > p.level then return false end
    local reward = M.reward_breakdown(g,wonders,p,town)
    p.wallet = p.wallet + reward.total
    if reward.first then p.level = p.level + 1 end
    p.seed = g.rng
    p.completed = nil
    g.reward_claimed = true
    return true, reward.first
end

return M
