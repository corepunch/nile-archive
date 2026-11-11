-- smoke.lua — the --smoke run: opens Pause (Sound, Restart and Quit present),
-- the guide, plays level one through injected clicks, claims the reward,
-- builds the first stall, runs the engine's pickup-and-move check, buys and
-- cancels a decoration through the catalogue, taps it for its bubble, replays
-- a winter wish for Gold only, checks that an unfinished board hides the
-- market, and enters level two. --smoke --campaign is campaign_smoke.lua.
local R = require("state")
local rules = require("rules")
local island = require("island")

local smoke_stage, smoke_frames, smoke_wait, smoke_partner = -2, 0, 0, -1
local smoke_move={}
local smoke_city_move
local function press_tile(key)
    local node = R.catalogue_tile(key)
    if node then app.inject_click(R.catalogue_form.boxes[node.id]:center()) end
    return node
end
function R.smoke()
    smoke_frames = smoke_frames + 1
    if smoke_frames > 8000 or R.g.lost then
        error(("smoke test failed at stage %d (overlay %d, level %d)"):format(smoke_stage,R.overlay,R.g.level))
    end
    if R.diving() then return end   -- the town <-> board dive takes no input
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
        if R.mission_banner.t > .2 and not R.mission_banner.skipped then app.inject_click(vec2(240, 300)); R.mission_banner.skipped = true end
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
        assert(R.pause_form.boxes.restart and R.pause_form.boxes.quit, "Pause on a board offers Restart and Quit")
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
            app.inject_click(R.town.buttons.play);smoke_stage=5;return
        end
        app.inject_click(R.town.buttons.build); smoke_stage = 2   -- Build: the earned stall
    elseif smoke_stage == 2 and R.overlay == R.OV_SHOP then
        assert(press_tile("arch"), "smoke: the earned stall is in the shop"); smoke_stage = 3
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
        assert(R.catalogue_tile("firs") and not R.catalogue_tile("arch"),"category source must refresh")
        local node,record=R.catalogue_tile("firs")
        assert(node and record.available,"smoke: starter decoration should be affordable")
        smoke_move.shop_gold=R.prog.wallet[1]
        app.inject_click(f.boxes[node.id]:center());smoke_stage=22
    elseif smoke_stage==22 and R.island.placing>=0 then
        assert(R.island.placing==10,"catalogue action lost its stable item key")
        app.inject_click(R.placement_form.boxes.cancel:center());smoke_stage=23
    elseif smoke_stage==23 and R.island.placing<0 then
        assert(R.island.count==1 and R.prog.wallet[1]==smoke_move.shop_gold,"cancelled purchase changed save state")
        R.open_catalogue();smoke_stage=24
    elseif smoke_stage==24 and R.overlay==R.OV_SHOP then
        local node=R.catalogue_tile("firs")
        if node then app.inject_click(R.catalogue_form.boxes[node.id]:center());smoke_stage=25 end
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
    elseif smoke_stage==27 then   -- a tap names the building in a bubble; no popup opens
        assert(R.overlay==R.OV_NONE and R.town.bubble and R.town.bubble.item==1 and R.town.bubble.text:find(R.buildings[11].name,1,true),
               "tap shows the purchased building's name and words")
        R.island_begin(10,true,1);smoke_stage=28
    elseif smoke_stage==28 and R.island.placing>=0 then
        assert(R.island.moving==1 and R.island.placing==10,"move must lift the purchased instance")
        app.inject_click(R.placement_form.boxes.cancel:center());smoke_stage=29
    elseif smoke_stage==29 and R.island.placing<0 then
        app.inject_click(R.town.buttons.middle);smoke_stage=30
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

return R
