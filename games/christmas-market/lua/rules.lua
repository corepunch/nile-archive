-- Game content, piece identities and restoration economy. Mechanics are shared.
local match3 = require("match3")
local campaign = require("campaign")
local M = match3.new{flags=0, radius=4, colors=6, match_min=4,
    levels=campaign.levels, level_shapes=campaign.shapes,
    kind_flags={[0]=match3.GOAL, [1]=match3.THAW, [2]=match3.WOOD, [4]=match3.STONE}}
M.RELIC_IDOL, M.RELIC_FLAME, M.RELIC_LEAF, M.RELIC_SCARAB, M.RELIC_CRYSTAL, M.RELIC_AMPHORA = 0, 1, 2, 3, 4, 5
local LEVELS = M.LEVELS

------------------------------------------------------------------- economy

M.GOLD, M.WOOD, M.STONE, M.STARS, M.COMPASSES = 1, 2, 3, 4, 5   -- purse slots

-- Guaranteed restoration funding is separate from the discretionary Gold purse.
-- Matches score points; their random colour mix cannot reduce a building grant.
M.FIRST_GOLD, M.REPLAY_GOLD, M.MOVE_GOLD, M.MAX_MOVE_GOLD = 80, 60, 2, 40
-- Pays the 20-compass land budget by the ninth discovery, at the Star gates.
M.compass_rewards = {1, 1, 3, 2, 2, 2, 3, 3, 3, 0}

function M.discovery_compasses(count)
    local n=0
    for i=1,math.min(count,LEVELS) do n=n+M.compass_rewards[i] end
    return n
end

function M.reward_breakdown(g, wonders, progress)
    local first = not progress or g.level == progress.level
    local bonus = math.min(M.MAX_MOVE_GOLD, math.max(0, g.moves) * M.MOVE_GOLD)
    local w = wonders[g.level + 1]
    local grant = first and w.cost or purse()
    local gold = first and M.FIRST_GOLD or M.REPLAY_GOLD
    return {first=first, grant=grant, base=gold, bonus=bonus,
        total=purse(grant[1]+gold+bonus, grant[2], grant[3], first and 3 or 0,
                    first and M.compass_rewards[g.level+1] or 0)}
end

function M.level_reward(g, wonders, progress)
    return M.reward_breakdown(g,wonders,progress).total
end

function M.progress_reward(p, g, wonders)
    if not g.won or g.reward_claimed or g.level < 0 or g.level >= LEVELS or g.level > p.level then return false end
    local reward = M.reward_breakdown(g,wonders,p)
    p.wallet = p.wallet + reward.total
    if reward.first then p.level = p.level + 1 end
    p.seed = g.rng
    g.reward_claimed = true
    return true, reward.first
end

return M
