-- Exercise the real expedition update loop, including an idle dead board.
local rules = require("rules")
local R = require("board")
require("screens")   -- the dialogs' motion helpers
local dead_board = require("fixtures/dead_board")


R.notice = function(message) R.toast = message end
R.tone = function() end
R.vfx_wave = function() end
local function setup(g)
    R.reset_board(g)
    R.idle_time = 5
    R.overlay, R.on_island, R.art_review = R.OV_NONE, false, false
    R.selected, R.tool, R.hint_a, R.hint_b = 0, 0, -1, -1
    R.toast = nil
end

local function inventory(g)
    local counts = {}
    for i=0,rules.CELLS-1 do
        local t = g.tiles[i]
        local key = tostring(t.kind)
        counts[key] = (counts[key] or 0) + 1
    end
    return counts
end
local function same_inventory(g, before)
    local after = inventory(g)
    for key, count in pairs(before) do check(after[key] == count, "reshuffle retains every gem: "..key) end
    for key, count in pairs(after) do check(before[key] == count, "reshuffle creates no gems: "..key) end
end

-- If the inventory cannot form a match-free playable board, never replace it.
do
    local g = rules.game_start(0,123)
    for i=0,rules.CELLS-1 do if g.active[i] then g.tiles[i]=rules.tile(0) end end
    local before = rules.game_copy(g)
    check(not rules.game_shuffle(g), "impossible reshuffle reports failure")
    for i=0,rules.CELLS-1 do check(g.tiles[i].kind==before.tiles[i].kind, "failed shuffle restores the board") end
end

for level = 0, rules.LEVELS - 1 do
    local g = dead_board(level)
    setup(g)
    rules.game_matches(g, R.pending, -1)
    check(R.pending.hits == 0 and not rules.game_hint(g), "fixture has no match or move")
    local before = rules.game_copy(g)
    local gems = inventory(g)
    R.board_update(.02)
    same_inventory(g,gems)
    check(rules.game_hint(g), "idle board recovers without a tool or player move: level " .. level + 1)
    rules.game_matches(g, R.pending, -1)
    check(R.pending.hits == 0, "recovered board has no free matches")
    check(R.selected == -1 and R.tool == -1 and R.hint_a == -1 and R.hint_b == -1,
          "reshuffle discards stale selection and hints")
    check(R.toast == "No moves. Board reshuffled.", "recovery explains the changed board")
    for _, key in ipairs({"moves", "score", "relics", "obstacles", "wood", "stone"}) do
        check(g[key] == before[key], "reshuffle preserves " .. key)
    end
    for i = 0, rules.CELLS - 1 do
        check(g.active[i] == before.active[i] and g.chain[i] == before.chain[i] and g.ice[i] == before.ice[i]
              and g.stone_hp[i] == before.stone_hp[i], "terrain survives recovery")
        if g.chain[i] > 0 or g.ice[i] > 0 or g.stone_hp[i] > 0 or not g.active[i] then
            check(g.tiles[i].kind == before.tiles[i].kind,
                  "locked relics and holes survive recovery")
        end
    end
    check(g.tools[1] == 0 and g.tools[2] == 0 and g.tools[3] == 0, "recovery needs no charges")
end

-- Both ways to shuffle use the actual permutation of piece objects, including
-- same-kind pieces, and preserve the identity of pieces held by blockers.
local modes = testing.game == "relic-rush" and {"recovery", "mixer"} or {"recovery"}
for _, mode in ipairs(modes) do
    local g, slot
    if mode == "mixer" then
        g = rules.game_start(29, 3, {map_room=true,lodge=true,observatory=true})
        slot = require("economy").bonuses.mixer.tool
        g.tools[slot], g.tool_meter[slot] = 1, g.tool_threshold
        g.bonus_preview = true
    else g = dead_board() end
    setup(g)
    local before, moves = {}, g.moves
    for i = 0, rules.CELLS - 1 do before[g.tiles[i]] = i end
    if slot then R.select_tool(slot - 1)
    else R.board_update(.02) end
    check(R.phase == R.PH_SHUFFLE and g.moves == moves, mode .. " starts flights without spending a move")
    check(not slot or (g.tools[slot] == 0 and g.tool_meter[slot] == 0), "Mixer spends exactly one charge")
    local destination
    R.phase_time = 0
    for i = 0, rules.CELLS - 1 do
        local t, at = R.piece_pose(i, 0)
        local source = before[t]
        near((at - R.cell_pos(source)):len(), 0, "every piece starts at its own source")
        if source ~= i then destination = i end
        if g.chain[i] > 0 or g.ice[i] > 0 or g.stone_hp[i] > 0 or not g.active[i] then
            check(source == i, "shuffle never moves a fixed piece or hole")
        end
    end
    check(destination ~= nil, "successful shuffle moves pieces")
    R.board_update(.25)
    local _, at, scale = R.piece_pose(destination, 0)
    check((at - R.cell_pos(before[g.tiles[destination]])):len() > 0 and
          (at - R.cell_pos(destination)):len() > 0 and scale < 1, "in-flight piece is between its endpoints")
    local _, a, b = rules.game_hint(g)
    R.attempt_swap(a, b)
    check(g.moves == moves and R.phase == R.PH_SHUFFLE, "flight holds back swaps")
    R.overlay = R.OV_PAUSE
    R.board_update(1)
    check(R.phase_time == .25, "pause freezes the flight")
    R.overlay = R.OV_NONE
    R.board_update(1)
    local _, landed = R.piece_pose(destination, 0)
    near((landed - R.cell_pos(destination)):len(), 0, "piece lands in its shuffled cell")
    check(R.phase == R.PH_IDLE and not R.shuffle_from and R.idle_time == 0, "flight restores board input and hint timing")
    R.attempt_swap(a, b)
    check(R.phase == R.PH_SWAP and g.moves == moves - 1, "the landed board accepts the next swap")
end

do
    local g = dead_board()
    setup(g)
    R.reduced_motion = true
    R.board_update(.02)
    check(R.phase == R.PH_IDLE and not R.shuffle_from and rules.game_hint(g), "reduced motion settles the shuffle immediately")
    R.reduced_motion = false
    setup(dead_board())
    R.board_update(.02)
    local next_board = rules.game_start(0, 123)
    R.reset_board(next_board)
    check(R.g == next_board and R.phase == R.PH_IDLE and not R.shuffle_from, "reset discards a shuffle in progress")
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
    for q = 2-rules.MATCH_MIN, 1 do
        local i = rules.hex_index(q, 0)
        g.active[i], g.tiles[i] = true, rules.tile(rules.RELIC_IDOL)
    end
    local rng, moves = g.rng, g.moves
    R.board_update(.02)
    check(R.phase == R.PH_CLEAR and g.rng == rng and g.moves == moves, "ready group clears before hints/recovery")
end

-- The old photo remains playable, but its connected five-amphora move
-- is now rejected: only a straight-line hint is legal.
do
    local g = dead_board()
    local columns = {"00132", "101453", "2245134", "532--414", "104---203",
                     "500--231", "2335543", "450152", "03504"}
    -- The photo is a radius-4 hexagon: nothing else of the board is in it.
    for i = 0, rules.CELLS - 1 do g.active[i], g.stone_hp[i], g.oil[i] = false, 0, 0 end
    for column, kinds in ipairs(columns) do
        local q = column - 5
        for offset = 1, #kinds do
            local i = rules.hex_index(q, math.max(-4, -q - 4) + offset - 1)
            local kind = tonumber(kinds:sub(offset, offset))
            g.active[i], g.tiles[i] = kind ~= nil, rules.tile(kind or -1)
            g.chain[i], g.ice[i] = 0, 0
        end
    end
    local upper, lower = rules.hex_index(2, -1), rules.hex_index(2, 0)
    g.chain[upper], g.chain[lower], g.ice[rules.hex_index(2, -2)] = 1, 1, 1
    g.obstacles = 3
    setup(g)
    local m, copy = rules.new_match(), rules.game_copy(g)
    local accepted = rules.game_swap(copy, rules.hex_index(3, -2), rules.hex_index(3, -3), m)
    if rules.flags & require("match3").LINE_MATCHES ~= 0 then
        check(not accepted and copy.moves == g.moves and m.hits == 0, "old connected-group move is rejected without a line")
    else
        check(accepted and m.hits == 5 and m.mask[upper] and m.mask[lower], "group-mode photo move retains both chained matches")
    end
    local rng = g.rng
    R.board_update(.02)
    if rules.MATCH_MIN == 4 then
        check(R.toast == "No moves. Board reshuffled." and rules.game_hint(g),
              "photo board has no straight four available and reshuffles to a playable board")
    else
        check(g.rng == rng and not R.toast and R.hint_a >= 0, "photo board receives a hint without reshuffling")
    end
end

-- Settlement and the idle fallback share recovery and terminal precedence.
for _, mode in ipairs({"fall", "won", "lost"}) do
    local g = dead_board()
    setup(g)
    local rng = g.rng
    if mode == "fall" then R.phase, R.phase_time = R.PH_FALL, 1
    elseif mode == "won" then
        local l = rules.level_of(g)
        g.score, g.relics, g.obstacles, g.moves, g.oil_left = l.score, l.relics, 0, 0, 0
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

if testing.game == "relic-rush" then
    local next_level = rules.game_start(1, 982)
    R.reset_board(next_level)
    local default_radius = R.HEX_R
    local opening = rules.game_start(0, 982)
    R.reset_board(opening)
    R.layout()
    local centre = rules.hex_center()
    for i = 0, rules.CELLS - 1 do
        local distance = rules.hex_distance(centre, i)
        local active = distance <= 4
        check(rules.game_cell_active(opening, i) == active, "The Landing fills a complete hex")
        check(opening.oil[i] == (distance <= 1 and 1 or 0), "The Landing has seven single plaques in the centre")
        check(R.cell_at(R.cell_pos(i)) == (active and i or -1), "The Landing's input follows its cells")
    end
    local left = R.cell_pos(rules.hex_index(-4, 2)).x - R.HEX_R
    local right = R.cell_pos(rules.hex_index(4, -2)).x + R.HEX_R
    near(R.HEX_R, default_radius, "The Landing uses the same cell size as later boards")
    near(left, R.SCREEN_W - right, "The Landing is centered across the screen")
    check(left >= R.SCREEN_W * .05, "The Landing leaves room beside its outer columns")

    local terraces = rules.game_start(8, 982)
    local entrance = rules.hex_index(0, -1)
    local empty = {}
    for i = 0, rules.CELLS - 1 do
        if terraces.active[i] and terraces.tiles[i].kind < 0 then empty[#empty+1] = i end
    end
    check(terraces.chain[entrance] == 1 and #empty >= 30, "the entrance chain holds back the lower terrace")
    local wave = rules.new_match()
    wave.mask[entrance] = true
    rules.game_apply(terraces, wave)
    rules.game_collapse(terraces)
    for _, i in ipairs(empty) do
        check(terraces.tiles[i].kind >= 0, "opening the chain feeds the lower terrace")
    end

    -- The same gate with two links: the terrace stays empty until the second hit.
    local links
    for _, entry in ipairs(rules.levels[9].chain_cells) do
        if entry.cell == entrance then links = entry end
    end
    links.hits = 2
    local shrines = rules.game_start(8, 982)
    links.hits = 1
    local gated = {}
    for i = 0, rules.CELLS - 1 do
        if shrines.active[i] and shrines.tiles[i].kind < 0 then gated[#gated+1] = i end
    end
    check(shrines.chain[entrance] == 2 and #gated >= 30, "a double chain holds back the lower terrace")
    for hit = 1, 2 do
        local strike = rules.new_match()
        strike.mask[entrance] = true
        rules.game_apply(shrines, strike)
        rules.game_collapse(shrines)
        for _, i in ipairs(gated) do
            check((shrines.tiles[i].kind >= 0) == (hit == 2), "the terrace refills after the second hit")
        end
    end

    local temple = rules.game_start(99, 982)
    local frozen
    for i = 0, rules.CELLS - 1 do
        if temple.ice[i] > 0 then frozen = i; break end
    end
    check(frozen and temple.ice[frozen] == 1 and temple.oil[frozen] == 2, "the final boss places ice over a green plaque")
    for _, layers in ipairs{2, 1, 0} do
        local strike = rules.new_match()
        strike.mask[frozen] = true
        rules.game_apply(temple, strike)
        check(temple.ice[frozen] == 0 and temple.oil[frozen] == layers, "ice absorbs a separate hit before the two plaque layers")
        rules.game_collapse(temple)
    end
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
        local resting = rules.hex_center()
        for i = 0, rules.CELLS-1 do
            if g.active[i] and g.chain[i] == 0 and g.ice[i] == 0 then resting = i; break end
        end
        local at = R.cell_pos(resting)
        R.board_input{released=true,pos=at,press_pos=at}
        check(not R.intro:done(), "opening release cannot skip the entrance")
        R.board_input{pressed=true,down=true,pos=at,press_pos=at}
        R.board_input{released=true,pos=at,press_pos=at}
        check(g.moves == moves and g.rng == rng and R.selected < 0 and R.intro:done(), "skip release consumes no move or selection")
        R.board_update(.01)
        check(R.phase == R.PH_IDLE and not R.intro, "completed entrance returns to idle")
        R.present_board(); R.board_update(3)
        check(R.phase == R.PH_IDLE and not R.intro, "natural completion releases the entrance too")
        local _, pos, scale, _, aspect = R.piece_pose(resting, 0)
        near(scale, 1, "finished gem has no enlargement")
        near(aspect, 1, "finished gem has no squash")
        near((pos-at):len(), 0, "finished gem sits at its cell centre")
        check(R.cell_at(pos) == resting, "resting cell input matches its pose")
        if testing.game == "relic-rush" then
            local left = R.cell_pos(rules.hex_index(-4, 0)).x - R.HEX_R
            local right = R.SCREEN_W - R.cell_pos(rules.hex_index(4, 0)).x - R.HEX_R
            check(left >= 24 and left <= 36 and right >= 24 and right <= 36,
                  "widest board retains narrow phone side margins")
            -- A 1x pose alone misses an enlarged sprite canvas. Check the
            -- rectangles actually submitted for every normal piece, including
            -- the hex idol, against the space between adjacent cell rows.
            local image, hex_kind, board_art, boxes = gfx.image, R.hex_piece_kind, R.board_art, {}
            R.hex_piece_kind = rules.RELIC_IDOL
            R.board_art = R.board_art or {}
            -- Temporarily record draw calls instead of requiring a renderer.
            -- The piece is each call's last image; earlier ones are its shadow.
            local last, striped = nil, gfx.image_striped
            gfx.image = function(_, box) last = box end -- luacheck: ignore 122
            gfx.image_striped = function() end -- luacheck: ignore 122
            local function draw(t, board) R.draw_relic(t, pos, scale, 255, aspect, board); boxes[#boxes + 1] = last end
            for kind = 0, 5 do draw(rules.tile(kind), true) end
            gfx.image, gfx.image_striped, R.hex_piece_kind = image, striped, hex_kind -- luacheck: ignore 122
            R.board_art = board_art
            check(#boxes == 6, "all six resting pieces are drawn")
            local pitch = math.sqrt(3) * R.HEX_R
            for i = 1, 6 do
                local box = boxes[i]
                check(box.w > .9 * pitch and box.w < pitch and box.h > .9 * pitch and box.h < pitch,
                      "resting piece fills its cell while preserving a gutter")
                near((box:center()-pos):len(), 0, "resting piece artwork stays centred")
            end
        end
        R.present_board(); R.reset_board(g)
        check(not R.intro and R.phase == R.PH_IDLE, "reset clears pending entrance")
    end
end

-- Popups and rewards settle before the clock advances, in both games (a
-- stalled clock on device once left a dim with no panel). Reels still play
-- the results card's parts, and a tap skips them.
do
    testing.reset()
    local claimed = 0
    local claim = R.claim_reward
    R.claim_reward = function() claimed = claimed + 1 end
    R.open_dialog()
    check(R.dialog.entry == 1 and R.dialog.fresh and R.dialog_settled(), "a dialog is visible on its opening frame")
    local first = R.dialog_part(.2, .3)
    check(first.f == 1 and first.u == 1 and R.dialog_settled(), "result parts appear without waiting for the clock")
    local arg = app.arg
    app.arg = function(name) if name == "reel" then return "" end end -- luacheck: ignore 122
    R.open_dialog()
    app.arg = arg -- luacheck: ignore 122
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
    check(claimed == 1 and not R.modal_closing, "the reward is banked on the closing frame")
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

-- More source mechanic rows must remain reachable without pushing Done offscreen.
do
    local _,height=R.guide_form:measure(432,R.skin)
    check(height<=800,"mechanics guide fits the portrait screen")
    check(R.guide_form:scroll_to("topics",R.guide_entries[#R.guide_entries].id),"last mechanic remains reachable by scrolling")
end

