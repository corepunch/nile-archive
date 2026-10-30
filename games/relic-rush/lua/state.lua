-- state.lua — the state shared by Relic Rush's modules, and their namespace:
-- every module attaches its public functions here (R.notice, R.cell_pos, ...)
-- so they can call each other without import cycles, the way relic.h did.
local R = {
    -- the game is laid out for a 480 x 900 portrait screen; taller phones add height
    SCREEN_W = 480, SCREEN_H = 900,
    HEX_R = 32,         -- radius-4 board spans 14 radii: 448 wide, with 16-unit screen margins
    BOARD_CLIP = rect(10, 236, 460, 512),
    drop = 0,            -- extra screen height on tall phones (see R.layout)
    hit_dy = 0,          -- where the open dialog's buttons sit below their layout

    -- overlays and board phases
    OV_NONE = 0, OV_GUIDE = 1, OV_PAUSE = 2, OV_RESULT = 3, OV_FAILED = 4, OV_WONDER = 5, OV_FINALE = 6, OV_ZONE = 7,
    PH_IDLE = 0, PH_SWAP = 1, PH_REJECT = 2, PH_CLEAR = 3, PH_FALL = 4,
    PAL_GOLD = 0, PAL_CREAM = 1, PAL_GREEN = 2, PAL_WHITE = 3,

    backdrop = nil, scenes = {}, relics = {}, glow = nil,
    font = nil,
    prog = nil,          -- {level, seed, wallet}
    island = nil,        -- the engine city

    -- the expedition in progress
    g = nil,
    pending = nil,       -- the match being cleared
    old_tiles = {},      -- the board before the current animation step
    fall_from = {}, wave_ice = {}, wave_chain = {},
    phase = 0,
    phase_time = 0, idle_time = 0, shake = 0,
    selected = -1, swap_a = -1, swap_b = -1, tool = -1, hint_a = -1, hint_b = -1,

    -- screens
    on_island = false,
    overlay = 0, modal_for = 0,   -- modal_for: the dialog whose entrance is playing
    modal_clock = 0, modal_exit = 0,
    modal_closing = false,
    inspect = -1, zone_card = -1,
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
