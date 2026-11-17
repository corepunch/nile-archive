-- match3_debug.lua — the entry points tools/screenshots.py, the test manifests
-- and reviewers use to open a portrait match-3 game's screen directly
-- (`require("match3.debug").bind(R, words)`, called by match3.game):
-- --level, --city, --showcase (--decorations N), --placing, --zone, --victory, --card, --fx shatter,
-- --catalogue, --expeditions, --dialog, --present, --mission, --goals-met,
-- --kudos, --reveal, --story-beat, --talk-through, --scroll-review, --dive and the art reviews.
-- --element-states reviews the authored surfaces.
-- --floor-reel oil plays three swaps that clear tablets on the chosen campaign level.
-- Nothing here runs in a normal game.
local D = {}

function D.bind(R, W)
    local rules = require("rules")
    local island = require("island")
    local journey = require("journey")
    local LEVELS, WONDERS, ISLAND_ZONES = rules.LEVELS, island.WONDERS, island.ISLAND_ZONES
    local debug = W.debug
    local function wallet(gold, stars)
        local extras = R.currency_prices and 160 or 0
        return purse(gold, extras, extras, stars)
    end

    -- A town after n story buildings: n buildings at their suggested spots and
    -- the regions a player would have opened by then, with Stars to match.
    local function island_with(n)
        local opened_at = {0, 6, 9, 15, 21, 27}
        local cleared = n > 0 and journey.wonder_levels[n] or 0
        R.prog.level, R.prog.wallet = cleared, wallet(340, cleared * 3)
        R.island.count = 0
        local open = 1
        for z = 1, ISLAND_ZONES - 1 do
            if cleared >= opened_at[z + 1] then open = open | (1 << z) end
        end
        R.island.open = tonumber(app.arg("open") or "") or open   -- --open MASK: only these regions (bit per region)
        R.island.open = R.island.open | 1
        local spend = purse(100000, 100000, 100000)
        for _ = 1, n do island.island_place_next(R.island, spend, cleared, 0) end
    end
    R.island_with = island_with

    -- --talk-through N moves the dialogue on every N frames, to film it;
    -- --scroll-review drags the open shop or level list.
    local talk_frames, scroll_frames, dive_frames = 0, 0, 0
    local floor_reel = app.arg("floor-reel")
    local floor_frames, floor_turn = 0, 0

    local function floor_move()
        local g = R.g
        local best, first, second, expected = 0
        for a = 0, rules.CELLS - 1 do
            for d = 0, 2 do
                local b = rules.hex_neighbor(a, d)
                if rules.game_can_swap(g, a, b) then
                    local copy, match = rules.game_copy(g), rules.new_match()
                    if rules.game_swap(copy, a, b, match) then
                        local duration = .17
                        repeat
                            rules.game_apply(copy, match)
                            local _, falls = rules.game_collapse(copy)
                            -- Clear, fall, and one frame of slack at each phase boundary.
                            duration = duration + .36 + #falls * rules.FALL_STEP
                            rules.game_matches(copy, match)
                        until match.hits == 0 or duration > 1.7
                        if match.hits == 0 and duration <= 1.7 then
                            local score = (g.oil_left - copy.oil_left) * 10 - duration
                            if score > best then
                                best, first, second = score, a, b
                                expected = copy.oil_left
                            end
                        end
                    end
                end
            end
        end
        assert(first, "floor reel needs a swap showing the requested change")
        R.attempt_swap(first, second)
        assert(R.phase == R.PH_SWAP, "floor reel swap did not start")
        return expected
    end

    local floor_expected
    function R.debug_frame()
        if floor_reel then
            floor_frames = floor_frames + 1
            if floor_expected and R.phase == R.PH_IDLE then
                local current = R.g.oil_left
                assert(current == floor_expected, "floor reel differed from the predicted move")
                print(("floor reel %s move %d, frame %d, %d covered cells"):format(floor_reel, floor_turn, floor_frames, current))
                floor_expected = nil
            end
            if floor_turn < 3 and floor_frames == 20 + floor_turn * 120 then
                assert(R.phase == R.PH_IDLE and not floor_expected, "floor reel move has not settled")
                floor_expected = floor_move()
                floor_turn = floor_turn + 1
            elseif floor_frames == 361 then
                assert(floor_turn == 3 and not floor_expected, "floor reel ended before the last swap settled")
            end
        end
        if app.arg("dive") then   -- --city N --dive: Play is pressed on the third frame (the town -> board dive)
            dive_frames = dive_frames + 1
            if dive_frames == 3 then R.play_level(R.prog.level); R.present_board() end
            if dive_frames == tonumber(app.arg("dive-back")) then R.on_island = true end   -- --dive-back F: and back to town
        end
        if app.arg("scroll-review") then
            scroll_frames = scroll_frames + 1
            local form = app.arg("catalogue") and R.catalogue_form or R.expedition_form
            local id = app.arg("catalogue") and "stock" or "levels"
            local box = form.boxes[id]
            if box then
                local start = vec2(box:center().x, box:max().y - 24)
                if scroll_frames == 10 then app.inject_press(start)
                elseif scroll_frames >= 12 and scroll_frames <= 21 then app.inject_move(start - vec2(0, (scroll_frames - 11) * 24))
                elseif scroll_frames == 22 then app.inject_release(start - vec2(0, 240))
                elseif scroll_frames == 30 then
                    assert(R.on_island and form.nodes[id].scroll_state.offset > 0, "a list drag must scroll without activating an entry")
                end
            end
        end
        local every = tonumber(app.arg("talk-through"))
        if not every then return end
        talk_frames = talk_frames + 1
        if talk_frames % every == 0 then story.next() end
    end

    function R.debug_screens()
        talk_frames, scroll_frames, dive_frames = 0, 0, 0
        floor_frames, floor_turn, floor_expected = 0, 0, nil
        R.cell_state_review = nil
        R.island.show_footprints = app.arg("footprints") ~= nil
        local a = app.arg("level")
        if a then R.g = R.make_board(tonumber(a) - 1, 123478, true); R.pending = rules.new_match(); R.on_island = false; R.toast_time = 0 end
        a = app.arg("reveal")   -- --level N --reveal F: clear that share of the tablets; 1 wins the board
        if a and R.g then
            local g, share = R.g, tonumber(a)
            local l = rules.level_of(g)
            for j = 1, math.min(#(l.oil or {}), math.ceil(share * #l.oil)) do
                g.oil[l.oil[j]], g.oil_left = 0, g.oil_left - 1
            end
            if share >= 1 then
                for i = 0, rules.CELLS - 1 do
                    g.chain[i], g.ice[i], g.stone_hp[i] = 0, 0, 0
                end
                g.obstacles = 0
                R.prog.level, R.quiet = g.level, false
                R.debug_skip_level()   -- first clear, with its beat
            end
        end
        if app.arg("cell-states") and R.g then
            -- --level N --cell-states: every Cradle of Rome cell state at once on that
            -- board: selected, mouse hover, an armed tool's area, ice and a double tablet.
            local g, open = R.g, {}
            for i = 0, rules.CELLS - 1 do
                if rules.game_cell_active(g, i) and (g.oil[i] or 0) == 0 and g.chain[i] == 0 then open[#open + 1] = i end
            end
            for i = 0, rules.CELLS - 1 do
                if (g.oil[i] or 0) == 1 then g.oil[i] = 2; break end
            end
            g.ice[open[#open]], g.obstacles = 1, g.obstacles + 1
            local tool = g.tool_slots and 1 or 2
            g.tools[tool] = math.max(g.tools[tool], 1)
            if g.single_charge_tools then g.tool_meter[tool] = g.tool_threshold end
            R.selected, R.tool = open[1], tool - 1
            R.cell_state_review = {hover = open[#open // 2], aim = open[#open - 3]}
        end
        a = app.arg("level")
        if floor_reel then
            assert(floor_reel == "oil" and a and R.g.oil_left > 0, "floor reel needs a level with tablets")
        end
        a = app.arg("city")
        if a then island_with(num.clampi(tonumber(a), 0, WONDERS)); R.on_island = true; R.toast_time = 0 end
        if app.arg("showcase") then
            local spots = {vec2(690, 2050), vec2(930, 2180), vec2(580, 1870), vec2(1050, 2000), vec2(820, 1900),
                           vec2(1180, 1800), vec2(760, 1700), vec2(1040, 1620), vec2(620, 1550), vec2(920, 1400)}
            R.prog.level, R.prog.wallet = LEVELS, wallet(340, LEVELS * 3)
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
            local decor = tonumber(app.arg("decorations") or "")   -- --decorations N: N decorations among the buildings
            if decor then
                local spot = 1
                for kind = WONDERS, #island.buildings - 1 do
                    if decor <= 0 then break end
                    local d = island.buildings[kind + 1]
                    if d.decoration or d.road then   -- props, with or without a road
                        local hint = spots[(spot - 1) % #spots + 1] + vec2(spot % 2 == 0 and 110 or -110, 60)
                        local ok, p = R.island:find_spot(kind, hint)
                        if ok then R.island:add(p, kind, 0); decor, spot = decor - 1, spot + 1 end
                    end
                end
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
            R.prog.level = journey.wonder_levels[R.island.count + 1]
            R.island_begin(R.island.count, true)
            local c = R.island
            if app.arg("placing") == "blocked" and c.count > 0 then   -- over a built building: the red ghost
                c.ghost = c.items[c.count].pos
                R.island_focus(c.ghost - vec2(0, 90), c.cam.zoom)
            elseif app.arg("placing") == "dragging" then   -- held between tiles: the footprint shows where it lands
                c.ghost = c.ghost + vec2(30, 26)
                c.held = true
            elseif app.arg("placing") == "focused" then R.placement_form.focus = "confirm" end
            R.toast_time = 0
        end
        a = app.arg("zone")
        if a then R.zone_card = num.clampi(tonumber(a), 1, ISLAND_ZONES - 1); R.overlay = R.OV_ZONE; R.on_island = true end
        if app.arg("victory") then   -- a level that funds a building; "clue": a story-only level
            local chosen = tonumber(app.arg("victory"))
            local level = chosen and num.clampi(math.floor(chosen) - 1, 0, LEVELS - 1)
                or app.arg("victory") == "clue" and 1 or debug.victory
            R.prog.level, R.prog.wallet = level, wallet(142, level * 3)
            R.g = rules.game_start(level, 123478)
            R.pending = rules.new_match()
            R.g.score, R.g.relics, R.g.wood, R.g.stone, R.g.won = 5860, 13, 9, 14, true
            if R.g.earnings then R.g.earnings = {24, 9, 14} end
            R.vfx_reset()
            R.on_island = false
            R.overlay = R.OV_RESULT
            R.toast_time = 0
        end
        a = app.arg("card")
        if a then
            local i = num.clampi(tonumber(a), 0, WONDERS - 1)
            island_with(i)
            R.prog.level = journey.wonder_levels[i + 1]
            R.prog.wallet = wallet(142, R.prog.level * 3)
            R.inspect = i
            R.overlay = R.OV_WONDER
            R.on_island = true
            R.toast_time = 0
        end
        a = app.arg("fx")
        if a then   -- `--fx shatter`: a blast across double and single tablets on level five
            assert(a == "shatter", "--fx takes shatter")
            local c = rules.hex_center()
            R.g = rules.game_start(4, 123478)
            R.pending = rules.new_match()
            R.on_island = false
            R.vfx_reset()
            local function near(i, r)
                local d = (R.cell_pos(i) - R.cell_pos(c)):len() / (2 * R.HEX_R)
                return d < r and rules.game_cell_active(R.g, i), d
            end
            do   -- aim at the busiest part of the board
                local best, most = c, -1
                for i = 0, rules.CELLS - 1 do
                    c = i
                    local count = 0
                    for j = 0, rules.CELLS - 1 do if near(j, 1.2) then count = count + 1 end end
                    if rules.game_cell_active(R.g, i) and count > most then best, most = i, count end
                end
                c = best
            end
            R.g.obstacles = R.g.obstacles - R.g.chain[c] - R.g.ice[c]
            R.g.chain[c], R.g.ice[c] = 0, 0
            if R.g.oil then   -- double (inner) and single tablets
                for i = 0, rules.CELLS - 1 do
                    local inside, d = near(i, 2.2)
                    if inside and R.g.chain[i] == 0 and R.g.ice[i] == 0 then
                        if R.g.oil[i] == 0 then R.g.oil_left = R.g.oil_left + 1 end
                        R.g.oil[i] = (d < 1.2 and i % 2 == 0) and 2 or 1
                    end
                end
            end
            R.g.active[c]=true;R.g.stone_hp[c]=0
            for i = 0, rules.CELLS - 1 do
                if near(i, 1.2) then R.pending.mask[i], R.pending.direct[i] = true, true end
            end
            R.pending.hits = 1
            R.finish_wave()
            R.toast_time = 0
        end
        if app.arg("catalogue") then
            island_with(4); R.on_island = true
            R.open_catalogue(app.arg("catalogue"), tonumber(app.arg("catalogue-page")) or 1); R.toast_time = 0
        end
        if app.arg("expeditions") then
            island_with(4); R.on_island = true; R.g.won = true
            if app.arg("resume-expedition") then R.g = rules.game_start(1, 123478); R.g.moves = 12 end
            R.open_expeditions(tonumber(app.arg("expedition-page"))); R.toast_time = 0
        end
        if app.arg("replay-victory") then
            island_with(4); R.g = rules.game_start(1, 123478); R.g.won = true; R.g.score = 5860; R.g.moves = 12
            if R.g.earnings then R.g.earnings = {24, 9, 14} end
            R.on_island = false; R.overlay = R.OV_RESULT; R.toast_time = 0
        end
        if app.arg("building-review") then
            local first = ((tonumber(app.arg("building-review")) or 1) - 1) * 4
            R.prog.level, R.prog.wallet = LEVELS, purse(2000, 0, 0, LEVELS * 3)
            R.island.count = 0; R.island.open = 63
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
            R.on_island = true; R.toast_time = 0
        end
        if app.arg("catalogue-item") then
            island_with(10); R.on_island = true
            local kind = tonumber(app.arg("catalogue-item")) or 10
            R.prog.wallet = purse(2000, 0, 0, 30)
            R.island_begin(kind, true)
        end
        if app.arg("catalogue-card") then
            island_with(10); R.on_island = true
            local kind = tonumber(app.arg("catalogue-card")) or debug.catalogue_card
            local ok, spot = R.island:find_spot(kind, vec2(760, 2030))
            assert(ok, "catalogue card needs a valid plot")
            R.inspect_item = R.island:add(spot, kind, 0)
            R.inspect = kind; R.overlay = R.OV_WONDER; R.toast_time = 0
        end
        if app.arg("art-states") or app.arg("hud-states") then R.art_review, R.toast_time, R.on_island = true, 0, false end
        if app.arg("element-states") then
            -- Review neighbouring stones and the tablet floor material.
            R.g = rules.game_start(0, 123478)
            R.pending, R.on_island, R.toast_time, R.art_review = rules.new_match(), false, 0, true
            local g = R.g
            g.stone_hp = {}
            for i = 0, rules.CELLS - 1 do
                g.active[i], g.chain[i], g.ice[i], g.stone_hp[i] = true, 0, 0, 0
                if g.tiles[i].kind < 0 then g.tiles[i] = rules.tile(i % rules.COLORS) end
            end
            for q = -2, 0 do
                local cell = rules.hex_index(q, -1)
                g.stone_hp[cell], g.tiles[cell] = 1, rules.tile(-1)
            end
            g.stone_hp[rules.hex_index(-2, 0)] = 1
            g.tiles[rules.hex_index(-2, 0)] = rules.tile(-1)
            g.oil = {}
            for i = 0, rules.CELLS - 1 do g.oil[i] = 0 end
            for _, cell in ipairs({rules.hex_index(1,0), rules.hex_index(2,0), rules.hex_index(2,1)}) do
                g.oil[cell] = 1
            end
            g.oil_left = 3
            g.initial_obstacles, g.obstacles = 4, 4
        end
        if app.arg("art-board") then
            R.g = rules.game_start(8, 123478)
            R.pending = rules.new_match()
            local cells = {rules.hex_index(-3,0),rules.hex_index(-2,0),rules.hex_index(-1,0),rules.hex_index(0,0),rules.hex_index(1,0),rules.hex_index(2,0)}
            for _,cell in ipairs(cells) do R.g.active[cell]=true;R.g.stone_hp[cell]=0 end
            for k, cell in ipairs(cells) do
                R.g.tiles[cell] = rules.tile(k - 1)
                R.g.chain[cell], R.g.ice[cell] = 0, 0
            end
            for hits = 1, 2 do
                local cell = rules.hex_index(3 - hits, 1)
                R.g.active[cell], R.g.stone_hp[cell], R.g.ice[cell] = true, 0, 0
                R.g.chain[cell], R.g.tiles[cell] = hits, rules.tile(hits)
            end
            R.selected, R.hint_a, R.hint_b = rules.hex_index(-2, 1), rules.hex_index(1, 1), rules.hex_index(2, 1)
            R.g.tools[1], R.g.tools[2], R.g.tools[3] = 2, 2, 0
            R.tool, R.toast_time, R.on_island = 1, 0, false
            R.art_review = true
        end
        if app.arg("present") then R.present_board() end
        if app.arg("mission") then   -- the level's mission banner, as a level starts
            local l = rules.level_of(R.g)
            R.mission(R.board_lesson and R.board_lesson(R.g) or l.lesson, ("%d. %s"):format(R.g.level + 1, l.name))
        end
        if app.arg("goals-met") then   -- score and goal pieces met: their capsules show the tick
            local l = rules.level_of(R.g)
            R.g.score, R.g.relics = l.score, l.relics
        end
        if app.arg("kudos") then R.award_kudos(tonumber(app.arg("kudos")) or 2) end
        a = app.arg("dialog")
        if a then   -- guide, pause, confirm, failed, finale, leaderboard, level-leaderboard, award, a dialogue (intro, adrian, mara, tomas) or a bubble
            R.toast_time = 0
            if a == "intro" then R.queue_story({key = journey.beats[1].key, lines = R.intro_lines}, true); R.present_board()   -- no board behind the talk yet
            elseif a == "adrian" then island_with(WONDERS); R.on_island = true; R.queue_story({key = "finale", lines = R.finale}, true)
            elseif a == "mara" then island_with(3); R.on_island = true; story.add({W.region_speaker, journey.regions[2], story.SHOUT})
            elseif a == "tomas" then island_with(2); R.on_island = true; story.say(debug.narrator, R.wonders[2].about)
            elseif a == "bubble" then
                island_with(2); R.on_island = true
                R.island_focus(R.island.items[2].pos, .8)
                R.town:say(1, R.building_words(1))
            elseif a == "leaderboard" then R.overlay = R.OV_PAUSE; R.open_leaderboard()   -- from Settings; --gamecenter-demo adds rivals
            elseif a == "level-leaderboard" then R.open_leaderboard(R.g.level)   -- over --victory's results card
            elseif a == "award" then   -- the recovered item's card, with --victory clue
                R.award = assert(R.award_for and R.award_for(R.g), "this game awards no item for this level")
                R.overlay = R.OV_AWARD
            else
                R.overlay = a == "guide" and R.OV_GUIDE or a == "pause" and R.OV_PAUSE or a == "failed" and R.OV_FAILED
                    or a == "confirm" and R.OV_CONFIRM or R.OV_FINALE
                if R.overlay == R.OV_FINALE then island_with(WONDERS); R.prog.level = LEVELS; R.on_island = true end
            end
        end
        local beat_key = app.arg("story-beat")   -- --story-beat KEY [--story-line N]: preview a scene from its Nth line
        if beat_key then
            local beat = assert(journey.find(beat_key), "unknown story beat")
            island_with(journey.earned(beat.level))
            R.on_island, R.overlay, R.intro, R.phase, R.toast_time = true, R.OV_NONE, nil, R.PH_IDLE, 0
            while story.active() do story.next() end
            local lines = {}
            for i = tonumber(app.arg("story-line")) or 1, #beat.lines do lines[#lines + 1] = beat.lines[i] end
            R.queue_story({key = beat.key, lines = lines}, true)
        end
        local choice_key = app.arg("story-choice")
        if choice_key then
            local beat = assert(journey.find(choice_key), "unknown story choice")
            island_with(journey.earned(beat.level))
            R.on_island, R.toast_time = true, 0
            R.open_story_choice(beat, true)
        end
        -- A debug screen may have replaced the board, or shown something else instead.
        if R.intro then
            if R.phase == R.PH_PRESENT and R.overlay == R.OV_NONE and not R.art_review then R.present_board()
            else
                R.intro = nil
                if R.phase == R.PH_PRESENT then R.phase = R.PH_IDLE end
            end
        end
        if R.overlay ~= R.OV_NONE and not app.arg("reel") then R.modal_for = R.overlay; R.open_dialog(true) end   -- stills show dialogs settled
    end
end

return D
