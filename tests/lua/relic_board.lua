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

-- Imported source masks fill the phone area, not their mostly empty enclosing
-- grid. Drawing and pointer lookup must retain the same shifted origin.
do
    local match3=require("match3")
    for _,spec in pairs(require("match3.reference")) do
        local model=match3.new{radius=spec.radius,levels={spec.level},colors=6}
        for _,width in ipairs{480,390} do
            local view=match3.view{SCREEN_W=width}
            model.bind_view(view)
            view.g=model.game_start(0,spec.seed)
            local minx,maxx,miny,maxy=math.huge,-math.huge,math.huge,-math.huge
            for i=0,model.CELLS-1 do if model.game_cell_active(view.g,i) then
                local p=view.cell_pos(i)
                check(view.cell_at(p)==i,"fitted source cell remains hit-testable")
                minx,maxx=math.min(minx,p.x-view.HEX_R),math.max(maxx,p.x+view.HEX_R)
                miny,maxy=math.min(miny,p.y-math.sqrt(3)*view.HEX_R/2),math.max(maxy,p.y+math.sqrt(3)*view.HEX_R/2)
            end end
            local top,bottom=view.hud_rect.y+view.hud_rect.h+16,view.tools_y-18
            check(minx>=8-.001 and maxx<=width-8+.001 and miny>=top-.001 and maxy<=bottom+.001,
                  "all source hex faces fit between HUD, tools and screen edges")
            check(math.abs(maxx-minx-(width-16))<.001 or math.abs(maxy-miny-(bottom-top))<.001,
                  "source board uses the maximum unclipped scale")
            near((minx+maxx)/2,width/2,"source field is horizontally centred")
            near((miny+maxy)/2,(top+bottom)/2,"source field is vertically centred")
            near(view.board_tool_bounds(1):center().x,width/2,"tools stay centred for asymmetric source masks")
        end
    end
end

local function inventory(g)
    local counts = {}
    for i=0,rules.CELLS-1 do
        local t = g.tiles[i]
        local key = t.kind .. ":" .. t.special
        counts[key] = (counts[key] or 0) + 1
    end
    return counts
end
local function same_inventory(g, before)
    local after = inventory(g)
    for key, count in pairs(before) do check(after[key] == count, "reshuffle retains every gem and special: "..key) end
    for key, count in pairs(after) do check(before[key] == count, "reshuffle creates no gems: "..key) end
end

-- Every special, including each ray axis, survives recovery as a whole piece.
for seed=1,12 do
    local g = dead_board(seed % rules.LEVELS)
    g.rng = seed
    local sp = 1
    for i=0,rules.CELLS-1 do
        if g.active[i] and g.chain[i]==0 and g.ice[i]==0 and g.hazard[i]==0 and g.stone_hp[i]==0
            and g.crate_hp[i]==0 and g.tiles[i].kind>=0 and sp<=rules.PRISM then
            g.tiles[i].special = sp
            sp = sp+1
        end
    end
    local before = inventory(g)
    check(rules.game_shuffle(g), "special inventory can be rearranged into a playable board")
    same_inventory(g,before)
    local m = rules.new_match()
    rules.game_matches(g,m,-1)
    check(m.hits==0 and rules.game_hint(g), "special reshuffle has a move and no free match")
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
              and g.chain[i] == before.chain[i] and g.ice[i] == before.ice[i]
              and g.stone_hp[i] == before.stone_hp[i] and g.crate_hp[i] == before.crate_hp[i]
              and g.hazard[i] == before.hazard[i], "terrain survives recovery")
        if g.chain[i] > 0 or g.ice[i] > 0 or g.hazard[i] > 0 or g.stone_hp[i] > 0
            or g.crate_hp[i] > 0 or g.tiles[i].kind == rules.DELIVERY or not g.active[i] then
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
        g.score, g.relics, g.dug, g.obstacles, g.moves = l.score, l.relics, g.initial_soil, 0, 0
        g.discovered, g.delivered = #g.objects, g.delivery_total
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
    local g=rules.game_start(16,123)
    R.g=g
    local goals=R.goal_entries()
    local l = rules.level_of(g)
    local remaining={score=l.score,idols=l.relics,sand=g.initial_soil,locks=g.obstacles,
        discoveries=#g.objects,deliveries=g.delivery_total}
    if l.goals then
        -- A level that names its goals shows exactly those, in its order.
        check(#goals==#l.goals,"late HUD shows only the level's own goals")
        for n,id in ipairs(l.goals) do
            check(goals[n].id==id and goals[n].remaining==remaining[id],"late HUD exposes the actual remaining goals")
        end
    else
        check(goals[1].id=="score" and goals[1].remaining==l.score and goals[2].id=="idols" and goals[2].remaining==l.relics
              and goals[3].id=="sand" and goals[3].remaining==g.initial_soil
              and goals[#goals].id=="locks" and goals[#goals].remaining==g.obstacles,"late HUD exposes the actual remaining goals")
    end
    g.score,g.relics,g.dug,g.obstacles=9000,99,99,0
    g.discovered,g.delivered=#g.objects,g.delivery_total
    for _,entry in ipairs(R.goal_entries()) do check(entry.remaining==0,"completed goal clamps at zero") end
    R.g=rules.game_start(0,123)
    local opening,first=R.goal_entries(),rules.levels[1].goals
    if first then
        check(#opening==#first and opening[1].id==first[1],"opening HUD shows the first level's own goals")
    else
        check(#opening==2 and opening[1].id=="score" and opening[2].id=="idols",
              "opening HUD shows the ordinary score and collection goals")
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
            check(left >= 12 and left <= 20 and right >= 12 and right <= 20,
                  "widest board retains narrow phone side margins")
            -- A 1x pose alone misses an enlarged sprite canvas. Check the
            -- rectangles actually submitted for every normal piece, including
            -- the hex idol, against the space between adjacent cell rows.
            local image, hex_kind, board_art, boxes = gfx.image, R.hex_piece_kind, R.board_art, {}
            R.hex_piece_kind = rules.RELIC_IDOL
            R.board_art = R.board_art or {}
            -- Temporarily record draw calls instead of requiring a renderer.
            gfx.image = function(_, box) boxes[#boxes + 1] = box end -- luacheck: ignore 122
            for kind = 0, 5 do R.draw_relic(rules.tile(kind), pos, scale, 255, aspect, true) end
            R.draw_relic(rules.tile(0, rules.PRISM), pos, scale, 255, aspect, false)
            gfx.image, R.hex_piece_kind = image, hex_kind -- luacheck: ignore 122
            R.board_art = board_art
            check(#boxes == 7, "all six resting pieces and a state panel are drawn")
            local pitch = math.sqrt(3) * R.HEX_R
            for i = 1, 6 do
                local box = boxes[i]
                check(box.w > .9 * pitch and box.w < pitch and box.h > .9 * pitch and box.h < pitch,
                      "resting piece fills its cell while preserving a gutter")
                near((box:center()-pos):len(), 0, "resting piece artwork stays centred")
            end
            check(boxes[7].w < 2 * R.HEX_R and boxes[7].h < 2 * R.HEX_R,
                  "state panel retains an inset from neighbouring cells")
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

-- A real release/tap starts the existing clearing phase without selecting twice.
do
    local g=rules.game_start(0,123);local cell=rules.hex_center()
    g.active[cell]=true;g.chain[cell],g.ice[cell],g.stone_hp[cell],g.crate_hp[cell],g.hazard[cell]=0,0,0,0,0
    g.tiles[cell]=rules.tile(0,rules.PLANE)
    setup(g);R.selected,R.tool=-1,-1;R.sound=false;R.reduced_motion=false
    local moves=g.moves;local at=R.cell_pos(cell)
    R.board_input{released=true,pos=at,press_pos=at}
    check(g.moves==moves-1 and R.phase==R.PH_CLEAR,"one tap activates and enters the preserved clear phase")
    check(#R.pending.flights==1,"plane activation reaches the animated effect event")
    local target=R.pending.flights[1].to
    check(g.tiles[target].kind==-1,"plane target is removed by the rules")
    local _,_,before_scale,before_alpha=R.piece_pose(target,0)
    R.board_update(.3)
    local _,_,during_scale,during_alpha=R.piece_pose(target,0)
    check(R.phase==R.PH_CLEAR and before_scale==1 and before_alpha==255 and during_scale==1 and during_alpha==255,
        "target stays visible during the flight and refill waits")
    R.board_update(.3)
    local _,_,impact_scale,impact_alpha=R.piece_pose(target,0)
    check(R.phase==R.PH_CLEAR and impact_scale<1 and impact_alpha<255,"target clears after the plane arrives")
    R.board_update(.13)
    check(R.phase==R.PH_FALL,"refill starts after the impact")
end

-- More source mechanic rows must remain reachable without pushing Done offscreen.
do
    local _,height=R.guide_form:measure(432,R.skin)
    check(height<=800,"mechanics guide fits the portrait screen")
    check(R.guide_form:scroll_to("topics","growth"),"last mechanic remains reachable by scrolling")
end

-- A shared source obstacle is drawn once, and looking at a queue never consumes it.
do
    local elements=require("match3.elements_view")
    local saved_game,saved_art,saved_intro,saved_image=R.g,R.board_art,R.intro,gfx.image
    local g=rules.game_start(0,123478)
    g.hs={cells={},groups={},queues={}}
    g.objects={};g.tunnel_to={};g.tunnel_from={};g.delivery_exits={}
    for i=0,rules.CELLS-1 do
        g.active[i]=true;g.hs.cells[i]={}
        g.stone_hp[i]=0;g.crate_hp[i]=0;g.hazard[i]=0
    end
    local a=rules.hex_index(0,0)
    local cells={a,rules.hex_index(1,0),rules.hex_index(0,1),rules.hex_index(1,1)}
    g.hs.groups[a]={kind="TARGET_GEN",count=8,cells=cells}
    for _,i in ipairs(cells) do g.hs.cells[i].group=a end
    local function maker(q,r,period,hits)
        local footprint={rules.hex_index(q,r),rules.hex_index(q+1,r),
            rules.hex_index(q,r+1),rules.hex_index(q+1,r+1)}
        local anchor=footprint[1]
        g.hs.groups[anchor]={kind="CARRY_GEN",cells=footprint,period=period,hits=hits}
        for _,i in ipairs(footprint) do g.hs.cells[i].group=anchor end
        return g.hs.groups[anchor]
    end
    local charged_maker=maker(-2,-2,5,1)
    maker(0,-3,5,2)
    maker(2,-3,3,1)
    local inlet=rules.hex_index(-3,0)
    g.hs.cells[inlet].visibleGenerator=true
    local queue={cursor=1,spawns=0,units={{element="cookie",hp=2}}}
    g.hs.queues[inlet]=queue
    local floor=rules.hex_index(3,0);g.hs.cells[floor].tile=2
    local portal_in, portal_out = rules.hex_index(-4,0), rules.hex_index(4,0)
    g.tunnel_to[portal_in], g.tunnel_from[portal_out] = portal_out, portal_in
    g.delivery_exits[rules.hex_index(3,1)] = true
    local cherry_cell, empty_jelly = rules.hex_index(-2,1), rules.hex_index(-2,2)
    g.hs.cells[cherry_cell].jelly, g.hs.cells[empty_jelly].jelly = 2, 2
    g.tiles[cherry_cell] = {kind=0, special=rules.NORMAL, element="cherry", hp=1}
    g.tiles[empty_jelly] = rules.tile(-1)
    g.hs.goals = {{type="COLOR_BOX", max=3, current=1}}
    local draws={}
    R.g,R.intro,R.board_art=g,nil,{}
    for _,name in ipairs(elements.assets) do R.board_art[name]=name end
    gfx.image=function(frame) draws[frame]=(draws[frame] or 0)+1 end -- luacheck: ignore 122
    elements.ground(R,rules,0)
    elements.blockers(R,rules,0)
    local goals = R.goal_entries()
    local first_draws=draws
    draws={}
    local box=rules.hex_index(3,1)
    for color=0,5 do
        for health=1,6 do
            g.hs.cells[box]={box=health,color=color}
            elements.blockers(R,rules,0)
        end
    end
    local box_draws=draws
    draws={}
    for hit=3,5 do
        charged_maker.hits=hit
        elements.blockers(R,rules,0)
    end
    gfx.image,R.g,R.board_art,R.intro=saved_image,saved_game,saved_art,saved_intro -- luacheck: ignore 122
    local charge_draws=draws
    draws=first_draws
    check(draws["apple-platter-8"]==1,"one source image spans a shared four-cell group")
    check(draws["donut-maker-1"]==1,"the first hit in a five-hit maker holds the original raw pose")
    check(draws["donut-maker-2"]==2,"the heated pose follows either two individual stages or one combined stage")
    for hit=3,5 do check(charge_draws["donut-maker-"..hit]==1,"each later charge has its own maker frame") end
    check(draws["generator-shell"]==1 and draws["cookie-2"]==1,"inlet shows its exact next authored object state")
    check(queue.cursor==1 and queue.spawns==0,"rendering the source queue does not advance simulation")
    check(draws["membrane-fill-2"]==1,"covered source floor uses its authored intact material")
    check(draws["tunnel-in"]==1 and draws["tunnel-out"]==1,"both source portal roles use their own sprite")
    check(draws["carry-exit-arrow"]==3,"donut exit draws three staggered copies of its original arrow")
    check(draws["jelly-2-cherry"]==1 and draws["jelly-2"]==1,"jelly displays a soft cherry only when one is present")
    check(elements.covers_cherry(g,cherry_cell,g.tiles[cherry_cell]),"the covered cherry is not drawn twice")
    check(goals[1].icon=="goal-color-box" and goals[1].remaining==2,"colored-box goal uses its source icon and rule count")
    for color=0,5 do
        for health=1,6 do
            local name=("color-box-%d-%d"):format(color,health)
            check(box_draws[name]==1,"colored box uses its own original frame: "..name)
        end
    end
end

-- A maker may receive another hit or release while its visual transition runs.
do
    local elements=require("match3.elements_view")
    local group={kind="CARRY_GEN",period=3,hits=0}
    local view={g={hs={groups={[1]=group}}}}
    elements.maker_observe(view)
    group.hits=1; elements.maker_observe(view)
    elements.maker_update(view,.5)
    check(view.maker_visual[1].pose==1,"combined hit shows its first stage")
    elements.maker_update(view,1.9)
    check(view.maker_visual[1].pose==2,"combined hit reaches its held pose")
    group.hits=3; elements.maker_observe(view)
    group.hits=0; elements.maker_observe(view)
    elements.maker_update(view,1.11)
    check(view.maker_visual[1].pose==0 and #view.maker_visual[1].queue==0,"queued release follows every stage")
    group.hits=1; elements.maker_observe(view)
    view.reduced_motion=true; elements.maker_update(view,0)
    check(view.maker_visual[1].pose==2,"reduced motion immediately settles")
    view.g={hs={groups={[1]={kind="CARRY_GEN",period=5,hits=0}}}}
    elements.maker_observe(view)
    check(view.maker_visual[1].pose==0,"new board resets maker presentation")
end
