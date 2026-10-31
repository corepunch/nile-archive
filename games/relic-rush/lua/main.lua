-- Relic Rush · The Lost Valley — hex match-4 expeditions that restore an island.
--
-- main.lua owns the flow between the two screens, progress and saving and
-- sound; debug_screens.lua holds the screenshot entry points and smoke.lua
-- the --smoke run.
local R = require("state")
local rules = require("rules")
local island = require("island")
require("screens")
require("catalogue")
require("expeditions")
require("vfx")
require("board")
require("island_view")
require("debug_screens")
require("smoke")
local LEVELS = rules.LEVELS
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

R.intro = {
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
    s:int("version", 2)
    R.prog.level = s:int("level", R.prog.level)
    R.prog.seed = s:int("seed", R.prog.seed) & 0xFFFFFFFF
    R.prog.wallet = s:ints("wallet", R.prog.wallet)
    R.island:serialize(s)
    story.serialize(s)
    if save.is_reading(s) then
        R.prog.level = num.clampi(R.prog.level, 0, LEVELS)
        R.needs_relocation=island.restore_saved(R.island,R.prog.level)
    end
end

function R.save_progress()
    if not R.test_mode then save.write("progress", serialize) end
end

function R.start_level(chosen)
    local lvl = num.clampi(chosen or R.prog.level, 0, LEVELS - 1)
    if lvl > R.prog.level then return false end
    if chosen and lvl == R.prog.level and island.wonder_count(R.island) < R.prog.level then
        R.notice("Restore your earned wonder before the next discovery."); return false
    end
    R.g = rules.game_start(lvl, (R.prog.seed + lvl * 7919) & 0xFFFFFFFF)
    R.pending = rules.new_match()
    R.on_island = false
    R.overlay = R.OV_NONE
    R.phase = R.PH_IDLE
    R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
    R.idle_time = 0
    R.vfx_reset()
    -- Elena explains a level's twist once; repeat visits keep the header quiet.
    local lesson = rules.level_of(R.g).lesson
    if not R.quiet then story.play(("level-%d"):format(R.g.level), {{"elena", lesson}}) end
    return true
end

function R.play_level(level)
    if R.g and R.g.level==level and not R.g.won and not R.g.lost then
        R.on_island=false;R.overlay=R.OV_NONE
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
    R.notice(first and "Restoration funded. Spare Gold is yours to decorate." or "Replay Gold collected. Choose a treasure in the Build Shop.")
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
    if app.arg("smoke") then R.smoke() end
    R.now = R.now + dt
    R.toast_time = R.toast_time - dt
    if inp.back and not talking and R.overlay == R.OV_NONE then R.overlay = R.OV_PAUSE end

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

---------------------------------------------------------------------- init

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
    R.hud_art = require("art").load_hud()
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
    R.buildings = R.island.defs   -- with the sprites loaded
    R.wonders = {}
    for i = 1, island.WONDERS do R.wonders[i]=R.buildings[i] end

    R.sound = true
    R.inspect, R.zone_card = -1, -1
    R.test_mode = app.arg("smoke") ~= nil or app.arg("shot") ~= nil or app.arg("fresh") ~= nil
    R.quiet = app.arg("shot") ~= nil   -- stills skip the story unless asked for (--dialog)
    R.bubble_wonder = -1
    R.prog = {level = 0, seed = 782341, wallet = purse()}
    if not app.arg("smoke") then save.read("progress", serialize) end
    if not R.quiet then story.play("intro", R.intro) end
    R.layout()
    R.start_level()
    if R.prog.level>=LEVELS then R.g.won=true end -- no unfinished attempt is created at campaign completion
    if R.prog.level > island.wonder_count(R.island) or R.prog.level >= LEVELS then R.on_island = true end
    if R.needs_relocation then
        R.on_island=true;R.notice("Some buildings need a new spot. Hold one to move it.")
    end
    R.debug_screens()
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
