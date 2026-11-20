-- Screen changes are selected by the app. The transition temporarily owns
-- painting, with idle input for both screens. The app also disables UI hit tests.
local styles = require("screen_transition.styles")
local T = {}
local Transition = {}
Transition.__index = Transition

function T.new(config, override)
    return setmetatable({config = config or {}, override = override}, Transition)
end

function Transition:watch(screen, enabled, describe)
    local from = self.current
    self.current = screen
    if not enabled then
        self.animation = nil
        return
    end
    if not from or from == screen then return end

    local routes = self.config.routes
    local outgoing = routes and routes[from]
    local name = self.override or (outgoing and outgoing[screen]) or self.config.style or "wipe"
    if name == "none" then
        self.animation = nil
        return
    end
    local d = describe and describe(from, screen) or {}
    d.from, d.to, d.t = from, screen, 0
    d.style, d.theme = styles.get(name), styles.theme(self.config.theme)
    d.masked = d.masked or screen
    d.mask_leaving = d.masked == from
    self.animation = d
end

function Transition:active() return self.animation ~= nil end

function Transition:covering()
    local d = self.animation
    return d and d.t < d.style.out
end

-- paint(id, idle, dt, transition, zoom, pan) draws the named screen.
-- A wipe renders both views. Other styles cover the outgoing view before
-- revealing the incoming one. "masked" selects the view drawn under the wipe.
function Transition:frame(inp, dt, paint)
    local d = self.animation
    local style = d.style
    local idle = input{pos = inp.pos, pinch = 1}
    local leaving, u
    if style.wipe then
        leaving, u = false, num.saturate(d.t / style.inn)
        paint(d.mask_leaving and d.to or d.from, idle, dt, d)
        style.mask(d, u)
        paint(d.masked, idle, dt, d)
        gfx.sdf_unmask()
    else
        leaving = d.t < style.out
        u = leaving and d.t / style.out or num.saturate((d.t - style.out) / style.inn)
        local id = leaving and d.from or d.to
        d.focus = d.focuses and d.focuses[id] or app.screen():center()
        local zoom, pan = style.look(d, leaving, u)
        paint(id, idle, dt, d, zoom, pan)
    end
    gfx.bleed(true)
    style.draw(d, leaving, u)
    gfx.bleed(false)
    d.t = d.t + dt
    if d.t >= style.out + style.inn then self.animation = nil end
end

return T
