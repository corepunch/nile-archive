-- archive_smoke.lua — the --smoke run: plays chapter one through injected
-- clicks, pans and long-presses the island, cancels and confirms a move and a
-- purchase, then reaches chapter three by finding the second clue and building
-- the temple through real form input. Every step asserts what it expects.
local G = require("archive_state")
local content = require("archive_content")
local economy = require("archive_economy")
local scene = require("archive_scene")
local scenes = content.scenes
local ITEMS, COINS, INFLUENCE = G.ITEMS, G.COINS, G.INFLUENCE
local MODAL_NONE, MODAL_WIN, MODAL_CHAPTERS = G.MODAL_NONE, G.MODAL_WIN, G.MODAL_CHAPTERS

local M = {}

local frames, step = 0, 0
local move = {}   -- the building move in progress: origin, grab offset, destination, coins before

-- Press the Buy button of the catalogue row with this stable item key.
local function buy(key)
    local f = G.spots.build_form
    assert(f, "building catalogue was not drawn")
    for _, node in pairs(f.nodes) do
        if node.item_key == key and node.local_id == "buy" then
            assert(node.enabled, "expected building is not affordable/unlocked")
            app.inject_click(f.boxes[node.id]:center())
            return
        end
    end
    error("building key absent from catalogue")
end

-- Tap the next unfound item of chapter `i`; true while one was left. The
-- picture covers the screen, so an item may start off it or under the HUD:
-- pan to it as a player would, then tap it.
local function find_next(i)
    for item = 1, ITEMS do
        if not G.found[item] then
            local at = G.cam:to_screen(scenes[i].at[item])
            if not app.screen():inflate2(vec2(-110, -110)):contains(at) then
                G.cam = G.cam:look(scenes[i].at[item]):clamp()
                at = G.cam:to_screen(scenes[i].at[item])
            end
            app.inject_click(at)
            return true
        end
    end
    return false
end

-- Press the first building where a player would, looking at it first.
local function press_building()
    local c = G.island
    c.cam = c.cam:look(move.origin - vec2(0, 50))
    move.press = c.cam:rect_to_screen(c:sprite_rect(c.items[1])):point(vec2(.5, .65))
    return c
end

function M.step()
    frames = frames + 1
    if frames > 6000 then error("Nile smoke timed out at step " .. tostring(step)) end
    if frames % 6 ~= 0 then return end
    if story.active() then story.next() return end
    if step == 0 then app.inject_click(G.spots.chapters); step = 1
    elseif step == 1 then
        assert(G.modal == MODAL_CHAPTERS, "chapters button failed")
        app.inject_click(G.spots.play1); step = 2
    elseif step == 2 then
        assert(G.scene == 1 and G.modal == MODAL_NONE, "play button failed")
        app.inject_click(G.cam:to_screen(vec2(640, 470))); step = 3   -- open floor: a miss
    elseif step == 3 then
        assert(scene.found_count() == 0, "a miss found an item")
        step = 4
    elseif step == 4 then
        if not find_next(1) then step = 5 end
    elseif step == 5 then
        assert(G.modal == MODAL_WIN and G.result and G.result.stars >= 1, "no result after every item")
        app.inject_click(G.spots.continue); step = 6
    elseif step == 6 then
        assert(not G.scene and G.wins[1] == 1 and G.stars[1] >= 1, "continue did not bank the chapter")
        assert(G.wallet[INFLUENCE] == 10 and not economy.can_play(G.wins, 10, 2), "scene must leave the building gate intact")
        move.origin, move.coins = G.island.items[1].pos, G.wallet[COINS]
        local c = press_building()
        move.cam = c.cam.center
        app.inject_press(move.press); step = 7
    elseif step == 7 then
        app.inject_move(move.press + vec2(-40, 0)); step = 8
    elseif step == 8 then
        assert(G.island.placing < 0 and G.island.cam.center.x > move.cam.x, "ordinary building drag must pan")
        app.inject_release(move.press + vec2(-40, 0)); move.pass = 1; step = 9
    elseif step == 9 then
        local c = press_building()
        move.grab = move.origin - c.cam:to_world(move.press)
        app.inject_press(move.press); move.hold = app.time(); step = 10
    elseif step == 10 and app.time() - move.hold > .65 then
        local c = G.island
        assert(c.moving == 0 and c.held, "long press must lift the building")
        local ok, spot = c:find_spot(c.placing, move.origin + vec2(200, 0))
        assert(ok, "no move destination")
        move.destination = spot
        move.drop = c.cam:to_screen(spot - move.grab)
        app.inject_move(move.drop); step = 11
    elseif step == 11 then
        app.inject_release(move.drop); step = 12
    elseif step == 12 then
        local c = G.island
        assert(not c.held and c.placing >= 0 and c.items[1].pos:dist(move.origin) < .01 and G.wallet[COINS] == move.coins,
               "release must leave an uncommitted preview")
        app.inject_click(move.pass == 1 and G.spots.move_cancel or G.spots.move_confirm); step = 13
    elseif step == 13 then
        local c = G.island
        assert(c.placing < 0 and G.wallet[COINS] == move.coins, "move must finish without spending coins")
        if move.pass == 1 then
            assert(c.items[1].pos:dist(move.origin) < .01, "cancel moved the building")
            move.pass = 2; step = 9
        else
            assert(c.items[1].pos:dist(move.destination) < .01, "confirm did not move the building")
            app.inject_click(G.spots.build); step = 14
        end
    elseif step == 14 then
        assert(G.tray, "build catalogue did not open")
        move.purchase_coins = G.wallet[COINS]
        buy(4); step = 15
    elseif step == 15 then
        assert(G.island.placing == 3 and G.wallet[COINS] == move.purchase_coins, "purchase preview charged early")
        app.inject_click(G.spots.move_cancel); step = 16
    elseif step == 16 then
        assert(G.island.placing < 0 and G.wallet[COINS] == move.purchase_coins, "cancelled purchase charged")
        app.inject_click(G.spots.build); step = 17
    elseif step == 17 then buy(4); step = 18
    elseif step == 18 then app.inject_click(G.spots.move_confirm); step = 19
    elseif step == 19 then
        assert(G.wallet[COINS] == move.purchase_coins - 60 and G.wallet[INFLUENCE] == 20 and G.island.count == 2,
               "confirmed fountain must charge once and grant Influence once")
        app.inject_click(G.spots.chapters); step = 20
    elseif step == 20 then
        assert(G.modal == MODAL_CHAPTERS, "chapter browser did not open")
        app.inject_click(G.spots.play2); step = 21
    elseif step == 21 then
        assert(G.scene == 2, "restoration did not open chapter two")
        if not find_next(2) then step = 22 end
    elseif step == 22 then
        assert(G.modal == MODAL_WIN and G.wallet[INFLUENCE] == 20, "second scene bypassed the island gate")
        app.inject_click(G.spots.continue); step = 23
    elseif step == 23 then
        assert(G.tray, "result should lead to construction when Influence is needed")
        buy(2); step = 24
    elseif step == 24 then app.inject_click(G.spots.move_confirm); step = 25
    elseif step == 25 then
        assert(G.wallet[INFLUENCE] == 50 and G.island.count == 3, "temple must open final chapter")
        app.inject_click(G.spots.chapters); step = 26
    elseif step == 26 then app.inject_click(G.spots.play3); step = 27
    elseif step == 27 then
        assert(G.scene == 3, "final chapter did not open")
        print("Nile smoke: scene rewards -> free move -> purchase cancel/confirm -> fountain -> chapter two -> temple -> chapter three passed")
        app.quit()
    end
end

return M
