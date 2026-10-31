-- Nile Archive — hidden-object chapters feeding an island-restoration meta-game.
--
-- The whole interface (header, chapters, shop, dialogs) is drawn by the shared
-- engine. main.lua owns the flow between the island and a chapter, the back
-- key, start-up and the debug entry points used for screenshots:
--   archive_state     the shared state and constants
--   archive_content   chapters, buildings, cast and dialogue
--   archive_economy   the tested economy contract
--   archive_progress  saving, the chapter goal and the player level
--   archive_kit       the look: panels, buttons, icons, text styles
--   archive_island    the island screen (an engine city)
--   archive_scene     the hidden-object rules and screen
--   archive_dialogs   the popups
--   archive_smoke     the --smoke run
local G = require("archive_state")
local content = require("archive_content")
local economy = require("archive_economy")
local progress = require("archive_progress")
local K = require("archive_kit")
local island = require("archive_island")
local scene = require("archive_scene")
local dialogs = require("archive_dialogs")
local smoke = require("archive_smoke")
local rgba = color
local scenes, SCENES = content.scenes, content.SCENES
local ITEMS, SLOTS, COINS, INFLUENCE, CHAPTERS, STARS = G.ITEMS, G.SLOTS, G.COINS, G.INFLUENCE, G.CHAPTERS, G.STARS
local MODAL_NONE, MODAL_WIN, MODAL_CAST, MODAL_CHAPTERS, MODAL_PAUSE =
    G.MODAL_NONE, G.MODAL_WIN, G.MODAL_CAST, G.MODAL_CHAPTERS, G.MODAL_PAUSE

------------------------------------------------------------------ frame

local function frame(dt)
    local inp = input.get()
    local world = input.world()
    local talking = story.active()
    if G.modal ~= MODAL_NONE or talking then world = input{pos = inp.pos, pinch = 1} end
    if inp.back and not talking then
        if G.modal == MODAL_WIN then scene.go_home()
        elseif G.modal ~= MODAL_NONE then G.modal = MODAL_NONE
        elseif G.island.placing >= 0 then G.island:cancel()
        elseif G.tray then G.tray = false; G.island.selected = -1
        elseif G.scene then G.modal, G.modal_time = MODAL_PAUSE, 0 end
    end
    fx.update(dt)

    local screen = app.screen()
    ui.set_enabled(G.modal == MODAL_NONE and not talking)
    if G.scene then scene.frame(screen, world, dt) else island.frame(screen, world) end
    ui.set_enabled(true)

    if G.modal ~= MODAL_NONE and not talking then   -- a dialogue goes first: the reward waits for it
        G.modal_time = G.modal_time + dt
        ui.modal_backdrop(G.modal_time * 4)
        dialogs.draw(G.modal, G.modal_time)
    end
    story.frame(dt)
    if G.smoke then smoke.step() end
end

------------------------------------------------------------------- setup

-- Debug/QA entry points used to capture screenshots:
-- --screen island|build|purchase|opening|first-build|first-win|scene0..2|cast|pause|chapters|win|story|horem|merit,
-- --catalogue <category> --catalogue-page N with --screen build, --building-review N,
-- and --footprints to check the buildings' measured footprints and pivots
local function apply_screen_arg(screen)
    G.wallet[INFLUENCE] = 100
    G.wallet[COINS] = 900
    G.wins = {1, 1, 0}
    G.wallet[CHAPTERS] = economy.completed(G.wins)
    if screen:sub(1, 5) == "scene" then
        scene.open(num.clampi((tonumber(screen:sub(6)) or 0) + 1, 1, SCENES))
        if app.arg("found") then
            for _, i in ipairs({1, 3, 4, 6}) do G.found[i] = -10 end
            G.score, G.combo, G.combo_left, G.clock = 1800, 3, 3.2, 47
            scene.refill_slots(app.time(), 0)
            for k = 1, SLOTS do G.slot_time[k] = app.time() - 10 end
            scene.show_hint()
            G.hint_ready = G.clock + 6
            G.bonus_in = 1
        end
    elseif screen == "build" then
        G.wallet[STARS] = economy.stars({3, 3, 1})   -- most of the catalogue unlocked, a few still locked
        island.open_tray(app.arg("catalogue") or "story", tonumber(app.arg("catalogue-page")))
    elseif screen == "purchase" then
        local ok, spot = G.island:find_spot(3, vec2(940, 760))
        assert(ok)
        G.island:begin_place(3, spot)
    elseif screen == "opening" then
        G.wallet = purse(economy.START_COINS, economy.START_INFLUENCE)
        G.wins, G.stars = {0, 0, 0}, {0, 0, 0}
    elseif screen == "first-build" then
        G.wallet = purse(140, 10, 1)
        G.wins = {1, 0, 0}
        G.tray = true
    elseif screen == "first-win" then
        scene.open(1)
        G.wallet = purse(140, 10, 1)
        G.wins, G.stars = {1, 0, 0}, {1, 0, 0}
        for i = 1, ITEMS do G.found[i] = 0 end
        G.result = {score = 2400, time = 180, stars = 1, payout = economy.reward(0, 0, 1, false)}
        G.modal, G.modal_time = MODAL_WIN, 2
    elseif screen == "cast" then
        G.modal, G.modal_time = MODAL_CAST, 1
    elseif screen == "pause" then
        scene.open(1)
        for _, i in ipairs({2, 5}) do G.found[i] = -10 end
        G.modal, G.modal_time = MODAL_PAUSE, 1
    elseif screen == "chapters" then
        G.wallet[INFLUENCE] = 30
        G.wins, G.stars = {1, 0, 0}, {3, 0, 0}
        G.wallet[CHAPTERS] = economy.completed(G.wins)
        G.modal, G.modal_time = MODAL_CHAPTERS, 1
    elseif screen == "win" then
        scene.open(2)
        for i = 1, ITEMS do G.found[i] = 0 end
        G.wins, G.stars = {1, 0, 0}, {3, 0, 0}
        G.wallet[CHAPTERS] = economy.completed(G.wins)
        G.result = {score = 4200, time = 68, stars = 3, payout = economy.reward(0, 0, 3, true)}
        G.modal, G.modal_time = MODAL_WIN, 2
    elseif screen == "story" then
        story.play("intro", content.intro)
    elseif screen == "horem" then
        scene.open(3)
        story.play("chapter-2", scenes[3].clue)
        story.next()   -- Nefra listens while her father's note speaks
    elseif screen == "merit" then
        story.add(content.merit_shore)
    elseif screen == "island" then
        local types = {1, 2, 3, 4, 1}
        local spots = {vec2(1060, 600), vec2(760, 860), vec2(960, 1000), vec2(1400, 700), vec2(1700, 900)}
        G.island.open = 7
        for i = 1, 5 do G.island:add(G.island:snap(spots[i], types[i]), types[i], 0) end
        local cam = G.island.cam
        cam.center = vec2(1150, 720)
        cam.zoom = .55
        G.island.cam = cam
    end
end

-- --building-review N places catalogue objects 8(N-1)+1 .. 8N on the open island,
-- zoomed to fit the page's widest footprint; add --footprints to check each
-- sprite against its tiles (docs/BUILDINGS.md).
local REVIEW_PAGE = 8
local function building_review(page)
    local c = G.island
    c.count = 0
    c.open = 15
    local first = content.RESTORATIONS + (page - 1) * REVIEW_PAGE
    local span = 0   -- the widest footprint on the page, in tiles
    for kind = first, math.min(first + REVIEW_PAGE, #G.buildings) - 1 do
        local d = G.buildings[kind + 1]
        span = math.max(span, d.size.w + d.size.h + 2)
    end
    local step = span * content.TILE * .71 + 30
    local centre = vec2(1190, 680)
    for k = 1, REVIEW_PAGE do
        local kind = first + k - 1
        if kind < #G.buildings then
            local at = centre + vec2(((k - 1) % 4 - 1.5) * step, ((k - 1) // 4 - .5) * step * .8)
            local ok, spot = c:find_spot(kind, c:snap(at, kind))
            assert(ok, "building review needs open ground")
            c:add(spot, kind, 0)
        end
    end
    local cam = c.cam
    cam.center, cam.zoom = centre - vec2(0, step * .15), math.min(1.9, 1080 / (4 * step))
    c.cam = cam
end

local function init()
    K.setup_theme()
    story.setup(content.cast, K.dialogue_style())
    for i = 1, SCENES do G.backgrounds[i] = texture.load(scenes[i].background) end
    G.coin = texture.load("icons/coin.png")
    G.influence = texture.load("icons/influence.png")
    island.setup()
    progress.new_game()
    progress.import_legacy()
    progress.read()
    G.scene = nil
    G.hint = nil
    G.smoke = app.arg("smoke") ~= nil
    G.island.show_footprints = app.arg("footprints") ~= nil
    local screen = app.arg("screen")
    local review = tonumber(app.arg("building-review"))
    if screen then apply_screen_arg(screen) elseif not review then story.play("intro", content.intro) end
    if review then building_review(review) end
end

return {
    title = "Архив Нила",
    id = "nile-archive",
    design = size2(1200, 900),
    max_aspect = 16 / 9,
    landscape = true,
    rotate_text = "«Архив Нила» играется только в альбомной ориентации. Поверните устройство.",
    clear = rgba(14, 43, 46),
    init = init,
    frame = frame,
}
