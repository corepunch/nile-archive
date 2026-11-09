-- Relic Rush · The Lost Valley — hex straight-line match-3 expeditions that restore an island.
--
-- main.lua owns the flow between the two screens, progress and saving, sound,
-- and the debug entry points used for screenshots and the smoke test.
local R = require("state")
local rules = require("rules")
local island = require("island")
require("screens")
require("catalogue")
require("expeditions")
require("vfx")
require("board")
require("island_view")
require("narrative")
require("campaign_smoke")
local journey = require("journey")
local LEVELS, WONDERS, ISLAND_ZONES = rules.LEVELS, island.WONDERS, island.ISLAND_ZONES
local rgba = color

-- Dialogue text: Lilita One in dark ink on the cream bubble.
function R.speech_style(size) return style{font = R.font, size = size, fill = rgba(74, 50, 28)} end

function R.notice(text)
    R.toast = text
    R.toast_time = 3.6
end

function R.tone(hz)
    if R.sound then sfx.tone(hz, .17) end
end

------------------------------------------------------------------ progress

local function serialize(s)
    local version = s:int("version", 3)
    R.prog.level = s:int("level", R.prog.level)
    R.prog.seed = s:int("seed", R.prog.seed) & 0xFFFFFFFF
    R.prog.wallet = s:ints("wallet", R.prog.wallet)
    R.prog.lives = s:int("lives", R.prog.lives)
    R.prog.life_at = s:int("life_at", R.prog.life_at)
    R.island:serialize(s)
    story.serialize(s)
    journey.serialize(s, R.prog)
    if save.is_reading(s) then
        R.prog.level = num.clampi(R.prog.level, 0, LEVELS)
        journey.migrate(R.prog, version)
        R.needs_relocation=island.restore_saved(R.island,R.prog.level)
    end
end

function R.save_progress()
    if not R.test_mode then save.write("progress", serialize) end
end

function R.start_level(chosen)
    local lvl = num.clampi(chosen or R.prog.level, 0, LEVELS - 1)
    if lvl > R.prog.level then return false end
    if lvl == R.prog.level and island.wonder_count(R.island) < journey.earned(R.prog.level) then
        R.notice("Build your earned stall before the next winter wish."); return false
    end
    if lvl == R.prog.level and journey.awaiting_return(R.prog) then
        R.notice("Something's happening in the market square."); return false
    end
    rules.refill_lives(R.prog, app.clock())
    if R.prog.lives == 0 then
        R.notice("A life returns every 30 minutes. Explore the market meanwhile.")
        return false
    end
    R.reset_board(rules.game_start(lvl, (R.prog.seed + lvl * 7919) & 0xFFFFFFFF))
    R.on_island = false
    R.overlay = R.OV_NONE
    R.phase, R.intro = R.PH_IDLE, nil
    R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
    R.idle_time = 0
    R.vfx_reset()
    -- Mechanics stay in the board lesson, apart from the story dialogue.
    if not R.quiet then
        local l = rules.level_of(R.g)
        R.mission(l.lesson, ("%d. %s"):format(lvl + 1, l.name)); R.present_board()
    end
    return true
end

function R.play_level(level)
    if R.g and R.g.level==level and not R.g.won and not R.g.lost then
        R.on_island=false;R.overlay=R.OV_NONE
        if R.phase == R.PH_IDLE or R.phase == R.PH_PRESENT then R.present_board() end
        return true
    end
    return R.start_level(level)
end

-- After the results dialog closes: bank the reward and go build.
function R.claim_reward()
    local paid, first = rules.progress_reward(R.prog, R.g, R.wonders)
    if not paid then return end
    R.save_progress()
    R.on_island = true
    R.overlay = R.OV_NONE
    R.notice(first and (journey.wonder_at(R.prog.level) and "New stall funded! Spare Gold is yours to decorate." or "Something's happening in the market square.")
        or "Replay Gold collected. Add some Christmas decorations.")
end

---------------------------------------------------------------- smoke test

-- --smoke: opens/closes the guide, plays level one through injected clicks, claims the
-- reward, builds the first wonder and enters level two.
local smoke_stage, smoke_frames, smoke_wait, smoke_partner = -2, 0, 0, -1
local smoke_move={}
local smoke_city_move
local function press_row(form, key, id)
    for _, node in pairs(form.nodes) do
        if node.item_key == key and node.local_id == id then
            app.inject_click(form.boxes[node.id]:center())
            return node
        end
    end
end

local function smoke()
    smoke_frames = smoke_frames + 1
    if smoke_frames > 8000 or R.g.lost then
        error(("smoke test failed at stage %d (overlay %d, level %d)"):format(smoke_stage,R.overlay,R.g.level))
    end
    if smoke_wait > 0 then   -- one click per few frames, so each press and release is its own frame
        smoke_wait = smoke_wait - 1
        return
    end
    smoke_wait = 3
    if story.active() then   -- tap through the dialogue
        assert(R.phase ~= R.PH_PRESENT or R.intro.t == 0, "smoke: the board fills only after the dialogue")
        app.inject_click(vec2(240, 300))
        return
    end
    if R.mission_banner and not R.on_island and R.overlay == R.OV_NONE then   -- a tap sends the mission banner on
        if not R.mission_banner.skipped then app.inject_click(vec2(240, 300)); R.mission_banner.skipped = true end
        return
    end
    -- The board's entrance takes no moves. A tap skips the first; the rest play out.
    if R.phase == R.PH_PRESENT and R.overlay == R.OV_NONE and not R.on_island then
        if not smoke_move.skipped and R.intro.t > 0 then
            app.inject_click(R.cell_pos(rules.hex_center())); smoke_move.skipped = true
        end
        return
    end
    if smoke_stage == -2 and R.overlay==R.OV_NONE then
        app.inject_click(R.board_pause:center());smoke_stage=-3   -- Pause, in the HUD band
    elseif smoke_stage == -3 and R.overlay==R.OV_PAUSE and R.dialog_settled() then
        smoke_move.sound = R.sound
        assert(not R.pause_form.boxes.restart and not R.pause_form.boxes.quit, "market Pause only shows supported actions")
        app.inject_click(R.pause_form.boxes.sound:center()+vec2(0,R.drop/2));smoke_stage=-4
    elseif smoke_stage == -4 then
        assert(R.sound == not smoke_move.sound and R.overlay == R.OV_PAUSE, "the Sound checkbox toggles sound")
        app.inject_click(R.pause_form.boxes.sound:center()+vec2(0,R.drop/2));smoke_stage=-5
    elseif smoke_stage == -5 then
        assert(R.sound == smoke_move.sound, "the Sound checkbox restores sound")
        app.inject_click(R.pause_form.boxes.guide:center()+vec2(0,R.drop/2));smoke_stage=-1
    elseif smoke_stage == -1 and R.overlay==R.OV_GUIDE and R.dialog_settled() then
        local done=R.guide_form.boxes.done
        assert(done and #R.guide_form.nodes.topics.children==5,"smoke: guide data source was not laid out")
        app.inject_click(done:center()+vec2(0,R.drop/2));smoke_stage=0
    elseif smoke_stage == 0 then
        if R.overlay == R.OV_RESULT then
            if R.dialog_settled() then app.inject_click(rect(76, 660, 328, 56):center() + vec2(0, R.drop / 2)); smoke_stage = 1 end
            return
        end
        if R.phase == R.PH_IDLE and R.overlay == R.OV_NONE and R.selected < 0 then
            local best, a, b = -1, -1, -1
            for i = 0, rules.CELLS - 1 do
                for z = 0, 2 do
                    local j = rules.hex_neighbor(i, z)
                    local v = rules.game_evaluate_move(R.g, i, j)
                    if v > best then best, a, b = v, i, j end
                end
            end
            if a >= 0 then app.inject_click(R.cell_pos(a)); smoke_partner = b end
        elseif R.selected >= 0 and R.phase == R.PH_IDLE and smoke_partner >= 0 then
            app.inject_click(R.cell_pos(smoke_partner))
            smoke_partner = -1
        end
    elseif smoke_stage == 1 and R.on_island and R.overlay == R.OV_NONE then
        if R.prog.level ~= 1 then error("smoke: the win was not banked") end
        if smoke_move.replay then
            local gain=R.prog.wallet[1]-smoke_move.replay_gold
            assert(gain>=60 and gain<=100 and R.prog.wallet[4]==3 and R.prog.wallet[5]==0 and island.wonder_count(R.island)==1,
                "replay must pay only Gold without changing discoveries or restoration")
            app.inject_click(R.island_buttons.play+vec2(0,R.drop));smoke_stage=5;return
        end
        app.inject_click(R.island_buttons.shop+vec2(0,R.drop)); smoke_stage = 2   -- Build: the earned stall
    elseif smoke_stage == 2 and R.overlay == R.OV_SHOP then
        assert(press_row(R.catalogue_form, "arch", "buy"), "smoke: the earned stall is in the shop"); smoke_stage = 3
    elseif smoke_stage == 3 and R.island.placing >= 0 then
        app.inject_click(R.placement_form.boxes.confirm:center()); smoke_stage = 4   -- PLACE & BUILD
    elseif smoke_stage == 4 and R.island.placing < 0 and R.overlay == R.OV_NONE then
        if R.island.count ~= 1 then error("smoke: the wonder was not built") end
        smoke_city_move = city.move_test(R.island, {
            look = function(at) R.island_focus(at-vec2(0,80),math.max(.65,R.island.cam.zoom)) end,
            wallet = function() return R.prog.wallet[rules.GOLD] end,
            cancel = function() app.inject_click(R.placement_form.boxes.cancel:center()) end,
            confirm = function() app.inject_click(R.placement_form.boxes.confirm:center()) end,
            offset = vec2(240,0),
        })
        smoke_stage=6
    elseif smoke_stage==6 then
        if not smoke_city_move() then R.open_catalogue("all");smoke_move.categories=0;smoke_stage=120 end
    elseif smoke_stage==120 then
        smoke_move.scroll_start=R.catalogue_form.boxes.stock:point(vec2(.5,.8))
        app.inject_press(smoke_move.scroll_start);smoke_stage=121
    elseif smoke_stage==121 then
        app.inject_move(smoke_move.scroll_start-vec2(0,170));smoke_stage=122
    elseif smoke_stage==122 then
        app.inject_release(smoke_move.scroll_start-vec2(0,170));smoke_stage=123
    elseif smoke_stage==123 then
        assert(R.overlay==R.OV_SHOP and R.catalogue_form.nodes.stock.scroll_state.offset>100,
            "drag must scroll decorations without choosing a building")
        smoke_stage=20
    elseif smoke_stage==20 and R.overlay==R.OV_SHOP then
        if smoke_move.categories<2 then
            app.inject_click(R.catalogue_form.boxes.category_next:center())
            smoke_move.categories=smoke_move.categories+1
        else smoke_stage=21 end
    elseif smoke_stage==21 and R.overlay==R.OV_SHOP then
        local f=R.catalogue_form
        assert(f:get_item("stock","firs") and not f:get_item("stock","arch"),"category source must refresh")
        for _,node in pairs(f.nodes) do
            if node.item_key=="firs" and node.local_id=="buy" then
                assert(node.enabled,"smoke: starter decoration should be affordable")
                smoke_move.shop_gold=R.prog.wallet[1]
                app.inject_click(f.boxes[node.id]:center());smoke_stage=22;break
            end
        end
    elseif smoke_stage==22 and R.island.placing>=0 then
        assert(R.island.placing==10,"catalogue action lost its stable item key")
        app.inject_click(R.placement_form.boxes.cancel:center());smoke_stage=23
    elseif smoke_stage==23 and R.island.placing<0 then
        assert(R.island.count==1 and R.prog.wallet[1]==smoke_move.shop_gold,"cancelled purchase changed save state")
        R.open_catalogue();smoke_stage=24
    elseif smoke_stage==24 and R.overlay==R.OV_SHOP then
        for _,node in pairs(R.catalogue_form.nodes) do
            if node.item_key=="firs" and node.local_id=="buy" then
                app.inject_click(R.catalogue_form.boxes[node.id]:center());smoke_stage=25;break
            end
        end
    elseif smoke_stage==25 and R.island.placing>=0 then
        app.inject_click(R.placement_form.boxes.confirm:center());smoke_stage=26
    elseif smoke_stage==26 and R.island.placing<0 then
        assert(R.island.count==2 and island.wonder_count(R.island)==1,"decoration changed campaign restoration count")
        assert(R.prog.wallet[1]==smoke_move.shop_gold-45,"purchase must charge once")
        local c=R.island
        R.island_focus(c.items[2].pos-vec2(0,80),.8)
        local bounds=c.cam:rect_to_screen(c:sprite_rect(c.items[2]))
        local target
        for y=1,9 do for x=1,9 do
            local point=bounds:point(vec2(x/10,y/10))
            if point.y>110 and point.y<690+R.drop and c:building_at(c.cam:to_world(point))==1 then target=point end
        end end
        assert(target,"purchased decoration needs an exposed input target")
        app.inject_click(target);smoke_stage=27
    elseif smoke_stage==27 and R.overlay==R.OV_WONDER then
        assert(R.inspect==10 and R.inspect_item==1,("purchased details: expected type 10 / item 1, got %s / %s"):format(tostring(R.inspect),tostring(R.inspect_item)))
        app.inject_click(R.wonder_form.boxes.action:center()+vec2(0,R.drop/2));smoke_stage=28
    elseif smoke_stage==28 and R.island.placing>=0 then
        assert(R.island.moving==1 and R.island.placing==10,"details must move the purchased instance")
        app.inject_click(R.placement_form.boxes.cancel:center());smoke_stage=29
    elseif smoke_stage==29 and R.island.placing<0 then
        app.inject_click(R.island_buttons.expeditions+vec2(0,R.drop));smoke_stage=30
    elseif smoke_stage==30 and R.overlay==R.OV_EXPEDITIONS then
        local f=R.expedition_form
        for _,node in pairs(f.nodes) do
            if node.item_key=='0' and node.local_id=='play' then
                assert(node.enabled,'completed expedition must be replayable')
                smoke_move.replay_gold=R.prog.wallet[1];smoke_move.replay=true
                app.inject_click(f.boxes[node.id]:center());smoke_stage=31;break
            end
        end
    elseif smoke_stage==31 and not R.on_island then
        smoke_move.resume_game=R.g;smoke_move.resume_moves=R.g.moves
        app.inject_click(vec2(40,38));smoke_stage=32
    elseif smoke_stage==32 then
        assert(not R.on_island and R.overlay==R.OV_NONE,'unfinished expedition must not expose island access')
        app.inject_click(R.board_pause:center());smoke_stage=33
    elseif smoke_stage==33 and R.overlay==R.OV_PAUSE and R.dialog_settled() then
        app.inject_click(vec2(12,220+R.drop/2));smoke_stage=34
    elseif smoke_stage==34 and R.overlay==R.OV_NONE then
        assert(not R.on_island and R.g==smoke_move.resume_game and R.g.moves==smoke_move.resume_moves,
               'background dismissal must resume the same unfinished board')
        smoke_stage=0
    elseif smoke_stage == 5 and not R.on_island and R.overlay == R.OV_NONE then
        if R.g.level ~= 1 then error("smoke: level two did not start") end
        print("smoke test passed: guide -> puzzle -> claim -> restoration -> pan/move -> catalogue purchase/cancel -> replay -> no island escape -> pause/background resume -> Gold only -> level 2")
        app.quit()
    end
end

-------------------------------------------------------------------- frame

local function frame(dt)
    if app.arg("cell-mask") then
        -- Same flat-top polygon as a cell, captured at texture resolution.
        gfx.rect(rect(0, 0, R.SCREEN_W, R.SCREEN_H), color(0, 0, 0))
        gfx.ngon(vec2(R.SCREEN_W / 2, R.SCREEN_H / 2), 64, 6, 0, color.WHITE)
        return
    end
    local inp = input.get()
    R.story_tick()
    local talking = story.active()
    local world = (R.overlay ~= R.OV_NONE or talking) and input{pos = inp.pos, pinch = 1} or input.world()
    R.layout()
    tween.instant(R.reduced_motion)   -- reduced motion: every tween settles on its next frame
    if app.arg("smoke") then if app.arg("campaign") then R.campaign_smoke() else smoke() end end
    R.now = R.now + dt
    if not talking then R.toast_time = R.toast_time - dt end
    if inp.back and not talking and R.overlay == R.OV_NONE then R.overlay = R.OV_PAUSE end

    R.board_update(dt)
    local now = app.clock()
    rules.refill_lives(R.prog, now)
    if rules.lose_life(R.prog, R.g, now) then R.save_progress() end
    R.vfx_update(dt)
    ui.set_enabled(R.overlay == R.OV_NONE and not talking)
    if R.on_island then R.island_screen(world, dt) else R.board_screen(world, dt) end
    if not R.on_island then
        R.vfx_draw()
        R.vfx_particles()
        R.draw_board_banners(dt)
    end
    R.draw_toast()
    ui.set_enabled(true)
    if not talking then R.overlays(dt) end   -- a dialogue comes first; dialogs wait for it
    story.frame(dt)
end

---------------------------------------------------------------- debug setup

-- An island after n expeditions: n wonders at their suggested spots and the
-- regions a player would have opened by then, with Stars to match.
local function island_with(n)
    local opened_at = {0, 6, 9, 15, 21, 27}
    local cleared = n > 0 and journey.wonder_levels[n] or 0
    R.prog.level, R.prog.wallet = cleared, purse(340, 0, 0, cleared * 3)
    R.island.count = 0
    local open = 1
    for z = 1, ISLAND_ZONES - 1 do
        if cleared >= opened_at[z + 1] then
            open = open | (1 << z)
        end
    end
    R.island.open = tonumber(app.arg("open") or "") or open   -- --open MASK: only these regions (bit per region)
    R.island.open = R.island.open | 1
    local spend = purse(100000)
    for _ = 1, n do island.island_place_next(R.island, spend, cleared, 0) end
end

local function debug_screens()
    R.island.show_footprints = app.arg("footprints") ~= nil
    local a = app.arg("level")
    if a then R.g = rules.game_start(tonumber(a) - 1, 123478); R.pending = rules.new_match(); R.on_island = false; R.toast_time = 0 end
    a = app.arg("city")
    if a then island_with(num.clampi(tonumber(a), 0, WONDERS)); R.on_island = true; R.toast_time = 0 end
    if app.arg("showcase") then
        local spots = {vec2(690, 2050), vec2(930, 2180), vec2(580, 1870), vec2(1050, 2000), vec2(820, 1900),
                       vec2(1180, 1800), vec2(760, 1700), vec2(1040, 1620), vec2(620, 1550), vec2(920, 1400)}
        R.prog.level, R.prog.wallet = LEVELS, purse(340, 0, 0, LEVELS * 3)
        R.island.count = 0
        R.island.open = 63
        for i = 0, WONDERS - 1 do
            local p = R.island:snap(spots[i + 1], i)
            if not R.island:can_place(p, i, -1) then
                local _, spot = R.island:find_spot(i, p)
                p = spot
            end
            R.island:add(p, i, 0)
        end
        R.island_focus(vec2(850, 1650), .52)
        R.on_island = true
        R.toast_time = 0
    end
    if app.arg("overview") then R.island_focus(vec2(island.ISLAND_W / 2, island.ISLAND_H / 2), .25) end
    a = app.arg("look")
    if a then   -- --look X,Y: centre the island camera on a world point
        local x, y = a:match("(%d+),(%d+)")
        if x then R.island_focus(vec2(tonumber(x), tonumber(y)), R.island.cam.zoom) end
    end
    if app.arg("placing") and R.island.count < WONDERS then
        R.prog.level = journey.wonder_levels[R.island.count + 1]
        R.island_begin(R.island.count, true)
        if app.arg("placing") == "blocked" and R.island.count > 0 then   -- over a built wonder: the red ghost
            local c = R.island
            c.ghost = c.items[c.count].pos
            R.island_focus(c.ghost - vec2(0, 90), c.cam.zoom)
        elseif app.arg("placing") == "dragging" then   -- held between tiles: the footprint shows where it lands
            local c = R.island
            c.ghost = c.ghost + vec2(30, 26)
            c.held = true
        end
        R.toast_time = 0
    end
    a = app.arg("zone")
    if a then R.zone_card = num.clampi(tonumber(a), 1, ISLAND_ZONES - 1); R.overlay = R.OV_ZONE; R.on_island = true end
    if app.arg("victory") then   -- the Lumber workshop's wish, which funds a stall; "clue": a story-only wish
        local level = app.arg("victory") == "clue" and 1 or 3
        R.prog.level, R.prog.wallet = level, purse(142, 0, 0, level * 3)
        R.g = rules.game_start(level, 123478)
        R.pending = rules.new_match()
        R.g.score, R.g.relics, R.g.wood, R.g.stone, R.g.won = 5860, 13, 9, 14, true
        R.vfx_reset()
        R.on_island = false
        R.overlay = R.OV_RESULT
        R.toast_time = 0
    end
    a = app.arg("card")
    if a then
        local i = num.clampi(tonumber(a), 0, WONDERS - 1)
        island_with(i)
        R.prog.level = journey.wonder_levels[i + 1]
        R.prog.wallet = purse(142, 0, 0, R.prog.level * 3)
        R.inspect = i
        R.overlay = R.OV_WONDER
        R.on_island = true
        R.toast_time = 0
    end
    a = app.arg("fx")
    if a then   -- fire one special in the middle of level nine
        local mode = a == "ray" and 0 or a == "bomb" and 1 or 2
        local c = rules.hex_center()
        R.g = rules.game_start(8, 123478)
        R.pending = rules.new_match()
        R.on_island = false
        R.vfx_reset()
        R.g.obstacles = R.g.obstacles - R.g.chain[c] - R.g.ice[c]
        R.g.chain[c], R.g.ice[c] = 0, 0
        R.g.tiles[c] = rules.tile(mode == 2 and 0 or 3, mode == 0 and rules.ROW or mode == 1 and rules.BOMB or rules.PRISM)
        R.pending.mask[c] = true
        R.pending.hits = 1
        R.finish_wave()
        R.toast_time = 0
    end
    if app.arg("catalogue") then
        island_with(4);R.on_island=true
        R.open_catalogue(app.arg("catalogue"),tonumber(app.arg("catalogue-page")) or 1);R.toast_time=0
    end
    if app.arg("expeditions") then
        island_with(4);R.on_island=true;R.g.won=true
        if app.arg("resume-expedition") then R.g=rules.game_start(1,123478);R.g.moves=12 end
        R.open_expeditions(tonumber(app.arg("expedition-page")));R.toast_time=0
    end
    if app.arg("replay-victory") then
        island_with(4);R.g=rules.game_start(1,123478);R.g.won=true;R.g.score=5860;R.g.moves=12
        R.on_island=false;R.overlay=R.OV_RESULT;R.toast_time=0
    end
    if app.arg("building-review") then
        local first=((tonumber(app.arg("building-review")) or 1)-1)*4
        R.prog.level, R.prog.wallet = LEVELS, purse(2000, 0, 0, LEVELS * 3)
        R.island.count=0;R.island.open=63
        local spots={vec2(700,1500),vec2(1100,1500),vec2(700,1850),vec2(1100,1850)}
        for k=0,3 do
            local kind=first+k
            if kind<#island.catalogue then
                local ok,spot=R.island:find_spot(kind,spots[k+1])
                assert(ok,"building review requires a valid footprint")
                R.island:add(spot,kind,0)
            end
        end
        R.island_focus(vec2(900,1550),.65)
        R.on_island=true;R.toast_time=0
    end
    if app.arg("catalogue-item") then
        island_with(10);R.on_island=true
        local kind=tonumber(app.arg("catalogue-item")) or 10
        R.prog.wallet=purse(2000,0,0,30)
        R.island_begin(kind,true)
    end
    if app.arg("catalogue-card") then
        island_with(10);R.on_island=true
        local kind=tonumber(app.arg("catalogue-card")) or 10
        local ok,spot=R.island:find_spot(kind,vec2(760,2030))
        assert(ok,"catalogue card needs a valid plot")
        R.inspect_item=R.island:add(spot,kind,0)
        R.inspect=kind;R.overlay=R.OV_WONDER;R.toast_time=0
    end
    if app.arg("art-states") then R.art_review, R.toast_time, R.on_island = true, 0, false end
    if app.arg("hud-states") then R.art_review, R.toast_time, R.on_island = true, 0, false end
    if app.arg("art-board") then
        R.g = rules.game_start(8, 123478)
        R.pending = rules.new_match()
        local cells = {rules.hex_index(-2, 0), rules.hex_index(-1, 0), rules.hex_index(0, 0), rules.hex_index(1, 0), rules.hex_index(2, 0)}
        for k, cell in ipairs(cells) do
            R.g.tiles[cell] = rules.tile(k - 1, k)
            R.g.chain[cell], R.g.ice[cell] = 0, 0
        end
        R.selected, R.hint_a, R.hint_b = rules.hex_index(-2, 1), rules.hex_index(1, 1), rules.hex_index(2, 1)
        R.g.tools = {2, 2, 0}
        R.tool, R.toast_time, R.on_island = 1, 0, false
        R.art_review = true
    end
    if app.arg("present") then R.present_board() end
    if app.arg("mission") then   -- the level's mission banner, as a level starts
        local l = rules.level_of(R.g)
        R.mission(l.lesson, ("%d. %s"):format(R.g.level + 1, l.name))
    end
    if app.arg("kudos") then R.award_kudos(tonumber(app.arg("kudos")) or 2) end
    a = app.arg("dialog")
    if a then   -- guide, pause, failed, finale, a dialogue (intro, mara, tomas, adrian) or a bubble
        R.toast_time = 0
        if a == "intro" then R.queue_story({key = "before-01", lines = R.intro_lines}, true); R.present_board()   -- no board behind the talk yet
        elseif a == "adrian" then island_with(WONDERS); R.on_island = true; R.queue_story({key = "after-30", lines = R.finale}, true)
        elseif a == "mara" then island_with(3); R.on_island = true; story.add({"pip", journey.regions[2], story.SHOUT})
        elseif a == "tomas" then island_with(2); R.on_island = true; story.say("noelle", R.wonders[2].about)
        elseif a == "bubble" then
            island_with(2); R.on_island = true
            R.bubble_wonder, R.bubble_text, R.bubble_time = 1, "A little more Christmas magic!", 3.5
            R.island_focus(R.island.items[2].pos, .8)
        else
            R.overlay = a == "guide" and R.OV_GUIDE or a == "pause" and R.OV_PAUSE or a == "failed" and R.OV_FAILED or R.OV_FINALE
            if R.overlay == R.OV_FINALE then island_with(WONDERS); R.prog.level = LEVELS; R.on_island = true end
        end
    end
    local beat_key = app.arg("story-beat")   -- --story-beat KEY [--story-line N]: preview a scene from its Nth line
    if beat_key then
        local beat = assert(journey.find(beat_key), "unknown story beat")
        island_with(journey.earned(beat.level))
        R.on_island, R.overlay, R.intro, R.phase, R.toast_time = true, R.OV_NONE, nil, R.PH_IDLE, 0
        while story.active() do story.next() end
        local lines = {}
        for i = tonumber(app.arg("story-line")) or 1, #beat.lines do lines[#lines + 1] = beat.lines[i] end
        R.queue_story({key = beat.key, lines = lines}, true)
    end
    -- A debug screen may have replaced the board, or shown something else instead.
    if R.intro then
        if R.phase == R.PH_PRESENT and R.overlay == R.OV_NONE and not R.art_review then R.present_board()
        else
            R.intro = nil
            if R.phase == R.PH_PRESENT then R.phase = R.PH_IDLE end
        end
    end
    if R.overlay ~= R.OV_NONE and not app.arg("reel") then R.modal_for = R.overlay; R.open_dialog(true) end   -- stills show dialogs settled
end

local function init()
    if app.arg("cell-mask") then return end
    R.font = R.skin:font("lilita")
    story.setup(R.cast, story_style{text = R.speech_style(21), name = R.pal(R.PAL_CREAM, 15), bubble = rgba(255, 246, 222, 252),
                                  edge = rgba(102, 68, 39), dim = rgba(5, 22, 22, 150), backdrop_blur = 7, portrait_height = .34, centered = true, skip = "SKIP"})
    local board_skin = require("art").skin()
    R.backdrop = board_skin.background
    R.scenes[1], R.scenes[2] = board_skin["scene-1"] or R.backdrop, board_skin["scene-2"] or R.backdrop
    -- match pieces: the Relics pack, or an optional art pack (--tiles / ?tiles=jewels|resources)
    local tiles = "festive"
    for i = 0, rules.COLORS - 1 do R.relics[i + 1] = board_skin[(app.arg("default-match3") and "kind-" or tiles .. "-") .. i] end
    R.board_art = require("art").load()
    R.hud_art = require("art").load_hud()
    R.life_art = texture.load("expedition-hud/life.png")
    if app.arg("art-states") then
        R.art_packs = {}
        for _, pack in ipairs({"festive"}) do
            R.art_packs[pack] = {}
            for k = 0, rules.COLORS - 1 do R.art_packs[pack][k + 1] = board_skin[(app.arg("default-match3") and "kind-" or pack .. "-") .. k] end
        end
    end
    R.vfx_init()
    R.island = city.new()
    island.island_setup(R.island)
    R.island.draw_over = R.draw_markers
    R.buildings = R.island.defs   -- with the sprites loaded
    R.wonders = {}
    for i=1,WONDERS do R.wonders[i]=R.buildings[i] end

    R.sound = true
    R.inspect, R.zone_card = -1, -1
    R.test_mode = app.arg("smoke") ~= nil or app.arg("shot") ~= nil or app.arg("fresh") ~= nil
    R.quiet = app.arg("shot") ~= nil   -- stills skip the story unless asked for (--dialog)
    R.bubble_wonder = -1
    R.prog = {level = 0, seed = 782341, wallet = purse(), lives = rules.LIVES, life_at = 0, story_seen = {}}
    if not app.arg("smoke") then save.read("progress", serialize) end
    if app.arg("empty-lives") then
        R.prog.lives, R.prog.life_at = 0, app.clock() + rules.LIFE_INTERVAL
    end
    R.story_current, R.story_preview = nil, false
    R.layout()
    if not R.start_level() then
        R.reset_board(rules.game_start(math.min(R.prog.level, LEVELS - 1), R.prog.seed))
        R.g.lost, R.g.life_paid = true, true
        R.on_island = true
    end
    if R.prog.level>=LEVELS then R.g.won=true end -- no unfinished attempt is created at campaign completion
    if journey.earned(R.prog.level) > island.wonder_count(R.island) or R.prog.level >= LEVELS then R.on_island = true end
    if R.needs_relocation then
        R.on_island=true;R.notice("Some buildings need a new spot. Hold one to move it.")
    end
    if not app.arg("smoke") then R.on_island = true end
    debug_screens()
end

return {
    title = "Christmas Market - Winter Wishes",
    id = "christmas-market",
    design = size2(R.SCREEN_W, R.SCREEN_H),
    fixed = true,
    max_aspect = 2.2,   -- tall phones (19.5:9) get a taller screen, not bars
    clear = rgba(9, 33, 31),
    init = init,
    frame = frame,
}
