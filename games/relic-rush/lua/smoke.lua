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
local function press_tile(key)
    local node = R.catalogue_tile(key)
    if node then app.inject_click(R.catalogue_form.boxes[node.id]:center()) end
    return node
end
local function press_row(form, key, id)
    for _, node in pairs(form.nodes) do
        if node.item_key == key and node.local_id == id then
            app.inject_click(form.boxes[node.id]:center())
            return node
        end
    end
end

-- --smoke --campaign: all thirty expeditions through the real result, Claim,
-- region, placement, dialogue and Play controls. Each board's goals are met
-- before one real swap, so this checks the flow; the extended greedy-bot
-- rules test checks that the boards themselves can be won.
local played = {}
local function campaign()
    local journey = require("journey")
    if frames > 16000 then
        error(("campaign smoke stalled at level %d (overlay %d, island %s, story %s)"):format(
            R.prog.level, R.overlay, tostring(R.on_island), table.concat(played, " ")))
    end
    if R.diving() then return end   -- the town HUD, Confirm included, is not drawn during the dive
    if wait > 0 then wait = wait - 1; return end
    wait = 2
    if story.active() then
        local b = R.story_current
        if b and played[#played] ~= b.key then played[#played + 1] = b.key end
        app.inject_click(vec2(240, 300)); return
    end
    if R.mission_banner and not R.on_island and R.overlay == R.OV_NONE then   -- a tap sends the mission banner on
        if R.mission_banner.t > .2 and not R.mission_banner.skipped then app.inject_click(vec2(240, 300)); R.mission_banner.skipped = true end
        return
    end
    local c = R.island
    if R.overlay == R.OV_FINALE then
        local want = {}
        for _, b in ipairs(journey.beats) do want[#want + 1] = b.key end
        assert(table.concat(played, " ") == table.concat(want, " "),
               "campaign smoke: beats played out of order: " .. table.concat(played, " "))
        for _, key in ipairs(want) do assert(R.prog.story_seen[key], "campaign smoke: unacknowledged beat " .. key) end
        assert(R.prog.story_choices["after-10"] == 1, "campaign smoke: Mara answered the signal")
        assert(R.prog.level == rules.LEVELS and island.wonder_count(c) == island.WONDERS and c.open == 63,
               "campaign smoke: thirty clears restore every wonder and open every region")
        print(("campaign smoke passed: %d expeditions, %d story beats, %d wonders, every region in %d frames"):format(
            R.prog.level, #played, island.wonder_count(c), frames))
        app.quit()
    elseif R.overlay == R.OV_STORY_CHOICE then
        local box = R.choice_form.boxes["1"]
        if box then app.inject_click(box:center()); wait = 10 end
    elseif R.overlay == R.OV_RESULT then
        if R.dialog_settled() then app.inject_click(rect(76, 660, 328, 56):center() + vec2(0, R.drop / 2)); wait = 20 end
    elseif R.overlay == R.OV_ZONE then
        if R.dialog_settled() then app.inject_click(rect(72, 487, 336, 47):center() + vec2(0, R.drop / 2)); wait = 20 end
    elseif c.placing >= 0 then
        app.inject_click(R.placement_form.boxes.confirm:center()); wait = 10
    elseif R.on_island and R.overlay == R.OV_NONE then
        local z = c:next_zone(R.prog.wallet)
        if z >= 0 and c:zone_available(z, R.prog.wallet) then R.expand(); wait = 10
        elseif island.wonder_count(c) < journey.earned(R.prog.level) then R.island_begin(island.wonder_count(c), true)
        elseif R.prog.level < rules.LEVELS then
            app.inject_click(R.town.buttons.play); wait = 10
        end
    elseif not R.on_island and R.overlay == R.OV_NONE and R.phase == R.PH_IDLE and R.selected < 0 then
        local g, l = R.g, rules.level_of(R.g)
        for i = 0, rules.CELLS - 1 do
            g.ice[i], g.chain[i], g.soil[i], g.stone_hp[i], g.crate_hp[i], g.hazard[i] = 0, 0, 0, 0, 0, 0
            if g.tiles[i].kind == rules.DELIVERY then
                -- The smoke tests progression, so complete delivery while preserving
                -- a stable match-free starting board for the next real swap.
                local match = rules.new_match()
                for kind = 0, rules.COLORS - 1 do
                    g.tiles[i] = rules.tile(kind)
                    rules.game_matches(g, match, -1)
                    if match.hits == 0 then break end
                end
                assert(match.hits == 0, "campaign smoke cannot replace delivered token")
            end
        end
        for _, object in ipairs(g.objects) do object.state = "revealed" end
        g.discovered, g.delivered = #g.objects, g.delivery_total
        g.score, g.relics, g.dug, g.obstacles, g.carpeted = l.score, l.relics, g.initial_soil, 0, g.carpet_total
        local ok, a, b = rules.game_hint(g)
        assert(ok, "campaign smoke needs a legal move")
        app.inject_click(R.cell_pos(a)); partner = b
    elseif partner >= 0 and R.selected >= 0 and R.phase == R.PH_IDLE then
        app.inject_click(R.cell_pos(partner)); partner = -1
    end
end

-- Every guide topic from the screen's data source is built, and the list
-- lays out its visible rows (it skips the ones scrolled out of view).
local function guide_laid_out()
    local rows = R.guide_form.nodes.topics.children
    return #rows > 0 and #rows == #R.guide_entries and rows[1].box ~= nil and rows[1].box.h > 0
end
function R.smoke()
    frames = frames + 1
    if app.arg("campaign") then return campaign() end
    if app.arg("empty-lives") then
        assert(R.g and R.on_island and R.prog.lives==0,"empty-life load must keep a valid, inert island view")
        if frames==4 then app.inject_click(R.town.buttons.play) end
        if frames==10 then app.quit() end
        return
    end
    if frames > 8000 or R.g.lost then
        error(("smoke test failed at stage %d (overlay %d, level %d)"):format(stage, R.overlay, R.g.level))
    end
    if R.diving() then return end   -- the town <-> board dive takes no input
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
    if R.mission_banner and not R.on_island and R.overlay == R.OV_NONE then   -- a tap sends the mission banner on
        if R.mission_banner.t > .2 and not R.mission_banner.skipped then app.inject_click(vec2(240, 300)); R.mission_banner.skipped = true end
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
        app.inject_click(R.board_pause:point(vec2(.1, .5))); stage = -3   -- enlarged Pause's left edge, outside its old touch area
    elseif stage == -3 and R.overlay == R.OV_PAUSE and R.dialog_settled() then   -- Sound off, then on again
        smoke_sound = R.sound
        app.inject_click(R.pause_form.boxes.sound:center() + vec2(0, R.drop / 2)); stage = -4
    elseif stage == -4 then
        assert(R.sound == not smoke_sound and R.overlay == R.OV_PAUSE, "smoke: the Sound checkbox toggles sound")
        app.inject_click(R.pause_form.boxes.sound:center() + vec2(0, R.drop / 2)); stage = -5
    elseif stage == -5 then
        assert(R.sound == smoke_sound, "smoke: the Sound checkbox toggles back")
        app.inject_click(R.pause_form.boxes.guide:center() + vec2(0, R.drop / 2)); stage = -1
    elseif stage == -1 and R.overlay == R.OV_GUIDE and R.dialog_settled() then
        local done = R.guide_form.boxes.done
        assert(done and guide_laid_out(), "smoke: guide data source was not laid out")
        app.inject_click(done:center() + vec2(0, R.drop / 2)); stage = 0
    elseif stage == 0 then
        if R.overlay == R.OV_RESULT then
            if R.dialog_settled() then app.inject_click(rect(76, 660, 328, 56):center() + vec2(0, R.drop / 2)); stage = 1 end
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
            assert(gain >= 60 and gain <= 100 and R.prog.wallet[4] == 3 and R.prog.wallet[5] == 0 and island.wonder_count(R.island) == 1,
                   "replay must pay only Gold without changing discoveries or restoration")
            app.inject_click(R.town.buttons.play); stage = 5; return
        end
        app.inject_click(R.town.buttons.build); stage = 2   -- CHOOSE A LOCATION
    elseif stage == 2 and R.overlay == R.OV_SHOP then
        press_tile("camp");stage=3
    elseif stage == 3 and R.island.placing >= 0 then
        app.inject_click(R.placement_form.boxes.confirm:center()); stage = 4   -- PLACE & BUILD
    elseif stage == 4 and R.island.placing < 0 and R.overlay == R.OV_NONE then
        if R.island.count ~= 1 then error("smoke: the wonder was not built") end
        move = city.move_test(R.island, {
            look = function(at) R.island_focus(at - vec2(0, 80), math.max(.65, R.island.cam.zoom)) end,
            wallet = function() return R.prog.wallet[rules.GOLD] end,
            cancel = function() app.inject_click(R.placement_form.boxes.cancel:center()) end,
            confirm = function() app.inject_click(R.placement_form.boxes.confirm:center()) end,
            offset = vec2(240, 0),
        })
        stage = 6
    elseif stage == 6 then   -- pan, hold to lift, drag, cancel, then confirm
        if not move() then R.open_catalogue("building"); shop.categories = 0; stage = 20 end
    elseif stage == 20 and R.overlay == R.OV_SHOP then
        if shop.categories < 2 then
            app.inject_click(R.catalogue_form.boxes.category_next:center())
            shop.categories = shop.categories + 1
        else stage = 21 end
    elseif stage == 21 and R.overlay == R.OV_SHOP then
        assert(R.catalogue_tile("shrub"), "category source must refresh")
        shop.gold = R.prog.wallet[1]
        local node = press_tile("shrub")
        assert(node and select(2, R.catalogue_tile("shrub")).available, "smoke: starter decoration should be affordable")
        stage = 22
    elseif stage == 22 and R.island.placing >= 0 then
        assert(R.island.placing == 37, "catalogue action lost its stable item key")
        app.inject_click(R.placement_form.boxes.cancel:center()); stage = 23
    elseif stage == 23 and R.island.placing < 0 then
        assert(R.island.count == 1 and R.prog.wallet[1] == shop.gold, "cancelled purchase changed save state")
        R.open_catalogue(); stage = 24
    elseif stage == 24 and R.overlay == R.OV_SHOP then
        if press_tile("shrub") then stage = 25 end
    elseif stage == 25 and R.island.placing >= 0 then
        app.inject_click(R.placement_form.boxes.confirm:center()); stage = 26
    elseif stage == 26 and R.island.placing < 0 then
        assert(R.island.count == 2 and island.wonder_count(R.island) == 1, "decoration changed campaign restoration count")
        assert(R.prog.wallet[1] == shop.gold - 15, "purchase must charge once")
        local c = R.island
        app.inject_click(c.cam:rect_to_screen(c:sprite_rect(c.items[2])):point(vec2(.5, .65))); stage = 27
    elseif stage==27 and R.overlay==R.OV_NONE then
        assert(R.town.bubble and R.town.bubble.item==1 and R.town.bubble.text:find("Round shrub",1,true),"tap shows the purchased building's name and subtitle")
        R.island_begin(37,true,1);stage=28
    elseif stage == 28 and R.island.placing >= 0 then
        assert(R.island.moving == 1 and R.island.placing == 37, "details must move the purchased instance")
        app.inject_click(R.placement_form.boxes.cancel:center()); stage = 29
    elseif stage == 29 and R.island.placing < 0 then
        app.inject_click(R.town.buttons.middle); stage = 30
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
        app.inject_click(R.board_pause:center()); stage = 33
    elseif stage == 33 and R.overlay == R.OV_PAUSE and R.dialog_settled() then
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
        app.inject_click(R.board_pause:center()); stage = 35
    -- Pause > Restart asks first: Keep playing returns to Pause, Restart starts over.
    elseif stage == 35 and R.overlay == R.OV_PAUSE and R.dialog_settled() then
        assert(R.pause_form.nodes.sound and R.pause_form.nodes.motion, "pause groups the Sound and Reduce motion checkboxes")
        app.inject_click(R.pause_form.boxes.restart:center() + vec2(0, R.drop / 2)); stage = 36
    elseif stage == 36 and R.overlay == R.OV_CONFIRM and R.dialog_settled() then
        app.inject_click(R.confirm_form.boxes.cancel:center() + vec2(0, R.drop / 2)); stage = 37
    elseif stage == 37 and R.overlay == R.OV_PAUSE and R.dialog_settled() then
        assert(R.g == shop.resume_game and R.g.score > 0, "Keep playing must not restart")
        app.inject_click(R.pause_form.boxes.restart:center() + vec2(0, R.drop / 2)); stage = 38
    elseif stage == 38 and R.overlay == R.OV_CONFIRM and R.dialog_settled() then
        app.inject_click(R.confirm_form.boxes.confirm:center() + vec2(0, R.drop / 2)); stage = 39
    elseif stage == 39 and R.overlay == R.OV_NONE then
        assert(not R.on_island and R.g ~= shop.resume_game and R.g.level == 0 and R.g.score == 0
               and R.g.moves == rules.level_of(R.g).moves and R.selected < 0 and R.tool < 0
               and R.phase == R.PH_IDLE and R.shake == 0,
               "restart must create a fresh attempt of the same expedition")
        shop.resume_game, shop.resume_moves = R.g, R.g.moves
        app.inject_click(R.board_pause:center()); stage = 40
    -- Pause > Quit to island keeps the board and pays nothing; the browser resumes it.
    elseif stage == 40 and R.overlay == R.OV_PAUSE and R.dialog_settled() then
        app.inject_click(R.pause_form.boxes.quit:center() + vec2(0, R.drop / 2)); stage = 41
    elseif stage == 41 and R.on_island and R.overlay == R.OV_NONE then
        assert(R.g == shop.resume_game and not R.g.won and not R.g.lost, "Quit must keep the unfinished board")
        assert(R.prog.wallet[1] == shop.pause_gold and R.prog.level == 1
               and R.prog.wallet[4] == 3 and R.prog.wallet[5] == 0 and island.wonder_count(R.island) == 1,
               "restart and quit must not award rewards or change restoration progress")
        app.inject_click(vec2(440, 58)); stage = 42   -- enlarged city Pause's lower edge
    elseif stage == 42 and R.overlay == R.OV_PAUSE and R.dialog_settled() then
        assert(not R.pause_form.boxes.restart and not R.pause_form.boxes.quit, "island pause must hide expedition-only actions")
        app.inject_click(R.pause_form.boxes.resume:center() + vec2(0, R.drop / 2)); stage = 43
    elseif stage == 43 and R.overlay == R.OV_NONE then
        app.inject_click(R.town.buttons.middle); stage = 44
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
