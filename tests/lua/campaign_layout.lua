-- Content contracts for both authored campaigns, using their real rules.
local rules = require('rules')
local campaign = require('campaign')
local other = require('games/' .. (campaign.levels[1].name == 'First Light'
    and 'christmas-market' or 'relic-rush') .. '/lua/campaign')
local seen = {}
for level, entry in ipairs(campaign.levels) do
    local label = ('level %d: '):format(level)
    check(#entry.mask == rules.CELLS and not entry.mask:find('[^01]'), label .. 'valid cell mask')
    check(not seen[entry.mask], label .. 'distinct campaign silhouette')
    seen[entry.mask] = true
    for _, peer in ipairs(other.levels) do
        check(entry.mask ~= peer.mask, label .. 'not copied from the other campaign')
    end
    check(#entry.terrain == rules.CELLS, label .. 'terrain covers the envelope')
    local g = rules.game_start(level - 1, 1)
    local count, soil, chains, ice, start = 0, 0, 0, 0
    for i = 0, rules.CELLS - 1 do
        if g.active[i] then
            count, start = count + 1, i
            soil = soil + g.soil[i]
            chains = chains + g.chain[i]
            ice = ice + (g.ice[i] > 0 and 1 or 0)
            check(type(entry.terrain[i+1]) == 'number', label .. 'authored terrain rank')
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
            check(g.tiles[i].kind < 0 and g.soil[i]+g.chain[i]+g.ice[i] == 0,
                label .. 'no target or piece in a hole')
        end
    end
    check(soil == entry.soil and chains == entry.chains and ice == entry.ice,
        label .. 'every authored target actually places')
    local queue, reached, head = {start}, {[start]=true}, 1
    while head <= #queue do
        local i = queue[head]
        head = head + 1
        for direction = 0, 5 do
            local j = rules.hex_neighbor(i, direction)
            if j >= 0 and g.active[j] and not reached[j] then
                reached[j], queue[#queue+1] = true, j
            end
        end
    end
    check(#queue == count, label .. 'connected working area')
    for seed = 1, 4 do
        g = rules.game_start(level - 1, seed)
        local m = rules.new_match()
        rules.game_matches(g, m, -1)
        check(m.hits == 0 and rules.game_hint(g), label .. 'playable settled opening seed ' .. seed)
    end
end
