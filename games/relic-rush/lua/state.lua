-- state.lua — the state shared by Relic Rush's modules, and their namespace:
-- every module attaches its public functions here (R.notice, R.cell_pos, ...)
-- so they can call each other without import cycles, the way relic.h did.
local R = require("match3").view{
    -- the game is laid out for a 480 x 900 portrait screen; taller phones add height
    SCREEN_W = 480, SCREEN_H = 900,
    HEX_R = 26.5,       -- resting radius: the entrance animates around this size, then returns to 1x
    BOARD_CLIP = rect(10, 236, 460, 512),
    drop = 0,            -- extra screen height on tall phones (see R.layout)
    hit_dy = 0,          -- where the open dialog's buttons sit below their layout

    intro = nil,

    -- overlays and board phases
    OV_NONE = 0, OV_GUIDE = 1, OV_PAUSE = 2, OV_RESULT = 3, OV_FAILED = 4, OV_WONDER = 5, OV_FINALE = 6, OV_ZONE = 7, OV_SHOP = 8, OV_EXPEDITIONS = 9, OV_CONFIRM = 10,
    PAL_GOLD = "gold", PAL_CREAM = "cream", PAL_GREEN = "green", PAL_WHITE = "white",   -- text styles in skin.lua

    backdrop = nil, scenes = {}, relics = {}, glow = nil,
    font = nil,
    prog = nil,          -- {level, seed, wallet}
    island = nil,        -- the engine city

    -- screens
    on_island = false,
    overlay = 0, modal_for = 0,   -- modal_for: the dialog whose entrance is playing
    dialog = nil,        -- the open dialog's motion (screens.lua: R.open_dialog)
    modal_closing = false,
    inspect = -1, inspect_item = -1, zone_card = -1,
    reduced_motion = false, sound = true, test_mode = false,
    toast = nil,
    toast_time = 0, now = 0,
    quiet = false,       -- no story (stills for the docs)
    bubble_wonder = -1,  -- a word bubble over a wonder just placed
    bubble_text = nil,
    bubble_time = 0,

    -- animated readouts
    score_display = 0, score_pulse = 0, goal_display = 0, goal_pulse = 0, word_time = 0,
    word_combo = 0, fx_combo = 0, fx_origin = -1,
}
return R
