-- archive_smoke.lua — the --smoke run: plays chapter one through injected
-- clicks (toggling Pause's reduced-motion checkbox on and off), runs the engine's pickup-and-move check on the island, cancels and
-- confirms a purchase, then reaches chapter three by finding the second clue,
-- building the temple and browsing the decoration catalogue (categories, pages
-- and a purchase) through real form input. Every step asserts what it expects.
local G = require("archive_state")
local content = require("archive_content")
local economy = require("archive_economy")
local scene = require("archive_scene")
local island = require("archive_island")
local scenes = content.scenes
local ITEMS, COINS, INFLUENCE = G.ITEMS, G.COINS, G.INFLUENCE
local MODAL_NONE, MODAL_WIN, MODAL_CHAPTERS = G.MODAL_NONE, G.MODAL_WIN, G.MODAL_CHAPTERS

local M = {}

local frames, step = 0, 0
local move             -- the engine's pickup/move check, while it runs
local purchase_coins   -- coins before a purchase preview

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

-- Press one of a form's own controls by id.
local function press(f, id)
    assert(f and f.boxes[id] and f.nodes[id].enabled ~= false, "form control " .. id .. " is not available")
    app.inject_click(f.boxes[id]:center())
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
        app.inject_click(G.spots.pause); step = 30
    -- Pause > Меньше анимации: on, then off again, then back to the scene.
    elseif step == 30 then
        assert(G.modal == G.MODAL_PAUSE, "pause button failed")
        app.inject_click(G.spots.motion); step = 31
    elseif step == 31 then
        assert(G.reduced_motion, "the motion checkbox did not turn reduced motion on")
        app.inject_click(G.spots.motion); step = 32
    elseif step == 32 then
        assert(not G.reduced_motion, "the motion checkbox did not turn reduced motion off")
        app.inject_click(G.spots.resume); step = 33
    elseif step == 33 then
        assert(G.modal == MODAL_NONE and G.scene == 1, "Продолжить did not resume the scene")
        step = 4
    elseif step == 4 then
        if not find_next(1) then step = 5 end
    elseif step == 5 then
        assert(G.modal == MODAL_WIN and G.result and G.result.stars >= 1, "no result after every item")
        app.inject_click(G.spots.continue); step = 6
    elseif step == 6 then
        assert(not G.scene and G.wins[1] == 1 and G.stars[1] >= 1, "continue did not bank the chapter")
        assert(G.wallet[INFLUENCE] == 10 and not economy.can_play(G.wins, 10, 2), "scene must leave the building gate intact")
        move = city.move_test(G.island, {
            look = function(at) G.island.cam = G.island.cam:look(at - vec2(0, 50)) end,
            wallet = function() return G.wallet[COINS] end,
            cancel = function() app.inject_click(G.spots.move_cancel) end,
            confirm = function() app.inject_click(G.spots.move_confirm) end,
        })
        step = 7
    elseif step == 7 then   -- pan, hold to lift, drag, cancel, then confirm
        if not move() then app.inject_click(G.spots.build); step = 14 end
    elseif step == 14 then
        assert(G.tray, "build catalogue did not open")
        purchase_coins = G.wallet[COINS]
        buy(4); step = 15
    elseif step == 15 then
        assert(G.island.placing == 3 and G.wallet[COINS] == purchase_coins, "purchase preview charged early")
        app.inject_click(G.spots.move_cancel); step = 16
    elseif step == 16 then
        assert(G.island.placing < 0 and G.wallet[COINS] == purchase_coins, "cancelled purchase charged")
        app.inject_click(G.spots.build); step = 17
    elseif step == 17 then buy(4); step = 18
    elseif step == 18 then app.inject_click(G.spots.move_confirm); step = 19
    elseif step == 19 then
        assert(G.wallet[COINS] == purchase_coins - 60 and G.wallet[INFLUENCE] == 20 and G.island.count == 2,
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
        app.inject_click(G.spots.build); step = 40
    elseif step == 40 then   -- browse the decoration catalogue: categories, then pages
        assert(G.tray, "build tray did not open")
        if island.TRAY_CATEGORIES[island.tray.category][1] ~= "tree" then
            press(G.spots.build_form, "category_next")
        else
            press(G.spots.build_form, "page_next"); step = 41
        end
    elseif step == 41 then
        assert(island.tray.page == 2, "catalogue did not page forward")
        press(G.spots.build_form, "page_prev"); step = 42
    elseif step == 42 then
        assert(island.tray.page == 1, "catalogue did not page back")
        purchase_coins = G.wallet[COINS]
        for i, kind in ipairs(content.kinds) do
            if kind.key == "date_palm" then buy(i) end
        end
        step = 43
    elseif step == 43 then
        assert(content.kinds[G.island.placing + 1].key == "date_palm", "decoration preview did not start")
        app.inject_click(G.spots.move_confirm); step = 44
    elseif step == 44 then
        assert(G.island.count == 4 and G.wallet[COINS] == purchase_coins - 30 and G.wallet[INFLUENCE] == 50,
            "a decoration must charge its coins once and grant no Influence")
        app.inject_click(G.spots.chapters); step = 26
    elseif step == 26 then app.inject_click(G.spots.play3); step = 27
    elseif step == 27 then
        assert(G.scene == 3, "final chapter did not open")
        print("Nile smoke: motion checkbox -> scene rewards -> free move -> purchase cancel/confirm -> fountain -> chapter two -> temple -> decoration catalogue -> chapter three passed")
        app.quit()
    end
end

return M
