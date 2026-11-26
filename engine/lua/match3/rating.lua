-- match3/rating.lua — when a campaign asks for an App Store rating.
--
-- The sheet is the system's own (app.request_review): the game's icon, five
-- stars and Not Now, over the game, in the player's language. Apple shows it
-- at most three times a year and forbids a look-alike, so each ask is spent on
-- a moment the player is pleased and has nothing to tap:
--
--   * only after a first clear, once the results are banked and the town has
--     stood untouched for a moment (match3.game waits for that);
--   * the first ask at the tenth board cleared, or from the sixth when the
--     board was lost and then won, the win that feels best;
--   * later asks many boards and weeks apart.
--
-- The state lives in the settings save, so starting the campaign again does
-- not ask again. A game tunes the numbers in game_config.lua ("rating").
local M = {}

M.DEFAULTS = {
    level = 10,           -- boards cleared before the first ask
    comeback_level = 6,   -- ...or this many, when the win follows a loss on that board
    gap_levels = 25,      -- boards between asks
    gap_days = 30,        -- and days between them
    asks = 3,             -- asks in all
    pause = 1.2,          -- seconds the town stands untouched before the sheet
}

-- asks: sheets asked for; level, day: boards cleared and the day (since the
-- Unix epoch) at the last one; losses: boards lost since the last win.
function M.new() return {asks = 0, level = 0, day = 0, losses = 0} end

function M.day(clock) return math.floor(clock / 86400) end

-- Whether the first clear that leaves `level` boards cleared earns an ask.
function M.due(config, state, level, day)
    if state.asks >= config.asks then return false end
    if state.asks == 0 then
        return level >= config.level or (state.losses > 0 and level >= config.comeback_level)
    end
    return level - state.level >= config.gap_levels and day - state.day >= config.gap_days
end

function M.asked(state, level, day)
    state.asks, state.level, state.day = state.asks + 1, level, day
end

function M.serialize(s, state)
    state.asks = s:int("rating_asks", state.asks)
    state.level = s:int("rating_level", state.level)
    state.day = s:int("rating_day", state.day)
    state.losses = s:int("rating_losses", state.losses)
end

-- The App Store page that opens on its review form: Settings' own link.
function M.url(app_store_id)
    return ("https://apps.apple.com/app/id%s?action=write-review"):format(app_store_id)
end

return M
