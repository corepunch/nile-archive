-- Relic Rush · The Lost Valley — hex match-4 expeditions that restore an island.
--
-- main.lua owns the flow between the two screens, progress and saving, sound,
-- and the debug entry points used for screenshots and the smoke test.
local R = require("state")
local rules = require("rules")
local island = require("island")
require("screens")
require("vfx")
require("board")
require("island_view")
local LEVELS, WONDERS, ISLAND_ZONES = rules.LEVELS, island.WONDERS, island.ISLAND_ZONES
local STARS, COMPASSES = rules.STARS, rules.COMPASSES
local rgba = color

-- The expedition (see docs/art-direction-v2.md). Busts come from the cast lineup.
local cast = {
    {id = "elena", name = "Elena Voss", role = "Archaeologist, expedition lead", portrait_path = "characters/elena.png",
     color = rgba(44, 108, 84), mouth = vec2(.46, .51)},
    {id = "mara", name = "Mara Bell", role = "Pilot and expedition partner", portrait_path = "characters/mara.png",
     color = rgba(150, 74, 40), right = true, mouth = vec2(.60, .49)},
    {id = "tomas", name = "Tomas Reed", role = "Island archivist", portrait_path = "characters/tomas.png",
     color = rgba(92, 112, 58), right = true, mouth = vec2(.44, .52)},
    {id = "adrian", name = "Adrian Vale", role = "Expedition financier", portrait_path = "characters/adrian.png",
     color = rgba(104, 48, 92), right = true, mouth = vec2(.46, .52)},
}

local intro = {
    {"elena", "The Lost Valley at last. Broken sunstones, silent terraces... someone lived here once.", story.THOUGHT},
    {"mara", "And now we do. I'll keep the plane ready. You find out who they were."},
    {"elena", "Every puzzle is an excavation. Let's start digging."},
}

R.finale = {
    {"adrian", "The Heart of the Sun... remarkable. My sponsors will be delighted."},
    {"elena", "It stays in the valley, Adrian. That was always the deal."},
}

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
    s:int("version", 1)
    R.prog.level = s:int("level", R.prog.level)
    R.prog.seed = s:int("seed", R.prog.seed) & 0xFFFFFFFF
    R.prog.wallet = s:ints("wallet", R.prog.wallet)
    R.island:serialize(s)
    story.serialize(s)
    if save.is_reading(s) then
        R.prog.level = num.clampi(R.prog.level, 0, LEVELS)
        if R.island.count > R.prog.level then R.island.count = R.prog.level end   -- never more wonders than wins
    end
end

function R.save_progress()
    if not R.test_mode then save.write("progress", serialize) end
end

function R.start_level()
    local lvl = num.clampi(R.prog.level, 0, LEVELS - 1)
    R.g = rules.game_start(lvl, (R.prog.seed + lvl * 7919) & 0xFFFFFFFF)
    R.pending = rules.new_match()
    R.on_island = false
    R.overlay = R.OV_NONE
    R.phase = R.PH_IDLE
    R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
    R.idle_time = 0
    R.vfx_reset()
    -- Elena explains a level's twist the first time; later it is a reminder
    local lesson = rules.level_of(R.g).lesson
    if R.quiet or not story.play(("level-%d"):format(R.g.level), {{"elena", lesson}}) then R.notice(lesson) end
end

-- After the results dialog closes: bank the reward and go build.
function R.claim_reward()
    rules.progress_reward(R.prog, R.g, R.wonders)
    R.save_progress()
    R.on_island = true
    R.overlay = R.OV_NONE
    R.notice("Your next wonder is ready to restore.")
end

---------------------------------------------------------------- smoke test

-- --smoke: plays level one through real (injected) mouse clicks, claims the
-- reward, builds the first wonder and enters level two.
local smoke_stage, smoke_frames, smoke_wait, smoke_partner = 0, 0, 0, -1

local function smoke()
    smoke_frames = smoke_frames + 1
    if smoke_frames > 8000 or R.g.lost then
        error(("smoke test failed at stage %d"):format(smoke_stage))
    end
    if smoke_wait > 0 then   -- one click per few frames, so each press and release is its own frame
        smoke_wait = smoke_wait - 1
        return
    end
    smoke_wait = 3
    if story.active() then   -- tap through the dialogue
        app.inject_click(vec2(240, 300))
        return
    end
    if smoke_stage == 0 then
        if R.overlay == R.OV_RESULT then
            if R.modal_clock > 1.4 then app.inject_click(rect(76, 660, 328, 56):center() + vec2(0, R.drop / 2)); smoke_stage = 1 end
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
        app.inject_click(vec2(240, 856 + R.drop)); smoke_stage = 2   -- CHOOSE A LOCATION
    elseif smoke_stage == 2 and R.overlay == R.OV_WONDER then
        app.inject_click(rect(76, 632, 328, 56):center() + vec2(0, R.drop / 2)); smoke_stage = 3
    elseif smoke_stage == 3 and R.island.placing >= 0 then
        app.inject_click(vec2(320, 856 + R.drop)); smoke_stage = 4   -- PLACE & BUILD
    elseif smoke_stage == 4 and R.island.placing < 0 and R.overlay == R.OV_NONE then
        if R.island.count ~= 1 then error("smoke: the wonder was not built") end
        app.inject_click(vec2(240, 856 + R.drop)); smoke_stage = 5   -- PLAY HEX LEVEL 2
    elseif smoke_stage == 5 and not R.on_island and R.overlay == R.OV_NONE then
        if R.g.level ~= 1 then error("smoke: level two did not start") end
        print("smoke test passed: swaps -> cascades -> win -> claim -> island -> build -> level 2")
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
    local talking = story.active()
    local world = (R.overlay ~= R.OV_NONE or talking) and input{pos = inp.pos, pinch = 1} or input.world()
    R.layout()
    if app.arg("smoke") then smoke() end
    R.now = R.now + dt
    R.toast_time = R.toast_time - dt
    if inp.back and not talking then R.overlay = R.overlay ~= R.OV_NONE and R.OV_NONE or R.OV_PAUSE end

    R.board_update(dt)
    R.vfx_update(dt)
    ui.set_enabled(R.overlay == R.OV_NONE and not talking)
    if R.on_island then R.island_screen(world, dt) else R.board_screen(world, dt) end
    if not R.on_island then
        R.vfx_draw()
        R.vfx_particles()
    end
    R.draw_toast()
    ui.set_enabled(true)
    if not talking then R.overlays(dt) end   -- a dialogue comes first; dialogs wait for it
    story.frame(dt)
end

---------------------------------------------------------------- debug setup

-- An island after n expeditions: n wonders at their suggested spots and the
-- regions a player would have opened by then, stars and compasses to match.
local function island_with(n)
    local opened_at = {0, 2, 3, 5, 7, 9}
    R.prog = {level = n, seed = 782341, wallet = purse(340, 115, 92, n * 3, n * 3)}
    R.island.count = 0
    local open = 1
    for z = 1, ISLAND_ZONES - 1 do
        if n >= opened_at[z + 1] then
            open = open | (1 << z)
            R.prog.wallet[COMPASSES] = R.prog.wallet[COMPASSES] - R.island.zones[z + 1].cost[COMPASSES]
        end
    end
    R.island.open = tonumber(app.arg("open") or "") or open   -- --open MASK: only these regions (bit per region)
    R.island.open = R.island.open | 1
    local spend = purse(100000, 100000, 100000)
    for _ = 1, n do island.island_place_next(R.island, spend, n, 0) end
end

local function debug_screens()
    local a = app.arg("level")
    if a then R.g = rules.game_start(tonumber(a) - 1, 123478); R.pending = rules.new_match(); R.on_island = false; R.toast_time = 0 end
    a = app.arg("city")
    if a then island_with(num.clampi(tonumber(a), 0, WONDERS)); R.on_island = true; R.toast_time = 0 end
    if app.arg("showcase") then
        local spots = {vec2(690, 2050), vec2(930, 2180), vec2(580, 1870), vec2(1050, 2000), vec2(820, 1900),
                       vec2(1180, 1800), vec2(760, 1700), vec2(1040, 1620), vec2(620, 1550), vec2(920, 1400)}
        R.prog = {level = LEVELS, seed = 782341, wallet = purse(340, 115, 92, 30, 10)}
        R.island.count = 0
        R.island.open = 63
        for i = 0, WONDERS - 1 do
            local p = spots[i + 1]
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
        R.prog.level = R.island.count + 1
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
    if app.arg("victory") then
        R.prog = {level = 1, seed = 782341, wallet = purse(142, 37, 45, 3, 3)}
        R.g = rules.game_start(1, 123478)
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
        R.prog.level = math.max(i + 1, 2)
        R.prog.wallet = purse(142, 37, 45, R.prog.level * 3, R.prog.level * 3)
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
    if app.arg("art-states") then R.art_review, R.toast_time = true, 0 end
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
    a = app.arg("dialog")
    if a then   -- guide, pause, failed, finale, a dialogue (intro, mara, tomas, adrian) or a bubble
        R.toast_time = 0
        if a == "intro" then story.play("intro", intro)
        elseif a == "adrian" then island_with(WONDERS); R.on_island = true; story.play("finale", R.finale)
        elseif a == "mara" then island_with(3); R.on_island = true; story.add({"mara", "New land is yours. Make it your own!", story.SHOUT})
        elseif a == "tomas" then island_with(2); R.on_island = true; story.say("tomas", R.wonders[2].about)
        elseif a == "bubble" then
            island_with(2); R.on_island = true
            R.bubble_wonder, R.bubble_text, R.bubble_time = 1, "A new wonder, exactly where you wanted it.", 3.5
            R.island_focus(R.island.items[2].pos, .8)
        else
            R.overlay = a == "guide" and R.OV_GUIDE or a == "pause" and R.OV_PAUSE or a == "failed" and R.OV_FAILED or R.OV_FINALE
            if R.overlay == R.OV_FINALE then island_with(WONDERS); R.on_island = true end
        end
    end
    if R.overlay ~= R.OV_NONE and not app.arg("reel") then R.modal_for, R.modal_clock = R.overlay, 1.6 end   -- stills show dialogs settled
end

local function init()
    if app.arg("cell-mask") then return end
    R.font = font.load("fonts/LilitaOne-Regular.ttf")
    story.setup(cast, story_style{text = R.speech_style(21), name = R.pal(R.PAL_CREAM, 15), bubble = rgba(255, 246, 222, 252),
                                  edge = rgba(102, 68, 39), dim = rgba(5, 22, 22, 150), backdrop_blur = 7, portrait_height = .27, framed = true, skip = "SKIP"})
    R.backdrop = texture.load("jungle.jpg")
    R.scenes[1] = texture.load("scene-lagoon.jpg")
    R.scenes[2] = texture.load("scene-temple.jpg")
    -- match pieces: the Relics pack, or an optional art pack (--tiles / ?tiles=jewels|resources)
    local tiles = app.arg("tiles")
    if tiles ~= "jewels" and tiles ~= "resources" then tiles = "relics" end
    for i = 0, rules.COLORS - 1 do R.relics[i + 1] = texture.load(("tile-sets/%s/%d.png"):format(tiles, i)) end
    R.board_art = require("art").load()
    if app.arg("art-states") then
        R.art_packs = {}
        for _, pack in ipairs({"relics", "jewels", "resources"}) do
            R.art_packs[pack] = {}
            for k = 0, rules.COLORS - 1 do R.art_packs[pack][k + 1] = texture.load(("tile-sets/%s/%d.png"):format(pack, k)) end
        end
    end
    R.vfx_init()
    R.island = city.new()
    island.island_setup(R.island)
    R.island.draw_over = R.draw_markers
    R.wonders = R.island.defs   -- with the sprites loaded

    R.sound = true
    R.inspect, R.zone_card = -1, -1
    R.test_mode = app.arg("smoke") ~= nil or app.arg("shot") ~= nil or app.arg("fresh") ~= nil
    R.quiet = app.arg("shot") ~= nil   -- stills skip the story unless asked for (--dialog)
    R.bubble_wonder = -1
    R.prog = {level = 0, seed = 782341, wallet = purse()}
    if not app.arg("smoke") then save.read("progress", serialize) end
    if not R.quiet then story.play("intro", intro) end
    R.layout()
    R.start_level()
    if R.prog.level > R.island.count or R.prog.level >= LEVELS then R.on_island = true end
    debug_screens()
end

return {
    title = "Relic Rush - The Lost Valley",
    id = "relic-rush",
    design = size2(R.SCREEN_W, R.SCREEN_H),
    fixed = true,
    max_aspect = 2.2,   -- tall phones (19.5:9) get a taller screen, not bars
    clear = rgba(9, 33, 31),
    init = init,
    frame = frame,
}
