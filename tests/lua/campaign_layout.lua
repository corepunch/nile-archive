-- Content contracts for both authored campaigns, using their real rules.
-- Check the authored geometry and the engine’s opening deals.
local rules = require('rules')
local campaign = require('campaign')
local island = require('island')
local economy = require('economy')
local R = require('screens')
check(rules.square and rules.COLUMNS == 9 and rules.ROWS == 12, '9×12 square envelope')
local expected = 100
check(rules.LEVELS == expected and rules.COLORS == 5, 'campaign length and five piece slots')
check(#rules.levels[4].chain_cells > 0, 'the tutorial that introduces chains contains a chain')
check(#island.ladder == 20, 'twenty campaign purchases')
local previous = 0
local owned = {preview=true}
R.board_art = setmetatable({}, {__index=function(_, frame) return frame end})
for n, step in ipairs(island.ladder) do
    check(step.after == 1 + (n - 1) * 5, 'one purchase every five clears')
    local cost = island.buildings[step.kind + 1].cost
    local total = cost[1] + cost[2] + cost[3]
    check(total >= previous, 'price total does not fall at ' .. step.unlock.building)
    previous = total
    local unlock = step.unlock
    local label = unlock.building .. ': '
    local before = rules.game_start(step.after, 21, owned)
    owned[unlock.building] = true
    local board = rules.game_start(step.after, 21, owned)
    local card = R.building_reward(step.kind)
    check(card and card.icon, label .. 'card shows one board item')
    if unlock.bonus then
        local bonus = unlock.bonus
        check(board.bonus_debut == bonus and before.bonus_debut ~= bonus and card.icon == bonus.icon,
            label .. 'card and first board agree on the purchased tool')
    else
        local piece = economy.FOOD and economy.pieces[unlock.kind] or unlock
        check(board.resource_yields[unlock.kind] == piece and before.resource_yields[unlock.kind] ~= piece
            and card.amount == piece.amount and card.unit, label .. 'card and first board agree on the matching yield')
    end
end
check(not R.building_reward(island.kinds.bench), 'decorations have no campaign piece')
for level, entry in ipairs(campaign.levels) do
    local label = ('level %d: '):format(level)
    check(#entry.mask == rules.CELLS and not entry.mask:find('[^01]'), label .. 'valid cell mask')
    local g = rules.game_start(level - 1, 1)
    local count, chains = 0, 0
    for i = 0, rules.CELLS - 1 do
        if g.active[i] then
            count = count + 1
            chains = chains + (g.chain[i] > 0 and 1 or 0)
            -- No tip or pocket requires a booster just to make a local match.
            local supported = false
            for axis = 0, rules.AXES - 1 do
                local length = 1
                for _, direction in ipairs{axis, axis+3} do
                    local j = rules.hex_neighbor(i, direction)
                    while j >= 0 and g.active[j] do
                        length = length + 1
                        j = rules.hex_neighbor(j, direction)
                    end
                end
                supported = supported or length >= rules.MATCH_MIN
            end
            check(supported, label .. 'cell ' .. i .. ' belongs to a match line')
        else
            check(g.tiles[i].kind < 0 and g.chain[i]+g.ice[i] == 0,
                label .. 'no target or piece in a hole')
        end
    end
    check(chains == #entry.chain_cells, label .. 'every authored blocker places')
    check(count >= 32, label .. 'at least 32 cells')
    for seed = 1, 4 do
        g = rules.game_start(level - 1, seed)
        local m = rules.new_match()
        rules.game_matches(g, m, -1)
        check(m.hits == 0 and rules.game_hint(g), label .. 'playable settled opening seed ' .. seed)
    end
end
