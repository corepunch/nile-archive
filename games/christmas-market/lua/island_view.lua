-- island_view.lua — the restored island: an engine city with the expedition's
-- HUD, region markers in the fog, placement and the bottom controls.
local R = require("state")
local rules = require("rules")
local island = require("island")
local journey = require("journey")
local SCREEN_W = R.SCREEN_W
local PAL_CREAM = R.PAL_CREAM
local rgba = color

function R.island_focus(world, zoom)
    local cam = R.island.cam
    cam.zoom = zoom
    R.island.cam = cam:look(world):clamp()
end

-- Start placing the next wonder (or moving a built one) and look at it.
function R.island_begin(kind, focus, item)
    local c = R.island
    if item and item>=0 then
        if item>=c.count then return end
        c:begin_move(item)
    else
        if not island.can_buy(c,R.prog.wallet,R.prog.level,kind) then
            R.notice("Complete winter wishes to fund this building.")
            return
        end
        local ok,spot=c:find_spot(kind,island.island_suggestion(math.min(kind,9)))
        if not ok then R.notice("Open more land before placing this building."); return end
        c:begin_place(kind,spot)
    end
    R.overlay, R.inspect = R.OV_NONE, -1
    if focus then R.island_focus(c.ghost-vec2(0,90),math.max(.65,c.cam.zoom)) end
    R.notice("Drag the building to choose a spot, or scroll the land.")
end

local function confirm_place()
    local c = R.island
    local fresh = c.moving < 0
    if fresh and not island.can_buy(c,R.prog.wallet,R.prog.level,c.placing) then
        R.notice("Complete winter wishes to fund this building."); return
    end
    local ev = c:confirm(R.prog.wallet, app.clock())
    if ev.result ~= city.BUILT and ev.result ~= city.MOVED then
        R.notice("Choose open snow clear of other buildings.")
        return
    end
    for k = 0, 23 do R.vfx_emit(ev.screen - vec2(0, 30), k % 6, false) end
    R.bubble_wonder = ev.building   -- the island answers in a word bubble over the building
    -- The building's story beat follows from narrative.lua once it stands.
    local kind = c.items[ev.building + 1].type
    R.bubble_text = journey.building_about(kind, R.prog.level, fresh and "A little more Christmas magic!" or "A cozy new home for this stall.")
    R.bubble_time = 3.5
    R.tone(740)
    R.save_progress()
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

-- The same bottom controls as Relic Rush, in the market's skin: Build in the
-- left corner, Play in the right, and the winter wishes medallion between.
local function round_button(center, icon, diameter)
    diameter = diameter or 64
    local r = rect.centered(center, size2(diameter, diameter))
    ui.block(r)
    local st = ui.hit(r:offset(vec2(0, R.hit_dy)), 0)
    local c = st.held and center + vec2(0, 2) or center
    gfx.circle(center + vec2(0, 4), 32, rgba(5, 30, 28, 150))
    gfx.circle(c, 32, rgba(116, 74, 33))
    gfx.circle(c, 30, rgba(236, 196, 112))
    gfx.circle(c, 26, rgba(176, 120, 48))
    gfx.circle(c, 25, rgba(22, 70, 48))
    gfx.glow(c + vec2(0, -5), 21, rgba(44, 120, 80), rgba(22, 70, 48, 0))
    icon(c)
    return st.clicked
end
local PLAY_BOUNDS = rect(316, 750, 148, 128)
local BUILD_BOUNDS = rect(16, 750, 132, 128)
R.island_buttons = {expeditions = vec2(202, 844), shop = BUILD_BOUNDS:center(), play = PLAY_BOUNDS:center()}
local navigation = ui.form{kind = "row", gap = 16, children = {
    {kind = "button", id = "build", text = "", role = "navigation_build", width = 132, height = 128},
    {kind = "spacer", grow = 1},
    {kind = "button", id = "play", text = "", role = "navigation_play", width = 148, height = 128},
}}

local placement_form = ui.form{kind = "row", children = {
    {kind = "button", id = "cancel", text = "", width = 56, height = 56, role = "placement_cancel"},
    {kind = "spacer", grow = 1},
    {kind = "button", id = "confirm", text = "", width = 56, height = 56, role = "placement_confirm", enabled_field = "valid"},
}}
R.placement_form = placement_form

local function placement_controls(c)
    local sprite = c.cam:rect_to_screen(c:sprite_rect(building{pos = c.ghost, type = c.placing}))
    local width = math.min(416, math.max(152, sprite.w))
    local x = num.clamp(sprite:center().x - width / 2, 16, SCREEN_W - width - 16)
    local y = num.clamp(sprite:max().y + 12, 110, app.screen().h - 78)
    placement_form.values.valid = c:can_place(c:snap(c.ghost, c.placing), c.placing, c.moving)
    local event = placement_form:draw(rect(x, y, width, 56), R.skin, {hit_offset = vec2(0, R.hit_dy)})
    if event and event.id == "cancel" then c:cancel(); R.notice("Your market is unchanged.")
    elseif event and event.id == "confirm" then confirm_place() end
end

local function bottom_controls()
    local c = R.island
    local y = R.drop
    local restored = island.wonder_count(c)
    if c.placing >= 0 then
        placement_controls(c)
        return
    end
    if round_button(R.island_buttons.expeditions + vec2(0, y), function(at)
        gfx.image(R.hud_art.complete, rect.centered(at, size2(44, 44)), color.WHITE)
    end) then R.open_expeditions() end
    local event = navigation:draw(rect(16, 750 + y, 448, 128), R.skin)
    if event and event.id == "build" then R.open_catalogue(restored < journey.earned(R.prog.level) and "wonder" or "building")
    elseif event and event.id == "play" then
        if restored < journey.earned(R.prog.level) then R.notice("Build your earned stall before the next winter wish."); R.open_catalogue("wonder")
        elseif R.prog.level >= rules.LEVELS then R.open_expeditions()
        else R.play_level(R.prog.level) end
    end
end

local snow_layers = {
    {count = 84, radius = 1.4, fall = 36, drift = 11, opacity = 175},
    {count = 44, radius = 2.6, fall = 62, drift = 19, opacity = 235},
}

-- Flakes ride the map: their pattern is anchored to the world origin, so a
-- pan or zoom carries them with the village while they keep falling. They
-- fade out before the bottom controls.
local function draw_snow(view, cam)
    local height = view.h * .86
    local time = R.reduced_motion and 0 or R.now
    local origin = cam:to_screen(vec2(0, 0))
    for _, layer in ipairs(snow_layers) do
        for i = 1, layer.count do
            local y = (i * 137 + time * (layer.fall + i % 7 * 4) + origin.y) % (height + 12) - 6
            local drift = time * layer.drift + math.sin(time * .8 + i * 2.4) * layer.drift
            local x = (i * 97 + drift + layer.fall + origin.x) % (view.w + 12) - 6
            local at = vec2(view.x + x, view.y + y)
            local radius = layer.radius * (.65 + i % 5 * .15)
            local fade = 1 - num.saturate((y / height - .7) / .3)
            gfx.circle(at + vec2(0, .8), radius + .65, rgba(60, 94, 137, 70 * fade))
            gfx.circle(at, radius, rgba(248, 252, 255, layer.opacity * fade))
        end
    end
end

-- The island fills the whole display, safe-area margins included, and the HUD
-- floats over it inside the safe screen, as island screens of match-3 games do.
function R.island_screen(inp, dt)
    local c = R.island
    local MAP_VIEW = app.bleed()
    local cam = c.cam
    cam.view = MAP_VIEW
    c.cam = cam
    local city_input=R.overlay==R.OV_NONE and inp or input{pos=inp.pos,pinch=1}
    local ev = c:update(city_input, R.prog.wallet, app.clock(), dt)
    if R.overlay == R.OV_NONE then
        if ev.result == city.PICKED then R.inspect, R.inspect_item, R.overlay = c.items[ev.building+1].type, ev.building, R.OV_WONDER
        elseif ev.result == city.ZONE then R.zone_card, R.overlay = ev.zone, R.OV_ZONE end
    end

    gfx.bleed(true)
    gfx.rect(MAP_VIEW, rgba(115, 143, 181))
    c:draw(inp, app.clock())
    draw_snow(MAP_VIEW, c.cam)
    gfx.bleed(false)
    R.vfx_particles()
    R.bubble_time = R.bubble_time - dt
    if R.bubble_time > 0 and R.bubble_wonder >= 0 and R.bubble_wonder < c.count then
        local sprite = c.cam:rect_to_screen(c:sprite_rect(c.items[R.bubble_wonder + 1]))
        gfx.clip(MAP_VIEW)
        story.bubble(sprite:point(vec2(.5, .08)), R.bubble_text, R.speech_style(15), rgba(255, 246, 222, 245), rgba(102, 68, 39), 220, story.SPEECH)
        gfx.unclip()
    end

    -- the HUD is drawn after the map, so tall buildings never cover buttons;
    -- a placement shows itself on the ghost alone: red when it can't go there
    R.draw_header()
    bottom_controls()
end

return R
