-- Optional timing of the bot's rule calls. A proxy keeps instrumentation local
-- to this player; the real rules table and other tests are never modified.
return function(rules)
    local profile = {rules=setmetatable({}, {__index=rules})}
    local rows = {}
    for _, name in ipairs{'game_copy', 'game_swap_matches', 'game_swap', 'game_apply', 'game_probe_swap'} do
        if rules[name] then
            local row = {name=name, calls=0, seconds=0}
            rows[#rows + 1] = row
            profile.rules[name] = function(...)
                local start = testing.monotonic()
                local a, b, c = rules[name](...)
                row.calls, row.seconds = row.calls + 1, row.seconds + testing.monotonic() - start
                return a, b, c
            end
        end
    end
    function profile.report()
        for _, row in ipairs(rows) do
            print(('BOT_PROFILE %s calls=%d seconds=%.6f'):format(row.name, row.calls, row.seconds))
        end
    end
    return profile
end
