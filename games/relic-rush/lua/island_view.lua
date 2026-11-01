-- island_view.lua — the restored island: an engine city with the expedition's
-- HUD, region markers in the fog, placement and the bottom controls.
local R = require("state")
local rules = require("rules")
local island = require("island")
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
            R.notice("Earn more expedition treasures to build this.")
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
        R.notice("Earn more expedition treasures to build this."); return
    end
    local ev = c:confirm(R.prog.wallet, app.clock())
    if ev.result ~= city.BUILT and ev.result ~= city.MOVED then
        R.notice("Choose open grass clear of other buildings.")
        return
    end
    for k = 0, 23 do R.vfx_emit(ev.screen - vec2(0, 30), k % 6, false) end
    R.bubble_wonder = ev.building   -- the island answers in a word bubble over the building
    local definition=R.buildings[c.items[ev.building+1].type+1]
    R.bubble_text=definition.name.."\n"..definition.about
    R.tone(740)
    if fresh and c.items[ev.building+1].type < island.WONDERS then   -- Tomas tells each wonder's story once; the last one brings Adrian
        local kind = c.items[ev.building + 1].type
        local w = R.wonders[kind + 1]
        story.play(("wonder-%d"):format(kind), {{"tomas", w.about}})
        if island.wonder_count(c) == island.WONDERS then
            story.play("finale", R.finale)
            R.overlay = R.OV_FINALE
        end
    end
    R.save_progress()
end

function R.expand()
    local z = R.island:next_zone(R.prog.wallet)
    if z < 0 then R.notice("Your whole island is open to explore.")
    else R.zone_card, R.overlay = z, R.OV_ZONE end
end

-- Region markers float over the fog: "+" when the region can open now, with a
-- breathing glow, so they replace a separate expand button. The name is plain
-- outlined text, without a plate.
local function draw_markers(c)
    local cam = c.cam
    local zones = c.zones
    for z = 1, c.zone_count - 1 do
        if not c:zone_open(z) then
            local p = cam:to_screen(zones[z + 1].marker)
            if not (p.x < -90 or p.x > SCREEN_W + 90 or p.y < cam.view.y - 50 or p.y > cam.view:max().y + 40) then
                local ready = c:zone_available(z, R.prog.wallet)
                if ready and not R.reduced_motion then
                    gfx.glow(p, 40, rgba(255, 220, 120, 110 + 60 * math.sin(R.now * 3)), rgba(255, 220, 120, 0))
                end
                gfx.circle(p + vec2(0, 2), 22, rgba(31, 35, 24, 90))
                gfx.circle(p, 21, rgba(102, 135, 101, 230))
                gfx.circle(p + vec2(0, -2), 18, ready and rgba(249, 211, 104) or rgba(231, 224, 185))
                R.say_at(ready and "+" or "?", p + vec2(0, -4), 25, PAL_CREAM, 0)
                R.say_at(zones[z + 1].name, p + vec2(0, 34), 15, PAL_CREAM, 160)
            end
        end
    end
end
R.draw_markers = draw_markers

-- No sheet over the map: one big Play button at the bottom, flanked by round
-- icon-only Expeditions and Shop buttons on the same horizontal centre line.
local function round_button(center, icon, diameter)
    diameter=diameter or 64
    local r = rect.centered(center, size2(diameter, diameter))
    ui.block(r)
    local st = ui.hit(r:offset(vec2(0, R.hit_dy)), 0)
    local c = st.held and center + vec2(0, 2) or center
    gfx.circle(center + vec2(0, 4), 32, rgba(5, 30, 28, 150))
    gfx.circle(c, 32, rgba(116, 74, 33))
    gfx.circle(c, 30, rgba(236, 196, 112))
    gfx.circle(c, 26, rgba(176, 120, 48))
    gfx.circle(c, 25, rgba(12, 62, 52))
    gfx.glow(c + vec2(0, -5), 21, rgba(40, 132, 100), rgba(12, 62, 52, 0))
    icon(c)
    return st.clicked
end
local PLAY_BOUNDS = rect(316, 786, 148, 92)
local BUILD_BOUNDS = rect(16, 786, 132, 92)
R.island_buttons = {expeditions=vec2(202,844),shop=BUILD_BOUNDS:center(),play=PLAY_BOUNDS:center()}
local navigation = ui.form{kind="row",gap=16,children={
    {kind="button",id="build",text="BUILDINGS",width=132,height=92,em=21},
    {kind="spacer",grow=1},
    {kind="button",id="play",text="PLAY",width=148,height=92,em=30},
}}

local placement_form = ui.form{kind="row",children={
    {kind="button",id="cancel",text="",width=56,height=56,role="placement_cancel"},
    {kind="spacer",grow=1},
    {kind="button",id="confirm",text="",width=56,height=56,role="placement_confirm",enabled_field="valid"},
}}
R.placement_form = placement_form

local function placement_controls(c)
    local sprite = c.cam:rect_to_screen(c:sprite_rect(building{pos=c.ghost,type=c.placing}))
    local width = math.min(416,math.max(152,sprite.w))
    local x = num.clamp(sprite:center().x-width/2,16,SCREEN_W-width-16)
    local y = num.clamp(sprite:max().y+12,110,app.screen().h-78)
    placement_form.values.valid = c:can_place(c:snap(c.ghost,c.placing),c.placing,c.moving)
    local event = placement_form:draw(rect(x,y,width,56),R.skin,{hit_offset=vec2(0,R.hit_dy)})
    if event and event.id=="cancel" then c:cancel(); R.notice("Your island is unchanged.")
    elseif event and event.id=="confirm" then confirm_place() end
end

local function bottom_controls()
    local c = R.island
    local y = R.drop
    local restored=island.wonder_count(c)
    if c.placing >= 0 then
        placement_controls(c)
        return
    end
    if round_button(R.island_buttons.expeditions + vec2(0,y),function(at) R.compass_icon(at,17) end) then R.open_expeditions() end
    local label=R.prog.level>=rules.LEVELS and "PLAY" or ("PLAY %d"):format(R.prog.level+1)
    navigation:set("play",label)
    local event=navigation:draw(rect(16,786+y,448,92),R.skin)
    if event and event.id=="build" then R.open_catalogue(restored<R.prog.level and "wonder" or "building")
    elseif event and event.id=="play" then
        if restored<R.prog.level then R.notice("Restore your earned wonder before the next discovery.");R.open_catalogue("wonder")
        elseif R.prog.level>=rules.LEVELS then R.open_expeditions()
        else R.play_level(R.prog.level) end
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
    -- A still has no physical pointer held down. Feed the real city gesture so
    -- --placing dragging actually captures the lifted sprite and ground shadow.
    if app.arg("shot") and app.arg("placing") == "dragging" and c.placing >= 0 then
        local p = c.cam:to_screen(c.ghost)
        city_input = input{pos=p, press_pos=p, down=true, dragging=true,
                           pressed=not R.capture_building_held, pinch=1}
        R.capture_building_held = true
    end
    local ev = c:update(city_input, R.prog.wallet, app.clock(), dt)
    if R.overlay == R.OV_NONE then
        if ev.result == city.PICKED then
            local definition=R.buildings[c.items[ev.building+1].type+1]
            R.bubble_wonder,R.bubble_text=ev.building,definition.name.."\n"..definition.about
        elseif ev.result == city.ZONE then R.zone_card, R.overlay = ev.zone, R.OV_ZONE end
    end

    gfx.bleed(true)
    gfx.rect(MAP_VIEW, rgba(22, 110, 119))
    c:draw(inp, app.clock())
    gfx.bleed(false)
    R.vfx_particles()
    if R.bubble_wonder >= 0 and R.bubble_wonder < c.count then
        local sprite = c.cam:rect_to_screen(c:sprite_rect(c.items[R.bubble_wonder + 1]))
        gfx.clip(MAP_VIEW)
        story.bubble(sprite:point(vec2(.5, .08)), R.bubble_text, R.speech_style(15), rgba(255, 246, 222, 245), rgba(102, 68, 39), 220, story.SPEECH)
        gfx.unclip()
    end

    -- the HUD is drawn after the map, so tall buildings never cover buttons;
    -- a placement shows itself on the ghost alone: red when it can't go there
    R.draw_header(true)
    bottom_controls()
end

return R
