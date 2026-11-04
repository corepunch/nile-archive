-- campaign_smoke.lua — --smoke --campaign: all thirty winter wishes through the
-- real result, Collect, region, stall card, placement, dialogue and Play
-- controls. Each board's goals are met before one real swap, so this checks
-- the flow; the extended greedy-bot rules test checks the boards themselves.
local R = require("state")
local rules = require("rules")
local island = require("island")
local journey = require("journey")

local frames, wait, partner = 0, 0, -1
local played = {}

function R.campaign_smoke()
    frames = frames + 1
    if frames > 16000 then
        error(("campaign smoke stalled at level %d (overlay %d, market %s, story %s)"):format(
            R.prog.level, R.overlay, tostring(R.on_island), table.concat(played, " ")))
    end
    if wait > 0 then wait = wait - 1; return end
    wait = 2
    if story.active() then
        local b = R.story_current
        if b and played[#played] ~= b.key then played[#played + 1] = b.key end
        app.inject_click(vec2(240, 300)); return
    end
    local c = R.island
    if R.overlay == R.OV_FINALE then
        local want = {}
        for _, b in ipairs(journey.beats) do want[#want + 1] = b.key end
        assert(table.concat(played, " ") == table.concat(want, " "),
               "campaign smoke: beats played out of order: " .. table.concat(played, " "))
        for _, key in ipairs(want) do assert(R.prog.story_seen[key], "campaign smoke: unacknowledged beat " .. key) end
        assert(R.prog.level == rules.LEVELS and island.wonder_count(c) == island.WONDERS and c.open == 63,
               "campaign smoke: thirty wishes build every stall and open every region")
        print(("campaign smoke passed: %d winter wishes, %d story beats, %d stalls, every region in %d frames"):format(
            R.prog.level, #played, island.wonder_count(c), frames))
        app.quit()
    elseif R.overlay == R.OV_RESULT then
        if R.dialog_settled() then app.inject_click(rect(76, 660, 328, 56):center() + vec2(0, R.drop / 2)); wait = 20 end
    elseif R.overlay == R.OV_ZONE then
        if R.dialog_settled() then app.inject_click(rect(72, 487, 336, 47):center() + vec2(0, R.drop / 2)); wait = 20 end
    elseif R.overlay == R.OV_WONDER then   -- the earned stall's card: CHOOSE A LOCATION
        if R.dialog_settled() then app.inject_click(rect(76, 632, 328, 56):center() + vec2(0, R.drop / 2)); wait = 10 end
    elseif c.placing >= 0 then
        app.inject_click(vec2(320, 856 + R.drop)); wait = 10   -- PLACE & BUILD
    elseif R.on_island and R.overlay == R.OV_NONE then
        local z = c:next_zone(R.prog.wallet)
        if z >= 0 and c:zone_available(z, R.prog.wallet) then
            local marker = c.zones[z + 1].marker
            R.island_focus(marker, c.cam.zoom)
            app.inject_click(R.island.cam:to_screen(marker))
            wait = 10
        elseif R.prog.level < rules.LEVELS then
            app.inject_click(vec2(240, 856 + R.drop)); wait = 10   -- CHOOSE A LOCATION or PLAY HEX LEVEL
        end
    elseif not R.on_island and R.overlay == R.OV_NONE and R.phase == R.PH_IDLE and R.selected < 0 then
        local g, l = R.g, rules.level_of(R.g)
        for i = 0, rules.CELLS - 1 do g.ice[i], g.chain[i], g.soil[i] = 0, 0, 0 end
        g.score, g.relics, g.dug, g.obstacles = l.score, l.relics, l.soil, 0
        local ok, a, b = rules.game_hint(g)
        assert(ok, "campaign smoke needs a legal move")
        app.inject_click(R.cell_pos(a)); partner = b
    elseif partner >= 0 and R.selected >= 0 and R.phase == R.PH_IDLE then
        app.inject_click(R.cell_pos(partner)); partner = -1
    end
end

return R
