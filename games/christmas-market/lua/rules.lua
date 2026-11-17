-- Game content, piece identities and restoration economy. Mechanics are shared.
local match3 = require("match3")
local campaign = require("campaign")
local economy = require("economy")
local reference=app.arg("homescapes") and assert(require("match3.reference")[app.arg("homescapes")],"unknown Homescapes reference level")
local flags = match3.LINE_MATCHES
if not reference then flags = flags | match3.NO_SPECIALS | match3.NO_RHOMBI end
local M = match3.new{flags=flags, radius=reference and reference.radius or 4, colors=reference and 6 or #economy.pieces + 1, match_min=3,
    levels=reference and {reference.level} or campaign.levels, level_shapes=campaign.shapes,
    bonus_size=108, sunburst_targets=not reference and economy.lightning_targets,
    kind_flags={[0]=match3.GOAL, [2]=match3.WOOD, [4]=match3.STONE}}
M.RELIC_IDOL, M.RELIC_FLAME, M.RELIC_LEAF, M.RELIC_SCARAB, M.RELIC_CRYSTAL, M.RELIC_AMPHORA = 0, 1, 2, 3, 4, 5
local LEVELS = M.LEVELS
-- The stalls in force, by building key. `built` is the game's own map, a
-- count of story stalls (every ladder stall up to that one), or nil for
-- every stall due by this wish.
local function restored_from(built, level)
    if type(built) == "table" then return built end
    local restored, stories = {}, 0
    for _, step in ipairs(require("island").ladder) do
        if built then
            if stories >= built then break end
            if step.story then stories = stories + 1 end
        elseif step.after > level then break end
        restored[step.unlock.building] = true
    end
    return restored
end

local start = M.game_start
function M.game_start(level, seed, built)
    if reference then return start(level, seed) end
    local yields, loadout = economy.loadout(restored_from(built, level), level + 1, seed or 1)
    local g = start(level, seed, yields, loadout)
    g.win_income, g.opening_tools = loadout.win_income, loadout.opening_tools
    for slot, uses in pairs(g.opening_tools) do g.tools[slot] = uses end
    return g
end
M.wonder_levels=campaign.wonder_levels
M.wonder_at=require("journey").wonder_at

------------------------------------------------------------------- economy

M.GOLD, M.FOOD, M.SUPPLIES, M.STARS = economy.GOLD, economy.FOOD, economy.SUPPLIES, economy.STARS
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
    local kind = M.wonder_at(g.level + 1)
    local w = kind and wonders[kind]
    local matched = purse(table.unpack(g.earnings or {}))
    -- The rink's and presents' takings pay on every win, as Rome's citizens do.
    local income = g.win_income or purse()
    local reward = matched + income + purse(0, 0, 0, first and 3 or 0)
    if first and w and app.arg("debug-walkthrough") then
        local available = (progress and progress.wallet or purse()) + reward
        for slot in ipairs(economy.currencies) do reward[slot] = reward[slot] + math.max(0, w.cost[slot] - available[slot]) end
    end
    return {first=first, wonder=w, income=income, total=reward}
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
