-- Nile Archive's chapter data, campaign awards and story around the shared search screen.
local G = require("archive_state")
local content = require("archive_content")
local economy = require("archive_economy")
local progress = require("archive_progress")
local K = require("archive_kit")
local screen = require("hidden_object.screen")

local scene = screen.new(G, {
    scenes = content.scenes,
    world = size2(1200, 800),
    rules = {
        slots = G.SLOTS,
        find_points = G.FIND_POINTS, miss_points = G.MISS_POINTS,
        combo_window = G.COMBO_WINDOW, combo_max = G.COMBO_MAX,
        hint_recharge = G.HINT_RECHARGE, star_times = G.STAR_TIMES,
    },
    hud = {
        styles = K.styles, bonus_label = "Бонус", hint_icon = K.icon_bulb,
        gold = K.GOLD, gold_hi = K.GOLD_HI, gold_seam = K.GOLD_SEAM,
    },
}, {
    pause = function() G.open_modal(G.MODAL_PAUSE) end,
    completed = function(i, result)
        if result then
            assert(economy.claim(G, i, result), "completed scene must pay once")
            haptic.play(haptic.SUCCESS)
            if result.clue then progress.play(content.scenes[i].clues[result.clue]) end
            progress.save()
            G.open_modal(G.MODAL_WIN)
        else
            local chapter = content.cache_chapter(i)
            if economy.claim_cache(G, chapter) then
                haptic.play(haptic.SUCCESS)
                progress.play(("c%dt2"):format(chapter))
                progress.save()
                G.open_modal(G.MODAL_CACHE)
            end
        end
    end,
})

local open = scene.open
function scene.open(i)
    G.island.selected, G.tray, G.modal = -1, false, G.MODAL_NONE
    open(i)
end

function scene.start(i)
    if progress.blocker(i) then return end
    scene.open(i)
    local chapter = content.cache_chapter(i)
    if chapter and progress.play(("c%dt1"):format(chapter)) then progress.save() end
end

function scene.go_home()
    G.modal = G.MODAL_NONE
    scene.close()
end

return scene
