-- Exercise the real expedition update loop, including an idle dead board.
local rules = require("rules")
local R = require("board")
require("screens")   -- the dialogs' motion helpers
local dead_board = require("fixtures/dead_board")


R.notice = function(message) R.toast = message end
R.tone = function() end
R.vfx_wave = function() end
local function setup(g)
    R.g, R.pending = g, rules.new_match()
    R.phase, R.phase_time, R.idle_time = R.PH_IDLE, 0, 5
    R.overlay, R.on_island, R.art_review = R.OV_NONE, false, false
    R.selected, R.tool, R.hint_a, R.hint_b = 0, 0, -1, -1
    R.toast = nil
    R.fall_steps = nil
end

for level = 0, rules.LEVELS - 1 do
    local g = dead_board(level)
    setup(g)
    rules.game_matches(g, R.pending, -1)
    check(R.pending.hits == 0 and not rules.game_hint(g), "fixture has no match or move")
    local before = rules.game_copy(g)
    R.board_update(.02)
    check(rules.game_hint(g), "idle board recovers without a tool or player move")
    rules.game_matches(g, R.pending, -1)
    check(R.pending.hits == 0, "recovered board has no free matches")
    check(R.selected == -1 and R.tool == -1 and R.hint_a == -1 and R.hint_b == -1,
          "reshuffle discards stale selection and hints")
    check(R.toast == "No moves. Board reshuffled.", "recovery explains the changed board")
    for _, key in ipairs({"moves", "score", "relics", "dug", "obstacles", "wood", "stone"}) do
        check(g[key] == before[key], "reshuffle preserves " .. key)
    end
    for i = 0, rules.CELLS - 1 do
        check(g.active[i] == before.active[i] and g.soil[i] == before.soil[i]
              and g.chain[i] == before.chain[i] and g.ice[i] == before.ice[i], "terrain survives recovery")
        if g.chain[i] > 0 or g.ice[i] > 0 or not g.active[i] then
            check(g.tiles[i].kind == before.tiles[i].kind and g.tiles[i].special == before.tiles[i].special,
                  "locked relics and holes survive recovery")
        end
    end
    check(g.tools[1] == 0 and g.tools[2] == 0 and g.tools[3] == 0, "recovery needs no charges")
end

-- Pausing and visiting the island must not change the suspended board.
for _, blocked in ipairs({"overlay", "on_island"}) do
    local g = dead_board()
    setup(g)
    if blocked == "overlay" then R.overlay = R.OV_PAUSE else R.on_island = true end
    local rng = g.rng
    R.board_update(.02)
    check(g.rng == rng and not rules.game_hint(g) and not R.toast, "suspended board waits: " .. blocked)
end

-- A playable board gets a hint rather than changing its pieces.
do
    local g = rules.game_start(6, 123)
    setup(g)
    local before = rules.game_copy(g)
    R.board_update(.02)
    check(g.rng == before.rng and R.hint_a >= 0 and R.hint_b >= 0 and not R.toast, "playable board only hints")
    check(rules.game_swap(rules.game_copy(g), R.hint_a, R.hint_b, rules.new_match()), "hint is a legal move")
end

-- Resolve ready groups before trying to recover a board; never skip a wave.
do
    local g = dead_board(0)
    setup(g)
    for q = -2, 1 do g.tiles[rules.hex_index(q, 0)] = rules.tile(rules.RELIC_IDOL) end
    local rng, moves = g.rng, g.moves
    R.board_update(.02)
    check(R.phase == R.PH_CLEAR and g.rng == rng and g.moves == moves, "ready group clears before hints/recovery")
end

-- The reported level-seven photo is playable: swap the right-hand idol up
-- into the amphora above it, joining five amphorae including two chains.
do
    local g = dead_board()
    local columns = {"00132", "101453", "2245134", "532--414", "104---203",
                     "500--231", "2335543", "450152", "03504"}
    for column, kinds in ipairs(columns) do
        local q = column - 5
        for offset = 1, #kinds do
            local i = rules.hex_index(q, math.max(-4, -q - 4) + offset - 1)
            if g.active[i] then g.tiles[i] = rules.tile(tonumber(kinds:sub(offset, offset))) end
            g.chain[i], g.ice[i] = 0, 0
        end
    end
    local upper, lower = rules.hex_index(2, -1), rules.hex_index(2, 0)
    g.chain[upper], g.chain[lower], g.ice[rules.hex_index(2, -2)] = 1, 1, 1
    g.obstacles = 3
    setup(g)
    local m, copy = rules.new_match(), rules.game_copy(g)
    check(rules.game_swap(copy, rules.hex_index(3, -2), rules.hex_index(3, -3), m)
          and m.hits == 5 and m.mask[upper] and m.mask[lower], "photo has a five-amphora move hitting both chains")
    local rng = g.rng
    R.board_update(.02)
    check(g.rng == rng and not R.toast and R.hint_a >= 0, "photo board receives a hint without reshuffling")
end

-- Settlement and the idle fallback share recovery and terminal precedence.
for _, mode in ipairs({"fall", "won", "lost"}) do
    local g = dead_board()
    setup(g)
    local rng = g.rng
    if mode == "fall" then R.phase, R.phase_time = R.PH_FALL, 1
    elseif mode == "won" then
        local l = rules.level_of(g)
        g.score, g.relics, g.dug, g.obstacles, g.moves = l.score, l.relics, l.soil, 0, 0
    else g.moves = 0 end
    R.board_update(.02)
    if mode == "fall" then
        check(rules.game_hint(g) and R.toast == "No moves. Board reshuffled.", "post-fall recovery explains reshuffle too")
    else
        check(g.rng == rng and not R.toast, "terminal board is not shuffled: " .. mode)
        check(R.overlay == (mode == "won" and R.OV_RESULT or R.OV_FAILED), "terminal result precedes recovery: " .. mode)
    end
end

-- Real animation-phase updates, with virtual time and no renderer. A swap
-- charges once, pauses mid-flight, then resolves every cascade without input.
for level=0,rules.LEVELS-1 do
    for _,reduced in ipairs({false,true}) do
        testing.reset()
        local g=rules.game_start(level,100+level)
        setup(g)
        R.reduced_motion=reduced
        local ok,a,b=rules.game_hint(g)
        check(ok,"phase fixture has a legal move")
        local moves=g.moves
        R.attempt_swap(a,b)
        check(R.phase==R.PH_SWAP and g.moves==moves-1 and g.score==0,"swap debits once before animation")
        R.attempt_swap(a,b)
        check(g.moves==moves-1,"busy phase ignores another swap")
        local before=rules.game_copy(g)
        R.overlay=R.OV_PAUSE
        testing.advance(30)
        R.board_update(app.dt())
        check(R.phase==R.PH_SWAP and R.phase_time==0 and require('support').same(g,before),"pause freezes a pending wave")
        R.overlay=R.OV_NONE
        for _=1,500 do
            testing.advance(.05)
            R.board_update(app.dt())
            if R.phase==R.PH_IDLE then break end
        end
        check(R.phase==R.PH_IDLE and g.score>0 and g.moves==moves-1,"all cascades settle without extra move charges")
        local m=rules.new_match()
        rules.game_matches(g,m,-1)
        check(m.hits==0,"settled board contains no unresolved matches")
    end
end
-- Gravity has multiple simultaneous steps. Cascades/results cannot settle
-- until the last step is shown, including reduced-motion timing.
for _, reduced in ipairs({false, true}) do
    local g = rules.game_start(6, 123)
    for i=0,rules.CELLS-1 do
        if g.active[i] and g.chain[i]==0 and g.ice[i]==0 and rules.hex_r(i)>0 then g.tiles[i]=rules.tile(-1) end
    end
    setup(g)
    R.reduced_motion = reduced
    R.phase, R.phase_time = R.PH_CLEAR, 1
    R.board_update(.01)
    check(R.phase==R.PH_FALL and #R.fall_steps>1, "clear enters engine trickling steps")
    local speed = reduced and .35 or 1
    local duration = (#R.fall_steps * rules.FALL_STEP + .08) * speed
    local moves = g.moves
    R.board_update(duration - .001)
    check(R.phase==R.PH_FALL and g.moves==moves, "engine waits for every fall step")
    R.board_update(.002)
    check(R.phase~=R.PH_FALL and g.moves==moves, "engine settles without spending another move")
end
R.reduced_motion = false

-- The compact header reports remaining win conditions from the rules, without
-- dropping score/sand/locks or exposing redundant current/target totals.
do
    local g=rules.game_start(6,123)
    R.g=g
    local goals=R.goal_entries()
    check(#goals==4 and goals[1].remaining==3800 and goals[2].remaining==16
          and goals[3].remaining==15 and goals[4].remaining==g.obstacles,"late HUD exposes all four remaining goals")
    g.score,g.relics,g.dug,g.obstacles=9000,99,99,0
    for _,entry in ipairs(R.goal_entries()) do check(entry.remaining==0,"completed goal clamps at zero") end
    R.g=rules.game_start(0,123)
    check(#R.goal_entries()==2,"opening HUD omits absent sand/lock objectives")
end

-- Entrance uses the real shared view: dialogue and overlays freeze its clock,
-- a skip release cannot play a move, and reset discards suspended presentation.
do
    testing.reset()
    R.vfx_emit, R.vfx_slam = function() end, function() end
    for _, reduced in ipairs{false, true} do
        local g = rules.game_start(4, 982)
        R.reset_board(g)
        R.overlay, R.on_island, R.art_review, R.reduced_motion = R.OV_NONE, false, false, reduced
        R.present_board()
        local moves, rng = g.moves, g.rng
        story.say(nil, "Please wait.")
        R.board_update(.2)
        check(R.intro.t == 0, "entrance waits for dialogue")
        story.next(); story.next()
        R.overlay = R.OV_PAUSE; R.board_update(.2)
        check(R.intro.t == 0, "modal pauses entrance")
        R.overlay, R.on_island = R.OV_NONE, true; R.board_update(.2)
        check(R.intro.t == 0, "island pauses entrance")
        R.on_island = false; R.board_update(.1)
        check(R.intro.t > 0, "entrance advances when visible")
        local at = R.cell_pos(rules.hex_center())
        R.board_input{released=true,pos=at,press_pos=at}
        check(g.moves == moves and g.rng == rng and R.selected < 0 and R.intro:done(), "skip release consumes no move or selection")
        R.board_update(.01)
        check(R.phase == R.PH_IDLE and not R.intro, "completed entrance returns to idle")
        R.present_board(); R.board_update(3)
        check(R.phase == R.PH_IDLE and not R.intro, "natural completion releases the entrance too")
        local _, pos, scale, _, aspect = R.piece_pose(rules.hex_center(), 0)
        near(scale, 1, "finished gem has no enlargement")
        near(aspect, 1, "finished gem has no squash")
        near((pos-at):len(), 0, "finished gem sits at its cell centre")
        check(R.cell_at(pos) == rules.hex_center(), "resting cell input matches its pose")
        if testing.game == "relic-rush" then
            -- A 1x pose alone misses an enlarged sprite canvas. Check the
            -- rectangles actually submitted for every normal piece, including
            -- the hex idol, against the space between adjacent cell rows.
            local image, hex_kind, boxes = gfx.image, R.hex_piece_kind, {}
            R.hex_piece_kind = rules.RELIC_IDOL
            -- Temporarily record draw calls instead of requiring a renderer.
            gfx.image = function(_, box) boxes[#boxes + 1] = box end -- luacheck: ignore 122
            for kind = 0, 5 do R.draw_relic(rules.tile(kind), pos, scale, 255, aspect, true) end
            gfx.image, R.hex_piece_kind = image, hex_kind -- luacheck: ignore 122
            check(#boxes == 6, "all six resting pieces are drawn")
            for _, box in ipairs(boxes) do
                check(box.w < math.sqrt(3) * R.HEX_R and box.h < math.sqrt(3) * R.HEX_R,
                      "resting piece canvas leaves a gutter inside its cell")
                near((box:center()-pos):len(), 0, "resting piece artwork stays centred")
            end
        end
        R.present_board(); R.reset_board(g)
        check(not R.intro and R.phase == R.PH_IDLE, "reset clears pending entrance")
    end
end

-- The dialogs' motion runs on the engine's tween module (docs/MOTION.md): an
-- entrance settles, the parts of a result arrive on one timeline a tap skips,
-- a newer dialog interrupts, the exit banks the reward, and reduced motion
-- settles everything on the next frame.
do
    testing.reset()
    local claimed = 0
    local claim = R.claim_reward
    R.claim_reward = function() claimed = claimed + 1 end
    R.open_dialog()
    check(R.dialog.entry == 0 and R.dialog.fresh and not R.dialog_settled(), "a dialog opens at the start of its entrance")
    tween.update(.1)
    check(R.dialog.entry > 0 and R.dialog.entry < 1, "the entrance eases in")
    tween.update(.2)
    check(R.dialog.entry == 1 and R.dialog_settled(), "the entrance settles in .28 s")
    R.dialog.n = 0
    local part = R.dialog_part(.2, .3)
    check(part.f == 0 and part.u == 0 and not R.dialog_settled(), "a part joins the dialog's timeline and holds it back")
    tween.update(.1)
    check(part.f == 0, "the part waits for its delay")
    tween.update(.2)
    check(part.f > part.u and part.u > 0 and part.f < 1, "then eases in, its linear progress alongside")
    R.dialog.n = 0
    check(R.dialog_part(.2, .3) == part, "parts are keyed by draw order")
    R.dialog_skip()
    check(part.f == 1 and part.u == 1 and R.dialog_settled(), "a tap skips the parts to their places")
    R.close_dialog()
    check(R.modal_closing and R.dialog.exit == 0, "the exit starts")
    tween.update(.3)
    check(claimed == 1 and not R.modal_closing and R.dialog.exit == 1, "and banks the reward when it ends")
    R.open_dialog()
    tween.update(.1)
    local was = R.dialog
    R.open_dialog()
    check(R.dialog ~= was and R.dialog.entry == 0 and not tween.is_tweening(was), "a newer dialog interrupts the old entrance")
    R.open_dialog(true)
    R.dialog.n = 0
    check(R.dialog.entry == 1 and R.dialog_part(.5, .3).f == 1 and R.dialog_settled(), "stills open a dialog settled")
    tween.instant(true)
    R.open_dialog()
    tween.update(1 / 60)
    check(R.dialog.entry == 1 and R.dialog_settled(), "reduced motion settles the entrance on the next frame")
    tween.instant(false)
    R.claim_reward = claim
    testing.reset()
end
