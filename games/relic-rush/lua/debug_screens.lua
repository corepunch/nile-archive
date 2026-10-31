-- debug_screens.lua — the entry points tools/screenshots.sh and reviewers use
-- to open a screen directly: --level, --city, --showcase, --placing, --zone,
-- --victory, --card, --fx, --catalogue, --expeditions, --dialog, --present,
-- --talk-through and the art reviews. Nothing here runs in a normal game.
local R = require("state")
local rules = require("rules")
local island = require("island")
local LEVELS, WONDERS, ISLAND_ZONES = rules.LEVELS, island.WONDERS, island.ISLAND_ZONES
local COMPASSES = rules.COMPASSES

-- An island after n expeditions: n wonders at their suggested spots and the
-- regions a player would have opened by then, stars and compasses to match.
local function island_with(n)
    local opened_at = {0, 2, 3, 5, 7, 9}
    R.prog = {level = n, seed = 782341, wallet = purse(340, 115, 92, n * 3, rules.discovery_compasses(n))}
    R.island.count = 0
    local open = 1
    for z = 1, ISLAND_ZONES - 1 do
        if n >= opened_at[z + 1] then
            open = open | (1 << z)
        end
    end
    R.island.open = tonumber(app.arg("open") or "") or open   -- --open MASK: only these regions (bit per region)
    R.island.open = R.island.open | 1
    for z = 1, ISLAND_ZONES - 1 do
        if R.island:zone_open(z) then R.prog.wallet[COMPASSES] = R.prog.wallet[COMPASSES] - R.island.zones[z + 1].cost[COMPASSES] end
    end
    local spend = purse(100000, 100000, 100000)
    for _ = 1, n do island.island_place_next(R.island, spend, n, 0) end
end

-- --talk-through N: move the dialogue on every N frames, to film it.
local talk_frames = 0
function R.debug_frame()
    local every = tonumber(app.arg("talk-through"))
    if not every then return end
    talk_frames = talk_frames + 1
    if talk_frames % every == 0 then story.next() end
end

function R.debug_screens()
    R.island.show_footprints = app.arg("footprints") ~= nil
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
            local p = R.island:snap(spots[i + 1], i)
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
    if app.arg("catalogue") then
        island_with(4)
        R.on_island = true
        R.open_catalogue(app.arg("catalogue"), tonumber(app.arg("catalogue-page")) or 1)
        R.toast_time = 0
    end
    if app.arg("expeditions") then
        island_with(4)
        R.on_island = true
        R.g.won = true
        if app.arg("resume-expedition") then R.g = rules.game_start(1, 123478); R.g.moves = 12 end
        R.open_expeditions(tonumber(app.arg("expedition-page")))
        R.toast_time = 0
    end
    if app.arg("replay-victory") then
        island_with(4)
        R.g = rules.game_start(1, 123478)
        R.g.won, R.g.score, R.g.moves = true, 5860, 12
        R.on_island = false
        R.overlay = R.OV_RESULT
        R.toast_time = 0
    end
    if app.arg("building-review") then
        local first = ((tonumber(app.arg("building-review")) or 1) - 1) * 4
        R.prog = {level = 10, seed = 782341, wallet = purse(2000, 500, 500, 30, 10)}
        R.island.count = 0
        R.island.open = 63
        local spots = {vec2(700, 1500), vec2(1100, 1500), vec2(700, 1850), vec2(1100, 1850)}
        for k = 0, 3 do
            local kind = first + k
            if kind < #island.catalogue then
                local ok, spot = R.island:find_spot(kind, spots[k + 1])
                assert(ok, "building review requires a valid footprint")
                R.island:add(spot, kind, 0)
            end
        end
        R.island_focus(vec2(900, 1550), .65)
        R.on_island = true
        R.toast_time = 0
    end
    if app.arg("catalogue-item") then
        island_with(10)
        R.on_island = true
        local kind = tonumber(app.arg("catalogue-item")) or 10
        R.prog.wallet = purse(2000, 500, 500, 30, 10)
        R.island_begin(kind, true)
    end
    if app.arg("catalogue-card") then
        island_with(10)
        R.on_island = true
        local kind = tonumber(app.arg("catalogue-card")) or 37
        local ok, spot = R.island:find_spot(kind, vec2(760, 2030))
        assert(ok, "catalogue card needs a valid plot")
        R.inspect_item = R.island:add(spot, kind, 0)
        R.inspect = kind
        R.overlay = R.OV_WONDER
        R.toast_time = 0
    end
    if app.arg("art-states") then R.art_review, R.toast_time = true, 0 end
    if app.arg("hud-states") then R.art_review, R.toast_time = true, 0 end
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
        if a == "intro" then story.play("intro", R.intro_lines); R.present_board()   -- no board behind the talk yet
        elseif a == "adrian" then island_with(WONDERS); R.on_island = true; story.play("finale", R.finale)
        elseif a == "mara" then island_with(3); R.on_island = true; story.add({"mara", "New land is yours. Make it your own!", story.SHOUT})
        elseif a == "tomas" then island_with(2); R.on_island = true; story.say("tomas", R.wonders[2].about)
        elseif a == "bubble" then
            island_with(2); R.on_island = true
            R.bubble_wonder, R.bubble_text, R.bubble_time = 1, "A new wonder, exactly where you wanted it.", 3.5
            R.island_focus(R.island.items[2].pos, .8)
        else
            R.overlay = a == "guide" and R.OV_GUIDE or a == "pause" and R.OV_PAUSE or a == "failed" and R.OV_FAILED
                or a == "confirm" and R.OV_CONFIRM or R.OV_FINALE
            if R.overlay == R.OV_FINALE then island_with(WONDERS); R.on_island = true end
        end
    end
    if app.arg("present") then R.present_board() end
    -- A debug screen may have replaced the board, or shown something else instead.
    if R.intro then
        if R.phase == R.PH_PRESENT and R.overlay == R.OV_NONE and not R.art_review then R.present_board()
        else
            R.intro = nil
            if R.phase == R.PH_PRESENT then R.phase = R.PH_IDLE end
        end
    end
    if R.overlay ~= R.OV_NONE and not app.arg("reel") then R.modal_for, R.modal_clock = R.overlay, 1.6 end   -- stills show dialogs settled
end

return R
