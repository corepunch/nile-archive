-- Engine-owned entrance for a match board: the HUD lands, the cells ripple out
-- from the centre, the pieces rain down their columns, blockers slam on top and
-- a sheen runs across as the board goes live. Everything is a pure function of
-- one clock, so a game asks where a thing is and draws it its own way, and the
-- entrance can be skipped or frozen under a dialog at any moment.
--
-- local intro = board_intro.new(cells, {
--     reduced = false,                -- reduced motion: one short fade, no travel
--     blocked = function(id) end,     -- does this cell have a blocker to slam on?
--     on_ring = function(ring) end,   -- a ring of cells has started to open
--     on_land = function(id) end,     -- a piece has hit its cell
--     on_slam = function(id) end,     -- a blocker has hit its cell
--     on_sheen = function() end,      -- the board is about to go live
-- })
-- cells: {id=, at=vec2, ring=0.., column=0.., row=0.., drop=pixels}, where ring
-- counts out from the centre, column is the distance from the middle column and
-- row counts up from the bottom of the piece's column; drop is how far it falls,
-- the same for a whole column so its pieces come down as a train and never overlap.
board_intro = {}

local CELLS_AT, RING_GAP, SWEEP = .1, .05, .03
local RELICS_AT, COLUMN_GAP, ROW_GAP, GRAVITY = .22, .03, .02, 5600
local BOUNCE_1, BOUNCE_2, BOUNCE_HEIGHT = .17, .1, 13
local SLAM_TIME, SLAM_GAP = .14, .022
local SHEEN_TIME = .36
local FADE_TIME = .25

-- A damped spring's step response: from 0 to 1, overshooting when damping < 1.
local function spring(t, hz, damping)
    if t <= 0 then return 0 end
    local w = 2 * math.pi * hz
    local d, wd = damping * w, w * math.sqrt(1 - damping * damping)
    return 1 - math.exp(-d * t) * (math.cos(wd * t) + d / wd * math.sin(wd * t))
end

local intro = {}
intro.__index = intro

function board_intro.new(cells, opts)
    opts = opts or {}
    local self = setmetatable({t = 0, opts = opts, cell_of = {}, list = {}, rings = {}, reduced = opts.reduced}, intro)
    local lo, hi, settled = math.huge, -math.huge, 0
    for i, c in ipairs(cells) do
        local at = c.at
        local turn = (math.atan(at.y - cells[1].at.y, at.x - cells[1].at.x) / (2 * math.pi)) % 1
        local entry = {id = c.id, at = at, ring = c.ring, drop = c.drop, clip = c.clip,
                       open_at = CELLS_AT + c.ring * RING_GAP + turn * SWEEP,
                       fall_at = RELICS_AT + c.column * COLUMN_GAP + c.row * ROW_GAP,
                       fall = math.sqrt(2 * c.drop / GRAVITY), blocked = opts.blocked and opts.blocked(c.id)}
        entry.land_at = entry.fall_at + entry.fall
        settled = math.max(settled, entry.land_at)
        entry.sweep = at.x * .5 + at.y * .866
        lo, hi = math.min(lo, entry.sweep), math.max(hi, entry.sweep)
        self.cell_of[c.id], self.list[i] = entry, entry
    end
    -- Blockers slam once the pieces have landed, from the outside in.
    local slams = 0
    table.sort(self.list, function(a, b)
        if a.ring ~= b.ring then return a.ring > b.ring end
        return a.id < b.id
    end)
    settled = settled + BOUNCE_1 * .7
    for _, c in ipairs(self.list) do
        if c.blocked then
            c.slam_at = settled + slams * SLAM_GAP
            slams = slams + 1
        end
    end
    local slammed = settled + (slams > 0 and (slams - 1) * SLAM_GAP + SLAM_TIME or 0)
    self.sheen_at = slammed
    self.ends = self.reduced and FADE_TIME or slammed + SHEEN_TIME
    for _, c in ipairs(self.list) do c.sweep = hi > lo and (c.sweep - lo) / (hi - lo) or 0 end
    return self
end

-- Advance the clock and call back what has just happened.
function intro:update(dt)
    if self.t >= self.ends then return end
    self.t = math.min(self.ends, self.t + dt)
    if self.reduced then return end
    local opts = self.opts
    for _, c in ipairs(self.list) do
        if not self.rings[c.ring] and self.t >= c.open_at then
            self.rings[c.ring] = true
            if opts.on_ring then opts.on_ring(c.ring) end
        end
        if not c.landed and self.t >= c.land_at then
            c.landed = true
            if opts.on_land then opts.on_land(c.id) end
        end
        if c.slam_at and not c.slammed and self.t >= c.slam_at + SLAM_TIME then
            c.slammed = true
            if opts.on_slam then opts.on_slam(c.id) end
        end
    end
    if not self.sheened and self.t >= self.sheen_at then
        self.sheened = true
        if opts.on_sheen then opts.on_sheen() end
    end
end

function intro:done() return self.t >= self.ends end

-- Jump to the end, as a tap does. Nothing skipped calls back.
function intro:skip()
    self.t = self.ends
    self.sheened = true
    for _, c in ipairs(self.list) do c.landed, c.slammed = true, true end
end

-- A part of the HUD's arrival: 0 (not yet) to 1, with spring overshoot.
function intro:arrive(delay, hz, damping)
    if self.t <= 0 then return 0 end
    if self.reduced or self:done() then return 1 end
    return spring(self.t - delay, hz or 3, damping or .55)
end

function intro:fade() return self.reduced and math.min(1, self.t / FADE_TIME) or 1 end

-- A cell: scale (0 hides it), turn in radians, lift downward, white flash 0..1.
function intro:cell(id)
    if self.t <= 0 then return 0, 0, 0, 0 end
    if self.reduced or self:done() then return 1, 0, 0, 0 end
    local c = self.cell_of[id]
    local t = self.t - c.open_at
    if t <= 0 then return 0, 0, 0, 0 end
    local s = spring(t, 3.1, .5)
    -- The piece's landing presses its cell down.
    local after = self.t - c.land_at
    local press = after > 0 and 4.5 * math.exp(-after * 13) * math.sin(after * 30) or 0
    return s, (1 - s) * -math.pi / 3, (1 - s) * 22 + press, math.max(0, 1 - t / .32)
end

-- A piece: visible, height above its cell, aspect (above 1 is squashed), and
-- whether it is still inside its column and needs masking.
function intro:relic(id)
    if self.t <= 0 then return false, 0, 1, false end
    if self.reduced or self:done() then return true, 0, 1, false end
    local c = self.cell_of[id]
    local t = self.t - c.fall_at
    if t <= 0 then return false, 0, 1, false end
    if t < c.fall then
        local u = t / c.fall
        return true, c.drop * (1 - u * u), 1 - .17 * u, true
    end
    local b = t - c.fall
    local height = 0
    if b < BOUNCE_1 then height = BOUNCE_HEIGHT * math.sin(b / BOUNCE_1 * math.pi)
    elseif b < BOUNCE_1 + BOUNCE_2 then height = BOUNCE_HEIGHT * .3 * math.sin((b - BOUNCE_1) / BOUNCE_2 * math.pi) end
    local aspect = 1 + .24 * math.exp(-b * 13) * math.cos(b * 27)
    -- It lands with the cell pressing down under it.
    local press = 4.5 * math.exp(-b * 13) * math.sin(b * 30)
    return true, height - press, aspect, false
end

-- A blocker: visible, scale (it slams down from above) and opacity.
function intro:blocker(id)
    if self.t <= 0 then return false, 1, 0 end
    if self.reduced or self:done() then return true, 1, 1 end
    local c = self.cell_of[id]
    if not c.slam_at then return true, 1, 1 end
    local t = self.t - c.slam_at
    if t <= 0 then return false, 1, 0 end
    local u = math.min(1, t / SLAM_TIME)
    if u < 1 then return true, 1.9 - .9 * u * u, u end
    local b = t - SLAM_TIME
    return true, 1 - .09 * math.exp(-b * 15) * math.cos(b * 32), 1
end

-- How strongly the final sheen is on this cell, 0..1.
function intro:sheen(id)
    if self.reduced or self.t <= self.sheen_at then return 0 end
    local wave = (self.t - self.sheen_at) / SHEEN_TIME * 1.5 - .25
    local x = (wave - self.cell_of[id].sweep) / .14
    return math.exp(-x * x)
end

-- Attach the same entrance lifecycle to either game's shared match-3 view.
-- Existing matching, refill poses and gestures continue through bind_view.
function board_intro.bind(R, rules)
    local update, input_board, pose, reset = R.board_update, R.board_input, R.piece_pose, R.reset_board
    R.PH_PRESENT = 5
    local no_tile = {kind = -1, special = 0}
    local notes = {392, 493.88, 587.33, 739.99, 880}
    function R.reset_board(g)
        reset(g)
        R.intro = nil
    end
    function R.present_board()
        R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
        local g, cells, center = R.g, {}, rules.hex_center()
        local dy = math.sqrt(3) * R.HEX_R
        for i = 0, rules.CELLS - 1 do
            if rules.game_cell_active(g, i) then
                local q, lo, hi = rules.hex_q(i), rules.hex_r(i), rules.hex_r(i)
                while rules.game_cell_active(g, rules.hex_index(q, lo - 1)) do lo = lo - 1 end
                while rules.game_cell_active(g, rules.hex_index(q, hi + 1)) do hi = hi + 1 end
                local top = R.cell_pos(rules.hex_index(q, lo))
                local entry = {id=i, at=R.cell_pos(i), ring=rules.hex_distance(center,i), column=math.abs(q), row=hi-rules.hex_r(i),
                    drop=(hi-lo+1)*dy+8,
                    clip=rect(R.cell_pos(i).x-R.piece_width/2-1,top.y-dy/2,R.piece_width+2,(hi-lo+1)*dy)}
                if i == center then table.insert(cells,1,entry) else cells[#cells+1]=entry end
            end
        end
        R.intro = board_intro.new(cells, {
            reduced=R.reduced_motion,
            blocked=function(i) return g.ice[i]>0 or g.chain[i]>0 end,
            on_ring=function(ring) R.tone(notes[num.clampi(ring,0,4)+1]) end,
            on_land=function(i) R.vfx_emit(R.cell_pos(i)+vec2(0,R.HEX_R*.55),g.tiles[i].kind,false,2) end,
            on_slam=function(i)
                R.vfx_slam(R.cell_pos(i),g.ice[i]>0 and 6 or 7)
                R.shake=math.max(R.shake,.05)
            end,
            on_sheen=function() R.goal_pulse,R.score_pulse=.22,.22; R.tone(1174.66) end,
        })
        R.phase, R.phase_time = R.PH_PRESENT, 0
    end
    function R.board_update(dt)
        if R.phase ~= R.PH_PRESENT then return update(dt) end
        if R.art_review or R.overlay ~= R.OV_NONE or R.on_island or story.active() then return end
        R.shake = math.max(0,R.shake-dt)
        R.intro:update(dt)
        if R.intro:done() then R.intro=nil; R.phase=R.PH_IDLE; R.idle_time=0 end
    end
    function R.board_input(inp)
        if R.phase ~= R.PH_PRESENT then return input_board(inp) end
        if inp.released and R.overlay == R.OV_NONE and not story.active() and R.intro.t > 0 then R.intro:skip() end
    end
    function R.piece_pose(i, sx)
        if R.phase ~= R.PH_PRESENT then return pose(i,sx) end
        local visible, height, aspect, masked = R.intro:relic(i)
        local sheen, at = R.intro:sheen(i), R.cell_pos(i)+vec2(sx,0)
        at.y = at.y-height-7*sheen
        return visible and R.g.tiles[i] or no_tile, at, 1+.1*sheen, 255*R.intro:fade(), aspect,
            masked and R.intro.cell_of[i].clip or nil
    end
end
