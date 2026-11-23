-- campaign_smoke.lua — --smoke --campaign: the hundred square wishes, through the
-- real result, Collect, region, stall card, placement, dialogue and Play
-- controls. Each board's goals are met before one real swap, so this checks
-- the flow; the extended greedy-bot rules test checks the boards themselves.
local R = require("state")
local rules = require("rules")
local island = require("island")

local frames, wait, partner, advents = 0, 0, -1, 0
local completion_seen = false
local played = {}
local due = 0
for _, step in ipairs(island.ladder) do
    if step.after <= rules.LEVELS then due = due + 1 end
end

function R.campaign_smoke()
    frames = frames + 1
    if frames > 48000 then   -- a hundred boards of up to 108 cells
        error(("campaign smoke stalled at level %d (overlay %d, market %s, story %s)"):format(
            R.prog.level, R.overlay, tostring(R.on_island), table.concat(played, " ")))
    end
    if R.diving() then return end   -- the town HUD, Confirm included, is not drawn during the dive
    if wait > 0 then wait = wait - 1; return end
    wait = 2
    if story.active() then
        local b = R.story_current
        if b and played[#played] ~= b.key then played[#played + 1] = b.key end
        app.inject_click(vec2(240, 300)); return
    end
    if R.mission_banner and not R.on_island and R.overlay == R.OV_NONE then   -- a tap sends the mission banner on
        if R.mission_banner.t > .2 and not R.mission_banner.skipped then app.inject_click(vec2(240, 300)); R.mission_banner.skipped = true end
        return
    end
    local c = R.island
    if R.overlay == R.OV_EPOCH and R.dialog_settled() then
        assert(R.epoch_award == advents + 1 and R.completed_epochs() == R.epoch_award,
            "each completed Advent shows its award once, in order")
        advents = R.epoch_award
        assert(c:zone_open(R.epoch_award), "the seasonal award opens its district")
        app.inject_click(R.epoch_form.boxes.back:center() + vec2(0, R.drop / 2)); wait = 10
    elseif R.overlay == R.OV_COMPLETE and R.dialog_settled() then
        completion_seen = R.prog.epoch_seen == #R.words.epochs
        app.inject_click(R.complete_form.boxes.back:center() + vec2(0, R.drop / 2)); wait = 10
    elseif R.prog.level == rules.LEVELS and island.campaign_count(c) == due
        and R.on_island and R.overlay == R.OV_NONE then
        assert(advents == #R.words.epochs and R.prog.epoch_seen == advents, "the final Advent is acknowledged")
        if not completion_seen then
            app.inject_click(R.town.buttons.play)
            wait = 10
            return
        end
        local journey = require("journey")
        assert(#played == #journey.beats + #journey.placements,
            ("every scene plays once: %d of %d"):format(#played, #journey.beats + #journey.placements))
        print(("campaign smoke passed: %d winter wishes, %d scenes, %d stalls, %d Advents"):format(
            R.prog.level, #played, island.campaign_count(c), advents))
        app.quit()
    elseif R.overlay == R.OV_RESULT then
        local claim = R.result_form.boxes.claim
        if claim and R.dialog_settled() then
            app.inject_click(claim:center() + vec2(0, R.drop / 2))
            wait = 20
        end
    elseif R.overlay == R.OV_SHOP then
        local kind = island.next_step(c, R.prog.level)
        local node = R.catalogue_tile(island.buildings[kind + 1].key)
        local box = node and R.catalogue_form.boxes[node.id]
        if box then app.inject_click(box:center()); wait = 10 end
    elseif R.overlay == R.OV_WONDER then
        if R.dialog_settled() then app.inject_click(R.wonder_form.boxes.action:center()); wait = 10 end
    elseif c.placing >= 0 then
        app.inject_click(R.placement_form.boxes.confirm:center()); wait = 10   -- PLACE & BUILD
    elseif R.on_island and R.overlay == R.OV_NONE then
        local kind = island.next_step(c, R.prog.level)
        if kind then
            app.inject_click(R.town.buttons.build); wait = 10
        elseif R.prog.level < rules.LEVELS then
            app.inject_click(R.town.buttons.play); wait = 10   -- Play the next wish
        end
    elseif not R.on_island and R.overlay == R.OV_NONE and R.phase == R.PH_IDLE and R.selected < 0 then
        local g = R.g
        for i = 0, rules.CELLS - 1 do g.chain[i], g.oil[i] = 0, 0 end
        g.obstacles, g.oil_left = 0, 0
        local cost = purse()
        for _, step in ipairs(island.ladder) do
            if step.after == g.level + 1 then cost = cost + R.buildings[step.kind + 1].cost end
        end
        g.earnings = {cost[1], cost[2], cost[3]}
        local ok, a, b = rules.game_hint(g)
        assert(ok, "campaign smoke needs a legal move")
        app.inject_click(R.cell_pos(a)); partner = b
    elseif partner >= 0 and R.selected >= 0 and R.phase == R.PH_IDLE then
        app.inject_click(R.cell_pos(partner)); partner = -1
    end
end

return R
