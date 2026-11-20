-- archive_state.lua — the state and constants shared by Nile Archive's
-- modules. Every module reads and writes the same table, so they can be
-- required in any order without import cycles.
local G = {
    -- purse slots: coins are spent, influence only grows; the third slot
    -- counts distinct completed searches and the fourth the best Stars across them
    -- (requirements, rebuilt from the wins and best stars, never spent)
    COINS = 1, INFLUENCE = 2, CHAPTERS = 3, STARS = 4,
    ITEMS = 8,                    -- hidden objects per scene
    ZONES = 4,                    -- island regions: the estate and three shores

    MODAL_NONE = 0, MODAL_WIN = 1, MODAL_CAST = 2, MODAL_CHAPTERS = 3, MODAL_PAUSE = 4,
    MODAL_JOURNAL = 5, MODAL_CACHE = 6,

    -- Hidden-object scoring, after June's Journey: each find scores more while
    -- a combo is alive, a stray tap costs points, and Stars reflect time and clears.
    FIND_POINTS = 300, MISS_POINTS = 60,
    COMBO_WINDOW = 5, COMBO_MAX = 5,
    HINT_RECHARGE = 20,
    SLOTS = 3,                    -- names on show at once, as in June's Journey
    STAR_TIMES = {75, 150},       -- seconds for three and two stars

    -- progress
    wallet = purse(),
    wins = {}, stars = {}, clues = {}, restored = {},
    cache_done = false, caches = {0, 0, 0}, projects = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    island = nil,                 -- the engine city
    buildings = nil,              -- the city's building defs, with the sprites loaded

    -- the hidden-object scene in play
    scene = nil,                  -- 1-based search or cache, nil = island
    found = {},                   -- found[i] = time the item was found
    hint = nil, hint_ready = 0,
    slots = {}, pills = {},       -- the item bar: item per slot, and each pill's motion
    marks = {},                   -- marks[i]: the ring growing on a found item
    score = 0, combo = 0, combo_left = 0, clock = 0, result = nil,
    misses = 0, hints = 0,
    cam = nil,                    -- hidden-object camera
    focus = vec2(), focus_time = 0,
    bonus_in = 0, bonus_goal = nil,   -- how far the combo bar has slid in, and where it is heading

    -- screens
    modal = 0, dialog = nil,      -- the open popup's motion (G.open_modal)
    reduced_motion = false,   -- Pause > Меньше анимации: no pops, pulses, sparkles or floating text
    tray = false,                 -- the building tray is open
    spots = {},                   -- where key controls were drawn this frame (smoke test)
    smoke = false,

    -- assets
    backgrounds = {}, coin = nil, influence = nil,
}

function G.open_modal(kind, settled)
    if G.dialog and G.dialog.tl then G.dialog.tl:kill() end
    G.modal = kind
    local instant = settled or G.reduced_motion
    local d = ui.popup_motion(instant)
    if kind == G.MODAL_WIN then
        d.stars = {{s = 0}, {s = 0}, {s = 0}}
        d.tl = tween.timeline{paused = true}   -- the stars wait for any dialogue
        d.tl:to(d.stars, .33, {s = 1}, .43):ease("out_back"):stagger(.18)
        if instant then d.tl:complete() end
    end
    G.dialog = d
end

function G.close_modal(after)
    local d = G.dialog
    d:close(function()
        if d.tl then d.tl:kill() end
        G.modal, G.dialog = G.MODAL_NONE, nil
        if after then after() end
    end, G.reduced_motion)
end
return G
