-- Engine-owned skin files. Compiled into the runtime by make gen.
--
-- A game describes its look once, as data: fonts, named colours, images, text
-- styles and, per control, a look for every interaction state. ui.skin(def)
-- compiles that description into the paint contract ui.form already uses
-- (style, panel, button, button_text, label, focus, checkbox, progress), and
-- into immediate-mode helpers, so forms and hand-placed widgets share one look.
-- The engine still owns layout, hit testing, focus and activation.
local Skin = {}
Skin.__index = Skin
local fonts = {}   -- font files are shared between skins
local STATES = {'normal', 'selected', 'hover', 'pressed', 'disabled'}
local function fail(message) error('ui.skin: ' .. message, 3) end

local function copy(t)
    local c = {}
    for k, v in pairs(t) do c[k] = v end
    return c
end

-- "#RRGGBB", "#RRGGBBAA", a palette name, {r,g,b,a} or a color value.
local function parse_color(skin, v, depth)
    if v == nil then return nil end
    if type(v) == 'string' then
        local hex = v:match('^#(%x+)$')
        if hex and (#hex == 6 or #hex == 8) then
            local n = tonumber(hex, 16)
            if #hex == 6 then return color(n >> 16 & 255, n >> 8 & 255, n & 255, 255) end
            return color(n >> 24 & 255, n >> 16 & 255, n >> 8 & 255, n & 255)
        end
        local named = skin.def.colors and skin.def.colors[v]
        if named == nil or (depth or 0) > 8 then fail('unknown colour ' .. v) end
        return parse_color(skin, named, (depth or 0) + 1)
    end
    if type(v) == 'table' and v[1] then return color(v[1], v[2], v[3], v[4] or 255) end
    return v
end
local function vec(v) return v and vec2(v[1] or v.x or 0, v[2] or v.y or 0) or vec2(0, 0) end
local function edges(v)
    if type(v) == 'number' then return v, v, v, v end
    v = v or {}
    return v[1] or 0, v[2] or 0, v[3] or 0, v[4] or 0
end

local function font_of(skin, name)
    local spec = skin.def.fonts and skin.def.fonts[name]
    if not spec then fail('unknown font ' .. tostring(name)) end
    if type(spec) == 'string' then spec = {path = spec} end
    if not spec.path then return spec.font, spec.scale or 1 end   -- an already loaded font
    if not fonts[spec.path] then fonts[spec.path] = font.load(spec.path) end
    return fonts[spec.path], spec.scale or 1
end

-- A text style resolved through `extends`; lengths are at `em` and scale with it.
local function text_spec(skin, name)
    local cached = skin.texts[name]
    if cached then return cached end
    local spec = skin.def.text and skin.def.text[name]
    if not spec then fail('unknown text style ' .. tostring(name)) end
    local resolved = spec.extends and copy(text_spec(skin, spec.extends)) or {}
    for k, v in pairs(spec) do if k ~= 'extends' then resolved[k] = v end end
    skin.texts[name] = resolved
    return resolved
end

-- The engine style for a text spec at `em`, with the paint transform applied
-- when `paint` is true. Measurement always uses logical (unscaled) units.
local function make_style(skin, name, em, paint)
    local spec = text_spec(skin, name)
    em = em or spec.em or 16
    local f, font_scale = font_of(skin, spec.font)
    local scale, _, alpha = 1, nil, 1
    if paint and skin.transform then scale, _, alpha = skin.transform() end
    local k = em / (spec.em or em) * scale
    local s = {font = f, size = em * font_scale * scale, fill = parse_color(skin, spec.fill or '#FFFFFF')}
    s.fill2 = parse_color(skin, spec.fill2)
    if spec.outline then s.outline, s.outline_width = parse_color(skin, spec.outline), (spec.outline_width or 1) * k end
    if spec.shadow then
        s.shadow, s.shadow_offset = parse_color(skin, spec.shadow), vec(spec.shadow_offset):scale(k)
        s.shadow_blur = spec.shadow_blur and spec.shadow_blur * k
    end
    if spec.tracking then s.tracking = spec.tracking * k end
    if alpha < 1 then s.fade = 1 - alpha end
    return style(s)
end

----------------------------------------------------------------- looks

-- A control's look in one interaction state: its spec's normal look with the
-- active states merged over it, in order. `layers` replaces the list; `set`
-- patches named layers, so a state only states what differs.
local function merge_look(base, over)
    if not over then return base end
    local look = copy(base)
    for k, v in pairs(over) do
        if k == 'set' then
            local layers = {}
            for i, layer in ipairs(look.layers or {}) do
                local patch = layer.name and v[layer.name]
                if patch then layer = copy(layer); for pk, pv in pairs(patch) do layer[pk] = pv end end
                layers[i] = layer
            end
            look.layers = layers
        else look[k] = v end
    end
    return look
end

local function control_spec(skin, kind, node)
    local spec = skin.def.controls and skin.def.controls[kind]
    if not spec then return nil end
    if spec.extends then
        local base = control_spec(skin, spec.extends)
        local merged = copy(base or {})
        for k, v in pairs(spec) do if k ~= 'extends' then merged[k] = v end end
        spec = merged
    end
    -- Variants (flat, accent, or the node's role) have the shape of a control
    -- spec: their state looks merge over the control's, other keys replace.
    if node and spec.variants then
        for _, key in ipairs({node.flat and 'flat' or false, node.accent and 'accent' or false, node.role or false}) do
            local variant = key and spec.variants[key]
            if variant then
                local merged = copy(spec)
                for k, v in pairs(variant) do
                    local state = false
                    for _, s in ipairs(STATES) do state = state or s == k end
                    merged[k] = state and merge_look(spec[k] or {}, v) or v
                end
                spec = merged
            end
        end
    end
    return spec
end

local function look_for(spec, st)
    if not spec then return nil end
    local look = spec.normal or {}
    if st then
        if st.selected then look = merge_look(look, spec.selected) end
        if st.hot and not st.disabled then look = merge_look(look, spec.hover) end
        if st.held and not st.disabled then look = merge_look(look, spec.pressed) end
        if st.disabled then look = merge_look(look, spec.disabled) end
    end
    return look
end

-- The paint transform, for dialogs that animate (scale, offset, opacity).
local function transformed(skin, r)
    if not skin.transform then return r, 1, 1 end
    local scale, offset, alpha = skin.transform()
    return rect.make(offset + r:pos():scale(scale), r:size():scale(scale)), scale, alpha
end

local function image_of(skin, name)
    local image = skin.images[name]
    if image then return image end
    local path = skin.def.images and skin.def.images[name] or name
    image = type(path) == 'string' and texture.load(path) or path
    skin.images[name] = image
    return image
end

local function nine_slice(t, dst, l, t_, r, b, tint)
    local w, h = t.w, t.h
    local xs = {0, l, w - r, w}
    local ys = {0, t_, h - b, h}
    local dx = {dst.x, dst.x + l, dst.x + dst.w - r, dst.x + dst.w}
    local dy = {dst.y, dst.y + t_, dst.y + dst.h - b, dst.y + dst.h}
    for i = 1, 3 do for j = 1, 3 do
        local src = rect(xs[i], ys[j], xs[i + 1] - xs[i], ys[j + 1] - ys[j])
        local out = rect(dx[i], dy[j], dx[i + 1] - dx[i], dy[j + 1] - dy[j])
        if src.w > 0 and src.h > 0 and out.w > 0 and out.h > 0 then gfx.image_part(t, src, out, tint) end
    end end
end

-- Layers draw in order inside the control box. Box fields: `inset` (number or
-- {left, top, right, bottom}; negative grows), `offset` {x, y}, `height_ratio`
-- (keep the top fraction of the box). A look's `offset` moves every layer that
-- is not `fixed`, and the caption.
local function draw_layer(skin, layer, box, look_offset, node, st)
    local l, t, r, b = edges(layer.inset)
    local lb = rect(box.x + l, box.y + t, box.w - l - r, box.h - t - b)
    if layer.height_ratio then lb = rect(lb.x, lb.y, lb.w, box.h * layer.height_ratio) end
    lb = lb:offset(vec(layer.offset))
    if not layer.fixed then lb = lb:offset(look_offset) end
    if layer.paint then layer.paint(lb, node, st, skin); return end
    local out, scale, alpha = transformed(skin, lb)
    local radius = (layer.radius or 0) * scale
    local function c(v) local parsed = parse_color(skin, v); return alpha < 1 and color.alpha(parsed, alpha) or parsed end
    if layer.shadow then gfx.shadow(out, radius, (layer.blur or 8) * scale, c(layer.shadow))
    elseif layer.fill then
        if layer.fill2 then gfx.round_rect_grad(out, radius, c(layer.fill), c(layer.fill2))
        else gfx.round_rect(out, radius, c(layer.fill)) end
    elseif layer.border then gfx.round_rect_line(out, radius, (layer.width or 1) * scale, c(layer.border))
    elseif layer.image then
        local image = image_of(skin, layer.image)
        if image and image.w > 0 then
            local tint = color(255, 255, 255, math.floor(255 * alpha + .5))
            if layer.slice then
                local sl, st_, sr, sb = edges(layer.slice)
                nine_slice(image, out, sl * scale, st_ * scale, sr * scale, sb * scale, tint)
            elseif layer.fit == 'contain' then gfx.image(image, out:fit(texture.size(image)), tint)
            else gfx.image(image, out, tint) end
        end
    elseif layer.check then   -- a tick drawn as two strokes, for checkboxes without artwork
        local w = (layer.width or 3) * scale
        gfx.polyline({out:point(vec2(.2, .52)), out:point(vec2(.42, .74)), out:point(vec2(.8, .28))}, w, c(layer.check))
    end
end

local function draw_look(skin, look, box, node, st)
    if not look then return end
    local offset = vec(look.offset)
    for _, layer in ipairs(look.layers or {}) do draw_layer(skin, layer, box, offset, node, st) end
end

-------------------------------------------------------- the form contract

local function node_text(skin, node, spec, fallback_text, fallback_em)
    local role = node and node.role and skin.def.roles and skin.def.roles[node.role]
    local name = node and node.text_style or role and role.text
    local em = node and node.em or role and role.em
    if not name and spec then
        name = node and node.wrap and spec.wrap_text or spec.text
        em = em or (node and node.wrap and spec.wrap_em) or spec.em
    end
    return name or fallback_text, em or fallback_em
end

local function caption_for(skin, kind, node, st)
    local spec = control_spec(skin, kind, node)
    local look = look_for(spec, st) or {}
    local name, em = node_text(skin, node, spec, look.text or 'body')
    return look.text and (not node or not node.text_style) and look.text or name, em, look, spec
end

function Skin:measure_style(node)
    local kind = node.kind == 'toggle' and 'toggle' or node.kind
    local name, em = node_text(self, node, control_spec(self, kind, node) or control_spec(self, 'label', node), 'body')
    local spec = text_spec(self, name)
    local f, font_scale = font_of(self, spec.font)
    em = em or spec.em or 16
    -- Measurement uses the bare font and size, so layout ignores decoration.
    return style{font = f, size = em * font_scale}
end

function Skin:text(name, em) return make_style(self, name, em, true) end
function Skin:font(name) return (font_of(self, name)) end
function Skin:measure_text(name, em) return make_style(self, name, em, false) end

function Skin:paint(kind, box, st, node)
    local spec = control_spec(self, kind, node)
    if spec then draw_look(self, look_for(spec, st), box, node, st) end
end

function Skin:paint_caption(kind, box, caption, st, node, align)
    local name, em, look, spec = caption_for(self, kind, node, st)
    local inset = (spec and spec.text_inset) or 8
    local inner = box:offset(vec(look.offset)):inflate(-inset)
    local out = transformed(self, inner)
    text.inside(make_style(self, name, em, true), out, align or vec2(.5, .5), caption)
end

function Skin:paint_panel(box, node) self:paint('panel', box, nil, node) end

function Skin:paint_button(box, st, node)
    self:paint(node and node.kind == 'toggle' and 'toggle' or 'button', box, st, node)
end

function Skin:paint_label(box, caption, node)
    local spec = control_spec(self, 'label', node)
    local name, em = node_text(self, node, spec, 'body')
    local align = vec2(node.text_align == 'start' and 0 or node.text_align == 'end' and 1 or .5, .5)
    local out = transformed(self, box)
    local s = make_style(self, name, em, true)
    if node.wrap then text.box(s, out, align, caption) else text.inside(s, out, align, caption) end
end

function Skin:paint_focus(box, node)
    local spec = self.def.controls and self.def.controls.focus
    if spec then draw_look(self, spec.normal or spec, box, node) end
end

-- A checkbox: a box with its own states, a mark when checked, then the caption.
function Skin:checkbox_parts(box, node)
    local spec = control_spec(self, 'checkbox', node) or {}
    local size = spec.size or 28
    local side = rect(box.x, box.y + (box.h - size) / 2, size, size)
    local gap = spec.gap or 10
    return side, rect(side.x + size + gap, box.y, math.max(0, box.w - size - gap), box.h), spec
end

function Skin:paint_checkbox(box, caption, node, st)
    local side, label, spec = self:checkbox_parts(box, node)
    draw_look(self, look_for(spec.box or spec, st), side, node, st)
    if st.selected then draw_look(self, look_for(spec.mark, st), side, node, st) end
    local name, em = node_text(self, node, spec, 'body')
    local look = look_for(spec, st) or {}
    text.inside(make_style(self, look.text or name, em, true), transformed(self, label), vec2(0, .5), caption)
end

function Skin:checkbox_size(node, caption)
    local spec = control_spec(self, 'checkbox', node) or {}
    local measured = text.measure(self:measure_style(node), caption)
    return (spec.size or 28) + (spec.gap or 10) + measured.w, math.max(spec.size or 28, measured.h, spec.min_height or 44)
end

function Skin:paint_progress(box, fraction, node)
    local spec = control_spec(self, 'progress', node)
    if not spec then ui.progress(box, fraction); return end
    draw_look(self, look_for(spec.track, nil), box, node)
    fraction = math.max(0, math.min(1, fraction))
    if fraction > 0 then draw_look(self, look_for(spec.fill, nil), rect(box.x, box.y, box.w * fraction, box.h), node) end
end

---------------------------------------------------------- immediate mode

-- A skinned button outside a form: returns true when clicked. Options:
-- enabled (default true), accent, flat, selected, role, hit_offset.
function Skin:draw_button(box, caption, opts)
    opts = opts or {}
    local node = {kind = 'button', accent = opts.accent, flat = opts.flat, role = opts.role}
    local enabled = opts.enabled ~= false
    local hit = opts.hit_offset and box:offset(opts.hit_offset) or box
    local st = ui.hit(hit, enabled and 0 or ui.DISABLED)
    st.disabled, st.selected = not enabled, not not opts.selected
    self:paint('button', box, st, node)
    self:paint_caption('button', box, caption, st, node)
    return enabled and st.clicked
end

-- A skinned checkbox outside a form: returns the (possibly toggled) value.
function Skin:draw_checkbox(box, caption, value, opts)
    opts = opts or {}
    local node = {kind = 'checkbox', role = opts.role}
    local enabled = opts.enabled ~= false
    local st = ui.hit(opts.hit_offset and box:offset(opts.hit_offset) or box, enabled and 0 or ui.DISABLED)
    st.disabled, st.selected = not enabled, not not value
    self:paint_checkbox(box, caption, node, st)
    if enabled and st.clicked then return not value end
    return value
end

-- Controls drawn from authored images must name every state's image; the
-- engine never tints one into another. Lists {control, state} still missing.
function Skin:audit(required)
    local missing = {}
    for kind, spec in pairs(self.def.controls or {}) do
        local function uses_images(look)
            for _, layer in ipairs(look and look.layers or {}) do if layer.image then return true end end
        end
        if type(spec) == 'table' and uses_images(spec.normal) then
            for _, state in ipairs(required and required[kind] or {'hover', 'pressed', 'disabled'}) do
                if not spec[state] then missing[#missing + 1] = {control = kind, state = state} end
            end
        end
    end
    table.sort(missing, function(a, b) return a.control .. a.state < b.control .. b.state end)
    return missing
end

------------------------------------------------------------------ compile

-- Native widgets (ui.button, ui.panel, toasts, modal backdrops) read a theme.
-- Fields the skin names override the engine theme current at compile time.
local function build_theme(skin, t)
    local theme = ui.theme()
    for k, v in pairs(t) do
        if type(v) == 'string' and skin.def.text and skin.def.text[v] then theme[k] = make_style(skin, v, nil, false)
        elseif k == 'radius' or k == 'backdrop_blur' then theme[k] = v
        else theme[k] = parse_color(skin, v) end
    end
    return theme
end

function ui.skin(def)
    if type(def) ~= 'table' then fail('expects a skin table') end
    for name, spec in pairs(def.text or {}) do
        if spec.extends and not (def.text or {})[spec.extends] then fail('text ' .. name .. ' extends unknown ' .. spec.extends) end
        if not spec.extends and not spec.font then fail('text ' .. name .. ' needs a font') end
    end
    for kind, spec in pairs(def.controls or {}) do
        if type(spec) ~= 'table' then fail('control ' .. kind .. ' must be a table') end
        for key in pairs(spec) do
            if key == 'focused' then fail(kind .. ': draw focus with controls.focus') end
        end
    end
    local skin = setmetatable({def = def, texts = {}, images = {}, transform = def.transform}, Skin)
    -- The form contract (plain functions that ui.form calls); the methods
    -- above keep distinct names so these fields never shadow them.
    skin.style = function(node) return skin:measure_style(node) end
    skin.panel = def.controls and def.controls.panel and function(box, node) skin:paint_panel(box, node) end or nil
    skin.button = function(box, st, node) skin:paint_button(box, st, node) end
    skin.button_text = function(box, caption, node, st)
        skin:paint_caption(node.kind == 'toggle' and 'toggle' or 'button', box, caption, st, node)
    end
    skin.label = function(box, caption, node) skin:paint_label(box, caption, node) end
    skin.focus = def.controls and def.controls.focus and function(box, node) skin:paint_focus(box, node) end or nil
    skin.checkbox = function(box, caption, node, st) skin:paint_checkbox(box, caption, node, st) end
    skin.measure_checkbox = function(node, caption) return skin:checkbox_size(node, caption) end
    skin.progress = function(box, fraction, node) skin:paint_progress(box, fraction, node) end
    if def.theme then skin.theme = build_theme(skin, def.theme) end
    return skin
end
ui.SKIN_STATES = STATES
