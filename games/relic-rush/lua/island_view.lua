-- island_view.lua — the restored island: an engine city with the expedition's
-- HUD, region markers in the fog, placement and the next-step panel.
local R = require("state")
local rules = require("rules")
local island = require("island")
local SCREEN_W, SCREEN_H, MAP_VIEW = R.SCREEN_W, R.SCREEN_H, R.MAP_VIEW
local PAL_GOLD, PAL_CREAM, PAL_GREEN, PAL_WHITE = R.PAL_GOLD, R.PAL_CREAM, R.PAL_GREEN, R.PAL_WHITE
local STARS, COMPASSES = rules.STARS, rules.COMPASSES
local rgba = color

function R.island_focus(world, zoom)
    local cam = R.island.cam
    cam.zoom = zoom
    R.island.cam = cam:look(world):clamp()
end

-- Start placing the next wonder (or moving a built one) and look at it.
function R.island_begin(i, focus)
    local c = R.island
    R.overlay = R.OV_NONE
    R.inspect = -1
    if i == c.count then
        local ok, spot = c:find_spot(i, island.island_suggestion(i))
        if not ok then
            R.notice("Open more land before placing this wonder.")
            return
        end
        c:begin_place(i, spot)
    elseif i >= 0 and i < c.count then
        c:begin_move(i)
    else
        return
    end
    if focus then R.island_focus(c.ghost - vec2(0, 90), math.max(.65, c.cam.zoom)) end
    R.notice("Tap to choose a spot. Drag the building or scroll the land.")
end

local function confirm_place()
    local c = R.island
    local fresh = c.moving < 0
    local ev = c:confirm(R.prog.wallet, app.clock())
    if ev.result ~= city.BUILT and ev.result ~= city.MOVED then
        R.notice("Choose open grass clear of other buildings.")
        return
    end
    for k = 0, 23 do R.vfx_emit(ev.screen - vec2(0, 30), k % 6, false) end
    R.bubble_wonder = ev.building   -- the island answers in a word bubble over the building
    R.bubble_text = fresh and "A new wonder, exactly where you wanted it." or "A fresh place for your island wonder."
    R.bubble_time = 3.5
    R.tone(740)
    if fresh then   -- Tomas tells each wonder's story once; the last one brings Adrian
        local kind = c.items[ev.building + 1].type
        local w = R.wonders[kind + 1]
        story.play(("wonder-%d"):format(kind), {{"tomas", w.about}})
        if c.count == island.WONDERS then
            story.play("finale", R.finale)
            R.overlay = R.OV_FINALE
        end
    end
    R.save_progress()
end

local function expand()
    local z = R.island:next_zone(R.prog.wallet)
    if z < 0 then R.notice("Your whole island is open to explore.")
    else R.zone_card, R.overlay = z, R.OV_ZONE end
end

-- Region markers float over the fog: "+" when the region can open now.
local function draw_markers(c)
    local cam = c.cam
    local zones = c.zones
    for z = 1, c.zone_count - 1 do
        if not c:zone_open(z) then
            local p = cam:to_screen(zones[z + 1].marker)
            if not (p.x < -90 or p.x > SCREEN_W + 90 or p.y < cam.view.y - 50 or p.y > cam.view:max().y + 40) then
                local ready = c:zone_available(z, R.prog.wallet)
                gfx.circle(p, 25, rgba(102, 135, 101, 220))
                gfx.circle(p + vec2(0, -2), 22, ready and rgba(249, 211, 104) or rgba(231, 224, 185))
                R.say_at(ready and "+" or "?", p + vec2(0, -5), 30, PAL_CREAM, 0)
                gfx.round_rect(rect(p.x - 76, p.y + 29, 152, 26), 10, rgba(30, 68, 53, 220))
                R.say_at(zones[z + 1].name, p + vec2(0, 40), 15, PAL_CREAM, 142)
            end
        end
    end
end
R.draw_markers = draw_markers

local function map_button(r, label, em, bg)
    gfx.round_rect(r, 12, bg)
    R.say(label, r, em, PAL_CREAM)
    return R.tapped(r)
end

local function bottom_panel()
    local c = R.island
    R.panel(rect(16, 745, 448, 138))
    if c.placing >= 0 then
        local ok = c:can_place(c.ghost, c.placing, c.moving)
        R.say_at(R.wonders[c.placing + 1].name, vec2(240, 767), 25, PAL_GOLD, 410)
        R.say_at("DRAG BUILDING TO MOVE  -  DRAG LAND TO SCROLL", vec2(240, 797), 11, PAL_WHITE, 0)
        if R.button(rect(32, 824, 140, 40), "CANCEL", true) then c:cancel(); R.notice("Your island is unchanged.") end
        if R.button(rect(191, 824, 257, 40), c.moving < 0 and "PLACE & BUILD" or "CONFIRM MOVE", ok) then confirm_place() end
    elseif c.count < R.prog.level then
        R.say_at(R.wonders[c.count + 1].name, vec2(240, 767), 25, PAL_GOLD, 410)
        R.say_at("CHOOSE ITS PLACE ON YOUR ISLAND", vec2(240, 797), 12, PAL_WHITE, 0)
        if R.button(rect(58, 824, 364, 40), "CHOOSE A LOCATION", true) then R.inspect, R.overlay = c.count, R.OV_WONDER end
    elseif R.prog.level >= rules.LEVELS then
        R.say_at("Your island, your story", vec2(240, 767), 27, PAL_GOLD, 0)
        R.say_at("DRAG TO EXPLORE. MOVE ANY BUILDING.", vec2(240, 797), 12, PAL_WHITE, 0)
        if R.button(rect(58, 824, 364, 40), "EXPLORE MY ISLAND", true) then R.notice("Drag the land to explore. Tap a wonder to move it.") end
    else
        R.say_at(("%d WONDERS  -  NEW LAND AWAITS"):format(c.count), vec2(240, 768), 15, PAL_WHITE, 0)
        R.say_at("SCROLL THE ISLAND. TAP A BUILDING TO MOVE IT.", vec2(240, 797), 11, PAL_WHITE, 0)
        if R.button(rect(58, 824, 364, 40), ("PLAY HEX LEVEL %d"):format(R.prog.level + 1), true) then
            if R.g.level == R.prog.level and not R.g.won and not R.g.lost then R.on_island = false
            else R.start_level() end
        end
    end
end

function R.island_screen(inp, dt)
    local c = R.island
    local cam = c.cam
    cam.view = MAP_VIEW
    c.cam = cam
    if R.overlay == R.OV_NONE then
        local ev = c:update(inp, R.prog.wallet, app.clock(), dt)
        if ev.result == city.PICKED then R.inspect, R.overlay = ev.building, R.OV_WONDER
        elseif ev.result == city.ZONE then R.zone_card, R.overlay = ev.zone, R.OV_ZONE end
    end

    gfx.rect(rect(0, 0, SCREEN_W, SCREEN_H), rgba(22, 110, 119))
    c:draw(inp, app.clock())
    if c.placing >= 0 then
        local ok = c:can_place(c.ghost, c.placing, c.moving)
        local p = c.cam:to_screen(c.ghost)
        gfx.clip(MAP_VIEW)
        gfx.round_rect(rect(p.x - 60, p.y + 15, 120, 26), 9, rgba(23, 64, 48, 235))
        R.say_at(ok and "LOOKS GOOD" or "CAN'T PLACE", p + vec2(0, 26), 13, ok and PAL_GREEN or PAL_CREAM, 0)
        gfx.unclip()
    end
    R.vfx_particles()
    R.bubble_time = R.bubble_time - dt
    if R.bubble_time > 0 and R.bubble_wonder >= 0 and R.bubble_wonder < c.count then
        local sprite = c.cam:rect_to_screen(c:sprite_rect(c.items[R.bubble_wonder + 1]))
        gfx.clip(MAP_VIEW)
        story.bubble(sprite:point(vec2(.5, .08)), R.bubble_text, R.speech_style(15), rgba(255, 246, 222, 245), rgba(102, 68, 39), 220, story.SPEECH)
        gfx.unclip()
    end

    -- the HUD is drawn after the map, so tall buildings never cover buttons
    gfx.rect(rect(0, 0, SCREEN_W, 92), rgba(13, 62, 58, 225))
    R.draw_header(true)
    local stats = rect(15, 170, 290, 30)
    gfx.round_rect(stats, 10, rgba(22, 68, 52, 220))
    ui.block(stats)
    R.say_at(("STARS %d   COMPASSES %d"):format(R.prog.wallet[STARS], R.prog.wallet[COMPASSES]), vec2(160, 182), 16, PAL_GOLD, 275)
    if map_button(rect(318, 170, 146, 30), "EXPAND  +", 16, rgba(47, 105, 67, 245)) then expand() end
    local dark = rgba(24, 70, 55, 235)
    if map_button(rect(15, 675, 48, 45), "-", 31, dark) then c.cam = c.cam:zoom_at(1 / 1.2, MAP_VIEW:center()) end
    if map_button(rect(72, 675, 48, 45), "+", 31, dark) then c.cam = c.cam:zoom_at(1.2, MAP_VIEW:center()) end
    if map_button(rect(355, 675, 110, 45), "MAP", 20, dark) then
        if c.cam.zoom > .35 then R.island_focus(vec2(island.ISLAND_W / 2, island.ISLAND_H / 2), .25)
        else R.island_focus(vec2(760, 2010), .65) end
    end
    bottom_panel()
end

return R
