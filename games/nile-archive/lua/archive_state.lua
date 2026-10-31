-- archive_state.lua — the state and constants shared by Nile Archive's
-- modules. Every module reads and writes the same table, so they can be
-- required in any order without import cycles.
local G = {
    -- purse slots: coins are spent, influence only grows; the third slot
    -- counts completed chapters and the fourth the best Stars across them
    -- (requirements, rebuilt from the wins and best stars, never spent)
    COINS = 1, INFLUENCE = 2, CHAPTERS = 3, STARS = 4,
    ITEMS = 8,                    -- hidden objects per scene
    ZONES = 4,                    -- island regions: the estate and three shores

    MODAL_NONE = 0, MODAL_WIN = 1, MODAL_CAST = 2, MODAL_CHAPTERS = 3, MODAL_PAUSE = 4,

    -- Hidden-object scoring, after June's Journey: each find scores more while
    -- a combo is alive, a stray tap costs points, and the stars come from the time.
    FIND_POINTS = 300, MISS_POINTS = 60,
    COMBO_WINDOW = 5, COMBO_MAX = 5,
    HINT_RECHARGE = 20,
    SLOTS = 3,                    -- names on show at once, as in June's Journey
    STAR_TIMES = {75, 150},       -- seconds for three and two stars

    -- progress
    wallet = purse(),
    wins = {0, 0, 0},
    stars = {0, 0, 0},            -- best stars per chapter
    island = nil,                 -- the engine city
    buildings = nil,              -- the city's building defs, with the sprites loaded

    -- the hidden-object scene in play
    scene = nil,                  -- 1-based chapter, nil = island
    found = {},                   -- found[i] = time the item was found
    hint = nil, hint_ready = 0,
    slots = {}, pills = {},       -- the item bar: item per slot, and each pill's motion (archive_scene.lua)
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

-- Open a popup over the island or the scene. Its motion runs on the engine's
-- tween module: the box pops in with a little overshoot while the backdrop
-- fades, and the stars of a result arrive one by one (archive_dialogs.lua
-- reads `G.dialog`). `settled` opens it at rest, for stills.
function G.open_modal(kind, settled)
    G.modal = kind
    local d = {pop = 0, backdrop = 0, stars = {{s = 0}, {s = 0}, {s = 0}}}
    d.tl = tween.timeline{paused = true}   -- main.lua plays it once any dialogue is over
    d.tl:to(d, .25, {pop = 1}, 0):ease("out_back")
    d.tl:to(d, .25, {backdrop = 1}, 0):ease("linear")
    d.tl:to(d.stars, .33, {s = 1}, .43):ease("out_back"):stagger(.18)
    if settled then d.tl:complete() end
    G.dialog = d
end
return G
