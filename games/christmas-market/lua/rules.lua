-- Game content, piece identities and restoration economy. Mechanics are shared.
local match3 = require("match3")
local campaign = require("campaign")
local economy = require("economy")
local M = match3.square_campaign(campaign)
M.RELIC_IDOL, M.RELIC_FLAME, M.RELIC_LEAF, M.RELIC_SCARAB, M.RELIC_CRYSTAL, M.RELIC_AMPHORA = 0, 1, 2, 3, 4, 5
local LEVELS = M.LEVELS
-- The stalls in force, by building key. `built` is the game's own map, a
-- count of story stalls (every ladder stall up to that one), or nil for
-- every stall due by this wish.
local function restored_from(built, level)
    if type(built) == "table" then return built end
    local restored, stories = {preview=true}, 0
    for _, step in ipairs(require("island").ladder) do
        if built then
            if stories >= built then break end
            if step.story then stories = stories + 1 end
        elseif step.after > level then break end
        restored[step.unlock.building] = true
    end
    return restored
end

function M.game_start(level, seed, built)
    level = math.max(0, math.min(level, LEVELS - 1))
    local number, restored = level + 1, restored_from(built, level)
    local yields, loadout = economy.board_loadout(number, restored, seed)
    local g = M.start_campaign_board(level, seed, yields, loadout)
    g.backdrop = economy.board_backdrop(number, restored)
    return g
end
M.wonder_levels=campaign.wonder_levels
M.wonder_at=require("journey").wonder_at

------------------------------------------------------------------- economy

M.GOLD, M.FOOD, M.SUPPLIES, M.CLEARED = economy.GOLD, economy.FOOD, economy.SUPPLIES, economy.CLEARED
function M.reward_breakdown(g, wonders, progress)
    local first = not progress or g.level == progress.level
    local kind = M.wonder_at(g.level + 1)
    local w = kind and wonders[kind]
    local matched = purse(table.unpack(g.earnings or {}))
    local income = M.perk_income and M.perk_income() or purse()
    local reward = matched + income + purse(0, 0, 0, first and 1 or 0)
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
