-- island_view.lua — Relic Rush's island on the engine's shared town screen
-- (engine/town.lua). Layout and wording are data/town.json; this file only
-- supplies the game's hooks: its wallet, words, icons and actions.
local R = require("state")
local rules = require("rules")
local island = require("island")
local journey = require("journey")
local match3 = require("match3")
local town = require("town")

function R.island_focus(world, zoom) R.town:focus(world, zoom) end
function R.island_begin(kind, focus, item)
    if not R.town:begin(kind, focus, item) then return false end
    R.overlay, R.inspect = R.OV_NONE, -1   -- placement happens on the open map
    return true
end

function R.expand()
    local z = R.island:next_zone(R.prog.wallet)
    if z < 0 then R.notice("Your whole island is open to explore.")
    else R.zone_card, R.overlay = z, R.OV_ZONE end
end

-- The building's name and its line for this point in the story.
function R.building_words(item)
    local kind = R.island.items[item + 1].type
    local definition = R.buildings[kind + 1]
    return definition.name .. "\n" .. journey.building_about(kind, R.prog.level, definition.about)
end

function R.town_setup()
    R.town = town.new(R.island, town.load("town.json"), {
        skin = R.skin,
        wallet = function() return R.prog.wallet end,
        notice = R.notice,
        capsules = R.header_capsules,
        menu = function(bounds) if match3.pause_button(R, bounds) then R.overlay = R.OV_PAUSE end end,
        middle = R.open_expeditions,
        middle_icon = function(at) R.compass_icon(at, 17) end,
        build = function()
            R.open_catalogue(island.wonder_count(R.island) < journey.earned(R.prog.level) and "wonder" or "building")
        end,
        play = function()
            if island.wonder_count(R.island) < journey.earned(R.prog.level) then
                R.notice("Restore your earned wonder before the next discovery."); R.open_catalogue("wonder")
            elseif R.prog.level >= rules.LEVELS then R.open_expeditions()
            else R.play_level(R.prog.level) end
        end,
        about = R.building_words,
        zone = function(z) R.zone_card, R.overlay = z, R.OV_ZONE end,
        can_buy = function(kind) return island.can_buy(R.island, R.prog.wallet, R.prog.level, kind) end,
        suggest = function(kind) return island.island_suggestion(math.min(kind, 9)) end,
        placed = function(ev)
            for k = 0, 23 do R.vfx_emit(ev.screen - vec2(0, 30), k % 6, false) end
            R.tone(740)
            R.save_progress()
        end,
        bubble_text = function() return R.speech_style(15) end,
        reduced_motion = function() return R.reduced_motion end,
        overlay = R.vfx_particles,
    })
    R.placement_form = R.town.placement_form
end

function R.island_screen(inp, dt)
    R.town:frame(inp, dt, R.overlay == R.OV_NONE)
end

return R
