-- smoke.lua — the --smoke run: opens and closes the guide, plays level one
-- through injected clicks, claims the reward, builds the first wonder, runs
-- the engine's pickup-and-move check, buys and cancels a decoration through
-- the catalogue, starts level two from Play, checks that an unfinished board
-- hides the island, and resumes it from Play after Quit.
local R = require("state")
local rules = require("rules")
local island = require("island")

local stage, frames, wait, partner = -2, 0, 0, -1
local smoke_sound   -- the sound setting before the smoke run toggles it
local move             -- the engine's pickup/move check, while it runs
local shop = {}        -- what the catalogue and resume stages remember

-- Press a list row's button by its stable item key.
local function press_tile(key)
    local node = R.catalogue_tile(key)
    local box = node and R.catalogue_form.boxes[node.id]
    if box then app.inject_click(box:center()); return node end
end

-- --smoke --campaign: all five square chapters (a hundred expeditions), through the real result, Claim,
-- region, placement and Play controls. Each board's goals are met
-- before one real swap, so this checks the flow; the extended greedy-bot
-- rules test checks that the boards themselves can be won.
local last_purchase = 0
for n, step in ipairs(island.ladder) do
    if step.after <= rules.LEVELS then last_purchase = n end
end
local function campaign()
    if frames > 160000 then   -- a hundred boards of up to 108 cells
        error(("campaign smoke stalled at level %d (overlay %d, island %s)"):format(
            R.prog.level, R.overlay, tostring(R.on_island)))
    end
    if R.diving() then return end   -- the town HUD, Confirm included, is not drawn during the dive
    if wait > 0 then wait = wait - 1; return end
    wait = 2
    assert(not story.active(), "Relic Rush uses board hints for its tutorial")
    if R.mission_banner and not R.on_island and R.overlay == R.OV_NONE then   -- a tap sends the mission banner on
        if R.mission_banner.t > .2 and not R.mission_banner.skipped then app.inject_click(vec2(240, 300)); R.mission_banner.skipped = true end
        return
    end
    local c = R.island
    if R.overlay == R.OV_EPOCH and R.dialog_settled() then
        assert(c:zone_open(R.epoch_award), "the epoch award opens its district")
        app.inject_click(R.epoch_form.boxes.back:center() + vec2(0, R.drop / 2)); wait = 10
    elseif R.overlay == R.OV_COMPLETE and R.dialog_settled() then
        app.inject_click(R.complete_form.boxes.back:center() + vec2(0, R.drop / 2)); wait = 10
    elseif R.prog.level == rules.LEVELS and island.campaign_count(c) == last_purchase
        and R.on_island and R.overlay == R.OV_NONE then
        print(("campaign smoke passed: %d expeditions, %d restorations"):format(
            R.prog.level, island.campaign_count(c)))
        app.quit()
    elseif R.overlay == R.OV_RESULT then
        if R.dialog_settled() and R.result_form.boxes.claim then app.inject_click(R.result_form.boxes.claim:center() + vec2(0, R.drop / 2)); wait = 20 end
    elseif R.overlay == R.OV_SHOP then
        local kind = island.next_step(c, R.prog.level)
        if press_tile(island.buildings[kind + 1].key) then wait = 10 end
    elseif R.overlay == R.OV_WONDER then
        if R.dialog_settled() then app.inject_click(R.wonder_form.boxes.action:center()); wait = 10 end
    elseif c.placing >= 0 then
        app.inject_click(R.placement_form.boxes.confirm:center()); wait = 10
    elseif R.on_island and R.overlay == R.OV_NONE then
        local kind = island.next_step(c, R.prog.level)
        if kind then
            app.inject_click(R.town.buttons.build); wait = 10
        elseif R.prog.level < rules.LEVELS then
            app.inject_click(R.town.buttons.play); wait = 10
        end
    elseif not R.on_island and R.overlay == R.OV_NONE and R.phase == R.PH_IDLE and R.selected < 0 then
        local g = R.g
        -- This scripted path skips most matches and exercises the real purchase UI.
        local income = purse()
        for _, step in ipairs(island.ladder) do
            if step.after == g.level + 1 then income = income + R.buildings[step.kind + 1].cost end
        end
        g.earnings = {income[1], income[2], income[3]}
        for i = 0, rules.CELLS - 1 do
            g.ice[i], g.chain[i], g.stone_hp[i], g.oil[i] = 0, 0, 0, 0
        end
        g.obstacles, g.oil_left = 0, 0
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
    if frames > 8000 or R.g.lost then
        error(("smoke test failed at stage %d (overlay %d, level %d)"):format(stage, R.overlay, R.g.level))
    end
    if R.diving() then return end   -- the town <-> board dive takes no input
    if R.overlay == R.OV_SHOP and not R.dialog_settled() then return end
    if wait > 0 then   -- one click per few frames, so each press and release is its own frame
        wait = wait - 1
        return
    end
    wait = 3
    assert(not story.active(), "Relic Rush uses board hints for its tutorial")
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
        assert(not R.mission_banner, "smoke: the blue plaques replace the mission banner")
        app.inject_click(R.board_pause:point(vec2(.1, .5))); stage = -3
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
            if R.modal_for == R.OV_RESULT and R.dialog_settled() then
                local boxes = R.result_form.boxes
                assert(not boxes.next_step and boxes.claim.y - boxes.resources:max().y <= 20,
                    "claim follows the last visible result row without a reserved gap")
                app.inject_click(R.result_form.boxes.claim:center() + vec2(0, R.drop / 2)); stage = 1
            end
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
        assert(R.town.navigation.nodes.play.level == 2, "smoke: Play shows level 2")
        -- The balance tests measure income; this run only needs the flow, so a
        -- short wallet is topped up to the price of the well and the shrub.
        local cost = island.wonders[1].cost + R.buildings[island.kinds.shrub + 1].cost
        for slot = 1, 3 do R.prog.wallet[slot] = math.max(R.prog.wallet[slot], cost[slot]) end
        app.inject_click(R.town.buttons.build); stage = 101
    elseif stage == 101 and R.overlay == R.OV_SHOP then
        if press_tile("well") then stage = 2 end
    elseif stage == 2 and R.overlay == R.OV_WONDER and R.dialog_settled() then
        assert(R.inspect == island.kinds.well and R.wonder_form:get("action") == R.words.card.build,
            "Build opens the funded Well")
        app.inject_click(R.wonder_form.boxes.action:center()); stage = 3
    elseif stage == 3 and R.island.placing >= 0 then
        app.inject_click(R.placement_form.boxes.confirm:center()); stage = 4   -- PLACE & BUILD
    elseif stage == 4 and R.island.placing < 0 and R.overlay == R.OV_NONE then
        if R.island.count ~= 2 then error("smoke: the wonder was not built") end   -- beside the crew's tent
        R.open_catalogue(); shop.categories = 0; stage = 20
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
        assert(R.island.count == 2 and R.prog.wallet[1] == shop.gold, "cancelled purchase changed save state")
        R.open_catalogue(); stage = 24
    elseif stage == 24 and R.overlay == R.OV_SHOP then
        if press_tile("shrub") then stage = 25 end
    elseif stage == 25 and R.island.placing >= 0 then
        app.inject_click(R.placement_form.boxes.confirm:center()); stage = 26
    elseif stage == 26 and R.island.placing < 0 then
        assert(R.island.count == 3 and island.wonder_count(R.island) == 1, "decoration changed campaign restoration count")
        assert(R.prog.wallet[1] == shop.gold - 15, "purchase must charge once")
        move = city.move_test(R.island, {
            item = 2,   -- the Well: the first restoration moves like any other building
            look = function(at) R.island_focus(at - vec2(0, 80), math.max(.65, R.island.cam.zoom)) end,
            wallet = function() return R.prog.wallet[rules.GOLD] end,
            cancel = function() app.inject_click(R.placement_form.boxes.cancel:center()) end,
            confirm = function() app.inject_click(R.placement_form.boxes.confirm:center()) end,
            offset = vec2(240, 0),
        })
        stage = 6
    elseif stage == 6 then
        if move() then return end
        R.island_focus(R.island.items[3].pos - vec2(0, 80), R.island.cam.zoom); stage = 7   -- the camera followed the Well
    elseif stage == 7 then
        local c = R.island
        app.inject_click(c.cam:rect_to_screen(c:sprite_rect(c.items[3])):point(vec2(.5, .65))); stage = 27
    elseif stage==27 and R.overlay==R.OV_NONE then
        assert(R.town.bubble and R.town.bubble.item==2 and R.town.bubble.text:find("Round shrub",1,true),"tap shows the purchased building's name and subtitle")
        R.island_begin(37,true,2);stage=28
    elseif stage == 28 and R.island.placing >= 0 then
        assert(R.island.moving == 2 and R.island.placing == 37, "details must move the purchased instance")
        app.inject_click(R.placement_form.boxes.cancel:center()); stage = 29
    elseif stage == 29 and R.island.placing < 0 then
        shop.wallet = purse(table.unpack(R.prog.wallet))
        app.inject_click(R.town.buttons.play); stage = 31
    elseif stage == 31 and not R.on_island and R.overlay == R.OV_NONE then
        assert(R.g.level == 1, "smoke: Play starts the next expedition")
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
        local capsules = R.header_capsules()
        assert(#capsules == 3, "the shared header shows only coins, supplies and food")
        local boxes = R.town.header_form.boxes
        assert(boxes.leading and boxes.leading:max().x <= boxes.cap1.x and boxes.cap3 and not boxes.menu
            and boxes.leading:center().y == boxes.cap3:center().y,
            "the board header only shows Moves and resources")
        for i, slot in ipairs{rules.GOLD, rules.SUPPLIES, rules.PROVISIONS} do
            assert(capsules[i].slot == slot and R.prog.wallet[slot] == shop.wallet[slot]
                and tonumber(capsules[i].value) == R.prog.wallet[slot] + R.g.earnings[slot],
                "smoke: the shared header previews live match earnings without banking them")
            local box = boxes["cap" .. i]
            for kind, piece in pairs(R.g.resource_yields) do
                if piece.slot == slot then
                    local target = R.resource_target(kind)
                    assert(target and target.x >= box.x and target.x < box.x + box.w,
                        "match particles fly to the displayed currency")
                end
            end
        end
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
        assert(not R.on_island and R.g ~= shop.resume_game and R.g.level == 1 and R.g.score == 0
               and R.g.moves == rules.level_of(R.g).moves and R.selected < 0 and R.tool < 0
               and R.phase == R.PH_IDLE and R.shake == 0,
               "restart must create a fresh attempt of the same expedition")
        shop.resume_game, shop.resume_moves = R.g, R.g.moves
        app.inject_click(R.board_pause:center()); stage = 40
    -- Pause > Quit to island keeps the board and pays nothing; Play resumes it.
    elseif stage == 40 and R.overlay == R.OV_PAUSE and R.dialog_settled() then
        app.inject_click(R.pause_form.boxes.quit:center() + vec2(0, R.drop / 2)); stage = 41
    elseif stage == 41 and R.on_island and R.overlay == R.OV_NONE then
        assert(R.g == shop.resume_game and not R.g.won and not R.g.lost, "Quit must keep the unfinished board")
        assert(R.prog.wallet[1] == shop.pause_gold and R.prog.level == 1
               and R.prog.wallet[4] == 1 and R.prog.wallet[5] == 0 and island.wonder_count(R.island) == 1,
               "restart and quit must not award rewards or change restoration progress")
        app.inject_click(R.town.buttons.pause); stage = 42
    elseif stage == 42 and R.overlay == R.OV_PAUSE and R.dialog_settled() then
        assert(not R.pause_form.boxes.restart and not R.pause_form.boxes.quit, "island pause must hide expedition-only actions")
        app.inject_click(R.pause_form.boxes.close:center() + vec2(0, R.drop / 2)); stage = 43
    elseif stage == 43 and R.overlay == R.OV_NONE then
        assert(R.town.navigation.nodes.play.level == 2, "smoke: Play still shows level 2 after quitting")
        app.inject_click(R.town.buttons.build); stage = 143
    elseif stage == 143 and R.overlay == R.OV_SHOP then
        if press_tile("log_cabin") then stage = 44 end
    elseif stage == 44 and R.overlay == R.OV_WONDER and R.dialog_settled() then
        local card = R.wonder_form.boxes
        assert(R.inspect == island.kinds.log_cabin and card.price and card.close and not card.action,
            "an underfunded project opens its own resource figures and closes from the corner")
        assert(R.wonder_form:get("price_caption") == R.words.card.missing, "an underfunded project shows its shortfall")
        app.inject_click(card.close:center() + vec2(0, R.drop / 2)); stage = 45
    elseif stage == 45 and R.on_island and R.overlay == R.OV_NONE then
        app.inject_click(R.town.buttons.play); stage = 46
    elseif stage == 46 and not R.on_island and R.overlay == R.OV_NONE then
        assert(R.g == shop.resume_game and R.g.moves == shop.resume_moves, "returning from island must preserve the suspended attempt")
        print("smoke test passed: sound checkbox -> guide -> puzzle -> claim -> restoration -> pan/move -> catalogue purchase/cancel -> level 2 from Play -> pause/background resume -> restart (cancel, confirm) -> quit to island -> island pause -> next restoration card -> resume expedition")
        app.quit()
    end
end

return R
