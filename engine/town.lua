-- town.lua — the town screen every city game shares (Relic Rush, Christmas
-- Market, Nile Archive): the map under the safe screen, weather, region
-- markers, a word bubble when a building is tapped, Cancel/Confirm beside a
-- lifted building, the wallet capsules and menu along the top, and the Build,
-- middle and Play controls along the bottom.
--
-- Layout and wording come from a JSON file in the game's data root, merged
-- over the defaults below, so every game lays the town out the same way.
-- Behaviour the JSON cannot express arrives as hooks; the look is the game's
-- ui.skin (roles navigation_build, navigation_play, navigation_levels, placement_cancel,
-- placement_confirm and the resource role named in header.role).
--
--   local town = require("town")
--   local view = town.new(c, town.load("town.json"), hooks)
--   view:frame(inp, dt, active)   -- once per frame; active = no dialog or story
--
-- Hooks (all optional unless marked):
--   skin                    the game's ui.skin (required)
--   wallet()                the purse the city charges (required)
--   notice(text)            show a short message
--   capsules()              {{icon=texture|fn(box), value=string, note=string, width=n,
--                             reserve=n, decorate=fn(box)}, ...}
--   menu(bounds)            draw the top-right menu button; handle its tap
--   build(), play(), middle()   bottom actions
--   middle_icon(center)     the icon in the round middle button
--   draw_middle(center)     replaces the round middle button (middle.kind "custom")
--   about(item)             the bubble's words for a placed building (0-based item)
--   zone(z)                 a closed region's marker or land was tapped
--   event(ev)               any other city event (BUILT, BLOCKED, ...)
--   can_buy(kind)           may a new building of this kind be bought now
--   suggest(kind)           where to look for room for a new building
--   placed(ev, fresh)       after Confirm built or moved a building
--   bubble_text()           text_style for the bubble
--   reduced_motion()        weather holds still
--   draw_world(view)        extra world-space drawing over the map
--   overlay()               drawing between the map and the HUD (particles)
--   extras(screen)          game-only HUD (Nile Archive's player plate, ...)
--   hide_bottom()           true while a game panel (Nile Archive's build tray) replaces the bottom row
local json = require("json")
local T = {}

local DEFAULTS = {
    background = "#16707A",
    header = {x = 20, y = 20, width = 110, height = 36, gap = 18, role = "wallet", align = "left",
              overhang = 18, menu = {size = 88, inset = 4, y = -2}},
    bottom = {margin = 16, bottom = 22, height = 128, build = 132, play = 148,
              middle = {kind = "round", diameter = 64, gap = 22, from_bottom = 56,
                        colors = {shadow = "#051E1C96", rim = "#744A21", gold = "#ECC470", bronze = "#B07830",
                                  face = "#0C3E34", glow = "#288464"}}},
    placement = {button = 56, min_width = 152, max_width = 416, gap = 12, margin = 16, top = 110, bottom = 78},
    markers = {visible = true, label = 15, label_width = 160, glow = "#FFDC786E", text = "cream"},
    bubble = {width = 300, seconds = 0, fill = "#FFF6DEF5", edge = "#664427"},
    focus = {lift = 90, min_zoom = .65},
    texts = {
        placing = "Drag the building to choose a spot, or scroll the land.",
        unchanged = "Nothing changed.",
        blocked = "Choose open ground clear of other buildings.",
        cant_afford = "Not enough to build this yet.",
        cant_buy = "This building is not available yet.",
        no_room = "Open more land before placing this building.",
    },
}

local function merge(base, over)
    if type(over) ~= "table" or over == json.null then return base end
    local out = {}
    for k, v in pairs(base) do out[k] = v end
    for k, v in pairs(over) do
        if v == json.null then out[k] = nil   -- null clears a default
        elseif type(v) == "table" and type(base[k]) == "table" and #v == 0 then out[k] = merge(base[k], v)
        else out[k] = v end
    end
    return out
end

-- "#RRGGBB" or "#RRGGBBAA"
local function rgba(s)
    if type(s) ~= "string" then return s end
    local hex = s:gsub("^#", "")
    local function byte(i) return tonumber(hex:sub(i, i + 1), 16) or 255 end
    return color(byte(1), byte(3), byte(5), #hex >= 8 and byte(7) or 255)
end
T.color = rgba

-- The game's town config: its JSON over the engine defaults.
function T.load(path) return json.load(path) end
function T.config(over) return merge(DEFAULTS, over) end

local View = {}
View.__index = View

local function notice(v, key)
    local text = v.cfg.texts[key] or key
    if v.hooks.notice and text then v.hooks.notice(text) end
end

function T.new(c, config, hooks)
    assert(hooks and hooks.skin and hooks.wallet, "town.new needs hooks.skin and hooks.wallet")
    local cfg = T.config(config)
    local v = setmetatable({city = c, cfg = cfg, hooks = hooks, buttons = {}, time = 0}, View)
    local b, p = cfg.bottom, cfg.placement
    v.navigation = ui.form{kind = "row", gap = 16, children = {
        {kind = "button", id = "build", text = "", role = "navigation_build", width = b.build, height = b.height},
        {kind = "spacer", grow = 1},
        {kind = "button", id = "play", text = "", role = "navigation_play", width = b.play, height = b.height},
    }}
    if b.layout == "play-primary" then
        v.navigation = ui.form{kind = "row", align = "center", gap = 8, children = {
            {kind = "button", id = "build", text = "", role = "navigation_build", width = b.build, height = b.secondary_height},
            {kind = "spacer", grow = 1},
            {kind = "button", id = "play", text = "", role = "navigation_play", width = b.play, height = b.height},
            {kind = "spacer", grow = 1},
            {kind = "button", id = "levels", text = "", role = "navigation_levels", width = b.build, height = b.secondary_height},
        }}
    end
    v.placement_form = ui.form{kind = "row", children = {
        {kind = "button", id = "cancel", text = "", width = p.button, height = p.button, role = "placement_cancel"},
        {kind = "spacer", grow = 1},
        {kind = "button", id = "confirm", text = "", width = p.button, height = p.button, role = "placement_confirm", enabled_field = "valid"},
    }}
    if cfg.markers.visible then c.draw_over = function(city_) v:draw_markers(city_) end end
    v:layout()
    return v
end

-- Where the controls are, in screen units; tests click these.
function View:layout()
    local s, b, h = app.screen(), self.cfg.bottom, self.cfg.header
    local row = rect(s.x + b.margin, s:max().y - b.bottom - b.height, s.w - 2 * b.margin, b.height)
    self.bottom_row = row
    self.buttons.build = rect(row.x, row.y, b.build, b.height):center()
    self.buttons.play = rect(row:max().x - b.play, row.y, b.play, b.height):center()
    local m = b.middle
    self.buttons.middle = m.kind == "round" and vec2(row.x + b.build + m.gap + m.diameter / 2, s:max().y - m.from_bottom)
        or vec2(row:center().x, s:max().y - m.from_bottom)
    if b.layout == "play-primary" then
        -- Measured from the physical display edge (app.bleed includes the
        -- home-indicator inset), so Play's gap below matches Build's gap beside.
        row = rect(row.x, app.bleed():max().y - b.bottom - b.height, row.w, b.height)
        self.bottom_row = row
        self.buttons.build = vec2(row.x + b.build / 2, row:center().y)
        self.buttons.play = row:center()
        self.buttons.middle = vec2(row:max().x - b.build / 2, row:center().y)
        self.buttons.levels = self.buttons.middle
    end
    local size = h.menu.size
    self.menu_bounds = rect(s:max().x - size - h.menu.inset, s.y + h.menu.y, size, size)
    self.buttons.menu = self.menu_bounds:center()
    return self.buttons
end

function View:focus(world, zoom)
    local cam = self.city.cam
    cam.zoom = zoom or cam.zoom
    self.city.cam = cam:look(world):clamp()
end

-- Start placing a new building of `kind`, or moving placed `item`.
function View:begin(kind, focus, item)
    local c, h = self.city, self.hooks
    if item and item >= 0 then
        if item >= c.count then return false end
        c:begin_move(item)
    else
        if h.can_buy and not h.can_buy(kind) then notice(self, "cant_buy"); return false end
        local ok, spot = c:find_spot(kind, h.suggest and h.suggest(kind) or c.cam.center)
        if not ok then notice(self, "no_room"); return false end
        c:begin_place(kind, spot)
    end
    self.bubble = nil
    if focus then self:focus(c.ghost - vec2(0, self.cfg.focus.lift), math.max(self.cfg.focus.min_zoom, c.cam.zoom)) end
    notice(self, "placing")
    return true
end

function View:confirm()
    local c, h = self.city, self.hooks
    local fresh = c.moving < 0
    if fresh and h.can_buy and not h.can_buy(c.placing) then notice(self, "cant_buy"); return end
    local ev = c:confirm(h.wallet(), app.clock())
    if ev.result ~= city.BUILT and ev.result ~= city.MOVED then
        notice(self, ev.result == city.CANT_AFFORD and "cant_afford" or "blocked")
        return
    end
    self:say(ev.building)
    if h.placed then h.placed(ev, fresh) end
    return ev
end

function View:cancel()
    self.city:cancel()
    notice(self, "unchanged")
end

-- A word bubble over a placed building (0-based item).
function View:say(item, text, seconds)
    text = text or (self.hooks.about and self.hooks.about(item))
    if not text or text == "" then self.bubble = nil; return end
    local s = seconds or self.cfg.bubble.seconds
    self.bubble = {item = item, text = text, left = s > 0 and s or nil}
end

------------------------------------------------------------------ drawing

-- Region markers float over the fog: "+" with a breathing glow when the
-- region can open now, "?" otherwise; the name below is plain outlined text.
function View:draw_markers(c)
    local cam, zones, cfg = c.cam, c.zones, self.cfg.markers
    local skin = self.hooks.skin
    local reduced = self.hooks.reduced_motion and self.hooks.reduced_motion()
    local view = cam.view
    for z = 1, c.zone_count - 1 do
        if not c:zone_open(z) then
            local p = cam:to_screen(zones[z + 1].marker)
            if p.x > view.x - 90 and p.x < view:max().x + 90 and p.y > view.y - 50 and p.y < view:max().y + 40 then
                local ready = c:zone_available(z, self.hooks.wallet())
                if ready and not reduced then
                    local g = rgba(cfg.glow)
                    gfx.glow(p, 40, color(g.r, g.g, g.b, math.floor(110 + 60 * math.sin(self.time * 3))), color(g.r, g.g, g.b, 0))
                end
                gfx.circle(p + vec2(0, 2), 22, color(31, 35, 24, 90))
                gfx.circle(p, 21, color(102, 135, 101, 230))
                gfx.circle(p + vec2(0, -2), 18, ready and color(249, 211, 104) or color(231, 224, 185))
                local st = skin:text(cfg.text, 25)
                text.inside(st, rect.centered(p + vec2(0, -4), size2(40, 40)), vec2(.5, .5), ready and "+" or "?")
                local name = zones[z + 1].name
                if name then
                    text.inside(skin:text(cfg.text, cfg.label), rect.centered(p + vec2(0, 34), size2(cfg.label_width, cfg.label * 2)),
                                vec2(.5, .5), name)
                end
            end
        end
    end
end

local function draw_weather(v, view)
    local w = v.cfg.weather
    if not w or not w.snow then return end
    local snow = w.snow
    local reduced = v.hooks.reduced_motion and v.hooks.reduced_motion()
    local time = reduced and 0 or v.time
    -- The pattern is anchored to the world origin: a pan carries the flakes
    -- with the town while they keep falling. They fade before the controls.
    local origin = v.city.cam:to_screen(vec2(0, 0))
    local height = view.h * (snow.height or .86)
    local fade_from = snow.fade_from or .7
    for _, layer in ipairs(snow.layers) do
        for i = 1, layer.count do
            local y = (i * 137 + time * (layer.fall + i % 7 * 4) + origin.y) % (height + 12) - 6
            local drift = time * layer.drift + math.sin(time * .8 + i * 2.4) * layer.drift
            local x = (i * 97 + drift + layer.fall + origin.x) % (view.w + 12) - 6
            local at = vec2(view.x + x, view.y + y)
            local radius = layer.radius * (.65 + i % 5 * .15)
            local fade = 1 - num.saturate((y / height - fade_from) / (1 - fade_from))
            gfx.circle(at + vec2(0, .8), radius + .65, color(60, 94, 137, math.floor(70 * fade)))
            gfx.circle(at, radius, color(248, 252, 255, math.floor(layer.opacity * fade)))
        end
    end
end

function View:header()
    local h, cfg, skin = self.hooks, self.cfg.header, self.hooks.skin
    local s = app.screen()
    local caps = h.capsules and h.capsules() or {}
    local right_edge = h.menu and self.menu_bounds.x - cfg.gap or s:max().x - cfg.x
    local x = cfg.align == "right" and right_edge or s.x + cfg.x
    local from, to, step = 1, #caps, 1
    if cfg.align == "right" then from, to, step = #caps, 1, -1 end   -- the first capsule still reads first
    for k = from, to, step do
        local cap = caps[k]
        local w = cap.width or cfg.width
        local r
        if cfg.align == "right" then r = rect(x - w, s.y + cfg.y, w, cfg.height); x = x - w - cfg.gap - cfg.overhang
        else r = rect(x, s.y + cfg.y, w, cfg.height); x = x + w + cfg.gap end
        local hit = rect(r.x - cfg.overhang, r.y - 12, r.w + cfg.overhang, r.h + 24)
        local tapped = skin:draw_resource(r, cap.icon, cap.value, {role = cfg.role, hit = hit, reserve = cap.reserve})
        if cap.decorate then cap.decorate(r) end
        if tapped and cap.note and h.notice then h.notice(cap.note) end
    end
    if h.menu then h.menu(self.menu_bounds) end
end

local function round_button(v, center)
    local m = v.cfg.bottom.middle
    local col = m.colors
    local d = m.diameter
    local r = rect.centered(center, size2(d, d))
    ui.block(r)
    local st = ui.hit(r, 0)
    local c = st.held and center + vec2(0, 2) or center
    local R = d / 2
    gfx.circle(center + vec2(0, 4), R, rgba(col.shadow))
    gfx.circle(c, R, rgba(col.rim))
    gfx.circle(c, R - 2, rgba(col.gold))
    gfx.circle(c, R - 6, rgba(col.bronze))
    gfx.circle(c, R - 7, rgba(col.face))
    local face = rgba(col.face)
    gfx.glow(c + vec2(0, -5), R - 11, rgba(col.glow), color(face.r, face.g, face.b, 0))
    if v.hooks.middle_icon then v.hooks.middle_icon(c) end
    return st.clicked
end

function View:bottom()
    local h, skin = self.hooks, self.hooks.skin
    local m = self.cfg.bottom.middle
    if self.cfg.bottom.layout ~= "play-primary" and m.kind == "round" then
        if round_button(self, self.buttons.middle) and h.middle then h.middle() end
    elseif self.cfg.bottom.layout ~= "play-primary" and h.draw_middle then h.draw_middle(self.buttons.middle) end
    local primary = self.cfg.bottom.layout == "play-primary"
    if primary then gfx.bleed(true) end
    local event = self.navigation:draw(self.bottom_row, skin)
    if primary then gfx.bleed(false) end
    if event and event.id == "build" and h.build then h.build()
    elseif event and event.id == "play" and h.play then h.play()
    elseif event and event.id == "levels" and h.middle then h.middle() end
end

-- Cancel and Confirm stand under the lifted building, kept on screen.
function View:placement()
    local c, p = self.city, self.cfg.placement
    local s = app.screen()
    local sprite = c.cam:rect_to_screen(c:sprite_rect(building{pos = c.ghost, type = c.placing}))
    local width = math.min(p.max_width, math.max(p.min_width, sprite.w))
    local x = num.clamp(sprite:center().x - width / 2, s.x + p.margin, s:max().x - width - p.margin)
    local y = num.clamp(sprite:max().y + p.gap, s.y + p.top, s:max().y - p.bottom)
    local f = self.placement_form
    f.values.valid = c:can_place(c:snap(c.ghost, c.placing), c.placing, c.moving)
        and (c.moving >= 0 or not self.hooks.can_buy or self.hooks.can_buy(c.placing))
    local event = f:draw(rect(x, y, width, p.button), self.hooks.skin)
    if event and event.id == "cancel" then self:cancel()
    elseif event and event.id == "confirm" then self:confirm() end
end

function View:frame(inp, dt, active)
    local c, h = self.city, self.hooks
    self.time = self.time + dt
    self:layout()
    local view = app.bleed()
    local cam = c.cam
    cam.view = view
    c.cam = cam
    local city_input = active and inp or input{pos = inp.pos, pinch = 1}
    -- A still has no pointer held down: feed the real gesture so a
    -- "--placing dragging" capture shows the lifted sprite and its shadow.
    if app.arg("shot") and app.arg("placing") == "dragging" and c.placing >= 0 then
        local p = c.cam:to_screen(c.ghost)
        city_input = input{pos = p, press_pos = p, down = true, dragging = true, pressed = not self.held_for_shot, pinch = 1}
        self.held_for_shot = true
    end
    if city_input.pressed then self.bubble = nil end   -- a tap anywhere dismisses the bubble; a building tap reopens it
    local ev = c:update(city_input, h.wallet(), app.clock(), dt)
    if active and ev.result ~= city.NONE then
        if ev.result == city.PICKED then self:say(ev.building)
        elseif ev.result == city.ZONE then if h.zone then h.zone(ev.zone) end
        elseif h.event then h.event(ev) end
    end

    gfx.bleed(true)
    gfx.rect(view, rgba(self.cfg.background))
    c:draw(inp, app.clock())
    draw_weather(self, view)
    if h.draw_world then h.draw_world(view) end
    gfx.bleed(false)
    if h.overlay then h.overlay() end

    local b = self.bubble
    if b and b.left then
        b.left = b.left - dt
        if b.left <= 0 then self.bubble, b = nil, nil end
    end
    if b and b.item >= 0 and b.item < c.count and c.placing < 0 then
        local sprite = c.cam:rect_to_screen(c:sprite_rect(c.items[b.item + 1]))
        local style = h.bubble_text and h.bubble_text() or h.skin:text(self.cfg.markers.text, 15)
        gfx.clip(view)
        story.bubble(sprite:point(vec2(.5, .08)), b.text, style, rgba(self.cfg.bubble.fill), rgba(self.cfg.bubble.edge),
                     self.cfg.bubble.width, story.SPEECH)
        gfx.unclip()
    end

    -- The HUD is drawn after the map, so tall buildings never cover buttons.
    self:header()
    if c.placing >= 0 then self:placement()
    elseif not (h.hide_bottom and h.hide_bottom()) then self:bottom() end
    if h.extras then h.extras(app.screen()) end
end

return T
