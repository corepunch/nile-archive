-- island_view.lua — the restored island: an engine city with the expedition's
-- HUD, region markers in the fog, placement and the next-step panel.
local R = require("state")
local rules = require("rules")
local island = require("island")
local SCREEN_W = R.SCREEN_W
local PAL_GOLD, PAL_CREAM, PAL_WHITE = R.PAL_GOLD, R.PAL_CREAM, R.PAL_WHITE
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
    R.notice("Tap to choose a spot. Drag the building or scroll the land.")
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
    R.bubble_text = fresh and "A little more Christmas magic!" or "A cozy new home for this stall."
    R.bubble_time = 3.5
    R.tone(740)
    if fresh and c.items[ev.building+1].type < island.WONDERS then   -- Tomas tells each wonder's story once; the last one brings Adrian
        local kind = c.items[ev.building + 1].type
        local w = R.wonders[kind + 1]
        story.play(("wonder-%d"):format(kind), {{"noelle", w.about}})
        if island.wonder_count(c) == island.WONDERS then
            story.play("finale", R.finale)
            R.overlay = R.OV_FINALE
        end
    end
    R.save_progress()
end

function R.expand()
    local z = R.island:next_zone(R.prog.wallet)
    if z < 0 then R.notice("The whole market is open for Christmas!")
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

-- A sheet along the bottom edge: it runs on under the home indicator, so it
-- reads as part of the screen rather than a card floating above it.
local function bottom_panel()
    local c = R.island
    local full = app.bleed()
    local y = R.drop
    local sheet = rect(12, 758 + y, 456, full:max().y - 758 - y + 24)
    gfx.bleed(true)
    R.panel(sheet)
    gfx.bleed(false)
    ui.block(sheet)
    local restored=island.wonder_count(c)
    if c.placing >= 0 then
        local ok = c:can_place(c:snap(c.ghost, c.placing), c.placing, c.moving)
        R.say_at(R.buildings[c.placing + 1].name, vec2(240, 782 + y), 25, PAL_GOLD, 410)
        R.say_at("DRAG BUILDING TO MOVE  -  DRAG LAND TO SCROLL", vec2(240, 811 + y), 11, PAL_WHITE, 0)
        if R.button(rect(30, 834 + y, 142, 44), "CANCEL", true) then c:cancel(); R.notice("Your market is unchanged.") end
        if R.button(rect(188, 834 + y, 262, 44), c.moving < 0 and "PLACE & BUILD" or "CONFIRM MOVE", ok) then confirm_place() end
    elseif restored < R.prog.level then
        R.say_at(R.wonders[restored + 1].name, vec2(240, 782 + y), 25, PAL_GOLD, 410)
        R.say_at("CHOOSE ITS PLACE IN YOUR MARKET", vec2(240, 811 + y), 12, PAL_WHITE, 0)
        if R.button(rect(58, 834 + y, 364, 44), "CHOOSE A LOCATION", true) then R.inspect, R.inspect_item, R.overlay = restored, -1, R.OV_WONDER end
    elseif R.prog.level >= rules.LEVELS then
        R.say_at("Your Christmas market", vec2(240, 782 + y), 27, PAL_GOLD, 0)
        R.say_at("REPLAY WINTER WISHES TO EARN DECORATION GOLD", vec2(240, 811 + y), 12, PAL_WHITE, 0)
        if R.button(rect(58, 834 + y, 364, 44), "PLAY FOR GOLD", true) then R.open_expeditions() end
    else
        R.say_at(("LIGHT UP THE SQUARE  %d / 10"):format(restored), vec2(240, 783 + y), 15, PAL_WHITE, 0)
        R.say_at("DRAG TO SCROLL. HOLD A BUILDING TO MOVE IT.", vec2(240, 811 + y), 11, PAL_WHITE, 0)
        if R.button(rect(58, 834 + y, 364, 44), ("PLAY HEX LEVEL %d"):format(R.prog.level + 1), true) then
            R.play_level(R.prog.level)
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
    gfx.bleed(false)
    for i=1,42 do
        local x=(i*97+math.sin(R.now*.25+i)*18)%480
        local y=(i*137+R.now*(12+i%4*5))%(R.SCREEN_H+R.drop)
        gfx.circle(vec2(x,y),1+i%3*.4,rgba(255,255,255,140))
    end
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
    R.draw_header(true)
    if c.placing<0 and R.button(rect(18,704+R.drop,218,42),"WINTER WISHES",true) then R.open_expeditions() end
    if c.placing<0 and R.button(rect(300,704+R.drop,162,42),"BUILD SHOP",true) then R.open_catalogue() end
    bottom_panel()
end

return R
