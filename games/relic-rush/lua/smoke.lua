-- smoke.lua — the --smoke run: opens and closes the guide, plays level one
-- through injected clicks, claims the reward, builds the first wonder, runs
-- the engine's pickup-and-move check, buys and cancels a decoration through
-- the catalogue, replays an expedition for Gold only, checks that an
-- unfinished board hides the island, and enters level two.
local R = require("state")
local rules = require("rules")
local island = require("island")

local stage, frames, wait, partner = -2, 0, 0, -1
local smoke_sound   -- the sound setting before the smoke run toggles it
local move             -- the engine's pickup/move check, while it runs
local shop = {}        -- what the catalogue and replay stages remember

-- Press a list row's button by its stable item key.
local function press_row(form, key, id)
    for _, node in pairs(form.nodes) do
        if node.item_key == key and node.local_id == id then
            app.inject_click(form.boxes[node.id]:center())
            return node
        end
    end
end

function R.smoke()
    frames = frames + 1
    if frames > 8000 or R.g.lost then
        error(("smoke test failed at stage %d (overlay %d, level %d)"):format(stage, R.overlay, R.g.level))
    end
    if wait > 0 then   -- one click per few frames, so each press and release is its own frame
        wait = wait - 1
        return
    end
    wait = 3
    if story.active() then   -- tap through the dialogue
        assert(R.phase ~= R.PH_PRESENT or R.intro.t == 0, "smoke: the board fills only after the dialogue")
        app.inject_click(vec2(240, 300))
        return
    end
    -- The board's entrance takes no moves. A tap skips the first; the rest play out.
    if R.phase == R.PH_PRESENT and R.overlay == R.OV_NONE and not R.on_island then
        if not shop.skipped and R.intro.t > 0 then
            app.inject_click(R.cell_pos(rules.hex_center())); shop.skipped = true
        end
        return
    end
    if stage == -2 and R.overlay == R.OV_NONE then
        assert(R.selected < 0 and R.g.moves == rules.level_of(R.g).moves, "smoke: the tap that skips the entrance must not play")
        app.inject_click(vec2(432, 46)); stage = -3
    elseif stage == -3 and R.overlay == R.OV_PAUSE and R.modal_clock > .4 then   -- Sound off, then on again
        smoke_sound = R.sound
        app.inject_click(R.pause_form.boxes.sound:center() + vec2(0, R.drop / 2)); stage = -4
    elseif stage == -4 then
        assert(R.sound == not smoke_sound and R.overlay == R.OV_PAUSE, "smoke: the Sound checkbox toggles sound")
        app.inject_click(R.pause_form.boxes.sound:center() + vec2(0, R.drop / 2)); stage = -5
    elseif stage == -5 then
        assert(R.sound == smoke_sound, "smoke: the Sound checkbox toggles back")
        app.inject_click(R.pause_form.boxes.guide:center() + vec2(0, R.drop / 2)); stage = -1
    elseif stage == -1 and R.overlay == R.OV_GUIDE and R.modal_clock > .4 then
        local done = R.guide_form.boxes.done
        assert(done and #R.guide_form.nodes.topics.children == 5, "smoke: guide data source was not laid out")
        app.inject_click(done:center() + vec2(0, R.drop / 2)); stage = 0
    elseif stage == 0 then
        if R.overlay == R.OV_RESULT then
            if R.modal_clock > 1.4 then app.inject_click(rect(76, 660, 328, 56):center() + vec2(0, R.drop / 2)); stage = 1 end
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
            if a >= 0 then app.inject_click(R.cell_pos(a)); partner = b end
        elseif R.selected >= 0 and R.phase == R.PH_IDLE and partner >= 0 then
            app.inject_click(R.cell_pos(partner))
            partner = -1
        end
    elseif stage == 1 and R.on_island and R.overlay == R.OV_NONE then
        if R.prog.level ~= 1 then error("smoke: the win was not banked") end
        if shop.replay then
            local gain = R.prog.wallet[1] - shop.replay_gold
            assert(gain >= 60 and gain <= 100 and R.prog.wallet[4] == 3 and R.prog.wallet[5] == 1 and island.wonder_count(R.island) == 1,
                   "replay must pay only Gold without changing discoveries or restoration")
            app.inject_click(vec2(240, 856 + R.drop)); stage = 5; return
        end
        app.inject_click(vec2(240, 856 + R.drop)); stage = 2   -- CHOOSE A LOCATION
    elseif stage == 2 and R.overlay == R.OV_WONDER then
        app.inject_click(rect(76, 632, 328, 56):center() + vec2(0, R.drop / 2)); stage = 3
    elseif stage == 3 and R.island.placing >= 0 then
        app.inject_click(vec2(320, 856 + R.drop)); stage = 4   -- PLACE & BUILD
    elseif stage == 4 and R.island.placing < 0 and R.overlay == R.OV_NONE then
        if R.island.count ~= 1 then error("smoke: the wonder was not built") end
        move = city.move_test(R.island, {
            look = function(at) R.island_focus(at - vec2(0, 80), math.max(.65, R.island.cam.zoom)) end,
            wallet = function() return R.prog.wallet[rules.GOLD] end,
            cancel = function() app.inject_click(vec2(100, 856 + R.drop)) end,
            confirm = function() app.inject_click(vec2(320, 856 + R.drop)) end,
            offset = vec2(240, 0),
        })
        stage = 6
    elseif stage == 6 then   -- pan, hold to lift, drag, cancel, then confirm
        if not move() then R.open_catalogue(); shop.categories = 0; stage = 20 end
    elseif stage == 20 and R.overlay == R.OV_SHOP then
        if shop.categories < 2 then
            app.inject_click(R.catalogue_form.boxes.category_next:center())
            shop.categories = shop.categories + 1
        else stage = 21 end
    elseif stage == 21 and R.overlay == R.OV_SHOP then
        assert(R.catalogue_records[1].id == "shrub", "category source must refresh")
        shop.gold = R.prog.wallet[1]
        local node = press_row(R.catalogue_form, "shrub", "buy")
        assert(node and node.enabled, "smoke: starter decoration should be affordable")
        stage = 22
    elseif stage == 22 and R.island.placing >= 0 then
        assert(R.island.placing == 37, "catalogue action lost its stable item key")
        app.inject_click(vec2(100, 856 + R.drop)); stage = 23
    elseif stage == 23 and R.island.placing < 0 then
        assert(R.island.count == 1 and R.prog.wallet[1] == shop.gold, "cancelled purchase changed save state")
        R.open_catalogue(); stage = 24
    elseif stage == 24 and R.overlay == R.OV_SHOP then
        if press_row(R.catalogue_form, "shrub", "buy") then stage = 25 end
    elseif stage == 25 and R.island.placing >= 0 then
        app.inject_click(vec2(320, 856 + R.drop)); stage = 26
    elseif stage == 26 and R.island.placing < 0 then
        assert(R.island.count == 2 and island.wonder_count(R.island) == 1, "decoration changed campaign restoration count")
        assert(R.prog.wallet[1] == shop.gold - 15, "purchase must charge once")
        local c = R.island
        app.inject_click(c.cam:rect_to_screen(c:sprite_rect(c.items[2])):point(vec2(.5, .65))); stage = 27
    elseif stage == 27 and R.overlay == R.OV_WONDER then
        assert(R.inspect == 37 and R.inspect_item == 1, "purchased details confused type and placed item index")
        app.inject_click(R.wonder_form.boxes.action:center() + vec2(0, R.drop / 2)); stage = 28
    elseif stage == 28 and R.island.placing >= 0 then
        assert(R.island.moving == 1 and R.island.placing == 37, "details must move the purchased instance")
        app.inject_click(vec2(100, 856 + R.drop)); stage = 29
    elseif stage == 29 and R.island.placing < 0 then
        app.inject_click(R.island_buttons.expeditions + vec2(0, R.drop)); stage = 30
    elseif stage == 30 and R.overlay == R.OV_EXPEDITIONS then
        shop.replay_gold = R.prog.wallet[1]
        local node = press_row(R.expedition_form, "0", "play")
        assert(node and node.enabled, "completed expedition must be replayable")
        shop.replay = true
        stage = 31
    elseif stage == 31 and not R.on_island then
        shop.resume_game, shop.resume_moves = R.g, R.g.moves
        app.inject_click(vec2(40, 38)); stage = 32
    elseif stage == 32 then
        assert(not R.on_island and R.overlay == R.OV_NONE, "old header corner must not return to the island")
        app.inject_click(vec2(440, 38)); stage = 33
    elseif stage == 33 and R.overlay == R.OV_PAUSE and R.modal_clock > .3 then
        app.inject_click(vec2(12, 220 + R.drop / 2)); stage = 34
    elseif stage == 34 and R.overlay == R.OV_NONE then
        assert(not R.on_island and R.g == shop.resume_game and R.g.moves == shop.resume_moves,
               "background dismissal must resume the same unfinished board")
        shop.pause_gold = R.prog.wallet[1]
        local ok, a, b = rules.game_hint(R.g)
        assert(ok, "restart smoke needs a legal move")
        app.inject_click(R.cell_pos(a)); partner = b; stage = 50
    elseif stage == 50 and R.selected >= 0 then
        app.inject_click(R.cell_pos(partner)); partner = -1; stage = 51
    elseif stage == 51 and R.phase == R.PH_IDLE and R.g.moves < shop.resume_moves then
        assert(R.g.score > 0, "restart smoke must exercise a partly played board")
        app.inject_click(vec2(440, 38)); stage = 35
    -- Pause > Restart asks first: Keep playing returns to Pause, Restart starts over.
    elseif stage == 35 and R.overlay == R.OV_PAUSE and R.modal_clock > .3 then
        assert(R.pause_form.nodes.sound and R.pause_form.nodes.motion, "pause groups the Sound and Reduce motion checkboxes")
        app.inject_click(R.pause_form.boxes.restart:center() + vec2(0, R.drop / 2)); stage = 36
    elseif stage == 36 and R.overlay == R.OV_CONFIRM and R.modal_clock > .3 then
        app.inject_click(R.confirm_form.boxes.cancel:center() + vec2(0, R.drop / 2)); stage = 37
    elseif stage == 37 and R.overlay == R.OV_PAUSE and R.modal_clock > .3 then
        assert(R.g == shop.resume_game and R.g.score > 0, "Keep playing must not restart")
        app.inject_click(R.pause_form.boxes.restart:center() + vec2(0, R.drop / 2)); stage = 38
    elseif stage == 38 and R.overlay == R.OV_CONFIRM and R.modal_clock > .3 then
        app.inject_click(R.confirm_form.boxes.confirm:center() + vec2(0, R.drop / 2)); stage = 39
    elseif stage == 39 and R.overlay == R.OV_NONE then
        assert(not R.on_island and R.g ~= shop.resume_game and R.g.level == 0 and R.g.score == 0
               and R.g.moves == rules.level_of(R.g).moves and R.selected < 0 and R.tool < 0
               and R.phase == R.PH_IDLE and R.shake == 0,
               "restart must create a fresh attempt of the same expedition")
        shop.resume_game, shop.resume_moves = R.g, R.g.moves
        app.inject_click(vec2(440, 38)); stage = 40
    -- Pause > Quit to island keeps the board and pays nothing; the browser resumes it.
    elseif stage == 40 and R.overlay == R.OV_PAUSE and R.modal_clock > .3 then
        app.inject_click(R.pause_form.boxes.quit:center() + vec2(0, R.drop / 2)); stage = 41
    elseif stage == 41 and R.on_island and R.overlay == R.OV_NONE then
        assert(R.g == shop.resume_game and not R.g.won and not R.g.lost, "Quit must keep the unfinished board")
        assert(R.prog.wallet[1] == shop.pause_gold and R.prog.level == 1
               and R.prog.wallet[4] == 3 and R.prog.wallet[5] == 1 and island.wonder_count(R.island) == 1,
               "restart and quit must not award rewards or change restoration progress")
        app.inject_click(vec2(440, 38)); stage = 42
    elseif stage == 42 and R.overlay == R.OV_PAUSE and R.modal_clock > .3 then
        assert(not R.pause_form.boxes.restart and not R.pause_form.boxes.quit, "island pause must hide expedition-only actions")
        app.inject_click(R.pause_form.boxes.resume:center() + vec2(0, R.drop / 2)); stage = 43
    elseif stage == 43 and R.overlay == R.OV_NONE then
        app.inject_click(R.island_buttons.expeditions + vec2(0, R.drop)); stage = 44
    elseif stage == 44 and R.overlay == R.OV_EXPEDITIONS then
        assert(press_row(R.expedition_form, "0", "play"), "the expedition row must offer to continue"); stage = 45
    elseif stage == 45 and not R.on_island and R.overlay == R.OV_NONE then
        assert(R.g == shop.resume_game and R.g.moves == shop.resume_moves, "returning from island must preserve the suspended attempt")
        stage = 0
    elseif stage == 5 and not R.on_island and R.overlay == R.OV_NONE then
        if R.g.level ~= 1 then error("smoke: level two did not start") end
        print("smoke test passed: sound checkbox -> guide -> puzzle -> claim -> restoration -> pan/move -> catalogue purchase/cancel -> replay -> pause/background resume -> restart (cancel, confirm) -> quit to island -> island pause -> resume expedition -> Gold only -> level 2")
        app.quit()
    end
end

return R
