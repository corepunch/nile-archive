-- Play Chapter 1 through real input, including placement, replays and the cache.
local G = require("archive_state")
local content = require("archive_content")
local economy = require("archive_economy")
local scene = require("archive_scene")
local island = require("archive_island")
local scenes = content.scenes
local COINS, INFLUENCE = G.COINS, G.INFLUENCE
local MODAL_NONE, MODAL_WIN, MODAL_CHAPTERS = G.MODAL_NONE, G.MODAL_WIN, G.MODAL_CHAPTERS

local M = {}

local frames, step = 0, 0
local move             -- the engine's pickup/move check, while it runs
local purchase_coins   -- coins before a purchase preview
local scroll_start

local function row_button(form, key, id)
    assert(form, "expected form was not drawn")
    for _, node in pairs(form.nodes) do
        if node.item_key == key and node.local_id == id then return node end
    end
    error("missing form control " .. id .. " for " .. key)
end

local function click_row(form, key, id)
    local node = row_button(form, key, id)
    assert(node.enabled, "expected row control to be enabled")
    app.inject_click(form.boxes[node.id]:center())
end

local function buy(key) click_row(G.spots.build_form, key, "buy") end
local function play(i) click_row(G.spots.browser, i, "play") end

-- Press one of a form's own controls by id.
local function press(f, id)
    assert(f and f.boxes[id] and f.nodes[id].enabled ~= false, "form control " .. id .. " is not available")
    app.inject_click(f.boxes[id]:center())
end

local function tap_item(i, item)
    local target = scenes[i].at[item]
    local at = G.cam:to_screen(target)
    if not app.screen():inflate2(vec2(-110, -110)):contains(at) then
        G.cam = G.cam:look(target):clamp()
        at = G.cam:to_screen(target)
    end
    app.inject_click(at)
end

local function find_next(i)
    for item = 1, #scenes[i].names do
        if not G.found[item] then tap_item(i, item); return true end
    end
    return false
end

local search, cache_coins

function M.step()
    frames = frames + 1
    if frames > 6000 then error("Nile smoke timed out at step " .. tostring(step)) end
    if frames % 6 ~= 0 then return end
    if story.active() then story.next() return end
    if step == 0 then app.inject_click(G.spots.chapters); step = 1
    elseif step == 1 then
        assert(G.modal == MODAL_CHAPTERS, "chapters button failed")
        play(1); step = 2
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
        assert(G.wallet[INFLUENCE] == 10 and economy.lock(G, 2) == "influence", "scene must leave the building gate intact")
        if G.tray then press(G.spots.build_form, "close"); return end
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
        play(2); step = 21
    elseif step == 21 then
        assert(G.scene == 2, "restoration did not open the library")
        if not find_next(2) then step = 22 end
    elseif step == 22 then
        assert(G.modal == MODAL_WIN and G.wallet[INFLUENCE] == 20, "second search bypassed the island gate")
        app.inject_click(G.spots.continue); step = G.clues[2] == 2 and 23 or 28
    elseif step == 28 then
        assert(not G.tray and G.clues[2] == 1, "the first library clear must lead to its replay")
        app.inject_click(G.spots.chapters); step = 29
    elseif step == 29 then
        assert(not row_button(G.spots.browser, 3, "play").enabled, "the temple cannot skip the second clue")
        play(2); step = 21
    elseif step == 23 then
        assert(G.tray, "result should lead to construction when Influence is needed")
        assert(not row_button(G.spots.build_form, 4, "buy").enabled, "the restored fountain must be unavailable to buy again")
        buy(2); step = 24
    elseif step == 24 then app.inject_click(G.spots.move_confirm); step = 25
    elseif step == 25 then
        assert(G.wallet[INFLUENCE] == 50 and G.island.count == 3, "the temple restoration must grant Influence once")
        app.inject_click(G.spots.build); step = 40
    elseif step == 40 then   -- browse the decoration catalogue: categories, then scroll
        assert(G.tray, "build tray did not open")
        if island.TRAY_CATEGORIES[island.tray.category][1] ~= "tree" then
            press(G.spots.build_form, "category_next")
        else
            local viewport = G.spots.build_form.boxes.stock
            scroll_start = viewport:point(vec2(.5, .8))
            app.inject_press(scroll_start); step = 41
        end
    elseif step == 41 then
        app.inject_move(scroll_start - vec2(0, 190)); step = 141
    elseif step == 141 then
        app.inject_release(scroll_start - vec2(0, 190)); step = 142
    elseif step == 142 then
        local stock = G.spots.build_form.nodes.stock
        assert(stock.scroll_state.offset > 100 and G.island.placing < 0, "drag must scroll without buying")
        press(G.spots.build_form, "category_prev"); step = 143
    elseif step == 143 then
        press(G.spots.build_form, "category_next"); step = 144
    elseif step == 144 then
        step = 42
    elseif step == 42 then
        assert(G.spots.build_form.nodes.stock.scroll_state.offset == 0, "category change should reset scroll")
        purchase_coins = G.wallet[COINS]
        for i, kind in ipairs(content.kinds) do
            if kind.key == "date_palm" then buy(i) end
        end
        step = 43
    elseif step == 43 then
        assert(content.kinds[G.island.placing + 1].key == "date_palm", "decoration preview did not start")
        app.inject_click(G.spots.move_confirm); step = 44
    elseif step == 44 then
        assert(G.island.count == 4 and G.wallet[COINS] == purchase_coins - 30 and G.wallet[INFLUENCE] == 53,
            "a decoration must charge its coins and grant Influence once")
        search = 3
        app.inject_click(G.spots.chapters); step = 26
    elseif step == 26 then
        play(search); step = 27
    elseif step == 27 then
        assert(G.scene == search, "expected search to open")
        if not find_next(search) then step = 45 end
    elseif step == 45 then
        assert(G.modal == MODAL_WIN, "search did not open the result")
        app.inject_click(G.spots.continue); step = 46
    elseif step == 46 then
        if G.clues[search] == 2 then search = search + 1 end
        if G.tray then
            assert(search == 4 or search == 5, "unexpected construction gate")
            buy(search == 4 and 3 or 5); step = 47
        else
            app.inject_click(G.spots.chapters); step = search == content.CACHE and 50 or 26
        end
    elseif step == 47 then
        app.inject_click(G.spots.move_confirm); step = 48
    elseif step == 48 then
        assert(not economy.lock(G, search), "restoration did not open the revisit")
        app.inject_click(G.spots.chapters); step = 26
    elseif step == 50 then
        assert(G.wallet[4] == 15 and not economy.cache_lock(G), "the last clue must open the cache")
        cache_coins = G.wallet[COINS]
        play(content.CACHE); step = 51
    elseif step == 51 then
        assert(G.scene == content.CACHE and G.slots[1] == 1 and not G.slots[2], "only the first cache target is shown")
        tap_item(content.CACHE, 2); step = 52
    elseif step == 52 then
        assert(scene.found_count() == 0 and G.misses == 0, "out-of-order cache taps are ignored without penalty")
        step = 53
    elseif step == 53 then
        if not find_next(content.CACHE) then step = 54 end
    elseif step == 54 then
        assert(G.cache_done and G.modal == G.MODAL_CACHE, "the ordered chain must finish the chapter")
        assert(G.wallet[COINS] == cache_coins + 150 and G.wallet[4] == 15, "cache pays once without Stars")
        press(G.spots.cache_result, "home"); step = 55
    elseif step == 55 then
        assert(not G.scene, "cache result did not return to the island")
        app.inject_click(G.spots.chapters); step = 56
    elseif step == 56 then
        assert(not row_button(G.spots.browser, content.CACHE, "play").enabled, "the completed cache cannot be replayed")
        press(G.spots.browser, "journal"); step = 57
    elseif step == 57 then
        assert(G.modal == G.MODAL_JOURNAL and #G.spots.journal.nodes.notes.children == 10, "journal must list nine clues and the cache")
        print("Nile smoke: search, placement, both revisit lists, ordered cache and journal passed")
        app.quit()
    end
end

return M
