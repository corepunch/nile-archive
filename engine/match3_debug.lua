-- match3_debug.lua — the entry points tools/screenshots.py, the test manifests
-- and reviewers use to open a portrait match-3 game's screen directly
-- (`require("match3.debug").bind(R, words)`, called by match3.game):
-- --level, --city, --showcase, --placing, --zone, --victory, --card, --fx,
-- --catalogue, --expeditions, --dialog, --present, --mission, --goals-met,
-- --kudos, --story-beat, --talk-through, --scroll-review, --dive and the art reviews.
-- --element-states populates a board with the new authored element states.
-- Nothing here runs in a normal game.
local D = {}

function D.bind(R, W)
    local rules = require("rules")
    local island = require("island")
    local journey = require("journey")
    local LEVELS, WONDERS, ISLAND_ZONES = rules.LEVELS, island.WONDERS, island.ISLAND_ZONES
    local debug = W.debug

    -- A town after n story buildings: n buildings at their suggested spots and
    -- the regions a player would have opened by then, with Stars to match.
    local function island_with(n)
        local opened_at = {0, 6, 9, 15, 21, 27}
        local cleared = n > 0 and journey.wonder_levels[n] or 0
        R.prog.level, R.prog.wallet = cleared, purse(340, 0, 0, cleared * 3)
        R.island.count = 0
        local open = 1
        for z = 1, ISLAND_ZONES - 1 do
            if cleared >= opened_at[z + 1] then open = open | (1 << z) end
        end
        R.island.open = tonumber(app.arg("open") or "") or open   -- --open MASK: only these regions (bit per region)
        R.island.open = R.island.open | 1
        local spend = purse(100000)
        for _ = 1, n do island.island_place_next(R.island, spend, cleared, 0) end
    end
    R.island_with = island_with

    -- --talk-through N moves the dialogue on every N frames, to film it;
    -- --scroll-review drags the open shop or level list.
    local talk_frames, scroll_frames, dive_frames = 0, 0, 0
    function R.debug_frame()
        if app.arg("dive") then   -- --city N --dive: Play is pressed on the third frame (the town -> board dive)
            dive_frames = dive_frames + 1
            if dive_frames == 3 then R.play_level(R.prog.level); R.present_board() end
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
        if app.arg("stripe-states") then R.art_review = true end
        R.island.show_footprints = app.arg("footprints") ~= nil
        local a = app.arg("level")
        if a then R.g = rules.game_start(tonumber(a) - 1, 123478); R.pending = rules.new_match(); R.on_island = false; R.toast_time = 0 end
        a = app.arg("city")
        if a then island_with(num.clampi(tonumber(a), 0, WONDERS)); R.on_island = true; R.toast_time = 0 end
        if app.arg("showcase") then
            local spots = {vec2(690, 2050), vec2(930, 2180), vec2(580, 1870), vec2(1050, 2000), vec2(820, 1900),
                           vec2(1180, 1800), vec2(760, 1700), vec2(1040, 1620), vec2(620, 1550), vec2(920, 1400)}
            R.prog.level, R.prog.wallet = LEVELS, purse(340, 0, 0, LEVELS * 3)
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
            local level = app.arg("victory") == "clue" and 1 or debug.victory
            R.prog.level, R.prog.wallet = level, purse(142, 0, 0, level * 3)
            R.g = rules.game_start(level, 123478)
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
            R.prog.level = journey.wonder_levels[i + 1]
            R.prog.wallet = purse(142, 0, 0, R.prog.level * 3)
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
            R.g.active[c]=true;R.g.stone_hp[c]=0;R.g.crate_hp[c]=0;R.g.hazard[c]=0
            R.g.tiles[c] = rules.tile(mode == 2 and 0 or 3, mode == 0 and rules.ROW or mode == 1 and rules.BOMB or a=="plane" and rules.PLANE or rules.PRISM)
            R.pending.mask[c] = true
            R.pending.hits = 1
            R.finish_wave()
            assert(R.pending.hits>0,"effect review must hit active cells")
            if a=="plane" then assert(#R.pending.flights>0,"plane review must emit a flight") end
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
        if app.arg("tunnel-hop") then
            -- One genuine fall step between distant endpoints for animation review.
            R.g = rules.game_start(0, 123478)
            R.pending, R.on_island, R.toast_time, R.art_review = rules.new_match(), false, 0, false
            local g, entry, exit = R.g, rules.hex_index(-3, 0), rules.hex_index(2, 0)
            g.active[entry], g.active[exit] = true, true
            g.tunnel_to[entry], g.tunnel_from[exit] = exit, entry
            local step = {tiles={}, from={}}
            for i = 0, rules.CELLS - 1 do step.tiles[i], step.from[i] = g.tiles[i], i end
            step.tiles[exit], step.from[exit] = rules.tile(0, rules.NORMAL), entry
            step.tiles[entry] = rules.tile(-1, rules.NORMAL)
            g.tiles[entry], g.tiles[exit] = step.tiles[entry], step.tiles[exit]
            R.fall_steps, R.phase, R.phase_time = {step}, R.PH_FALL, 0
        end
        if app.arg("element-states") then
            -- Populate a real board with every authored strength and colour.
            R.g = rules.game_start(0, 123478)
            R.pending, R.on_island, R.toast_time, R.art_review = rules.new_match(), false, 0, true
            local g = R.g
            g.stone_hp, g.crate_hp, g.crate_kind, g.hazard = {}, {}, {}, {}
            g.tunnel_to, g.tunnel_from, g.delivery_exits = {}, {}, {}
            for i = 0, rules.CELLS - 1 do
                g.active[i], g.soil[i], g.chain[i], g.ice[i] = true, 0, 0, 0
                g.stone_hp[i], g.crate_hp[i], g.crate_kind[i], g.hazard[i] = 0, 0, -1, 0
            end
            for hp = 1, 3 do
                local cell = rules.hex_index(hp - 3, -1)
                g.stone_hp[cell], g.tiles[cell] = hp, rules.tile(-1, rules.NORMAL)
            end
            for kind = 0, 5 do
                for hp = 1, 2 do
                    local q, r = kind - 3, hp
                    local cell = rules.hex_index(q, r)
                    g.crate_hp[cell], g.crate_kind[cell] = hp, kind
                    g.tiles[cell] = rules.tile(-1, rules.NORMAL)
                end
            end
            local covered, partial, revealed = rules.hex_index(-3, 0), rules.hex_index(-1, 0), rules.hex_index(1, 0)
            g.objects = {{cells={covered}, state="hidden"}, {cells={partial}, state="partial"},
                         {cells={revealed}, state="revealed"}}
            g.soil[covered], g.soil[partial] = 1, 1
            g.initial_soil, g.initial_obstacles, g.obstacles = 2, 16, 16
            g.delivery_total, g.delivered = 1, 0
            local entry, exit = rules.hex_index(-4, 0), rules.hex_index(3, -3)
            g.tunnel_to[entry], g.tunnel_from[exit] = exit, entry
            g.hazard[rules.hex_index(2, -1)] = 1
            g.delivery_exits[rules.hex_index(3, -2)] = true
            g.tiles[rules.hex_index(3, -1)] = rules.tile(rules.DELIVERY, rules.NORMAL)
        end
        if app.arg("art-board") then
            R.g = rules.game_start(8, 123478)
            R.pending = rules.new_match()
            local cells = {rules.hex_index(-3,0),rules.hex_index(-2,0),rules.hex_index(-1,0),rules.hex_index(0,0),rules.hex_index(1,0),rules.hex_index(2,0)}
            R.g.objects={};R.g.object_only=false
            for _,cell in ipairs(cells) do
                R.g.active[cell]=true;R.g.soil[cell]=0;R.g.stone_hp[cell]=0;R.g.crate_hp[cell]=0;R.g.hazard[cell]=0
            end
            for k, cell in ipairs(cells) do
                R.g.tiles[cell] = rules.tile(k - 1, k)
                R.g.chain[cell], R.g.ice[cell] = 0, 0
            end
            R.selected, R.hint_a, R.hint_b = rules.hex_index(-2, 1), rules.hex_index(1, 1), rules.hex_index(2, 1)
            R.g.tools = {2, 2, 0}
            R.tool, R.toast_time, R.on_island = 1, 0, false
            R.art_review = true
        end
        if app.arg("homescapes-art") then
            -- Real board drawing paths, with every recovered blocker strength.
            R.g=rules.game_start(0,123478)
            local g=R.g
            g.objects={};g.object_only=false
            g.hs={cells={},groups={},queues={},palettes={},sources={},goals={
                {type="STATUE",max=3,current=0},{type="TRASHSTONE",max=3,current=0},
                {type="TRASH",max=3,current=0},{type="BUBBLE_MEMBRANE",max=3,current=0}}}
            for i=0,rules.CELLS-1 do
                g.active[i]=true;g.soil[i]=0;g.chain[i]=0;g.ice[i]=0
                g.stone_hp[i]=0;g.crate_hp[i]=0;g.hazard[i]=0;g.hs.cells[i]={}
            end
            g.tunnel_to={};g.tunnel_from={};g.delivery_exits={}
            for hp=1,3 do
                local statue=rules.hex_index(hp-2,-2)
                local nut=rules.hex_index(hp-2,-1)
                local stack=rules.hex_index(hp-2,0)
                g.hs.cells[statue].statue=hp;g.tiles[statue]=rules.tile(-1)
                g.tiles[nut]={kind=0,special=rules.NORMAL,element="hazelnut",hp=hp}
                g.hs.cells[stack].stack=hp;g.tiles[stack]=rules.tile(-1)
            end
            for hp=1,2 do
                local i=rules.hex_index(hp-2,1);g.hs.cells[i].tile=hp
                g.tiles[i]=rules.tile(-1)
            end
            if app.arg("homescapes-art")=="generators" then
                for i=0,rules.CELLS-1 do g.hs.cells[i]={};g.tiles[i]=rules.tile(i%6) end
                local function group(q,r,kind,count,hits)
                    local cells={rules.hex_index(q,r),rules.hex_index(q+1,r),rules.hex_index(q,r+1),rules.hex_index(q+1,r+1)}
                    local anchor=cells[1]
                    g.hs.groups[anchor]={kind=kind,count=count,cells=cells,hits=hits or 0,period=3,batch=3}
                    for _,i in ipairs(cells) do assert(i>=0,"art footprint");g.hs.cells[i].group=anchor;g.tiles[i]=rules.tile(-1) end
                end
                group(-3,0,"TARGET_GEN",9)
                group(-1,-2,"TARGET_GEN",4)
                group(1,-3,"CARRY_GEN",1,0)
                group(1,-1,"CARRY_GEN",1,1)
                group(-1,1,"CARRY_GEN",1,2)
                group(1,1,"CARRY_GEN",1,3)
                local anchor=rules.hex_index(-3,2)
                g.hs.groups[anchor]={kind="SHUTTERS",count=3,cells={}}
                for r=2,4 do
                    local i=rules.hex_index(-3,r);g.hs.cells[i].group=anchor
                    table.insert(g.hs.groups[anchor].cells,i)
                end
                local inlet=rules.hex_index(-1,-3)
                g.hs.cells[inlet].visibleGenerator=true;g.tiles[inlet]=rules.tile(-1)
                g.hs.queues[inlet]={cursor=1,units={{element="cookie",hp=3}}}
                g.hs.goals={{type="TARGET_GENERATOR",max=13,current=0},{type="CARRY",max=12,current=0},{type="SHUTTERS",max=1,current=0}}
            end
            R.pending=rules.new_match();R.on_island=false;R.overlay=R.OV_NONE;R.toast_time=0;R.art_review=true
        end
        if app.arg("homescapes") then
            R.g=rules.game_start(0,require("match3.reference")[app.arg("homescapes")].seed)
            assert(R.g.hs,"source preview must load source mechanics")
            R.pending=rules.new_match();R.on_island=false;R.overlay=R.OV_NONE;R.toast_time=0;R.art_review=true
        end
        if app.arg("present") then R.present_board() end
        if app.arg("mission") then   -- the level's mission banner, as a level starts
            local l = rules.level_of(R.g)
            R.mission(l.lesson, ("%d. %s"):format(R.g.level + 1, l.name))
        end
        if app.arg("goals-met") then   -- score and goal pieces met: their capsules show the tick
            local l = rules.level_of(R.g)
            R.g.score, R.g.relics = l.score, l.relics
        end
        if app.arg("kudos") then R.award_kudos(tonumber(app.arg("kudos")) or 2) end
        a = app.arg("dialog")
        if a then   -- guide, pause, confirm, failed, finale, leaderboard, level-leaderboard, a dialogue (intro, adrian, mara, tomas) or a bubble
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
        local object_state = app.arg("quest-object-state")
        if object_state then
            local object = assert(R.g.objects[1], "quest object preview needs a recovery board")
            assert(object.art and (object_state == "partial" or object_state == "revealed"), "unknown quest object preview")
            local count = object_state == "partial" and #object.cells - 1 or #object.cells
            for i = 1, count do R.g.soil[object.cells[i]] = 0 end
            rules.game_apply(R.g, rules.new_match())
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
