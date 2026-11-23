-- Game content, piece identities and restoration economy. Mechanics are shared.
local match3 = require("match3")
local campaign = require("campaign")
local economy = require("economy")
local spring_well = require("buildings")[economy.WELL_KIND + 1]
local M = match3.square_campaign(campaign)

function M.game_start(level, seed, restored)
    local number = math.max(0, math.min(level, M.LEVELS-1)) + 1
    local yields, loadout = economy.board_loadout(number, restored, seed)
    local g = M.start_campaign_board(level, seed, yields, loadout)
    g.backdrop = economy.board_backdrop(number, restored)
    return g
end
M.RELIC_IDOL, M.RELIC_FLAME, M.RELIC_LEAF, M.RELIC_SCARAB, M.RELIC_CRYSTAL, M.RELIC_AMPHORA = 0, 1, 2, 3, 4, 5
local LEVELS = M.LEVELS
M.wonder_levels=campaign.wonder_levels
M.wonder_at=require("journey").wonder_at

------------------------------------------------------------------- economy

M.GOLD, M.PROVISIONS, M.SUPPLIES, M.CLEARED = economy.GOLD, economy.PROVISIONS, economy.SUPPLIES, economy.CLEARED
M.COMPASSES = 5   -- reserved slot retained in old saves
function M.reward_breakdown(g, progress)
    local first = not progress or g.level == progress.level
    local matched = purse(table.unpack(g.earnings or {}))
    local income = M.perk_income and M.perk_income() or purse()   -- the citizens' perks
    local decoration = M.decoration_income and M.decoration_income() or 0   -- the town's decorations
    local reward = matched + income + purse(0, 0, 0, first and 1 or 0)
    if g.won and first and g.level == 0 then
        reward[M.GOLD] = math.max(reward[M.GOLD], spring_well.cost[M.GOLD])
    end
    reward[M.GOLD] = reward[M.GOLD] + decoration
    return {first=first, income=income, decoration=decoration, total=reward}
end

function M.level_reward(g, wonders, progress)
    return M.reward_breakdown(g,progress).total
end

function M.progress_reward(p, g)
    if not g.won or g.reward_claimed or g.level < 0 or g.level >= LEVELS or g.level > p.level then return false end
    local reward = M.reward_breakdown(g,p)
    p.wallet = p.wallet + reward.total
    if reward.first then p.level = p.level + 1 end
    p.seed = g.rng
    p.completed = nil
    g.reward_claimed = true
    return true, reward.first
end

return M
