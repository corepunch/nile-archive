-- Game content, piece identities and restoration economy. Mechanics are shared.
local match3 = require("match3")
local campaign = require("campaign")
local economy = require("economy")
local M = match3.new{flags=match3.LINE_MATCHES | match3.COLOR_TOOL, columns=9, rows=12, colors=campaign.colors, match_min=3,
    refill_damping=2, levels=campaign.levels, level_shapes=campaign.shapes,
    kind_flags={[0]=match3.GOAL,  [2]=match3.WOOD, [4]=match3.STONE}}
local start = M.game_start
function M.game_start(level, seed, restored)
    local number = math.max(0, math.min(level, M.LEVELS-1)) + 1
    local spec = M.levels[number]
    local yields, loadout, bonus, debut = economy.board_loadout(spec, number, restored, seed)
    local g = start(level, seed, yields, loadout)
    g.bonus, g.bonus_debut = bonus, debut
    g.bonus_preview = restored and restored.preview
    g.backdrop = economy.board_backdrop(spec, number, restored)
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
    local reward = matched + purse(0, 0, 0, first and 1 or 0)
    return {first=first, total=reward}
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
