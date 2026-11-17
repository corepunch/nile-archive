-- Content contracts for both authored campaigns, using their real rules.
-- tools/hex_levels.py validates the sources; this checks what the engine builds.
local rules = require('rules')
local campaign = require('campaign')
for level, entry in ipairs(campaign.levels) do
    local label = ('level %d: '):format(level)
    check(#entry.mask == rules.CELLS and not entry.mask:find('[^01]'), label .. 'valid cell mask')
    local g = rules.game_start(level - 1, 1)
    local count, chains, ice = 0, 0, 0
    for i = 0, rules.CELLS - 1 do
        if g.active[i] then
            count = count + 1
            chains = chains + (g.chain[i] > 0 and 1 or 0)
            ice = ice + (g.ice[i] > 0 and 1 or 0)
            -- No tip or pocket requires a booster just to make a local match.
            local supported = false
            for axis = 0, 2 do
                local length = 1
                for _, direction in ipairs{axis, axis+3} do
                    local j = rules.hex_neighbor(i, direction)
                    while j >= 0 and g.active[j] do
                        length = length + 1
                        j = rules.hex_neighbor(j, direction)
                    end
                end
                supported = supported or length >= 3
            end
            check(supported, label .. 'cell ' .. i .. ' belongs to a match line')
        else
            check(g.tiles[i].kind < 0 and g.chain[i]+g.ice[i] == 0,
                label .. 'no target or piece in a hole')
        end
    end
    check(chains == #entry.chain_cells and ice == #entry.ice_cells, label .. 'every authored blocker places')
    check(count >= 49, label .. 'at least 49 cells')
    for seed = 1, 4 do
        g = rules.game_start(level - 1, seed)
        local m = rules.new_match()
        rules.game_matches(g, m, -1)
        check(m.hits == 0 and rules.game_hint(g), label .. 'playable settled opening seed ' .. seed)
    end
end
