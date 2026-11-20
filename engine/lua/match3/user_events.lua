-- match3/user_events.lua — Cradle of Rome's If/Then user events, shared by the
-- square campaigns (Relic Rush, Christmas Market). A game keeps its data
-- (lua/user_events.lua) and one thin file, lua/user_events_runtime.lua:
--
--     local R = require("state")
--     return require("match3.user_events").install(R, {
--         data = require("user_events"), rules = require("rules"),
--         island = require("island"), economy = require("economy")})
--
-- required after every hook it wraps (R.finish_wave, R.board_update,
-- R.serialize_campaign, R.open_catalogue, rules.game_start/game_apply).
--
-- An event is checked only while it is available and not done. When its If
-- is met it runs each Then and is done for good. Progress (available, done,
-- the few lasting counters) is saved with the campaign. Lasting effects (per
-- piece yields, tool charge, income per win, building upgrades, trophies) are
-- derived from the done events, never stored, so retuning the data applies to
-- old saves too.
--
-- Upgrades are events with an `upgrade` table ({title, keeper, building}): the
-- phrase, the cast id of the character who runs the building and its key.
-- Placing the building arms the event (city_<building> -> THEN_USER_EVENT_AVAILABLE);
-- meeting its feat upgrades the building, a trophy is
-- awarded and the perk applies for good. The arrival scene is the journey's
-- upgrade beat for that event ({phase="upgrade", event=id}, played on the
-- next return to town); without one a toast announces it. The building's card
-- (R.upgrade_card) names the upgrade and its perk, or the feat while it is armed.
-- `M.upgrade_events(rows)` builds those events from compact rows.
--
-- Conditions (If). Board ones count on the current expedition only.
--   IF_PLAYER_MAKE_MATCH length [max_length]    a straight line of at least length (and at most max_length)
--   IF_PLAYER_MAKE_COMBO length                 one move clears in at least length waves
--   IF_PLAYER_MAKE_AUTOMATCH_CHAIN amount       a move's cascade adds amount waves after the first
--   IF_PLAYER_MAKE_MATCH_SERIES amount min_length       consecutive moves each with such a line
--   IF_PLAYER_MAKE_COMBO_SERIES amount min_length       consecutive moves each with such a combo
--   IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES amount        consecutive moves that clear a plaque
--   IF_PLAYER_MAKE_MATCH_IN_TIME amount min_length time  lines within time seconds
--   IF_PLAYER_MAKE_COMBO_IN_TIME amount min_length time  combos within time seconds
--   IF_PLAYER_MAKE_EFFECTIVE_MOVES_IN_TIME amount time   plaque-clearing moves within time seconds
--   IF_PLAYER_MAKE_MATCH_IN_LEVEL amount min_length      lines on one expedition
--   IF_PLAYER_MAKE_COMBO_IN_LEVEL amount min_length      combos on one expedition
--   IF_PLAYER_GET_RESOURCE_IN_LEVEL id amount   coins, food, supplies or score earned on one expedition
--   IF_PLAYER_GET_RESOURCE id amount            banked from won expeditions within the event's levels
--   IF_PLAYER_GET_SCORE_IN_LEVEL amount, IF_PLAYER_GET_SCORE amount   the same for score
--   IF_PLAYER_COMPLETE_LEVELS amount            won expeditions
--   IF_PLAYER_COMPLETE_LEVELS_IN_TIME amount time       won expeditions each within time seconds
--   IF_PLAYER_COMPLETE_LEVELS_WITHOUT_LIFE_LOSS amount  wins in a row without a failed board
--   IF_PLAYER_COMPLETE_LEVELS_WITHOUT_BONUS_USE amount  wins in a row without tapping a bonus
--   IF_PLAYER_GET_READY_BONUSES amount          charged bonuses at once
--   IF_PLAYER_BUILT_CONSTRUCTION id             a building is placed on the island
--   IF_PLAYER_UPGRADE_CONSTRUCTION amount       upgrades earned (buildings upgraded)
--   IF_PLAYER_SESSION_TIME amount               minutes since launch
--   IF_GAME_SHOW_MOVE_HINT amount               the board's amount-th move suggestion
--   IF_GAME_PUZZLE_TILE_APPEAR, IF_GAME_DOUBLE_PUZZLE_TILE_APPEAR   a board opens with (double) plaques
--   IF_GAME_LOCK_APPEAR, IF_GAME_DOUBLE_LOCK_APPEAR, IF_GAME_FREEZE_APPEAR   ... chains, double chains, ice
--   IF_GAME_BALL_APPEAR id                      ... a piece or bonus gem by key
--   IF_GAME_PUZZLE_BALL_APPEAR                  ... the expedition's story piece
--   IF_GAME_MOVES_FALL_BELOW moves              moves left drop below moves (Rome: TIME_FALL_BELOW)
--   IF_GAME_BONUS_READY id                      a bonus (by key) becomes charged
--   IF_GAME_SHOP_ENTER                          the building catalogue opens
--
-- Effects (Then), in order:
--   THEN_SHOW_TUTORIAL / THEN_SHOW_HINT id text [delay]
--       a toast on the board or the island (Rome's HINT_INFO dimmed the
--       scene; campaign boards here keep no banner).
--   THEN_PLAYER_ADD_TROPHY id                   a trophy (names in user_events.lua)
--   THEN_PLAYER_ADD_RESOURCE id amount          once, into the wallet
--   THEN_PLAYER_ADD_RESOURCE_PER_LEVEL id amount   amount more of coins, food or supplies in every won
--                                               level's reward from then on (derived: U.win_income())
--   THEN_GAME_CHARGE_TOOL id amount             the tool slot of bonus id (hammer, bomb ...): each of its
--                                               pieces charges amount points more per match (derived)
--   THEN_GAME_CHANGE_CHIP_WEIGHT id amount      a piece pays (a bonus gem charges) amount
--   THEN_CITY_UPGRADE_BUILDING id               the building's upgrade level rises
--   THEN_PLAYER_ADD_GAME_CENTER_TROPHY id       a Game Center achievement
--   THEN_USER_EVENT_AVAILABLE id available      turns the space-separated events on or off
local M = {}

function M.install(R, cfg)
    local rules, island, economy, data = cfg.rules, cfg.island, cfg.economy, cfg.data
    -- The wallet slot each resource id names (the purse slots are save data in both games).
    local SLOTS = cfg.slots or {coins=1, food=2, supplies=3}
    local U = {events=data.events, trophy_names=data.trophies, by_id={}}
    for _, e in ipairs(U.events) do
        assert(not U.by_id[e.id], "duplicate user event " .. e.id)
        U.by_id[e.id] = e
    end

    local AVAILABLE, DONE = 1, 2

    ------------------------------------------------------------------ state

    -- Profile state lives on R.prog, so a fresh profile (and every test run) starts clean.
    function U.state()
        local p = R.prog
        if not p.user_events then
            local s = {available={}, done={}, count={}, pending={}}   -- pending: delayed hints
            for _, e in ipairs(U.events) do s.available[e.id] = e.available ~= false end
            p.user_events = s
        end
        return p.user_events
    end

    -- Per-board state lives on the board.
    local function board(g)
        g.user_events = g.user_events or {time=0, hints=0, lines=0, combos=0, series={}, recent={},
            tools={}, waves=0, longest=0, effective=false, bonus_used=false}
        return g.user_events
    end

    function U.serialize(s)
        local st = U.state()
        for _, e in ipairs(U.events) do
            local id = e.id
            local bits = (st.available[id] and AVAILABLE or 0) | (st.done[id] and DONE or 0)
            bits = s:int("user_event." .. id, bits)
            st.available[id], st.done[id] = bits & AVAILABLE ~= 0, bits & DONE ~= 0
            st.count[id] = s:int("user_event." .. id .. ".count", st.count[id] or 0)
            if st.count[id] == 0 then st.count[id] = nil end
        end
        local clean = s:int("user_event.clean", st.clean or 0)
        st.clean = clean ~= 0 and clean or nil
    end

    ------------------------------------------------------------------ derived effects

    local function each_done_effect(kind, fn)
        if not R.prog then return end   -- before a profile loads, nothing is done
        local st = U.state()
        for _, e in ipairs(U.events) do
            if st.done[e.id] then
                for _, t in ipairs(e.Then) do if t[1] == kind then fn(t, e) end end
            end
        end
    end

    -- Piece key -> amount it pays (a bonus gem: the charge it gives).
    function U.chip_weights()
        local weights = {}
        each_done_effect("THEN_GAME_CHANGE_CHIP_WEIGHT", function(t) weights[t.id] = t.amount end)
        return weights
    end

    function U.upgrades(key)
        local n = 0
        each_done_effect("THEN_CITY_UPGRADE_BUILDING", function(t) if t.id == key then n = n + 1 end end)
        return n
    end

    function U.trophies()
        local list = {}
        each_done_effect("THEN_PLAYER_ADD_TROPHY", function(t)
            list[#list + 1] = {id=t.id, name=U.trophy_names[t.id] or t.id}
        end)
        return list
    end

    local function upgrade_count()
        local n = 0
        each_done_effect("THEN_CITY_UPGRADE_BUILDING", function() n = n + 1 end)
        return n
    end

    -- Tool slot (1-4, a bonus piece's `tool`) -> points more each of its pieces charges per match.
    function U.tool_charges()
        local extra = {}
        each_done_effect("THEN_GAME_CHARGE_TOOL", function(t)
            local bonus = assert(economy.bonuses[t.id], "unknown bonus " .. tostring(t.id))
            extra[bonus.tool] = (extra[bonus.tool] or 0) + t.amount
        end)
        return extra
    end

    -- What every won level now adds to its reward: a purse, in the wallet's slots.
    function U.win_income()
        local income = purse()
        each_done_effect("THEN_PLAYER_ADD_RESOURCE_PER_LEVEL", function(t)
            local slot = assert(SLOTS[t.id], "unknown resource " .. tostring(t.id))
            income[slot] = income[slot] + t.amount
        end)
        return income
    end
    rules.perk_income = U.win_income   -- reward_breakdown adds it to every win

    -- The board's yields with the upgrades' weights in force, by kind.
    function U.apply_weights(g)
        if not g.resource_yields then return end
        local weights, extra, amounts = U.chip_weights(), U.tool_charges(), nil
        for kind, piece in pairs(g.resource_yields) do
            local amount = weights[piece.key] or piece.tool and extra[piece.tool] and piece.amount + extra[piece.tool]
            if amount then amounts = amounts or {}; amounts[kind] = amount end
        end
        g.yield_amounts = amounts
    end

    ------------------------------------------------------------------ effects

    -- Campaign boards keep no mission banner, so every hint is the toast.
    local function show(text) R.notice(text) end

    local function set_available(ids, on)
        local st = U.state()
        for id in tostring(ids):gmatch("%S+") do
            assert(U.by_id[id], "unknown user event " .. id)
            st.available[id] = on
        end
    end

    U.THEN = {
        THEN_SHOW_TUTORIAL = function(t)
            if (t.delay or 0) > 0 then local pending = U.state().pending; pending[#pending + 1] = {at=R.now + t.delay, text=t.text}
            else show(t.text) end
        end,
        THEN_PLAYER_ADD_TROPHY = function() end,   -- derived: U.trophies()
        THEN_PLAYER_ADD_RESOURCE_PER_LEVEL = function() end,   -- derived: U.win_income()
        THEN_GAME_CHARGE_TOOL = function()   -- derived; the current board changes at once
            if R.g then U.apply_weights(R.g) end
        end,
        THEN_PLAYER_ADD_RESOURCE = function(t)
            local add = purse()
            add[assert(SLOTS[t.id], "unknown resource " .. tostring(t.id))] = t.amount
            R.prog.wallet = R.prog.wallet + add
        end,
        THEN_GAME_CHANGE_CHIP_WEIGHT = function()   -- derived; the current board changes at once
            if R.g then U.apply_weights(R.g) end
        end,
        THEN_CITY_UPGRADE_BUILDING = function() end,   -- derived: U.upgrades(key)
        THEN_PLAYER_ADD_GAME_CENTER_TROPHY = function(t) gamecenter.unlock(t.id) end,
        THEN_USER_EVENT_AVAILABLE = function(t) set_available(t.id, t.available ~= false) end,
    }
    U.THEN.THEN_SHOW_HINT = U.THEN.THEN_SHOW_TUTORIAL

    -- An upgrade is earned: its scene is the journey's upgrade beat, played on the
    -- next return to town. Without one a toast names the building and the upgrade.
    local function arrive(e)
        local c = e.upgrade
        local journey = require("journey")
        if journey.find_upgrade and journey.find_upgrade(e.id) then return end
        local building = island.buildings[U.kinds[c.building] + 1]
        show(("%s: %s"):format(building.name, c.title))
    end

    local function fire(e)
        local st = U.state()
        st.done[e.id] = true
        for _, t in ipairs(e.Then) do
            local effect = assert(U.THEN[t[1]], "unknown user event effect " .. tostring(t[1]))
            effect(t, e)
        end
        if e.upgrade then arrive(e) end
    end

    -- A failed board ends every run of wins in a row.
    function U.lost()
        local st = U.state()
        for _, e in ipairs(U.events) do
            if e.If[1] == "IF_PLAYER_COMPLETE_LEVELS_WITHOUT_LIFE_LOSS" then st.count[e.id] = nil end
        end
    end

    ------------------------------------------------------------------ conditions

    local function slot_amount(g, id)
        if id == "score" then return g.score or 0 end
        return g.earnings and g.earnings[assert(SLOTS[id], "unknown resource " .. tostring(id))] or 0
    end

    local function any_cell(g, fn)
        for i = 0, rules.CELLS - 1 do
            if rules.game_cell_active(g, i) and fn(i) then return true end
        end
        return false
    end

    local function count_in(st, id, n) st.count[id] = (st.count[id] or 0) + n; return st.count[id] end

    -- Each condition: the event it listens to and its test. A test may keep
    -- per-board progress in b (board(g)) or lasting progress in st.count[e.id].
    local IF = {}
    U.IF = IF

    IF.IF_PLAYER_MAKE_MATCH = {on="wave", test=function(c, ev)
        return ev.longest >= c.length and (not c.max_length or ev.longest <= c.max_length)
    end}
    IF.IF_PLAYER_MAKE_COMBO = {on="move", test=function(c, ev) return ev.waves >= c.length end}
    IF.IF_PLAYER_MAKE_AUTOMATCH_CHAIN = {on="move", test=function(c, ev) return ev.waves - 1 >= c.amount end}
    local function series(ok)
        return {on="move", test=function(c, ev, b, e)
            b.series[e.id] = ok(c, ev) and (b.series[e.id] or 0) + 1 or 0
            return b.series[e.id] >= c.amount
        end}
    end
    IF.IF_PLAYER_MAKE_MATCH_SERIES = series(function(c, ev) return ev.longest >= (c.min_length or 3) end)
    IF.IF_PLAYER_MAKE_COMBO_SERIES = series(function(c, ev) return ev.waves >= (c.min_length or 2) end)
    IF.IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES = series(function(_, ev) return ev.effective end)
    local function in_time(on, ok)
        return {on=on, test=function(c, ev, b, e)
            local times = b.recent[e.id] or {}
            b.recent[e.id] = times
            for _ = 1, ok(c, ev) do times[#times + 1] = b.time end
            while times[1] and times[1] < b.time - c.time do table.remove(times, 1) end
            return #times >= c.amount
        end}
    end
    local function lines(c, ev)
        local n = 0
        for _, run in ipairs(ev.runs) do if run >= (c.min_length or 3) then n = n + 1 end end
        return n
    end
    IF.IF_PLAYER_MAKE_MATCH_IN_TIME = in_time("wave", lines)
    IF.IF_PLAYER_MAKE_COMBO_IN_TIME = in_time("move", function(c, ev) return ev.waves >= (c.min_length or 2) and 1 or 0 end)
    IF.IF_PLAYER_MAKE_EFFECTIVE_MOVES_IN_TIME = in_time("move", function(_, ev) return ev.effective and 1 or 0 end)
    IF.IF_PLAYER_MAKE_MATCH_IN_LEVEL = {on="wave", test=function(c, ev, b, e)
        b.series[e.id] = (b.series[e.id] or 0) + lines(c, ev)
        return b.series[e.id] >= c.amount
    end}
    IF.IF_PLAYER_MAKE_COMBO_IN_LEVEL = {on="move", test=function(c, ev, b, e)
        if ev.waves >= (c.min_length or 2) then b.series[e.id] = (b.series[e.id] or 0) + 1 end
        return (b.series[e.id] or 0) >= c.amount
    end}
    IF.IF_PLAYER_GET_RESOURCE_IN_LEVEL = {on="wave", test=function(c, ev) return slot_amount(ev.g, c.id) >= c.amount end}
    IF.IF_PLAYER_GET_SCORE_IN_LEVEL = {on="wave", test=function(c, ev) return slot_amount(ev.g, "score") >= c.amount end}
    IF.IF_PLAYER_GET_RESOURCE = {on="won", test=function(c, ev, _, e, st)
        return count_in(st, e.id, slot_amount(ev.g, c.id)) >= c.amount
    end}
    IF.IF_PLAYER_GET_SCORE = {on="won", test=function(c, ev, _, e, st)
        return count_in(st, e.id, slot_amount(ev.g, "score")) >= c.amount
    end}
    IF.IF_PLAYER_COMPLETE_LEVELS = {on="won", test=function(c, _, _, e, st) return count_in(st, e.id, 1) >= c.amount end}
    IF.IF_PLAYER_COMPLETE_LEVELS_IN_TIME = {on="won", test=function(c, _, b, e, st)
        return count_in(st, e.id, b.time <= c.time and 1 or 0) >= c.amount
    end}
    -- Counted from the moment the event is armed; a failed board resets every such count (U.lost).
    IF.IF_PLAYER_COMPLETE_LEVELS_WITHOUT_LIFE_LOSS = {on="won", test=function(c, _, _, e, st) return count_in(st, e.id, 1) >= c.amount end}
    IF.IF_PLAYER_COMPLETE_LEVELS_WITHOUT_BONUS_USE = {on="won", test=function(c, _, _, _, st) return (st.clean or 0) >= c.amount end}
    IF.IF_PLAYER_GET_READY_BONUSES = {on="board", test=function(c, ev)
        local n = 0
        for _, count in pairs(ev.g.tools or {}) do if count > 0 then n = n + 1 end end
        return n >= c.amount
    end}
    IF.IF_PLAYER_BUILT_CONSTRUCTION = {on="island", test=function(c)
        local kind = U.kinds[c.id]
        return assert(kind, "unknown building " .. tostring(c.id)) and island.owned(R.island, kind) > 0
    end}
    IF.IF_PLAYER_UPGRADE_CONSTRUCTION = {on="island", test=function(c) return upgrade_count() >= c.amount end}
    IF.IF_PLAYER_SESSION_TIME = {on="island", test=function(c) return app.clock() - U.launched >= 60 * c.amount end}
    IF.IF_GAME_SHOW_MOVE_HINT = {on="hint", test=function(c, _, b) return b.hints == c.amount end}
    IF.IF_GAME_PUZZLE_TILE_APPEAR = {on="start", test=function(_, ev)
        return ev.g.oil ~= nil and any_cell(ev.g, function(i) return ev.g.oil[i] == 1 end)
    end}
    IF.IF_GAME_DOUBLE_PUZZLE_TILE_APPEAR = {on="start", test=function(_, ev)
        return ev.g.oil ~= nil and any_cell(ev.g, function(i) return ev.g.oil[i] > 1 end)
    end}
    IF.IF_GAME_LOCK_APPEAR = {on="start", test=function(_, ev) return any_cell(ev.g, function(i) return ev.g.chain[i] == 1 end) end}
    IF.IF_GAME_DOUBLE_LOCK_APPEAR = {on="start", test=function(_, ev) return any_cell(ev.g, function(i) return ev.g.chain[i] > 1 end) end}
    IF.IF_GAME_FREEZE_APPEAR = {on="start", test=function(_, ev) return any_cell(ev.g, function(i) return ev.g.ice[i] > 0 end) end}
    IF.IF_GAME_BALL_APPEAR = {on="start", test=function(c, ev)
        local g = ev.g
        return any_cell(g, function(i)
            local piece = g.resource_yields and g.resource_yields[g.tiles[i].kind]
            return piece ~= nil and piece.key == c.id
        end)
    end}
    IF.IF_GAME_PUZZLE_BALL_APPEAR = {on="start", test=function(_, ev) return rules.level_of(ev.g).story_piece ~= nil end}
    IF.IF_GAME_MOVES_FALL_BELOW = {on="move", test=function(c, ev) return ev.g.moves < c.moves and ev.g.moves > 0 end}
    IF.IF_GAME_BONUS_READY = {on="bonus_ready", test=function(c, ev) return ev.key == c.id end}
    IF.IF_GAME_SHOP_ENTER = {on="shop", test=function() return true end}

    ------------------------------------------------------------------ dispatch

    -- The expedition an event counts on: the board's, or on the island the next one.
    local function in_range(e, g)
        local number = g and g.level + 1 or (R.prog.level + 1)
        return number >= (e.from_level or 1) and number <= (e.to_level or math.huge)
    end

    function U.emit(on, ev)
        ev = ev or {}
        local st, g = U.state(), ev.g
        local b = g and board(g)
        local fired = false
        for _, e in ipairs(U.events) do
            local id = e.id
            local cond = IF[e.If[1]]
            assert(cond, "unknown user event condition " .. tostring(e.If[1]))
            if cond.on == on and st.available[id] and not st.done[id] and in_range(e, g)
                and cond.test(e.If, ev, b, e, st) then
                fire(e); fired = true
            end
        end
        if fired then R.save_progress() end
        return fired
    end

    -- Rome's F5: every test="1" event fires at once.
    function U.fire_tests()
        for _, e in ipairs(U.events) do
            if e.test and not U.state().done[e.id] then fire(e) end
        end
    end

    ------------------------------------------------------------------ hooks

    U.kinds = {}
    for i, definition in ipairs(island.catalogue) do U.kinds[definition.key] = i - 1 end
    U.launched = app.clock()

    -- The straight lines a wave clears, from the matched cells before they go.
    local function runs_of(g, m)
        local runs, ordinary = {}, m.ordinary or {}
        for i in pairs(ordinary) do
            local kind = g.tiles[i].kind
            local function same(c) return c >= 0 and ordinary[c] and g.tiles[c].kind == kind end
            for axis = 0, 2 do
                if not same(rules.hex_neighbor(i, axis + 3)) then
                    local n, c = 0, i
                    while same(c) do n, c = n + 1, rules.hex_neighbor(c, axis) end
                    if n >= rules.MATCH_MIN then runs[#runs + 1] = n end
                end
            end
        end
        return runs
    end
    U.runs_of = runs_of

    -- Board starts use the upgrades' weights for pieces the player matches.
    local game_start = rules.game_start
    function rules.game_start(...)
        local g = game_start(...)
        U.apply_weights(g)
        return g
    end

    -- The engine reads a piece's amount while clearing; weights stand in for it
    -- there only, so every other comparison still sees the economy's own tables.
    local game_apply = rules.game_apply
    function rules.game_apply(g, m)
        local amounts = g.yield_amounts
        if not amounts then return game_apply(g, m) end
        local saved = {}
        for kind, amount in pairs(amounts) do
            local piece = g.resource_yields[kind]
            if piece then
                saved[kind] = piece
                g.resource_yields[kind] = setmetatable({amount=amount}, {__index=piece})
            end
        end
        local cleared = game_apply(g, m)
        for kind, piece in pairs(saved) do g.resource_yields[kind] = piece end
        return cleared
    end

    local finish_wave = R.finish_wave
    function R.finish_wave()
        local g = R.g
        local b = board(g)
        local runs = runs_of(g, R.pending)
        local oil = g.oil_left
        finish_wave()
        local longest = 0
        for _, n in ipairs(runs) do longest = math.max(longest, n) end
        b.waves, b.longest = g.combo, math.max(b.longest, longest)
        if oil and g.oil_left and g.oil_left < oil then b.effective = true end
        U.emit("wave", {g=g, runs=runs, longest=longest})
    end

    local open_catalogue = R.open_catalogue
    function R.open_catalogue(...)
        open_catalogue(...)
        U.emit("shop")
    end

    local serialize = R.serialize_campaign
    function R.serialize_campaign(s)
        serialize(s)
        U.serialize(s)
    end

    -- Every frame: watch the board for the moments the engine has no hook for.
    local board_update = R.board_update
    function R.board_update(dt)
        local g, phase, hint = R.g, R.phase, R.hint_a
        board_update(dt)
        local st = U.state()
        if app.arg("user-events-test") and not st.tested then st.tested = true; U.fire_tests() end
        local pending = st.pending
        for i = #pending, 1, -1 do   -- delayed hints wait on the board clock
            local p = pending[i]
            if R.now >= p.at and R.overlay == R.OV_NONE then show(p.text); table.remove(pending, i) end
        end
        if R.on_island or not g or g ~= R.g or g.bonus_preview then
            if R.on_island and R.island then U.emit("island") end
            return
        end
        local b = board(g)
        if not b.started then
            b.started = true
            for t, n in pairs(g.tools or {}) do b.tools[t] = n end
            U.emit("start", {g=g})
        end
        if R.overlay == R.OV_NONE and not g.won and not g.lost then b.time = b.time + dt end
        if hint < 0 and R.hint_a >= 0 then b.hints = b.hints + 1; U.emit("hint", {g=g}) end
        for t, n in pairs(g.tools or {}) do
            local was = b.tools[t] or 0
            if n > 0 and was == 0 then
                local slot = g.tool_slots and g.tool_slots[t]
                U.emit("bonus_ready", {g=g, key=slot and slot.key})
                U.emit("board", {g=g})
            elseif n < was then b.bonus_used = true end
            b.tools[t] = n
        end
        if phase ~= R.PH_IDLE and R.phase == R.PH_IDLE and b.waves > 0 then
            U.emit("move", {g=g, waves=b.waves, longest=b.longest, effective=b.effective})
            b.waves, b.longest, b.effective = 0, 0, false
        end
        if g.won and not b.won and g.level == R.prog.level then
            b.won = true
            st.clean = not b.bonus_used and (st.clean or 0) + 1 or 0
            U.emit("won", {g=g})
        elseif g.lost and not b.lost then
            b.lost = true
            U.lost()
        end
    end

    R.user_events = U

    ------------------------------------------------------------------ upgrades

    function U.upgrade_of(kind)
        for _, e in ipairs(U.events) do
            if e.upgrade and U.kinds[e.upgrade.building] == kind then return e end
        end
    end

    local function currency_name(id) return economy.currencies[assert(SLOTS[id], id)].name end
    local function currency_icon(id) return R.board_art and R.currency_icon and R.currency_icon(SLOTS[id]) end

    -- A feat as the end of "... when you ...", and as resource amounts when it
    -- counts a resource (the standard indicator, never "150 Food" in a sentence).
    local function feat_of(e)
        local c, kind = e.If, e.If[1]
        local target = cfg.target or "plaque"
        if kind == "IF_PLAYER_GET_RESOURCE_IN_LEVEL" then
            return ("bank this much %s in one level"):format(currency_name(c.id)),
                {{id="feat-" .. c.id, icon=currency_icon(c.id), amount=c.amount}}
        elseif kind == "IF_PLAYER_MAKE_MATCH" then return ("make a match of %d or more"):format(c.length)
        elseif kind == "IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES" then
            return ("make %d moves in a row that each clear a %s"):format(c.amount, target)
        elseif kind == "IF_PLAYER_MAKE_MATCH_IN_LEVEL" then
            return ("make %d matches of %d or more in one level"):format(c.amount, c.min_length or 3)
        elseif kind == "IF_PLAYER_MAKE_MATCH_SERIES" then
            return ("make a match of %d or more in %d moves in a row"):format(c.min_length or 3, c.amount)
        elseif kind == "IF_PLAYER_MAKE_MATCH_IN_TIME" then
            return ("make %d matches within %d seconds"):format(c.amount, c.time)
        elseif kind == "IF_PLAYER_COMPLETE_LEVELS_WITHOUT_LIFE_LOSS" then
            return ("win %d levels in a row without a failed one"):format(c.amount)
        end
        return "meet their feat"
    end
    U.feat_of = feat_of

    -- The perk as a short sentence and the resource indicators that show it.
    local function perk_of(e)
        for _, t in ipairs(e.Then) do
            if t[1] == "THEN_PLAYER_ADD_RESOURCE_PER_LEVEL" then
                return "", "EVERY WIN",
                    {{id="perk-" .. t.id, icon=currency_icon(t.id), amount="+" .. t.amount}}
            elseif t[1] == "THEN_GAME_CHARGE_TOOL" then
                local bonus = economy.bonuses[t.id]
                return ("The %s charges faster."):format(bonus.name), "TOOL",
                    {{id="perk-" .. t.id, icon=R.board_art and R.board_art[bonus.icon]}}
            end
        end
        return "", "", {}
    end
    U.perk_of = perk_of

    -- What a building's card says about its upgrade: nil without one (or before
    -- the building stands). {about, caption, entries, short}: the sentence, the
    -- caption over the indicators, the indicators, and the one-line tap text.
    function U.card(kind)
        local e = U.upgrade_of(kind)
        if not e then return end
        local st, title = U.state(), e.upgrade.title
        if st.done[e.id] then
            local text, caption, entries = perk_of(e)
            local short = ("Upgraded: %s."):format(title)
            return {about=text ~= "" and short .. " " .. text or short, caption=caption, entries=entries, short=short}
        elseif st.available[e.id] then
            local feat, entries = feat_of(e)
            return {about=("Upgrade: %s, when you %s."):format(title, feat), caption="FEAT", entries=entries or {}}
        end
    end

    R.upgrade_card = U.card
    R.upgrade_done = function(id) return U.state().done[id] == true end

    -- A building placed or bought mid-board changes what its pieces pay.
    local refresh_board_bonuses = R.refresh_board_bonuses
    if refresh_board_bonuses then
        function R.refresh_board_bonuses(...)
            refresh_board_bonuses(...)
            if R.g then U.apply_weights(R.g) end
        end
    end

    return U
end

------------------------------------------------------------------ data helper

-- Upgrade events from compact rows, in Rome's two-step flow: placing the
-- building arms the upgrade (city_<building>), meeting the feat earns it.
--   {id="man_03", building="well", title="a second rope and pulley", keeper="tomas",
--    If={...feat...}, perk={"THEN_PLAYER_ADD_RESOURCE_PER_LEVEL", id="food", amount=10}}
function M.upgrade_events(rows)
    local events = {}
    for _, row in ipairs(rows) do
        events[#events + 1] = {id="city_" .. row.building,
            If={"IF_PLAYER_BUILT_CONSTRUCTION", id=row.building},
            Then={{"THEN_USER_EVENT_AVAILABLE", id=row.id, available=true}}}
    end
    for _, row in ipairs(rows) do
        events[#events + 1] = {id=row.id, available=false,
            upgrade={title=row.title, keeper=row.keeper, building=row.building},
            If=row.If,
            Then={{"THEN_PLAYER_ADD_TROPHY", id="TROPHY_" .. row.id:sub(5)},
                {"THEN_CITY_UPGRADE_BUILDING", id=row.building}, row.perk}}
    end
    return events
end

return M
