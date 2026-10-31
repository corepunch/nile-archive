-- tween.lua — the engine's motion module: easing curves, tweens, timelines,
-- staggers, punch and shake. Compiled into the runtime by make gen, it runs
-- before main.lua and defines the globals `ease` and `tween`. The engine
-- ticks tween.update(dt) before every game frame. docs/MOTION.md is the guide.
--
-- The design borrows from the libraries games are usually animated with:
--   GSAP     a tween or timeline is a function of its playhead, so seeking,
--            reversing, yoyo loops and time scaling fall out of one render();
--            timeline positions ("<", ">", "+=0.2", labels), defaults, staggers
--   flux     a tiny chainable Lua surface (:ease, :delay, :after, :on_complete),
--            groups with their own update(), field-level overwrite
--   DOTween  :loops(n, "yoyo"), punch and shake, an out-easing default
--   Godot 4  from / relative, the child returned from a timeline so its
--            modifiers chain onto it, method tweens (tween.value)
local pi, sin, cos, sqrt, asin, floor, huge = math.pi, math.sin, math.cos, math.sqrt, math.asin, math.floor, math.huge
local function saturate(t) return t < 0 and 0 or t > 1 and 1 or t end

------------------------------------------------------------------ easing
-- Every curve is f(t, ...) with t in [0, 1] (clamped) and optional parameters.
-- A family is written once as its ease-in; out and in-out are derived from it,
-- as flux does. Bounce is written as its ease-out.
ease = {}
local function power(n) return function(t) return t ^ n end end
local families = {
    sine = function(t) return 1 - cos(t * pi / 2) end,
    quad = power(2), cubic = power(3), quart = power(4), quint = power(5),
    expo = function(t) return t == 0 and 0 or 2 ^ (10 * t - 10) end,
    circ = function(t) return 1 - sqrt(1 - t * t) end,
    -- overshoot: how far it pulls back first (1.70158 overshoots by 10%)
    back = function(t, s) s = s or 1.70158; return (s + 1) * t * t * t - s * t * t end,
    -- amplitude (>= 1) and period of the spring; Penner's formulation
    elastic = function(t, a, p)
        if t == 0 or t == 1 then return t end
        a, p = a or 1, p or .3
        local s = a < 1 and p / 4 or p / (2 * pi) * asin(1 / a)
        if a < 1 then a = 1 end
        return -(a * 2 ^ (10 * (t - 1)) * sin((t - 1 - s) * 2 * pi / p))
    end,
}
local function out_of(f) return function(t, a, b) return 1 - f(1 - saturate(t), a, b) end end
local function in_out_of(f)
    return function(t, a, b)
        t = saturate(t)
        if t < .5 then return f(2 * t, a, b) / 2 end
        return 1 - f(2 - 2 * t, a, b) / 2
    end
end
for name, f in pairs(families) do
    local fin = function(t, a, b) return f(saturate(t), a, b) end
    ease["in_" .. name], ease["out_" .. name], ease["in_out_" .. name] = fin, out_of(fin), in_out_of(fin)
end
ease.out_bounce = function(t)
    t = saturate(t)
    if t < 1 / 2.75 then return 7.5625 * t * t end
    if t < 2 / 2.75 then t = t - 1.5 / 2.75; return 7.5625 * t * t + .75 end
    if t < 2.5 / 2.75 then t = t - 2.25 / 2.75; return 7.5625 * t * t + .9375 end
    t = t - 2.625 / 2.75
    return 7.5625 * t * t + .984375
end
ease.in_bounce = out_of(ease.out_bounce)
ease.in_out_bounce = in_out_of(ease.in_bounce)
ease.linear = function(t) return saturate(t) end
ease.none = ease.linear
-- n equal steps, holding each value until the next (CSS steps(n, jump-end))
ease.steps = function(t, n) n = n or 4; t = saturate(t); return t >= 1 and 1 or floor(t * n) / n end
ease.in_out = ease.in_out_cubic   -- the historic name of the engine's cubic in-out

-- A curve by name or function; nil is the default, out_cubic.
function ease.get(spec)
    if spec == nil then return ease.out_cubic end
    if type(spec) == "function" then return spec end
    local f = type(spec) == "string" and ease[spec]
    if type(f) ~= "function" then error("tween: unknown easing " .. tostring(spec), 3) end
    return f
end

------------------------------------------------------------------ clips
-- A clip is anything with a playhead: a tween, a timeline, an interval or a
-- callback. Rendering is a pure function of the head, so every control is a
-- seek. Fields: pre (delay), dur (one iteration), reps (loops, -1 forever),
-- mode (restart | yoyo | incremental), speed, dir (1 or -1), head.
local Clip = {}
Clip.__index = Clip
local Tween = setmetatable({}, Clip)
Tween.__index = Tween
local Timeline = setmetatable({}, Clip)
Timeline.__index = Timeline
local Group = {}
Group.__index = Group

local function new_clip(class, group)
    return setmetatable({group = group, pre = 0, dur = 0, reps = 0, mode = "restart", speed = 1, dir = 1, head = 0,
                         iter = -1, paused = false, started = false, done = false, killed = false, live = false,
                         cbs = {}, claims = {}}, class)
end

local function fire(clip, name, arg)
    local fn = clip.cbs[name]
    if fn then fn(clip, arg) end
end

local function arg_check(cond, what, level)
    if not cond then error("tween: " .. what, level or 3) end
end

local function root_of(clip)
    while clip.parent do clip = clip.parent end
    return clip
end

local function is_timeline(clip) return getmetatable(clip) == Timeline end
local function idle(clip) return is_timeline(clip) and #clip.children == 0 end

-- Duration of one iteration; timelines measure their children.
function Clip:span() return self.dur end
-- Duration of everything: delay, every loop.
function Clip:total()
    if self.reps < 0 then return huge end
    return self.pre + self:span() * (self.reps + 1)
end
-- The end of one play, finite even when looping forever.
function Clip:once() return self.pre + self:span() end

function Clip:apply(p, i) end
function Clip:init() end

-- Render the clip at an absolute local time. Idempotent.
function Clip:render(head)
    local total = self:total()
    if head > total then head = total end
    if head < 0 then head = 0 end
    self.head = head
    local t = head - self.pre
    if t < 0 then
        if not self.started then return end
        t = 0
    end
    if not self.started then
        self.started = true
        self:init()
        fire(self, "start")
    end
    local span = self:span()
    local i, p = 0, 1
    if span > 0 then
        i = floor(t / span)
        if self.reps >= 0 and i > self.reps then i = self.reps end
        p = (t - i * span) / span
        if p > 1 then p = 1 end
        if self.mode == "yoyo" and i % 2 == 1 then p = 1 - p end
    end
    if i ~= self.iter then
        local was = self.iter
        self.iter = i
        for k = math.max(was, 0) + 1, i do fire(self, "loop", k) end
    end
    self:apply(p, i)
    fire(self, "update")
    if self.dir > 0 then
        if head >= total then
            if not self.done then self.done = true; fire(self, "complete") end
        else self.done = false end
    elseif head <= 0 then
        if not self.done then self.done = true; fire(self, "reverse_complete") end
    else self.done = false end
end

function Clip:advance(dt)
    if self.paused then return end
    if self.group and self.group.instant then
        self:render(self.dir > 0 and self:once() or 0)
        self.done = true
        return
    end
    self:render(self.head + dt * self.speed * self.dir)
end

-- Put a root clip back in its group's list after it finished or was created idle.
function Clip:wake()
    local g = self.group
    if g and not self.live and not self.killed and not self.parent then g:add(self) end
    return self
end

-- Overwrite: a root clip owns every (target, key) its tweens have started on.
-- A newer root that starts on the same key takes it, and the older stops
-- writing it. Siblings in one timeline never overwrite each other.
function Clip:claim(target, key)
    local root = root_of(self)
    local g = root.group
    if not g then return end
    local owners = g.owners[target]
    if not owners then owners = {}; g.owners[target] = owners end
    local prev = owners[key]
    if prev and prev ~= root then prev:drop(target, key) end
    owners[key] = root
    root.claims[#root.claims + 1] = {target, key}
end

function Clip:release()
    local g = self.group
    if g then
        for _, c in ipairs(self.claims) do
            local owners = g.owners[c[1]]
            if owners and owners[c[2]] == self then owners[c[2]] = nil end
        end
    end
    self.claims = {}
end

function Clip:drop(target, key) end
-- Claim again what the clip's started tweens still write, after it rejoins a group.
function Clip:reclaim() end

-- chainable settings ----------------------------------------------------
function Clip:delay(s) arg_check(type(s) == "number" and s >= 0, "delay must be a nonnegative number"); self.pre = s; return self end
-- n extra plays, -1 forever; mode restart (default), yoyo or incremental
function Clip:loops(n, mode)
    arg_check(type(n) == "number" and n >= -1 and n % 1 == 0, "loops must be an integer >= -1")
    arg_check(mode == nil or mode == "restart" or mode == "yoyo" or mode == "incremental", "loop mode is restart, yoyo or incremental")
    self.reps, self.mode = n, mode or "restart"
    return self
end
function Clip:time_scale(s)
    if s == nil then return self.speed end
    arg_check(type(s) == "number" and s >= 0, "time scale must be a nonnegative number")
    self.speed = s
    return self
end
for _, name in ipairs({"start", "update", "complete", "loop", "reverse_complete"}) do
    Clip["on_" .. name] = function(self, fn)
        arg_check(fn == nil or type(fn) == "function", "on_" .. name .. " takes a function")
        self.cbs[name] = fn
        return self
    end
end
-- Apply a table of settings by name: {ease = "out_back", delay = .1, loops = 2, on_complete = fn, ...}.
-- A table value spreads into the setter's arguments: {ease = {"out_back", 2.5}, loops = {-1, "yoyo"}}.
function Clip:configure(opts)
    if opts == nil then return self end
    arg_check(type(opts) == "table", "options must be a table")
    for k, v in pairs(opts) do
        local setter = self[k]
        arg_check(type(setter) == "function" and k ~= "configure", "unknown option " .. tostring(k))
        if type(v) == "table" and (k == "ease" or k == "loops") then setter(self, table.unpack(v)) else setter(self, v) end
    end
    return self
end

-- controls ---------------------------------------------------------------
function Clip:pause() self.paused = true; return self end
function Clip:resume() self.paused = false; return self:wake() end
function Clip:play() self.dir, self.paused = 1, false; return self:wake() end
function Clip:reverse() self.dir, self.paused = -1, false; return self:wake() end
function Clip:restart() self.done, self.iter = false, -1; self:render(0); return self:play() end
function Clip:seek(t) self.done = false; self:render(t); return self:wake() end
-- 0..1 of the whole clip (of one play when looping forever); reading gives the current fraction
function Clip:progress(p)
    local total = self:total()
    if total == huge then total = self:once() end
    if p == nil then return total > 0 and saturate(self.head / total) or 0 end
    return self:seek(saturate(p) * total)
end
function Clip:complete()
    local total = self:total()
    self:render(total < huge and total or self:once())
    return self
end
function Clip:kill()
    self.killed, self.paused = true, true
    self:release()
    return self
end
Clip.stop = Clip.kill
function Clip:is_active() return self.live and not self.paused and not self.done and not self.killed end
function Clip:is_done() return self.done end

------------------------------------------------------------------ tweens
local function is_list(t) return type(t) == "table" and t[1] ~= nil end

local function copy_value(v)
    if type(v) ~= "table" then return v end
    local c = {}
    for k, x in pairs(v) do c[k] = x end
    return setmetatable(c, getmetatable(v))
end

local function diff_value(cur, final, key)
    if type(final) == "number" then
        arg_check(type(cur) == "number", "field " .. tostring(key) .. " is not a number", 4)
        return final - cur
    end
    arg_check(type(final) == "table" and type(cur) == "table", "field " .. tostring(key) .. " must be a number or a value table", 4)
    local d = {}
    for f, x in pairs(final) do
        arg_check(type(x) == "number" and type(cur[f]) == "number", "field " .. tostring(key) .. "." .. tostring(f) .. " is not a number", 4)
        d[f] = x - cur[f]
    end
    return d
end

local function add_value(cur, final, key)
    if type(final) == "number" then
        arg_check(type(cur) == "number", "field " .. tostring(key) .. " is not a number", 4)
        return cur + final
    end
    local r = copy_value(cur)
    for f, x in pairs(final) do r[f] = (cur[f] or 0) + x end
    return r
end

local function new_tween(group, targets, dur, vars)
    arg_check(type(targets) == "table", "target must be a table or a list of tables")
    arg_check(type(dur) == "number" and dur >= 0, "duration must be a nonnegative number")
    arg_check(type(vars) == "table", "fields must be a table of final values")
    local t = new_clip(Tween, group)
    t.targets = is_list(targets) and targets or {targets}
    for _, target in ipairs(t.targets) do arg_check(type(target) == "table", "every target must be a table") end
    t.base, t.dur, t.vars = dur, dur, {}
    for k, v in pairs(vars) do t.vars[k] = v end
    t.curve, t.a1, t.a2 = ease.out_cubic, nil, nil
    t.offsets = {}
    for j = 1, #t.targets do t.offsets[j] = 0 end
    return t
end

-- A tween from `vars` to the current values.
local function from_tween(group, targets, dur, vars)
    arg_check(type(vars) == "table", "from takes a table of start values")
    local goals = {}
    for k in pairs(vars) do goals[k] = function(_, target) return target[k] end end
    return new_tween(group, targets, dur, goals):from(vars)
end

-- Record every target's start and the distance to its goal.
function Tween:init()
    self.props = {}
    for j, target in ipairs(self.targets) do
        local p = {start = {}, diff = {}, final = {}, dead = {}}
        self.props[j] = p
        for key, goal in pairs(self.vars) do
            if type(goal) == "function" then goal = goal(j, target) end
            local cur = target[key]
            arg_check(cur ~= nil, "target has no field " .. tostring(key), 4)
            local from = self.fromv and self.fromv[key]
            if type(from) == "function" then from = from(j, target) end
            local start = from ~= nil and copy_value(from) or copy_value(cur)
            if self.rel then goal = add_value(start, goal, key) end
            p.start[key], p.final[key], p.diff[key] = start, copy_value(goal), diff_value(start, goal, key)
            self:claim(target, key)
        end
    end
end

function Tween:reclaim()
    if not self.props then return end
    for j, target in ipairs(self.targets) do
        local p = self.props[j]
        for key in pairs(p.diff) do if not p.dead[key] then self:claim(target, key) end end
    end
end

function Tween:drop(target, key)
    for j, t in ipairs(self.targets) do
        if t == target then
            if self.props then self.props[j].dead[key] = true else self.vars[key] = nil end
        end
    end
end

local function write(target, key, start, diff, final, e, exact)
    if exact then target[key] = copy_value(final); return end
    if type(diff) == "number" then target[key] = start + diff * e; return end
    local v = {}
    for f, d in pairs(diff) do v[f] = start[f] + d * e end
    for f, x in pairs(start) do if v[f] == nil then v[f] = x end end
    target[key] = setmetatable(v, getmetatable(start))
end

function Tween:apply(p, i)
    local t, base, incr = p * self.dur, self.base, self.mode == "incremental"
    for j, target in ipairs(self.targets) do
        local pj
        if base > 0 then pj = saturate((t - self.offsets[j]) / base)
        else pj = (p >= 1 or t >= self.offsets[j]) and 1 or 0 end
        local props = self.props[j]
        if self.wave then
            for key, diff in pairs(props.diff) do
                if not props.dead[key] then
                    local start = props.start[key]
                    write(target, key, start, self.wave(self, pj, j, key, diff), start, 1, pj >= 1)
                end
            end
        else
            local e = self.curve(pj, self.a1, self.a2)
            if incr then e = e + i end
            for key, diff in pairs(props.diff) do
                if not props.dead[key] then
                    write(target, key, props.start[key], diff, props.final[key], e, pj >= 1 and not incr)
                end
            end
        end
    end
end

-- settings ---------------------------------------------------------------
-- A curve by name or function, with its parameters: :ease("out_back", 2.5)
function Tween:ease(spec, a, b) self.curve, self.a1, self.a2 = ease.get(spec), a, b; return self end
-- Start values, taken instead of the current ones; the target jumps there now.
function Tween:from(vars)
    arg_check(type(vars) == "table", "from takes a table of start values")
    arg_check(not self.started, "from must come before the tween starts")
    self.fromv = vars
    self.started = true
    self:init()
    fire(self, "start")
    self:apply(0, 0)
    return self
end
-- Goals are offsets from the start values.
function Tween:relative(flag) self.rel = flag ~= false; return self end
-- Offset each target's start: seconds between targets, or {each = seconds between
-- starts | amount = seconds from the first start to the last, from = "start" |
-- "end" | "center" | "random" | an index, ease = a curve over the spread}.
function Tween:stagger(opts)
    if type(opts) == "number" then opts = {each = opts} end
    arg_check(type(opts) == "table", "stagger takes seconds or a table")
    local n = #self.targets
    local each = opts.each or 0
    local from, order = opts.from or "start", {}
    local centre = (n - 1) / 2
    if from == "random" then
        local g = root_of(self).group or Group.default
        local keys = {}
        for j = 1, n do keys[j] = {j, g:random()} end
        table.sort(keys, function(a, b) return a[2] < b[2] end)
        for k, r in ipairs(keys) do order[r[1]] = k - 1 end
    else
        for j = 1, n do
            local i = j - 1
            if from == "start" then order[j] = i
            elseif from == "end" then order[j] = n - 1 - i
            elseif from == "center" then order[j] = math.abs(i - centre)
            else arg_check(type(from) == "number", "stagger.from is start, end, center, random or an index"); order[j] = math.abs(i - from) end
        end
    end
    local span = 0
    for _, o in pairs(order) do span = math.max(span, o) end
    local curve = opts.ease and ease.get(opts.ease)
    local most = 0
    for j = 1, n do
        local k = span > 0 and order[j] / span or 0
        if curve then k = curve(k) end
        self.offsets[j] = opts.amount and k * opts.amount or k * span * each
        most = math.max(most, self.offsets[j])
    end
    self.dur = self.base + most
    return self
end
-- A tween that starts when this one completes: :after([target,] duration, fields)
function Tween:after(a, b, c)
    arg_check(not self.parent, "after chains root tweens; use timeline positions inside a timeline")
    local target, dur, vars = a, b, c
    if type(a) == "number" then target, dur, vars = self.targets, a, b end
    local t = new_tween(self.group, target, dur, vars)
    local prev = self.cbs.complete
    self.cbs.complete = function(me)
        if prev then prev(me) end
        t:wake()
    end
    return t
end

------------------------------------------------------------------ timelines
local function new_timeline(group)
    local tl = new_clip(Timeline, group)
    tl.children, tl.labels = {}, {}
    return tl
end

function Timeline:span()
    local span = 0
    for _, c in ipairs(self.children) do
        local e = c.start + c:total()
        if e > span then span = e end
    end
    for _, at in pairs(self.labels) do if at > span then span = at end end
    return span
end

function Timeline:apply(p, i)
    local t = p * self:span()
    for _, c in ipairs(self.children) do
        if not c.killed then
            c.dir = self.dir
            local h, ct = t - c.start, c:total()
            if h <= 0 then
                if c.started and not (c.done and c.head <= 0) then c:render(0) end
            elseif h >= ct then
                if not (c.done and c.head >= ct) then c:render(ct) end
            else
                c:render(h)
            end
        end
    end
end

function Timeline:reclaim()
    for _, c in ipairs(self.children) do c:reclaim() end
end

function Timeline:drop(target, key)
    for _, c in ipairs(self.children) do c:drop(target, key) end
end

function Timeline:init()
    for _, c in ipairs(self.children) do c.head, c.iter, c.done = 0, -1, false end
end

-- GSAP's position parameter: a number is absolute; "+=x" / "-=x" from the end;
-- "<" / ">" the start / end of the last child, with an offset ("<0.1", ">-0.2");
-- a label, with an offset ("beat+=0.2"); nil is the end.
local function offset_of(s)
    if s == nil or s == "" then return 0 end
    local n = tonumber((s:gsub("^([+-])=", "%1")))
    arg_check(n ~= nil, "bad position offset " .. tostring(s), 4)
    return n
end
function Timeline:position(pos)
    if pos == nil then return self:span() end
    if type(pos) == "number" then return pos end
    arg_check(type(pos) == "string", "position must be a number, a string or nil")
    local anchor, rest = pos:match("^([<>])(.*)$")
    if anchor then
        local last = self.last
        local base = last and (anchor == "<" and last.start or last.start + math.min(last:total(), 1e9)) or 0
        return base + offset_of(rest)
    end
    local sign, amount = pos:match("^([+-])=(.*)$")
    if sign then return self:span() + offset_of(sign .. amount) end
    local name, tail = pos:match("^([%a_][%w_]*)(.*)$")
    arg_check(name ~= nil, "bad position " .. pos)
    local at = self.labels[name]
    if at == nil then at = self:span(); self.labels[name] = at end
    return at + offset_of(tail)
end

local function insert_child(self, clip, pos)
    clip.parent, clip.start = self, self:position(pos)
    clip.head, clip.iter, clip.done = 0, -1, false
    local kids = self.children
    local at = #kids + 1
    while at > 1 and kids[at - 1].start > clip.start do at = at - 1 end
    table.insert(kids, at, clip)
    self.last = clip
end

-- Put a clip (a tween or another timeline) at a position; it leaves its group.
-- Returns the clip, so its settings chain on: tl:to(card, .3, {y = 0}):ease("out_back")
function Timeline:add(clip, pos)
    arg_check(getmetatable(clip) == Tween or is_timeline(clip), "add takes a tween or a timeline")
    arg_check(not clip.parent, "the clip is already in a timeline")
    if clip.group and clip.live then clip.group:remove(clip) end
    clip.group = nil
    insert_child(self, clip, pos)
    if self.defaults and getmetatable(clip) == Tween then clip:configure(self.defaults) end
    return clip
end
function Timeline:to(target, dur, vars, pos) return self:add(new_tween(nil, target, dur, vars), pos) end
function Timeline:from(target, dur, vars, pos)
    local t = new_tween(nil, target, dur, {})
    for k in pairs(vars) do t.vars[k] = function(_, obj) return obj[k] end end
    self:add(t, pos)
    return t:from(vars)
end
function Timeline:set(target, vars, pos) return self:to(target, 0, vars, pos) end
-- A call at a position; the function receives the clip. Returns the timeline.
function Timeline:call(fn, pos)
    arg_check(type(fn) == "function", "call takes a function")
    insert_child(self, new_clip(Clip, nil):on_start(fn), pos)
    return self
end
-- A pause of `dur` seconds appended to the end. Returns the timeline.
function Timeline:wait(dur)
    arg_check(type(dur) == "number" and dur >= 0, "wait takes seconds")
    local c = new_clip(Clip, nil)
    c.dur = dur
    insert_child(self, c, nil)
    return self
end
-- Name a position; later children can sit at "name" or "name+=0.2". Returns the timeline.
function Timeline:label(name, pos)
    arg_check(type(name) == "string" and name:match("^[%a_][%w_]*$"), "a label is a word")
    self.labels[name] = self:position(pos)
    return self
end
function Timeline:punch(target, dur, vars, opts, pos) return self:add(Group.make_punch(nil, target, dur, vars, opts), pos) end
function Timeline:shake(target, dur, vars, opts, pos)
    return self:add(Group.make_shake(root_of(self).group or Group.default, target, dur, vars, opts), pos)
end

------------------------------------------------------------------ groups
-- A group ticks its own clips; `tween` is the default group, ticked by the engine.
function Group.new()
    return setmetatable({clips = {}, owners = setmetatable({}, {__mode = "k"}), speed = 1, paused = false,
                         instant = false, seed = 0x4A17B83}, Group)
end

function Group:random()
    local x = self.seed
    x = x ~ ((x << 13) & 0xFFFFFFFF)
    x = x ~ (x >> 17)
    x = x ~ ((x << 5) & 0xFFFFFFFF)
    self.seed = x
    return (x >> 8) * (1.0 / 16777216.0)
end

function Group:add(clip)
    clip.group, clip.live = self, true
    self.clips[#self.clips + 1] = clip
    clip:reclaim()
    return clip
end

function Group:remove(clip)
    for i, c in ipairs(self.clips) do
        if c == clip then table.remove(self.clips, i); break end
    end
    clip.live = false
    clip:release()
end

-- Advance every clip by dt seconds (the current frame's by default). Newest
-- first, as flux does: a tween made this frame records its start values before
-- an older tween on the same field writes, and takes the field over from it.
-- Clips a callback adds start next frame.
function Group:update(dt)
    if dt == nil then dt = app.dt() end
    arg_check(type(dt) == "number" and dt >= 0, "update takes nonnegative seconds")
    if self.paused then return end
    dt = dt * self.speed
    self.frame = (self.frame or 0) + 1
    for i = #self.clips, 1, -1 do
        local c = self.clips[i]
        if c and c.ticked ~= self.frame then
            c.ticked = self.frame
            if not c.killed and not idle(c) then c:advance(dt) end
            if c.killed or (c.done and not idle(c)) then self:remove(c) end
        end
    end
end

-- Tween fields of a target, or of every target in a list, to final values:
-- tween.to(card, .3, {x = 100, alpha = 1}, {ease = "out_back", delay = .1})
function Group:to(target, dur, vars, opts) return self:add(new_tween(self, target, dur, vars)):configure(opts) end
-- From `vars` to the current values; the target jumps to `vars` now.
function Group:from(target, dur, vars, opts) return self:add(from_tween(self, target, dur, vars)):configure(opts) end
-- Write the values now, through the overwrite rules.
function Group:set(target, vars)
    local t = new_tween(self, target, 0, vars)
    t:render(0)
    t:release()
    return t
end
-- Tween a value and hand each step to fn: tween.value(0, 100, .5, function(v) ... end)
function Group:value(from, to, dur, fn, opts)
    arg_check(type(fn) == "function", "value takes a function")
    local proxy = {v = from}
    return self:to(proxy, dur, {v = to}):on_update(function() fn(proxy.v) end):configure(opts)
end
-- A timeline: {defaults = {ease = ...}, paused = true, loops = n, delay = s, on_complete = fn, ...}
function Group:timeline(opts)
    local tl = self:add(new_timeline(self))
    if opts then
        arg_check(type(opts) == "table", "timeline options must be a table")
        tl.defaults = opts.defaults
        local rest = {}
        for k, v in pairs(opts) do if k ~= "defaults" and k ~= "paused" then rest[k] = v end end
        tl:configure(rest)
        if opts.paused then tl:pause() end
    end
    return tl
end

-- punch and shake -------------------------------------------------------
-- A punch goes `vars` away from the start and springs back with decaying swings
-- (DOTween's DOPunch): vibrato is swings per second, elasticity (0..1) how far
-- the back-swings go past the start.
local function punch_wave(self, p, j, key, diff)
    local swings = math.max(1, self.vibrato * self.base)
    local s = sin(p * swings * pi) * (1 - p)
    if s < 0 then s = s * self.elasticity end
    if type(diff) == "number" then return diff * s end
    local v = {}
    for f, d in pairs(diff) do v[f] = d * s end
    return v
end
function Group.make_punch(group, target, dur, vars, opts)
    local t = new_tween(group, target, dur, vars)
    opts = opts or {}
    t.vibrato, t.elasticity = opts.vibrato or 10, opts.elasticity == nil and 1 or opts.elasticity
    t.wave, t.rel = punch_wave, true
    return t
end
function Group:punch(target, dur, vars, opts) return self:add(Group.make_punch(self, target, dur, vars, opts)) end

-- A shake jitters by up to `vars` around the start and settles (DOTween's
-- DOShake): vibrato is jolts per second, randomness (0..180) how far the
-- direction wanders from alternating, fade_out tapers the strength.
local function shake_wave(self, p, j, key, diff)
    local frames = self.frames[j][key]
    local n = #frames
    local x = p * (n - 1)
    local k = floor(x) + 1
    if k >= n then return frames[n] end
    local u = x - (k - 1)
    u = u * u * (3 - 2 * u)
    local a, b = frames[k], frames[k + 1]
    if type(diff) == "number" then return a + (b - a) * u end
    local v = {}
    for f in pairs(diff) do v[f] = a[f] + (b[f] - a[f]) * u end
    return v
end
function Group.make_shake(group, target, dur, vars, opts)
    local rng = group or Group.default
    local t = new_tween(group, target, dur, vars)
    opts = opts or {}
    local vibrato, randomness, fade = opts.vibrato or 10, opts.randomness or 90, opts.fade_out ~= false
    local n = math.max(2, floor(vibrato * dur + .5) + 1)
    t.wave, t.frames, t.rel = shake_wave, {}, true
    for j = 1, #t.targets do
        t.frames[j] = {}
        for key, strength in pairs(vars) do
            local frames = {}
            for k = 1, n do
                local amp = k == n and 0 or (fade and (n - k) / (n - 1) or 1)
                local angle = (k % 2 == 0 and pi or 0) + (rng:random() * 2 - 1) * randomness / 180 * pi
                if type(strength) == "number" then
                    frames[k] = strength * amp * cos(angle)
                else
                    local v, fields = {}, {}
                    for f in pairs(strength) do fields[#fields + 1] = f end
                    table.sort(fields)
                    for idx, f in ipairs(fields) do
                        local axis = idx == 1 and cos(angle) or idx == 2 and sin(angle) or cos(angle + idx)
                        v[f] = strength[f] * amp * axis
                    end
                    frames[k] = v
                end
            end
            t.frames[j][key] = frames
        end
    end
    return t
end
function Group:shake(target, dur, vars, opts) return self:add(Group.make_shake(self, target, dur, vars, opts)) end

-- queries and bulk control ---------------------------------------------
local function tweens_of(clip, target, found)
    if clip.killed then return found end
    if getmetatable(clip) == Tween then
        for _, t in ipairs(clip.targets) do if t == target then found[#found + 1] = clip; break end end
    elseif is_timeline(clip) then
        for _, c in ipairs(clip.children) do tweens_of(c, target, found) end
    end
    return found
end
-- Every tween of a target, inside timelines too.
function Group:of(target)
    local found = {}
    for _, c in ipairs(self.clips) do tweens_of(c, target, found) end
    return found
end
function Group:is_tweening(target) return #self:of(target) > 0 end
-- Kill every tween of a target, or only the named fields: tween.kill(card, "x", "y")
function Group:kill(target, ...)
    local keys = {...}
    for _, t in ipairs(self:of(target)) do
        if #keys == 0 then
            t:kill()
            if not t.parent then self:remove(t) end
        else
            for _, k in ipairs(keys) do t:drop(target, k) end
        end
    end
    return self
end
function Group:kill_all()
    for _, c in ipairs(self.clips) do c.killed, c.live = true, false; c:release() end
    self.clips = {}
    return self
end
function Group:count() return #self.clips end
function Group:pause() self.paused = true; return self end
function Group:play() self.paused = false; return self end
function Group:time_scale(s)
    if s == nil then return self.speed end
    arg_check(type(s) == "number" and s >= 0, "time scale must be a nonnegative number")
    self.speed = s
    return self
end
-- Reduced motion: every clip completes on its next update; callbacks still fire.
function Group:set_instant(flag) self.instant = flag ~= false; return self end

------------------------------------------------------------------ the module
Group.default = Group.new()
tween = {}
for _, name in ipairs({"update", "to", "from", "set", "value", "timeline", "punch", "shake", "of", "is_tweening",
                       "kill", "kill_all", "count", "pause", "play", "time_scale"}) do
    tween[name] = function(...) return Group[name](Group.default, ...) end
end
-- An independent group with its own update(dt), time scale and overwrite scope.
function tween.group() return Group.new() end
-- Reduced motion for the default group; without an argument, reads it.
function tween.instant(flag)
    if flag == nil then return Group.default.instant end
    Group.default:set_instant(flag)
end
-- Forget every clip and setting of the default group (tests, screen changes).
function tween.reset() Group.default = Group.new() end
