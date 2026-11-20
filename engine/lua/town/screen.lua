-- The town screen shared by Relic Rush, Christmas
-- Market, Nile Archive): the map under the safe screen, weather, region
-- markers, a word bubble when a building is tapped, Cancel/Confirm beside a
-- lifted building, the wallet capsules and menu along the top, and the Build,
-- middle and Play controls along the bottom.
--
-- Layout and wording come from the game's town_config.lua, merged
-- over the defaults below, so every game lays the town out the same way.
-- Behaviour the table cannot express arrives as hooks; the look is the game's
-- ui.skin (roles navigation_build, navigation_play, placement_cancel,
-- placement_confirm and the resource role named in header.role).
--
--   local town = require("town.screen")
--   local view = town.new(c, require("town_config"), hooks)
--   view:frame(inp, dt, active)   -- once per frame; active = no dialog or story
--
-- Hooks (all optional unless marked):
--   skin                    the game's ui.skin (required)
--   wallet()                the purse the city charges (required)
--   notice(text)            show a short message
--   capsules()              {{icon=texture|fn(box), value=string, note=string, width=n, slot=wallet slot,
--                             reserve=n, decorate=fn(box)}, ...}
--   menu(bounds)            draw and handle an optional header menu
--   build(), play(), middle(), pause()   bottom actions
--   build_rim(center, radius)           optional effect around the Build button
--   rail()                  {{id=, icon=texture, value=string, ready=bool, waiting=bool,
--                            portrait=texture, progress=0..1}, ...}: round
--                           markers down the left edge, under the header (requests, tasks)
--   rail_tap(id)            a rail marker was tapped
--   rail_paint(box, entry, state, ready_time)   paints one marker's face and icon (default: a plain disc)
--   play_label()            optional caption on Play
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
local N = ui.node

local T = {}
T.none = {}   -- in a game's town_config.lua, clears a default

local DEFAULTS = {
    background = "#16707A",
    header = {x = 20, y = 20, width = 110, height = 36, gap = 18, role = "wallet", align = "left",
              overhang = 18, menu = {size = 88, inset = 4, y = -2}},
    bottom = {margin = 16, bottom = 22, height = 128, build = 132, play = 148,
              middle = {kind = "round", diameter = 64, gap = 22, from_bottom = 56,
                        colors = {shadow = "#051E1C96", rim = "#744A21", gold = "#ECC470", bronze = "#B07830",
                                  face = "#0C3E34", glow = "#288464"}}},
    placement = {button = 56, min_width = 152, max_width = 416, gap = 12, margin = 16, top = 110, bottom = 78},
    -- Markers of `size` stacked from `top` below the safe screen's top edge;
    -- each figure sits in a `caption`-tall readout of the `role` resource look.
    rail = {x = 10, top = 96, size = 60, gap = 12, caption = 22, role = "wallet", text = "cream",
            glow = "#FFDC786E", rim = "#668765E6", face = "#E7E0B9", ready = "#F9D368", shadow = "#1F23185A"},
    markers = {visible = true, label = 15, label_width = 160, glow = "#FFDC786E", text = "cream"},
    bubble = {width = 300, seconds = 0, fill = "#FFF6DEF5", edge = "#664427"},
    focus = {lift = 90, min_zoom = .65},
    texts = {
        placing = "Drag the building to choose a spot, or scroll the land.",
        restoring = "Confirm to restore this building at its original site.",
        unchanged = "Nothing changed.",
        blocked = "Choose open ground clear of other buildings.",
        cant_afford = "Not enough to build this yet.",
        cant_buy = "This building is not available yet.",
        no_room = "Open more land before placing this building.",
    },
}

local function merge(base, over)
    if type(over) ~= "table" or over == T.none then return base end
    local out = {}
    for k, v in pairs(base) do out[k] = v end
    for k, v in pairs(over) do
        if v == T.none then out[k] = nil   -- town.none clears a default
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

-- The game's town config over the engine defaults.
-- A speech bubble whose first line is a title: larger and bold (the same fill
-- as an outline, since the skins carry one weight per font), then the subtitle.
-- The town config can choose the skin's text and color palettes.
local TITLE_SCALE = 1.3
local function bubble_draw(tip, utf8, sub, fill, edge, max_width, title_style)
    local title, rest = utf8:match("^([^\n]*)\n(.*)$")
    if not title then
        story.bubble(tip, utf8, sub, fill, edge, max_width, story.SPEECH)
        return
    end
    local head = title_style or style.outlined(style.sized(sub, sub.size * TITLE_SCALE), sub.size * 0.035, sub.fill)
    local pad, vpad, gap = sub.size * .7, sub.size * .55, sub.size * .15
    local top = vpad - sub.size * .28   -- the title's line box reaches above its capitals; trim it so both gaps look equal
    local inner = max_width - 2 * pad
    local a, b = text.box_size(head, inner, title), text.box_size(sub, inner, rest)
    local size = size2(math.max(a.w, b.w) + 2 * pad, a.h + gap + b.h + top + vpad)
    local screen = app.screen()
    local box = rect.anchor(tip - vec2(0, 22), size, vec2(.5, 1))
    local margin = 8
    if rect.pos(box).y < rect.pos(screen).y + margin then box = rect.anchor(tip + vec2(0, 22), size, vec2(.5, 0)) end
    local lo = rect.pos(screen) + vec2(margin, margin)
    box = rect.make(vec2.clamp(rect.pos(box), lo, rect.max(screen) - vec2(size.w, size.h) - vec2(margin, margin)), size)
    story.bubble_shape(box, tip, fill, edge, story.SPEECH)
    local inside = rect.make(rect.pos(box) + vec2(pad, top), size2(size.w - 2 * pad, size.h - top - vpad))
    text.box(head, inside:top(a.h), vec2(.5, .5), title)
    text.box(sub, inside:bottom(b.h), vec2(.5, .5), rest)
end

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
    v.navigation = ui.form(N.row {gap = 16,
        N.button {id = "build", text = "", role = "navigation_build", width = b.build, height = b.height},
        N.spacer {grow = 1},
        N.button {id = "play", text = "", role = "navigation_play", width = b.play, height = b.height},
    })
    if b.layout == "play-primary" and b.pause then
        v.navigation = ui.form(N.row {align = "center", gap = 8,
            N.spacer {grow = 1},
            N.button {id = "build", text = "", role = "navigation_build", width = b.build, height = b.secondary_height},
            N.button {id = "play", text = "", role = "navigation_play", width = b.play, height = b.height},
            N.button {id = "pause", text = "", role = "navigation_pause", width = b.build, height = b.secondary_height},
            N.spacer {grow = 1},
        })
    elseif b.layout == "play-primary" then
        v.navigation = ui.form(N.row {align = "center", gap = 8,
            N.button {id = "build", text = "", role = "navigation_build", width = b.build, height = b.secondary_height},
            N.spacer {grow = 1},
            N.button {id = "play", text = "", role = "navigation_play", width = b.play, height = b.height},
            N.spacer {grow = 1},
            N.spacer {width = b.build},   -- balances Build, so Play stays centred
        })
    end
    v.placement_form = ui.form(N.row {
        N.button {id = "cancel", text = "", width = p.button, height = p.button, role = "placement_cancel"},
        N.spacer {grow = 1},
        N.button {id = "confirm", text = "", width = p.button, height = p.button, role = "placement_confirm", enabled_field = "valid"},
    })
    if cfg.markers.visible then c.draw_over = function(city_) v:draw_markers(city_) end end
    v:layout()
    return v
end

-- Where the controls are, in screen units; tests click these.
function View:layout()
    local s, b = app.screen(), self.cfg.bottom
    local row = rect(s.x + b.margin, s:max().y - b.bottom - b.height, s.w - 2 * b.margin, b.height)
    self.bottom_row = row
    self.buttons.build = rect(row.x, row.y, b.build, b.height):center()
    self.buttons.play = rect(row:max().x - b.play, row.y, b.play, b.height):center()
    local m = b.middle
    self.buttons.middle = m.kind == "round" and vec2(row.x + b.build + m.gap + m.diameter / 2, s:max().y - m.from_bottom)
        or vec2(row:center().x, s:max().y - m.from_bottom)
    if b.layout == "play-primary" then
        if not b.pause then
            -- The variant without Pause extends to the physical edge.
            row = rect(row.x, app.bleed():max().y - b.bottom - b.height, row.w, b.height)
        end
        self.bottom_row = row
        local boxes = self.navigation:layout(row, self.hooks.skin)
        self.buttons.build = boxes.build:center()
        self.buttons.play = boxes.play:center()
        self.buttons.middle = nil   -- this layout has no middle control
        self.buttons.pause = boxes.pause and boxes.pause:center()
    end
    self:header_layout({})
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
        if c.moving ~= item then return false end
    else
        if h.can_buy and not h.can_buy(kind) then notice(self, "cant_buy"); return false end
        local ok, spot = c:find_spot(kind, h.suggest and h.suggest(kind) or c.cam.center)
        if not ok then notice(self, "no_room"); return false end
        c:begin_place(kind, spot)
    end
    self:dismiss_bubble()
    if focus then self:focus(c.ghost - vec2(0, self.cfg.focus.lift), math.max(self.cfg.focus.min_zoom, c.cam.zoom)) end
    local site = c.defs[kind + 1].fixed_site
    notice(self, (site.x ~= 0 or site.y ~= 0) and "restoring" or "placing")
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
    if not text or text == "" then self:dismiss_bubble(); return end
    local s = seconds or self.cfg.bubble.seconds
    local instant = self.hooks.reduced_motion and self.hooks.reduced_motion()
        or (app.arg("shot") and not app.arg("reel"))
    self.bubble = {item = item, text = text, left = s > 0 and s or nil, motion=ui.popup_motion(instant)}
end

function View:dismiss_bubble()
    local b = self.bubble
    if b then
        b.motion:close(function() self.bubble = nil end, self.hooks.reduced_motion and self.hooks.reduced_motion())
    end
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
    -- Every flake owns an irrational-stride column and phase (so none share a
    -- path or arrive together) and its own fall speed and sway. Flakes are soft
    -- radial blobs with no outline or shadow.
    local span = height + 24
    for li, layer in ipairs(snow.layers) do
        for i = 1, layer.count do
            local k = i + li * 1000
            local r1 = (k * 0.6180339887) % 1
            local r2 = (k * 0.7548776662) % 1
            local r3 = (k * 0.5698402910) % 1
            local speed = layer.fall * (.7 + r3 * .6)
            local y = (r2 * span + time * speed + origin.y) % span - 12
            local sway = math.sin(time * (.5 + r1 * .6) + k * 2.4) * layer.drift
            local x = (r1 * (view.w + 24) + time * layer.drift * .35 + sway + origin.x) % (view.w + 24) - 12
            local radius = layer.radius * (.7 + r3 * .8) * 1.8
            local fade = 1 - num.saturate((y / height - fade_from) / (1 - fade_from))
            if y > -6 then
                local a = math.floor(layer.opacity * fade * (.65 + r2 * .35))
                gfx.glow(vec2(view.x + x, view.y + y), radius, color(255, 255, 255, a), color(255, 255, 255, 0))
            end
        end
    end
end

-- The header is one row, vertically centred: the wallet capsules and the menu
-- button share a centre line however tall each is. A capsule's node includes
-- its icon's overhang to the left of the pill.
function View:header_layout(caps, cfg)
    cfg = cfg or self.cfg.header
    local s, leading_width = app.screen(), cfg.leading_width
    local menu, oh = self.hooks.menu and cfg.menu, cfg.overhang
    local right, center = cfg.align == "right", cfg.align == "center"
    local h = menu and menu.size or cfg.band_height or cfg.height
    local top = s.y + (menu and menu.y or cfg.y)
    local left = s.x + cfg.x - ((right or center) and 0 or oh)
    local band = rect(left, top, s:max().x - (menu and menu.inset or cfg.x) - left, h)
    local gap = right and cfg.gap or cfg.gap - oh
    local spacer = right or menu
    local count = #caps + (leading_width and 1 or 0) + (menu and 1 or 0) + (spacer and 1 or 0)
    local reserved = (leading_width or 0) + (menu and menu.size or 0) + #caps * oh
        + math.max(0, count - 1) * gap
    local wanted = 0
    local key = {cfg.align, leading_width or 0}
    for _, cap in ipairs(caps) do
        local width = cap.width or cfg.width
        wanted = wanted + width
        key[#key + 1] = width
    end
    -- Preserve the moves and square menu slots when the row runs out of room.
    local scale = wanted > 0 and num.clamp((band.w - reserved) / wanted, 0, 1) or 1
    if center then band = rect.centered(band:center(), size2(reserved + wanted * scale, h)) end
    key[#key + 1] = scale
    key = table.concat(key, ",")
    if self.header_cfg ~= cfg or self.header_key ~= key then
        local children = {}
        if right then children[1] = N.spacer {grow = 1} end
        if leading_width then
            children[#children + 1] = N.custom {id = "leading", width = leading_width, height = cfg.height}
        end
        for k, cap in ipairs(caps) do
            children[#children + 1] = N.custom {id = "cap" .. k,
                width = oh + (cap.width or cfg.width) * scale, height = cfg.height}
        end
        if menu then
            if not right then children[#children + 1] = N.spacer {grow = 1} end
            children[#children + 1] = N.custom {id = "menu", width = menu.size, height = menu.size}
        end
        -- Left-aligned pills let the next icon overhang into the gap.
        self.header_form = ui.form(N.row {align = "center", gap = gap, children = children})
        self.header_cfg, self.header_key = cfg, key
    end
    local boxes = self.header_form:layout(band, self.hooks.skin)
    if menu then
        self.menu_bounds = boxes.menu
        self.buttons.menu = boxes.menu:center()
    end
    return boxes
end

function View:header(caps, cfg)
    local h, skin = self.hooks, self.hooks.skin
    cfg = cfg or self.cfg.header
    caps = caps or (h.capsules and h.capsules()) or {}
    local boxes = self:header_layout(caps, cfg)
    self.resource_targets = {}
    for k, cap in ipairs(caps) do
        local node = boxes["cap" .. k]
        local r = rect(node.x + cfg.overhang, node.y, node.w - cfg.overhang, node.h)
        if cap.slot then self.resource_targets[cap.slot] = skin:resource_icon_box(r, cfg.role):center() end
        local hit = rect(r.x - cfg.overhang, r.y - 12, r.w + cfg.overhang, r.h + 24)
        local tapped = skin:draw_resource(r, cap.icon, cap.value, {
            role = cfg.role, hit = hit, reserve = cap.reserve, interactive = cfg.interactive,
        })
        if cap.decorate then cap.decorate(r) end
        if tapped and cap.note and h.notice then h.notice(cap.note) end
    end
    if h.menu and boxes.menu then h.menu(self.menu_bounds) end
    return boxes.leading
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
        if round_button(self, self.buttons.middle) then
            haptic.play(haptic.TICK, .6)
            if h.middle then h.middle() end
        end
    elseif self.cfg.bottom.layout ~= "play-primary" and h.draw_middle then h.draw_middle(self.buttons.middle) end
    local primary = self.cfg.bottom.layout == "play-primary"
    if primary then gfx.bleed(true) end
    -- Play's caption is the game's: the number of the level it starts.
    if h.play_label then self.navigation:set("play", h.play_label()) end
    local event = self.navigation:draw(self.bottom_row, skin)
    if h.build_rim then
        local box = self.navigation.boxes.build
        h.build_rim(box:center(), math.min(box.w, box.h) * .46)
    end
    if primary then gfx.bleed(false) end
    if event and (event.id == "build" or event.id == "play" or event.id == "pause") then
        haptic.play(haptic.TICK, .6)
    end
    if event and event.id == "build" and h.build then h.build()
    elseif event and event.id == "play" and h.play then h.play()
    elseif event and event.id == "pause" and h.pause then h.pause() end
end

-- Where the rail's markers stand, in screen units; tests click these.
function View:rail_layout(count)
    local cfg, s = self.cfg.rail, app.screen()
    local boxes = {}
    for i = 1, count do
        boxes[i] = rect(s.x + cfg.x, s.y + cfg.top + (i - 1) * (cfg.size + cfg.caption + cfg.gap), cfg.size, cfg.size)
    end
    return boxes
end

-- Each marker and its readout stay anchored while the skin draws any ready effect.
function View:rail()
    local h, cfg, skin = self.hooks, self.cfg.rail, self.hooks.skin
    local entries = h.rail and h.rail() or {}
    local boxes = self:rail_layout(#entries)
    local reduced = h.reduced_motion and h.reduced_motion()
    self.rail_targets = {}
    for i, entry in ipairs(entries) do
        local box = boxes[i]
        self.rail_targets[entry.id] = box:center()
        -- Ready markers keep their generous touch target.
        local target = entry.ready and box:inflate(5):offset(vec2(0, -3)) or box
        ui.block(target)
        local st = ui.hit(target, 0)
        local ready_time
        if entry.ready then
            local g = rgba(cfg.glow)
            gfx.glow(box:center(), cfg.size * .8, color(g.r, g.g, g.b, 185), color(g.r, g.g, g.b, 0))
            if not reduced and not st.held then ready_time = self.time + (i - 1) * .61 end
        end
        if h.rail_paint then h.rail_paint(box, entry, st, ready_time)
        else
            local lift = st.held and vec2(0, 2) or vec2(0, 0)
            local centre, radius = box:center(), box.w / 2
            gfx.circle(centre + vec2(0, 3), radius, rgba(cfg.shadow))
            gfx.circle(centre + lift, radius, rgba(cfg.rim))
            gfx.circle(centre + lift, radius - 4, rgba(entry.ready and cfg.ready or cfg.face))
            if entry.icon then gfx.image(entry.icon, box:inflate(-10):offset(lift), color(255, 255, 255, entry.waiting and 120 or 255)) end
        end
        if entry.value then
            local readout = rect(box.x, box:max().y + 2, box.w, cfg.caption)
            skin:paint("resource", readout, nil, {kind = "resource", radius = readout.h * .5, role = cfg.role})
            text.inside(skin:text(cfg.text, cfg.caption * .72), readout, vec2(.5, .5), entry.value)
        end
        if st.clicked then
            haptic.play(haptic.TICK, .6)
            if h.rail_tap then h.rail_tap(entry.id) end
        end
    end
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
    if city_input.pressed then self:dismiss_bubble() end
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
        if b.left <= 0 then b.left = nil; self:dismiss_bubble() end
    end
    if b and b.motion:step(dt, city_input, h.reduced_motion and h.reduced_motion())
        and b.item >= 0 and b.item < c.count and (c.placing < 0 or b.motion.after_exit) then
        local sprite = c.cam:rect_to_screen(c:sprite_rect(c.items[b.item + 1]))
        local bubble, skin = self.cfg.bubble, h.skin
        local em = bubble.em or 15
        local style = bubble.text and skin:text(bubble.text, em)
            or h.bubble_text and h.bubble_text() or skin:text(self.cfg.markers.text, 15)
        local title = bubble.title and skin:text(bubble.title, (bubble.text and em or style.size) * TITLE_SCALE)
        gfx.clip(view)
        b.motion:paint(function()
            bubble_draw(sprite:point(vec2(.5, .08)), b.text, style, skin:color(bubble.fill), skin:color(bubble.edge),
                        bubble.width, title)
        end, {floating=true})
        gfx.unclip()
    end

    -- The HUD is drawn after the map, so tall buildings never cover buttons.
    self:header()
    if c.placing >= 0 then self:placement()
    elseif not (h.hide_bottom and h.hide_bottom()) then
        self:bottom()
        if h.rail then self:rail() end
    end
    if h.extras then h.extras(app.screen()) end
end

return T
