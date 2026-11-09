-- Relic Rush · The Lost Valley — hex straight-line match-3 expeditions that restore an island.
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

local journey = require("journey")
require("narrative")

-- Dialogue text: Lilita One in dark ink on the cream bubble.
function R.speech_style(size) return style{font = R.font, size = size * 1.5, fill = rgba(74, 50, 28)} end

function R.notice(text)
    R.toast = text
    R.toast_time = 3.6
end

function R.tone(hz)
    if R.sound then sfx.tone(hz, .17) end
end

------------------------------------------------------------------ progress

local function serialize(s)
    local version = s:int("version", 4)
    R.prog.level = s:int("level", R.prog.level)
    R.prog.seed = s:int("seed", R.prog.seed) & 0xFFFFFFFF
    R.prog.wallet = s:ints("wallet", R.prog.wallet)
    R.prog.lives = s:int("lives",R.prog.lives or rules.LIVES)
    R.prog.life_at = s:int("life_at",R.prog.life_at or 0)
    R.island:serialize(s)
    story.serialize(s)
    journey.serialize(s,R.prog)
    if save.is_reading(s) then
        R.prog.level = num.clampi(R.prog.level, 0, LEVELS)
        journey.migrate(R.prog,version)
        R.needs_relocation=island.restore_saved(R.island,R.prog.level)
    end
end

function R.save_progress()
    if not R.test_mode then save.write("progress", serialize) end
end

function R.start_level(chosen)
    local lvl = num.clampi(chosen or R.prog.level, 0, LEVELS - 1)
    if lvl > R.prog.level then return false end
    if lvl == R.prog.level and island.wonder_count(R.island) < journey.earned(R.prog.level) then
        R.notice("Restore your earned wonder before the next discovery."); return false
    end
    if lvl == R.prog.level and journey.awaiting_return(R.prog) then
        R.notice("A new clue awaits on your island."); return false
    end
    rules.refill_lives(R.prog,app.clock())
    if R.prog.lives<=0 then R.on_island=true;R.notice("A life returns every 30 minutes. Explore your valley meanwhile.");return false end
    R.reset_board(rules.game_start(lvl, (R.prog.seed + lvl * 7919) & 0xFFFFFFFF))
    R.on_island = false
    R.overlay = R.OV_NONE
    R.intro = nil
    R.vfx_reset()
    -- Mechanics stay in the board lesson, apart from the story dialogue.
    if not R.quiet then
        local l = rules.level_of(R.g)
        R.mission(l.lesson, ("%d. %s"):format(lvl + 1, l.name)); R.present_board()
    end
    return true
end

function R.play_level(level)
    if R.g and R.g.level==level and not R.g.won and not R.g.lost then
        R.on_island=false;R.overlay=R.OV_NONE
        if R.phase == R.PH_IDLE or R.phase == R.PH_PRESENT then R.present_board() end
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
    R.notice(first and (journey.wonder_at(R.prog.level) and "Restoration funded. Spare Amulets are yours to decorate." or "A new clue awaits on your island.") or "Replay Amulets collected. Choose a treasure in the Build Shop.")
end

-------------------------------------------------------------------- frame

local function frame(dt)
    if R.prog then rules.refill_lives(R.prog,app.clock());if R.g and rules.lose_life(R.prog,R.g,app.clock()) then R.save_progress() end end
    if app.arg("cell-mask") then
        -- Same flat-top polygon as a cell, captured at texture resolution.
        gfx.rect(rect(0, 0, R.SCREEN_W, R.SCREEN_H), color(0, 0, 0))
        gfx.ngon(vec2(R.SCREEN_W / 2, R.SCREEN_H / 2), 64, 6, 0, color.WHITE)
        return
    end
    local inp = input.get()
    R.story_tick()
    local talking = story.active()
    local world = (R.overlay ~= R.OV_NONE or talking) and input{pos = inp.pos, pinch = 1} or input.world()
    R.layout()
    tween.instant(R.reduced_motion)   -- reduced motion: every tween settles on its next frame
    if app.arg("smoke") then R.smoke() end
    R.debug_frame()
    R.now = R.now + dt
    if not talking then R.toast_time = R.toast_time - dt end
    if inp.back and not talking and R.overlay == R.OV_NONE then R.overlay = R.OV_PAUSE end

    R.board_update(dt)
    R.vfx_update(dt)
    ui.set_enabled(R.overlay == R.OV_NONE and not talking)
    if R.on_island then R.island_screen(world, dt) else R.board_screen(world, dt) end
    if not R.on_island then
        R.vfx_draw()
        R.vfx_particles()
        R.draw_board_banners(dt)
    end
    R.draw_toast()
    ui.set_enabled(true)
    if not talking then R.overlays(dt) end   -- a dialogue comes first; dialogs wait for it
    story.frame(dt)
end

---------------------------------------------------------------------- init

local function init()
    if app.arg("cell-mask") then return end
    R.font = R.skin:font("lilita")
    story.setup(R.cast, story_style{text = R.speech_style(21), name = R.pal(R.PAL_CREAM, 22.5), bubble = rgba(255, 246, 222, 252),
                                  edge = rgba(102, 68, 39), dim = rgba(5, 22, 22, 150), backdrop_blur = 7, portrait_height = .34, centered = true, skip = "SKIP"})
    local board_skin = require("art").skin()
    R.backdrop = board_skin.background
    R.scenes[1], R.scenes[2] = board_skin["scene-1"] or R.backdrop, board_skin["scene-2"] or R.backdrop
    -- match pieces: the Relics pack, or an optional art pack (--tiles / ?tiles=jewels|resources)
    local tiles = app.arg("tiles")
    if tiles ~= "jewels" and tiles ~= "resources" then tiles = "relics" end
    R.hex_piece_kind = not app.arg("default-match3") and tiles ~= "resources" and 0 or nil
    for i = 0, rules.COLORS - 1 do R.relics[i + 1] = board_skin[(app.arg("default-match3") and "kind-" or tiles .. "-") .. i] end
    R.board_art = require("art").load()
    R.hud_art = require("art").load_hud()
    R.life_art=texture.load("expedition-hud/life.png")
    if app.arg("art-states") then
        R.art_packs = {}
        for _, pack in ipairs({"relics", "jewels", "resources"}) do
            R.art_packs[pack] = {}
            for k = 0, rules.COLORS - 1 do R.art_packs[pack][k + 1] = board_skin[(app.arg("default-match3") and "kind-" or pack .. "-") .. k] end
        end
    end
    R.vfx_init()
    R.island = city.new()
    island.island_setup(R.island)
    R.buildings = R.island.defs   -- with the sprites loaded
    R.town_setup()
    R.wonders = {}
    for i = 1, island.WONDERS do R.wonders[i]=R.buildings[i] end

    R.sound = true
    R.inspect, R.zone_card = -1, -1
    R.test_mode = app.arg("smoke") ~= nil or app.arg("shot") ~= nil or app.arg("fresh") ~= nil
    R.quiet = app.arg("shot") ~= nil   -- stills skip the story unless asked for (--dialog)
    R.prog = {level = 0, seed = 782341, wallet = purse(),lives=rules.LIVES,life_at=0,story_seen={}}
    if not app.arg("smoke") then save.read("progress", serialize) end
    if app.arg("empty-lives") then R.prog.lives=0;R.prog.life_at=app.clock()+1800;R.quiet=true end
    rules.refill_lives(R.prog,app.clock())
    R.story_current,R.story_preview=nil,false
    R.layout()
    if not R.start_level() then
        -- A loaded zero-life wallet still needs an inert board for shared view
        -- updates. It cannot be resumed as an unfinished expedition.
        R.reset_board(rules.game_start(math.min(R.prog.level,LEVELS-1),R.prog.seed))
        R.g.lost,R.g.life_paid=true,true
        R.on_island=true
    end
    if R.prog.level>=LEVELS then R.g.won=true end -- no unfinished attempt is created at campaign completion
    if journey.earned(R.prog.level) > island.wonder_count(R.island) or R.prog.level >= LEVELS then R.on_island = true end
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
