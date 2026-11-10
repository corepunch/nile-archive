-- Reusable deterministic hex match-3 engine. Game configuration is data and
-- integer behavior flags; graphics never implement matching, gravity or input.
local E = {
    NO_TRICKLE=1, NO_SPECIALS=2, NO_TOOLS=4, NO_HINTS=8, NO_RESHUFFLE=16, NO_THAW=32, LINE_MATCHES=64,
    GOAL=1, THAW=2, WOOD=4, STONE=8, -- per-kind behavior bits
}

-- Engine-owned interaction state; a game adds only its screen/presentation data.
function E.view(state)
    state = state or {}
    state.SCREEN_W, state.SCREEN_H = state.SCREEN_W or 480, state.SCREEN_H or 900
    state.HEX_R, state.drop = state.HEX_R or 32, 0
    state.PH_IDLE, state.PH_SWAP, state.PH_REJECT, state.PH_CLEAR, state.PH_FALL = 0, 1, 2, 3, 4
    state.old_tiles, state.fall_from, state.wave_ice, state.wave_chain = {}, {}, {}, {}
    state.phase, state.phase_time, state.idle_time, state.shake = 0, 0, 0, 0
    state.selected, state.swap_a, state.swap_b, state.tool, state.hint_a, state.hint_b = -1, -1, -1, -1, -1, -1
    return state
end

-- The two match-3 cities share the same view templates. Game code supplies
-- localized copy, skin colors, and records with stable keys via set_items.
function E.catalogue_form(title, hint, close, detail_color, paint_tile)
    -- Icons in rows of four: a record is one row, {id, cells={building records}}.
    -- A tile is its painted icon under a flat button (pick1..pick4).
    return ui.form{kind='column',panel=true,padding=18,gap=8,children={
        {kind='label',text=title,height=40,em=32},
        {kind='row',height=38,gap=8,children={
            {kind='button',id='category_prev',text='<',width=42,em=22},
            {kind='label',id='category',grow=1,em=21},
            {kind='button',id='category_next',text='>',width=42,em=22},
        }},
        {kind='label',text=hint,height=24,em=14,text_style=detail_color},
        {kind='list',id='stock',scroll=true,height=350,gap=8,item=function(row)
            local cells = {}
            for j = 1, 4 do
                local record = row.cells[j]
                cells[j] = record and {kind='overlay',grow=1,height=100,children={
                    {kind='custom',paint=function(box) paint_tile(box, record) end},
                    {kind='button',id='pick'..j,text='',flat=true},
                }} or {kind='spacer',grow=1}
            end
            return {kind='row',height=100,gap=8,children=cells}
        end},
        {kind='label',id='info_name',height=26,em=20},
        {kind='label',id='info_note',height=40,wrap=true,em=14,text_style=detail_color},
        {kind='button',id='close',text=close,height=42,em=21},
    }}
end

-- Slim rows: the whole row is the button (id 'play'); paint_level draws its
-- medallion, name and state.
function E.expedition_form(title, intro, close, detail_color, paint_level)
    return ui.form{kind='column',panel=true,padding=20,gap=12,children={
        {kind='label',text=title,height=42,em=34},
        {kind='label',text=intro,wrap=true,em=14,text_style=detail_color},
        {kind='list',id='levels',scroll=true,height=430,gap=6,item=function(e)
            return {kind='overlay',height=e.state == 'current' and 66 or 50,children={
                {kind='custom',paint=function(box) paint_level(box, e) end},
                {kind='button',id='play',text='',flat=true,enabled=e.available},
            }}
        end},
        {kind='button',id='close',text=close,height=42,em=21},
    }}
end

-- One GPU texture per skin. Every named image is a borrowed texture region,
-- so existing gfx.image, form images and particles use the same atlas directly.
local skins = {}
function E.skin(override)
    local key = override or "default"
    if skins[key] then return skins[key] end
    local atlas = override and texture.load(override.path) or texture.match3_default()
    assert(atlas.tex, "cannot load match3 skin atlas")
    local frames = override and override.frames or require("match3.frames")
    local skin = {atlas=atlas}
    for name, box in pairs(frames) do
        local image = texture.region(atlas, rect(box[1], box[2], box[3], box[4]))
        assert(image.tex, "invalid match3 frame: " .. name)
        skin[name] = image
    end
    for _, name in ipairs({"kind-0", "kind-1", "kind-2", "kind-3", "kind-4", "kind-5", "ray-row", "ray-column", "ray-diagonal",
        "bomb", "prism", "sand", "chain", "ice-1", "ice-2", "selected", "hint", "guide", "cell-mask", "score", "complete", "background"}) do
        assert(skin[name], "missing match3 frame: " .. name)
    end
    for _, tool in ipairs({"pickaxe", "dynamite", "sunburst", "pause"}) do
        for _, state in ipairs({"normal", "selected", "pressed", "hover", "disabled"}) do
            assert(skin[tool .. "-" .. state], "missing authored match3 control state")
        end
    end
    skins[key] = skin
    return skin
end

-- The same board controls use the authored images from either skin.
E.TOOL_SIZE = 76
E.GOAL_W = 70   -- every goal capsule; fits a four-digit score

function E.tool_state(charges, selected, inside, down, started_inside, hover, idle)
    if charges <= 0 or not idle then return "disabled" end
    if inside and down and started_inside then return "pressed" end
    if selected then return "selected" end
    if inside and hover then return "hover" end
    return "normal"
end

function E.pause_button(R, bounds, offset)
    local st = ui.hit(bounds, 0)
    local state = st.held and "pressed" or st.hot and "hover" or "normal"
    gfx.image(R.hud_art["pause-" .. state], offset and bounds:offset(offset) or bounds, color.WHITE)
    return st.clicked
end

function E.bind_board_ui(R, rules, tool_art)
    local rgba, PI = color, math.pi
    local PAL_GOLD, PAL_CREAM, PAL_WHITE = R.PAL_GOLD, R.PAL_CREAM, R.PAL_WHITE
    function R.goal_entries()
        local g, l = R.g, rules.level_of(R.g)
        local entries = {
            {id="score", icon="score", remaining=math.max(0, l.score-g.score)},
            {id="idols", icon="idols", remaining=math.max(0, l.relics-g.relics)},
        }
        if l.soil>0 then entries[#entries+1]={id="sand",icon="sand",remaining=math.max(0,l.soil-g.dug)} end
        if g.initial_obstacles>0 then entries[#entries+1]={id="locks",icon="chain",remaining=math.max(0,g.obstacles)} end
        return entries
    end
    local goal_centers = {}
    local function goal_panel(box, entry)
        goal_centers[entry.id] = R.skin:resource_icon_box(box, "goal"):center()
        local icon = entry.icon=="score" and R.hud_art.score
            or entry.icon=="idols" and R.relics[rules.RELIC_IDOL+1]
            or R.board_art[entry.icon]
        -- Collections landing on a goal make it bounce.
        local pulse = entry.id=="idols" and R.goal_pulse or entry.id=="score" and R.score_pulse or 0
        local met = entry.remaining==0
        R.skin:draw_resource(box, icon, tostring(entry.remaining), {role="goal", interactive=false,
            icon_scale=1 + math.sin(num.saturate(pulse / .22) * PI) * .16,
            done=met})   -- one tick, the same in every capsule
    end
    local hud_form=ui.form{kind="row",gap=6,align="center",children={
        {kind="spacer",width=82},    -- the Moves medallion
        {kind="spacer",grow=1},
        {kind="list",id="goals",direction="row",gap=6,item=function(entry)
            -- Every goal is the same capsule: one width, one height, one tick.
            return {kind="custom",width=E.GOAL_W,height=30,paint=function(box) goal_panel(box,entry) end}
        end},
        {kind="spacer",grow=1},
        {kind="spacer",width=64},    -- Pause
    }}

    -- Hexagonal medallion, echoing the board cells: gold rim, jade face, the
    -- remaining moves large inside. It warms to red over the last five moves.
    local function draw_moves(arrive)
        local c, r, a = vec2(56, R.hud_rect:center().y), 40 * arrive, (arrive - 1) * PI / 3   -- flat-top, like the cells
        local moves = R.g.moves
        local urgent = moves <= 5 and not R.g.won
        if urgent and not R.reduced_motion then
            gfx.additive(true)
            gfx.glow(c, r + 14, rgba(255, 92, 40, 70 + 50 * math.sin(R.now * 6)), rgba(255, 92, 40, 0))
            gfx.additive(false)
        end
        gfx.ngon(c + vec2(0, 5), r, 6, a, rgba(3, 20, 18, 150))
        gfx.ngon(c, r, 6, a, rgba(116, 74, 33))
        gfx.ngon(c, r - 2, 6, a, rgba(236, 196, 112))
        gfx.ngon(c + vec2(0, 2), r - 5, 6, a, rgba(176, 120, 48))
        local face = R.skin:color(urgent and "moves_low" or "moves_face")
        local glow = R.skin:color(urgent and "moves_low_glow" or "moves_glow")
        gfx.ngon(c, r - 7, 6, a, face)
        gfx.glow(c + vec2(0, -4), r - 12, glow, color.alpha(face, 0))
        if arrive < .8 then return end   -- the numbers come with the settled medallion
        text.inside(R.pal(PAL_CREAM, 9), rect.centered(c + vec2(0, -17 * arrive), size2(56, 12)), vec2(.5, .5), "MOVES")
        local s = R.pal(urgent and PAL_WHITE or PAL_GOLD, 29 * arrive)
        text.inside(s, rect.centered(c + vec2(0, 5 * arrive), size2(62, 34)), vec2(.5, .5), tostring(moves))
    end

    function R.goal_target(kind)
        -- Collection flights land on the goal they advance.
        return goal_centers[kind==rules.RELIC_IDOL and "idols" or "score"] or vec2(250, R.hud_rect:center().y)
    end
    function R.draw_board_hud()
        local top = R.intro and R.intro:arrive(0, 2.8, .58) or 1
        if top <= 0 then return end
        local offset = vec2(0, (top - 1) * (R.hud_rect.y + 110))
        assert(hud_form:set_items("goals",R.goal_entries()))
        -- Medallion, goals and Pause all centre on the band's midline.
        hud_form:draw(rect.centered(R.hud_rect:center(), size2(R.hud_rect.w - 28, 44)):offset(offset),R.skin,{interactive=false})
        local medallion = R.intro and R.intro:arrive(.16, 3, .42) or 1
        if medallion > .05 then draw_moves(medallion) end
        if E.pause_button(R, R.board_pause, offset) then R.overlay = R.OV_PAUSE end
    end

    -- The level's mission arrives across the middle of the screen, holds,
    -- then slides away, once any dialogue has finished. A tap sends it on.
    function R.mission(text, title)
        R.mission_banner = {text = text, title = title, t = 0}
    end
    local MISSION_IN, MISSION_HOLD, MISSION_OUT = .4, 3.6, .4
    local function draw_mission(dt)
        local m = R.mission_banner
        if not m or R.overlay ~= R.OV_NONE or story.active() then return end
        if m.t == 0 then R.play("mission") end
        m.t = m.t + dt
        local w, h = R.SCREEN_W, 150
        local center = vec2(w / 2, R.board_origin.y - 30)
        local slide
        if m.t < MISSION_IN then slide = (1 - ease.out_back(m.t / MISSION_IN)) * w
        elseif m.t < MISSION_IN + MISSION_HOLD then slide = 0
        else slide = -ease.in_cubic(num.saturate((m.t - MISSION_IN - MISSION_HOLD) / MISSION_OUT)) * w end
        if m.t > MISSION_IN + MISSION_HOLD + MISSION_OUT then R.mission_banner = nil; return end
        if R.reduced_motion then slide = 0 end
        local band = rect.centered(center + vec2(slide, 0), size2(w + 40, h))
        local fade = num.saturate(m.t / .2) * (1 - num.saturate((m.t - MISSION_IN - MISSION_HOLD) / MISSION_OUT))
        gfx.bleed(true)
        gfx.rect(app.bleed(), rgba(4, 20, 18, 90 * fade))   -- the board steps back behind the mission
        gfx.bleed(false)
        gfx.shadow(band:offset(vec2(0, 8)), 4, 18, rgba(0, 0, 0, 110))
        gfx.rect(band, R.skin:color("moves_face"))
        gfx.rect(rect(band.x, band.y + 6, band.w, band.h - 12), color.shade(R.skin:color("moves_face"), 1.18))
        gfx.rect(rect(band.x, band.y + 3, band.w, 2), rgba(236, 196, 112))
        gfx.rect(rect(band.x, band:max().y - 5, band.w, 2), rgba(236, 196, 112))
        local inner = band:inflate(-36)
        if m.title then
            text.inside(R.pal(PAL_CREAM, 17), rect(inner.x + 20, band.y + 16, inner.w - 40, 22), vec2(.5, .5), m.title)
        end
        text.box(R.pal(PAL_GOLD, 30), rect(inner.x + 20, band.y + (m.title and 42 or 20), inner.w - 40, band.h - (m.title and 58 or 40)),
                 vec2(.5, .5), m.text)
        -- Any tap while it holds sends it on its way; the board stays untouched.
        -- The tap that started the level (Play releases as the board opens) is not one.
        ui.block(app.bleed())
        if ui.hit(app.bleed(), 0).clicked and m.t > .15 and m.t < MISSION_IN + MISSION_HOLD then m.t = MISSION_IN + MISSION_HOLD end
    end

    -- Kudos pop over the board, swell, then rise and fade.
    local function draw_kudos(dt)
        local k = R.kudos
        if not k then return end
        k.t = k.t + dt
        local life = 1.25
        if k.t > life then R.kudos = nil; return end
        local pop = k.t < .22 and ease.out_back(k.t / .22) or 1
        local fade = 1 - num.saturate((k.t - .95) / .3)
        local at = R.board_origin + vec2(0, -20 - num.saturate((k.t - .9) / .35) * 30)
        -- Glyphs with outline and shadow are rasterised per pixel size, so the pop
        -- steps through a few sizes instead of one new size every frame.
        local em = (40 + 6 * k.level) * (math.floor(pop * 5 + .5) / 5)
        if not R.reduced_motion then
            gfx.additive(true)
            gfx.glow(at, 150 * pop, rgba(255, 214, 110, 120 * fade), rgba(255, 214, 110, 0))
            gfx.additive(false)
        end
        local st = R.pal(k.level >= 3 and PAL_WHITE or PAL_GOLD, em)
        st.fill = color.alpha(st.fill, fade)
        if st.fill2 then st.fill2 = color.alpha(st.fill2, fade) end
        if st.outline then st.outline = color.alpha(st.outline, fade) end
        if st.shadow then st.shadow = color.alpha(st.shadow, fade) end
        text.inside(st, rect.centered(at, size2(R.SCREEN_W - 20, em * 1.6)), vec2(.5, .5), k.text)
    end

    function R.draw_board_banners(dt)
        draw_kudos(dt)
        draw_mission(dt)
    end

    function R.draw_board_tools(inp)
        if R.intro and R.intro:arrive(.05, 2.8, .58) <= 0 then return end
        for k = 0, 2 do
            local r = R.board_tool_bounds(k)
            local x, y = r:center().x, r.y
            local charges = R.g.tools[k + 1]
            local state = E.tool_state(charges, R.tool == k, r:contains(inp.pos), inp.down,
                                       inp.press_pos ~= nil and r:contains(inp.press_pos), inp.hover,
                                       R.phase == R.PH_IDLE or R.phase == R.PH_PRESENT)
            -- The tools spring up from the bottom edge one by one; they take taps at rest.
            local rise = R.intro and R.intro:arrive(.14 + k * .07, 3, .48) or 1
            local up = vec2(0, (1 - rise) * 120)
            local drawn = r:offset(up)
            gfx.shadow(drawn:offset(vec2(0, 4)), 20, 10, rgba(0, 0, 0, 90))
            gfx.image(R.board_art[tool_art[k + 1] .. "-" .. state], drawn:inflate(5), color.WHITE)
            gfx.circle(vec2(x + 31, y + 4) + up, 14, rgba(116, 74, 33))
            gfx.circle(vec2(x + 31, y + 4) + up, 12, charges > 0 and rgba(46, 112, 70) or rgba(75, 94, 80))
            R.say(tostring(charges), rect(x + 18, y - 9, 26, 26):offset(up), 16, PAL_CREAM)
            if ui.hit(r, 0).clicked and R.phase == R.PH_IDLE then R.select_tool(k) end
        end
    end
end

function E.result_rects(screen_w, screen_h)
    local w, s = math.min(408, screen_w - 48), math.min(1, (screen_h - 100) / 556)
    local x, y = (screen_w - w) / 2, (screen_h - 556 * s) / 2 + 8
    return {card = rect(x, y, w, 556 * s), header = rect(x + 22, y - 26 * s, w - 44, 74 * s), stars = rect(x + 70, y + 70 * s, w - 140, 64 * s),
            score_label = rect(x + 66, y + 140 * s, w - 132, 20 * s), score = rect(x + 60, y + 163 * s, w - 120, 53 * s),
            treasure_label = rect(x + 30, y + 217 * s, w - 60, 20 * s), rewards = rect(x + 22, y + 243 * s, w - 44, 91 * s),
            progress = rect(x + 44, y + 349 * s, w - 88, 36 * s), next = rect(x + 28, y + 397 * s, w - 56, 65 * s),
            claim = rect(x + 40, y + 480 * s, w - 80, 56 * s)}
end

function E.guide_form(copy, guide_icon)
    return ui.form{kind="column",panel=true,padding=20,children={
        {kind="label",text=copy.title,height=44,em=34},
        {kind="label",text=copy.instructions,height=26,em=13,text_style="white"},
        {kind="spacer",height=14},
        {kind="list",id="topics",gap=12,item=function(entry)
            local align=entry.icon and "start" or "center"
            return {kind="row",gap=14,align="center",children={
                {kind="custom",width=64,height=64,visible=entry.icon~=nil,paint=function(r) guide_icon(r,entry.icon) end},
                {kind="column",grow=1,gap=4,children={
                    {kind="label",text=entry.title,wrap=true,text_align=align,em=22,text_style="gold"},
                    {kind="label",text=entry.description,wrap=true,text_align=align,em=16,text_style="cream"},
                }},
            }}
        end},
        {kind="spacer",height=18},
        {kind="label",text="TOOLS DO NOT COST MOVES. TAP ONE, THEN A TILE.",height=28,em=12,text_style="white"},
        {kind="spacer",height=10},
        {kind="button",id="done",text=copy.done,height=45,em=25},
    }}
end

function E.pause_form(guide_label, quit_label, leaderboard_label)
    return ui.form{
        root={kind="column",panel=true,padding={40,20,40,22},gap=16,children={
            {kind="label",text="Settings",height=44,em=34},
            {kind="label",id="level",height=22,em=16,text_style="cream"},
            {kind="column",panel=true,role="group",padding={18,8,18,10},gap=6,children={
                {kind="checkbox",id="sound",text="SOUND",height=50},
                {kind="checkbox",id="motion",text="REDUCE MOTION",height=50},
            }},
            {kind="column",gap=12,children={
                {kind="button",id="resume",text="RESUME",height=52},
                {kind="button",id="restart",text="RESTART",height=46,role="secondary",visible=quit_label~=nil,visible_field="expedition"},
                {kind="button",id="quit",text=quit_label,height=46,role="secondary",visible=quit_label~=nil,visible_field="expedition"},
            }},
            {kind="button",id="leaderboard",text=leaderboard_label,height=32,role="link",em=20,visible=leaderboard_label~=nil},
            {kind="button",id="guide",text=guide_label,height=32,role="link",em=20},
        }},
        bindings={{id="sound",field="sound",type="boolean"},{id="motion",field="reduced_motion",type="boolean"}},
    }
end

local function draw_dialog_form(R, form, width, y)
    local _, height = form:measure(width, R.skin)
    local bounds = rect.centered(vec2(R.SCREEN_W / 2, y), size2(width, height))
    R.modal_bounds = R.pr(bounds)
    return form:draw(bounds, R.skin, {hit_offset=vec2(0, R.hit_dy)})
end

function E.draw_guide(R, form)
    local event = draw_dialog_form(R, form, 432, R.SCREEN_H / 2 + 10)
    if event and event.id == "done" then R.overlay = R.OV_NONE end
end

function E.draw_pause(R, form, level)
    local ok, message = form:push(R)
    assert(ok, message)
    form.values.expedition = not R.on_island
    form:set("level", level)
    -- the leaderboard link makes the card taller: sit lower so its top clears the gear
    local event = draw_dialog_form(R, form, 396, R.SCREEN_H / 2 + (R.words.leaderboard and 24 or 0))
    if not event then return end
    if event.kind == "change" then
        ok, message = form:pull(R)
        assert(ok, message)
        sfx.enable(R.sound)
    elseif event.id == "resume" then R.overlay = R.OV_NONE
    elseif event.id == "guide" then R.overlay = R.OV_GUIDE
    else return event.id end   -- restart, quit, leaderboard: the game decides
end

function E.new(config)
    config = config or {}
    local flags, kind_flags = config.flags or 0, config.kind_flags or {}
    assert(math.type(flags) == "integer" and flags >= 0 and flags < 128, "invalid match3 flags")
    assert(not config.radius or math.type(config.radius) == "integer" and config.radius >= 1 and config.radius <= 16, "invalid hex radius")
    local M = {flags=flags}
    -- Axial hex grid; neighbours are
    -- numbered 0..5 and opposite directions differ by 3.
    M.HEX_RADIUS = config.radius or 4
    M.CELLS = 1 + 3 * M.HEX_RADIUS * (M.HEX_RADIUS + 1)
    local radius, stride = M.HEX_RADIUS, M.HEX_RADIUS * 4 + 1
    local CELLS = M.CELLS
    local qs, rs, index = {}, {}, {}
    do
        local n = 0
        for q = -radius, radius do
            for r = math.max(-radius, -q - radius), math.min(radius, -q + radius) do
                qs[n], rs[n] = q, r
                index[q * stride + r] = n
                n = n + 1
            end
        end
    end
    -- direction d: 0 = (+1, 0), 1 = (0, +1), 2 = (-1, +1), 3..5 the opposites
    local dirs = {[0] = {1, 0}, {0, 1}, {-1, 1}, {-1, 0}, {0, -1}, {1, -1}}
    local neighbors = {}
    for i = 0, CELLS - 1 do
        neighbors[i] = {}
        for d = 0, 5 do
            local q, r = qs[i] + dirs[d][1], rs[i] + dirs[d][2]
            neighbors[i][d] = (math.abs(q) <= radius and math.abs(r) <= radius and math.abs(q + r) <= radius) and index[q * stride + r] or -1
        end
    end

    function M.hex_index(q, r)
        if math.abs(q) > radius or math.abs(r) > radius or math.abs(q + r) > radius then return -1 end
        return index[q * stride + r]
    end
    function M.hex_q(cell) return qs[cell] or 0 end
    function M.hex_r(cell) return rs[cell] or 0 end
    function M.hex_neighbor(cell, d)
        local n = neighbors[cell]
        return n and n[d] or -1
    end
    function M.hex_center() return index[0] end
    function M.hex_distance(a, b)
        if a < 0 or a >= CELLS or b < 0 or b >= CELLS then return 10000 end
        local q, r = qs[a] - qs[b], rs[a] - rs[b]
        return (math.abs(q) + math.abs(r) + math.abs(q + r)) // 2
    end
    local hex_index, hex_q, hex_r, hex_neighbor, hex_distance, hex_center =
        M.hex_index, M.hex_q, M.hex_r, M.hex_neighbor, M.hex_distance, M.hex_center


    M.COLORS, M.MATCH_MIN = config.colors or 6, config.match_min or 3
    assert(math.type(M.COLORS) == "integer" and M.COLORS >= 3, "at least three match3 kinds required")
    assert(math.type(M.MATCH_MIN) == "integer" and M.MATCH_MIN >= 3, "match minimum must be at least three")
    M.levels = config.levels or {{name="Resources", lesson="Connect matching resources.", moves=30, score=1000, relics=0, soil=0, chains=0, ice=0}}
    M.LEVELS, M.level_shapes = #M.levels, config.level_shapes or {}
    assert(M.LEVELS > 0, "match3 needs a level")
    local LEVELS, COLORS, MATCH_MIN = M.LEVELS, M.COLORS, M.MATCH_MIN
    M.NORMAL, M.ROW, M.COLUMN, M.DIAGONAL, M.BOMB, M.PRISM = 0, 1, 2, 3, 4, 5
    local NORMAL, ROW, COLUMN, DIAGONAL, BOMB, PRISM = 0, 1, 2, 3, 4, 5
    function M.level_of(g) return M.levels[g.level + 1] end
    --------------------------------------------------------------------- rules

    -- xorshift32 on 32-bit values, the same stream as the C original
    local function random_next(g)
        local x = g.rng
        x = x ~ ((x << 13) & 0xFFFFFFFF)
        x = x ~ (x >> 17)
        x = x ~ ((x << 5) & 0xFFFFFFFF)
        if x == 0 then x = 0x12345678 end
        g.rng = x
        return x
    end
    local function randn(g, n) return random_next(g) % n end

    local function tile(kind, special) return {kind = kind, special = special or NORMAL} end
    M.tile = tile

    local function swap_tiles(g, a, b) g.tiles[a], g.tiles[b] = g.tiles[b], g.tiles[a] end
    local function locked(g, i) return g.chain[i] > 0 or g.ice[i] > 0 end

    local function cell_active(g, cell) return cell >= 0 and cell < CELLS and g.active[cell] end
    M.game_cell_active = cell_active

    local function equal(g, a, b)
        return cell_active(g, a) and cell_active(g, b) and g.tiles[a].kind >= 0 and g.tiles[a].kind == g.tiles[b].kind
    end

    local function ray_for_axis(axis) return axis == 0 and ROW or axis == 1 and COLUMN or DIAGONAL end
    local function axis_of_ray(sp) return sp == ROW and 0 or sp == COLUMN and 1 or 2 end

    -- An empty match: which cells clear (mask) and which specials appear (make).
    local function new_match() return {mask = {}, make = {}, hits = 0} end
    M.new_match = new_match

    local function count_hits(m)
        local n = 0
        for i = 0, CELLS - 1 do if m.mask[i] then n = n + 1 end end
        m.hits = n
        return n
    end

    -- Flood fill of identical relics through shared hex edges.
    local function collect_group(g, start, cells)
        if not cell_active(g, start) or g.tiles[start].kind < 0 then return 0 end
        local seen = {[start] = true}
        local n, head = 1, 1
        cells[1] = start
        while head <= n do
            local a = cells[head]
            head = head + 1
            local na = neighbors[a]
            for d = 0, 5 do
                local b = na[d]
                if b >= 0 and not seen[b] and equal(g, start, b) then
                    seen[b] = true
                    n = n + 1
                    cells[n] = b
                end
            end
        end
        return n
    end

    -- Count a contiguous run through a cell; holes and other colours stop it.
    local function run_length(g, cell, axis)
        local n = 1
        for sign = 0, 1 do
            local d = axis + sign * 3
            local c = hex_neighbor(cell, d)
            while equal(g, cell, c) do
                n = n + 1
                c = hex_neighbor(c, d)
            end
        end
        return n
    end

    local function mark_line(g, m, cell, axis)
        if cell_active(g, cell) then m.mask[cell] = true end
        for sign = 0, 1 do
            local d = axis + (sign == 1 and 3 or 0)
            local c = hex_neighbor(cell, d)
            while c >= 0 do
                if cell_active(g, c) then m.mask[c] = true end
                c = hex_neighbor(c, d)
            end
        end
    end

    local function mark_area(g, m, cell, blast_radius)
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and hex_distance(cell, i) <= blast_radius then m.mask[i] = true end
        end
    end

    local function mark_color(g, m, kind)
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and g.tiles[i].kind == kind then m.mask[i] = true end
        end
    end

    function M.game_matches(g, m, preferred)
        m.mask, m.make, m.hits = {}, {}, 0
        if flags & E.LINE_MATCHES ~= 0 then
            -- Process maximal runs independently: touching branches never count
            -- toward their length or receive an unrelated run's reward.
            for i = 0, CELLS - 1 do
                if cell_active(g, i) and g.tiles[i].kind >= 0 then
                    for axis = 0, 2 do
                        if not equal(g, i, hex_neighbor(i, axis + 3)) then
                            local cells, c = {}, i
                            while equal(g, i, c) do
                                cells[#cells + 1] = c
                                c = hex_neighbor(c, axis)
                            end
                            local n = #cells
                            if n >= MATCH_MIN then
                                local pick = -1
                                for _, a in ipairs(cells) do
                                    m.mask[a] = true
                                    if g.tiles[a].special == NORMAL and not locked(g, a)
                                        and (pick < 0 or a == preferred) then pick = a end
                                end
                                local sp = n >= MATCH_MIN + 2 and PRISM
                                    or n == MATCH_MIN + 1 and ray_for_axis(axis) or NORMAL
                                if flags & E.NO_SPECIALS == 0 and pick >= 0 and sp ~= NORMAL
                                    and (not m.make[pick] or sp > m.make[pick]) then m.make[pick] = sp end
                            end
                        end
                    end
                end
            end
            count_hits(m)
            return
        end
        local seen = {}
        local cells = {}
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and g.tiles[i].kind >= 0 and not seen[i] then
                local n = collect_group(g, i, cells)
                local pick, longest, long_axis = -1, 0, 0
                for k = 1, n do seen[cells[k]] = true end
                if n >= MATCH_MIN then
                    for k = 1, n do
                        local a = cells[k]
                        m.mask[a] = true
                        m.hits = m.hits + 1
                        if g.tiles[a].special == NORMAL and not locked(g, a) and (pick < 0 or a == preferred) then pick = a end
                        for axis = 0, 2 do
                            if not equal(g, a, hex_neighbor(a, axis + 3)) then   -- count each run from its start
                                local run, c = 0, a
                                while c >= 0 and equal(g, a, c) do
                                    run = run + 1
                                    c = hex_neighbor(c, axis)
                                end
                                if run > longest then longest, long_axis = run, axis end
                            end
                        end
                    end
                    -- Larger groups reward combinations beyond the configured minimum.
                    local sp = flags & E.NO_SPECIALS == 0 and (n >= MATCH_MIN + 2 and (longest >= MATCH_MIN + 2 and PRISM or BOMB)
                        or n == MATCH_MIN + 1 and ray_for_axis(long_axis)) or NORMAL
                    if pick >= 0 and sp ~= NORMAL then m.make[pick] = sp end
                end
            end
        end
    end
    local game_matches = M.game_matches

    function M.game_can_swap(g, a, b)
        return cell_active(g, a) and cell_active(g, b) and hex_distance(a, b) == 1 and not locked(g, a) and not locked(g, b)
            and g.tiles[a].kind >= 0 and g.tiles[b].kind >= 0
    end
    local game_can_swap = M.game_can_swap

    -- false (and the board unchanged) if nothing would clear
    function M.game_swap(g, a, b, m)
        if g.won or g.lost or not game_can_swap(g, a, b) then return false end
        swap_tiles(g, a, b)
        m.mask, m.make, m.hits = {}, {}, 0
        local sa, sb = g.tiles[a].special, g.tiles[b].special
        if sa == PRISM or sb == PRISM then
            local p = sa == PRISM and a or b
            local o = p == a and b or a
            if sa == PRISM and sb == PRISM then
                for i = 0, CELLS - 1 do if cell_active(g, i) then m.mask[i] = true end end
            else
                local kind = g.tiles[o].kind
                mark_color(g, m, kind)
                if g.tiles[o].special ~= NORMAL then   -- prism + special: that colour turns special first
                    for i = 0, CELLS - 1 do
                        if g.tiles[i].kind == kind then g.tiles[i].special = g.tiles[o].special end
                    end
                end
            end
            m.mask[p], m.mask[o] = true, true
            g.tiles[p].special = NORMAL
        elseif sa ~= NORMAL and sb ~= NORMAL then
            m.mask[a], m.mask[b] = true, true
            if sa == BOMB and sb == BOMB then
                mark_area(g, m, b, 2)
            elseif sa == BOMB or sb == BOMB then
                for i = 0, CELLS - 1 do
                    if hex_distance(b, i) <= 1 then
                        for z = 0, 2 do mark_line(g, m, i, z) end
                    end
                end
            else
                for z = 0, 2 do mark_line(g, m, b, z) end
            end
        else
            game_matches(g, m, b)
            if not m.mask[a] and not m.mask[b] then
                swap_tiles(g, a, b)
                m.mask, m.make, m.hits = {}, {}, 0
                return false
            end
        end
        if count_hits(m) == 0 then
            swap_tiles(g, a, b)
            return false
        end
        g.moves = g.moves - 1
        g.combo = 0
        return true
    end
    local game_swap = M.game_swap

    -- Clear one wave, fire specials; returns the relics cleared.
    function M.game_apply(g, m)
        local fired, thaw = {}, {}
        local more = true
        while more do   -- specials hit by the wave fire, possibly hitting more specials
            more = false
            for i = 0, CELLS - 1 do
                if cell_active(g, i) and m.mask[i] and not m.make[i] and not fired[i] and g.tiles[i].special ~= NORMAL and not locked(g, i) then
                    fired[i] = true
                    more = true
                    local sp = g.tiles[i].special
                    if sp == ROW or sp == COLUMN or sp == DIAGONAL then mark_line(g, m, i, axis_of_ray(sp))
                    elseif sp == BOMB then mark_area(g, m, i, 1)
                    else mark_color(g, m, g.tiles[i].kind) end
                end
            end
        end
        for i = 0, CELLS - 1 do   -- matched thaw-enabled kinds clear neighboring ice
            if cell_active(g, i) and m.mask[i] and (kind_flags[g.tiles[i].kind] or 0) & E.THAW ~= 0 and flags & E.NO_THAW == 0 and not locked(g, i) then
                for d = 0, 5 do
                    local j = hex_neighbor(i, d)
                    if cell_active(g, j) and g.ice[j] > 0 and not m.mask[j] then thaw[j] = true end
                end
            end
        end
        local cleared = 0
        g.last_gold, g.last_wood, g.last_stone = 0, 0, 0
        g.combo = g.combo + 1
        for i = 0, CELLS - 1 do
            if cell_active(g, i) then
                if thaw[i] then g.ice[i], g.obstacles = g.ice[i] - 1, g.obstacles - 1 end
                if m.mask[i] then
                    if g.ice[i] > 0 then
                        g.ice[i], g.obstacles, g.score = g.ice[i] - 1, g.obstacles - 1, g.score + 20
                    elseif g.chain[i] > 0 then
                        g.chain[i], g.obstacles, g.score = g.chain[i] - 1, g.obstacles - 1, g.score + 20
                    else
                        if g.soil[i] > 0 then g.soil[i], g.dug, g.score = g.soil[i] - 1, g.dug + 1, g.score + 30 end
                        local k = g.tiles[i].kind
                        if k >= 0 then
                            if (kind_flags[k] or 0) & E.GOAL ~= 0 then g.relics, g.last_gold = g.relics + 1, g.last_gold + 1 end
                            if (kind_flags[k] or 0) & E.WOOD ~= 0 then g.wood, g.last_wood = g.wood + 1, g.last_wood + 1 end
                            if (kind_flags[k] or 0) & E.STONE ~= 0 then g.stone, g.last_stone = g.stone + 1, g.last_stone + 1 end
                            g.score = g.score + 50 * g.combo
                            cleared = cleared + 1
                            if m.make[i] then g.tiles[i].special = m.make[i]
                            else g.tiles[i] = tile(-1, NORMAL) end
                        end
                    end
                end
            end
        end
        g.cleared = g.cleared + cleared
        return cleared
    end
    local game_apply = M.game_apply

    -- Gravity follows the three downward hex edges, preferring straight down.
    -- A gem can slide diagonally only when its own cell below is unavailable;
    -- every exposed column top creates new pieces directly from above. Interior
    -- cells still trickle around locks, or spawn when all parents are blocked.
    -- Return original source IDs plus simultaneous one-edge animation steps.
    M.FALL_STEP = .08
    local fall_order = {}
    for i = 0, CELLS - 1 do fall_order[#fall_order + 1] = i end
    table.sort(fall_order, function(a, b)
        local ay, by = 2 * hex_r(a) + hex_q(a), 2 * hex_r(b) + hex_q(b)
        return ay == by and a < b or ay > by
    end)

    function M.game_collapse(g)
        local from, steps, spawned = {}, {}, 0
        for i = 0, CELLS - 1 do from[i] = i end
        local function movable(i) return cell_active(g, i) and not locked(g, i) end
        local function donor(i) return movable(i) and g.tiles[i].kind >= 0 end
        local function side_donor(i)
            if not donor(i) then return false end
            local down = hex_neighbor(i, 1)
            return not movable(down) or g.tiles[down].kind >= 0
        end
        while true do
            local step, used, empty = {tiles = {}, from = {}}, {}, 0
            local next_from = {}
            for i = 0, CELLS - 1 do
                step.tiles[i], step.from[i], next_from[i] = g.tiles[i], i, from[i]
            end
            for _, i in ipairs(fall_order) do
                if movable(i) and g.tiles[i].kind < 0 then
                    empty = empty + 1
                    -- Alternate equal left/right choices spatially, without using RNG.
                    local left, right = -1, -1
                    if flags & E.NO_TRICKLE == 0 then left, right = hex_neighbor(i, 3), hex_neighbor(i, 5) end
                    if (hex_q(i) + hex_r(i)) % 2 == 0 then left, right = right, left end
                    local above, source = hex_neighbor(i, 4), nil
                    local inlet = not cell_active(g, above)
                    if not inlet then
                        if donor(above) and not used[above] then source = above
                        elseif side_donor(left) and not used[left] then source = left
                        elseif side_donor(right) and not used[right] then source = right end
                    end
                    if source then
                        step.tiles[i], step.from[i], next_from[i] = g.tiles[source], source, from[source]
                        step.tiles[source], next_from[source], used[source] = tile(-1), source, true
                    elseif inlet or not movable(left) and not movable(right) and not movable(above) then
                        spawned = spawned + 1
                        step.tiles[i], step.from[i], next_from[i] = tile(randn(g, COLORS)), -1, -spawned
                    end
                end
            end
            if empty == 0 then break end
            steps[#steps + 1] = step
            g.tiles, from = step.tiles, next_from
            assert(#steps <= CELLS * CELLS, "gravity failed to settle")
        end
        return from, steps
    end

    local function copy_array(t)
        local c = {}
        for i = 0, CELLS - 1 do c[i] = t[i] end
        return c
    end

    -- A deep copy of a game, for trying moves out.
    function M.game_copy(g)
        local c = {}
        for k, v in pairs(g) do c[k] = v end
        c.tiles = {}
        for i = 0, CELLS - 1 do c.tiles[i] = tile(g.tiles[i].kind, g.tiles[i].special) end
        c.active, c.soil, c.chain, c.ice = copy_array(g.active), copy_array(g.soil), copy_array(g.chain), copy_array(g.ice)
        c.tools = {g.tools[1], g.tools[2], g.tools[3]}
        return c
    end
    local game_copy = M.game_copy

    -- Any move that clears something: ok, a, b.
    function M.game_hint(g)
        local m = new_match()
        for i = 0, CELLS - 1 do
            for d = 0, 2 do
                local j = hex_neighbor(i, d)
                if game_can_swap(g, i, j) then
                    local copy = game_copy(g)
                    if game_swap(copy, i, j, m) then return true, i, j end
                end
            end
        end
        return false
    end
    local game_hint = M.game_hint

    local function fill_without_matches(g)
        local cells = {}
        for i = 0, CELLS - 1 do
            if not locked(g, i) then g.tiles[i] = tile(-1, NORMAL) end
        end
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and not locked(g, i) then
                local choices, n = {}, 0
                for k = 0, COLORS - 1 do
                    g.tiles[i] = tile(k, NORMAL)
                    local valid = true
                    if flags & E.LINE_MATCHES ~= 0 then
                        for axis = 0, 2 do
                            if run_length(g, i, axis) >= MATCH_MIN then valid = false; break end
                        end
                    else valid = collect_group(g, i, cells) < MATCH_MIN end
                    if valid then n = n + 1; choices[n] = k end
                end
                if n == 0 then return false end
                g.tiles[i] = tile(choices[randn(g, n) + 1], NORMAL)
            end
        end
        return true
    end

    local function generate_board(g)
        -- never erase blockers or fill a hole merely to manufacture a move
        local m = new_match()
        for _ = 1, 2000 do
            if fill_without_matches(g) then
                game_matches(g, m, -1)
                if m.hits == 0 and game_hint(g) then return end
            end
        end
    end

    -- Recovery moves whole pieces, including earned specials. Locked pieces
    -- and terrain stay put; an unsuccessful search restores the original board.
    function M.game_shuffle(g)
        local cells, pieces, original = {}, {}, {}
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and not locked(g, i) then
                cells[#cells + 1], pieces[#pieces + 1] = i, g.tiles[i]
                original[i] = g.tiles[i]
            end
        end
        local m = new_match()
        for _ = 1, 2000 do
            for i = #pieces, 2, -1 do
                local j = randn(g, i) + 1
                pieces[i], pieces[j] = pieces[j], pieces[i]
            end
            for i, cell in ipairs(cells) do g.tiles[cell] = pieces[i] end
            game_matches(g, m, -1)
            if m.hits == 0 and game_hint(g) then return true end
        end
        for cell, piece in pairs(original) do g.tiles[cell] = piece end
        return false
    end
    local game_shuffle = M.game_shuffle

    function M.game_start(lvl, seed)
        lvl = math.max(0, math.min(lvl, LEVELS - 1))
        local g = {
            tiles = {}, active = {}, soil = {}, chain = {}, ice = {},
            level = lvl, moves = 0, score = 0, relics = 0, dug = 0, obstacles = 0, initial_obstacles = 0, initial_soil = 0,
            combo = 0, cleared = 0, last_gold = 0, last_wood = 0, last_stone = 0, wood = 0, stone = 0,
            rng = (seed and seed ~= 0) and (seed & 0xFFFFFFFF) or 12345,
            won = false, lost = false,
            tools = {2, 2, 2},   -- pickaxe, dynamite, sunburst charges
        }
        local l = M.levels[lvl + 1]
        g.moves = l.moves
        local order, n = {}, 0
        for i = 0, CELLS - 1 do
            g.active[i] = not l.mask or l.mask:sub(i + 1, i + 1) == "1"
            g.tiles[i] = tile(-1, NORMAL)
            g.soil[i], g.chain[i], g.ice[i] = 0, 0, 0
            if g.active[i] then n = n + 1; order[n] = i end
        end
        generate_board(g)
        for i = 1, n do   -- selection sort, exactly as the original orders ties
            for j = i + 1, n do
                if l.terrain and l.terrain[order[j] + 1] < l.terrain[order[i] + 1] then order[i], order[j] = order[j], order[i] end
            end
        end
        for i = 1, math.min(l.soil, n) do g.soil[order[i]] = 1 end
        local taken = {}
        for i = 0, math.min(l.chains, n) - 1 do
            local cell = order[(i * 3 + 1) % n + 1]
            g.chain[cell], taken[cell] = 1, true
        end
        local count = 0
        for k = 0, n - 1 do
            if count >= l.ice then break end
            local cell = order[(k + 4) % n + 1]
            if not taken[cell] and hex_distance(cell, hex_center()) <= math.max(1, radius - 1) then
                g.ice[cell] = (l.ice_layers == 2 and count % 3 == 0) and 2 or 1
                taken[cell] = true
                count = count + 1
            end
        end
        for i = 0, CELLS - 1 do g.initial_obstacles = g.initial_obstacles + g.ice[i] + g.chain[i] end
        g.obstacles = g.initial_obstacles
        g.initial_soil = l.soil
        local m = new_match()
        game_matches(g, m, -1)
        if m.hits > 0 or not game_hint(g) then generate_board(g) end
        return g
    end

    function M.game_check_end(g)
        local l = M.levels[g.level + 1]
        g.won = g.score >= l.score and g.relics >= l.relics and g.dug >= l.soil and g.obstacles == 0
        g.lost = not g.won and g.moves <= 0
        if flags & E.NO_RESHUFFLE == 0 and not g.won and not g.lost and not game_hint(g) then
            return game_shuffle(g)   -- discard stale selection/hints only after recovery
        end
        return false
    end

    -- Tools: 0 pickaxe (one cell), 1 dynamite (radius 1), 2 sunburst (three axes).
    function M.game_tool(g, tool, cell, m)
        if flags & E.NO_TOOLS ~= 0 or tool < 0 or tool > 2 or g.tools[tool + 1] <= 0 or g.won or g.lost or not cell_active(g, cell) then return false end
        m.mask, m.make, m.hits = {}, {}, 0
        g.tools[tool + 1] = g.tools[tool + 1] - 1
        g.combo = 0
        if tool == 0 then m.mask[cell] = true
        elseif tool == 1 then mark_area(g, m, cell, 1)
        else for z = 0, 2 do mark_line(g, m, cell, z) end end
        count_hits(m)
        return true
    end

    -- How good a move is for a greedy player: score plus weighted goal progress.
    function M.game_evaluate_move(g, a, b)
        if not game_can_swap(g, a, b) then return -1 end
        local c = game_copy(g)
        local m = new_match()
        if not game_swap(c, a, b, m) then return -1 end
        game_apply(c, m)
        local goal = M.levels[g.level + 1].relics
        local relics = math.min(c.relics, goal) - math.min(g.relics, goal)
        return c.score - g.score + relics * 90 + (c.dug - g.dug) * 200 + (g.obstacles - c.obstacles) * 220
    end


    -- Presentation adapter: callbacks below emit graphics, sound, haptics and notices.
    -- The engine owns selection, gestures, phase timing and all piece poses.
    function M.bind_view(R)
    local function noop() end
    R.tone, R.vfx_wave = R.tone or noop, R.vfx_wave or noop
    R.notice = R.notice or function(message) R.toast, R.toast_time = message, 3.6 end
    R.tool_notes = R.tool_notes or {"Choose a piece to remove.", "Choose the centre of a blast.", "Choose a piece to clear its axes."}
    function R.reset_board(g)
        R.g, R.pending = g, M.new_match()
        R.phase, R.phase_time, R.idle_time, R.shake = 0, 0, 0, 0
        R.swap_a, R.swap_b, R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1, -1, -1
        R.fall_steps, R.fall_from = nil, {}
        R.kudos, R.kudos_level, R.mission_banner = nil, 0, nil
    end
    local rules = M
    local HEX_R, HEX_DY = R.HEX_R, math.sqrt(3) * R.HEX_R

    -- One board-screen layout for every match-3 game. Games paint into its
    -- bands but cannot move them. It is measured up from the bottom edge, at
    -- the size it has on a 480x1040 phone: the tool row, the board above it,
    -- then the HUD band (goals, moves and Pause). The backdrop painting keeps
    -- its 1040-tall scale and stands on the bottom edge too, so its scenery
    -- always ends just above the HUD. A shorter screen only crops the top of
    -- the painting; the board is never squeezed.
    assert(R.layout == nil, "the match3 board layout is engine-owned; games must not define R.layout")
    local REF_H, HUD_FROM_BOTTOM, BOARD_FROM_BOTTOM, TOOLS_FROM_BOTTOM, HUD_H = 1040, 772, 409, 100, 64
    local board_size = size2(((1.5 * M.HEX_RADIUS + 1) * HEX_R + 6) * 2, ((M.HEX_RADIUS + .5) * HEX_DY + 6) * 2)
    local function layout()
        local w, design_h = R.SCREEN_W or 480, R.SCREEN_H or 900
        local h = math.max(design_h, app.screen().h)
        R.drop = h - design_h
        R.hud_rect = rect(0, h - HUD_FROM_BOTTOM, w, HUD_H)
        R.board_pause = rect.centered(vec2(w - 46, R.hud_rect:center().y), size2(64, 64))
        R.board_toast = rect(38, R.hud_rect.y + 68, w - 76, 28)
        R.tools_y = h - TOOLS_FROM_BOTTOM
        R.board_origin = vec2(w / 2, h - BOARD_FROM_BOTTOM)
        R.BOARD_CLIP = rect.centered(R.board_origin, board_size)
    end
    -- Where a backdrop of this pixel size goes in the bleed rect `full`:
    -- at least its 1040-tall scale, covering the screen, on the bottom edge.
    function R.backdrop_rect(size, full)
        local s = math.max(math.max(REF_H, full.h) / size.h, full.w / size.w)
        local sw, sh = size.w * s, size.h * s
        return rect(full.x + (full.w - sw) / 2, full.y + full.h - sh, sw, sh)
    end
    function R.board_tool_bounds(k)
        local x = R.board_origin.x + (k - 1) * 120
        return rect(x - E.TOOL_SIZE / 2, R.tools_y, E.TOOL_SIZE, E.TOOL_SIZE)
    end
    R.layout = layout
    layout()
    local CELL_SIZE = R.piece_width or HEX_DY
    local PI = math.pi
    local PH_IDLE, PH_SWAP, PH_REJECT, PH_CLEAR, PH_FALL = 0, 1, 2, 3, 4
    R.PH_IDLE, R.PH_SWAP, R.PH_REJECT, R.PH_CLEAR, R.PH_FALL = PH_IDLE, PH_SWAP, PH_REJECT, PH_CLEAR, PH_FALL
    function R.cell_pos(i) return R.board_origin + vec2(hex_q(i) * 1.5 * HEX_R, (hex_r(i) + hex_q(i) * .5) * HEX_DY) end
    local cell_pos = R.cell_pos

    -- Screen point to the active cell under it, by rounding cube coordinates.
    function R.cell_at(p)
        local d = p - R.board_origin
        local q = d.x * 2 / (3 * HEX_R)
        local r = -d.x / (3 * HEX_R) + d.y / HEX_DY
        local s = -q - r
        local iq, ir, is = math.floor(q + .5), math.floor(r + .5), math.floor(s + .5)
        local dq, dr, ds = math.abs(iq - q), math.abs(ir - r), math.abs(is - s)
        if dq > dr and dq > ds then iq = -ir - is
        elseif dr > ds then ir = -iq - is end
        local cell = hex_index(iq, ir)
        return cell_active(R.g, cell) and cell or -1
    end

    function R.select_tool(k)
        if R.phase ~= PH_IDLE then return end
        if R.g.tools[k + 1] > 0 and flags & E.NO_TOOLS == 0 then
            R.tool = R.tool == k and -1 or k
            R.selected = -1
            R.notice(R.tool < 0 and "Tool put away." or R.tool_notes[k + 1])
        else R.notice("No charges left. More tools next expedition.") end
    end
    local function tap_cell(at)
        local cell = R.cell_at(at)
        if cell < 0 then
            R.selected, R.tool = -1, -1
            return
        end
        R.idle_time = 0
        R.hint_a, R.hint_b = -1, -1
        if R.tool >= 0 then
            if rules.game_tool(R.g, R.tool, cell, R.pending) then
                R.tool = -1
                R.play("tool")
                R.finish_wave()
            end
            return
        end
        if R.selected == cell then R.selected = -1
        elseif R.selected >= 0 and hex_distance(R.selected, cell) == 1 then R.attempt_swap(R.selected, cell)
        else R.selected = cell; R.play("select") end
    end

    -- A swipe trades with the neighbour best aligned with the gesture.
    local function swipe(from, to)
        local a, b = R.cell_at(from), -1
        local d = to - from
        local best = -1
        if a < 0 then return end
        for k = 0, 5 do
            local n = hex_neighbor(a, k)
            if n >= 0 then
                local alignment = d:norm():dot((cell_pos(n) - cell_pos(a)):norm())
                if alignment > best then best, b = alignment, n end
            end
        end
        if best > .75 then R.attempt_swap(a, b) end
    end

    function R.board_input(inp)
        assert(R.layout == layout, "the match3 board layout is engine-owned; games must not replace R.layout")
        if not inp.released or R.overlay ~= R.OV_NONE then return end
        local d = inp.pos - inp.press_pos
        if R.phase == PH_IDLE and R.cell_at(inp.press_pos) >= 0 and (math.abs(d.x) > 16 or math.abs(d.y) > 16) then swipe(inp.press_pos, inp.pos)
        elseif R.phase == PH_IDLE and R.BOARD_CLIP:contains(inp.pos) then tap_cell(inp.pos) end
    end

    ---------------------------------------------------------------------- rules

    local function snapshot()
        for i = 0, CELLS - 1 do
            local t = R.g.tiles[i]
            R.old_tiles[i] = {kind = t.kind, special = t.special}
            R.wave_ice[i], R.wave_chain[i] = R.g.ice[i], R.g.chain[i]
        end
    end

    local notes = {523.25, 659.25, 783.99, 1046.5, 1318.5}
    -- The board's sound bank on the polyphonic synth: {hz, seconds, delay, volume}.
    local C5, E5, G5, C6, E6, G6 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1567.98
    local sounds = {
        select = {{880, .05, 0, .45}},
        swap = {{392, .07, 0, .6}, {587.33, .09, .045, .6}},
        reject = {{311.13, .09, 0, .75}, {233.08, .15, .08, .75}},
        special = {{E5, .1, 0, .7}, {G5, .1, .05, .7}, {C6, .12, .1, .7}, {E6, .22, .15, .6}},
        blast = {{98, .3, 0, 1.4}, {196, .22, .01, .9}, {G6, .12, .04, .35}, {C6, .18, .07, .35}},
        tool = {{C5, .07, 0, .6}, {G5, .1, .05, .6}},
        mission = {{C5, .5, 0, .35}, {E5, .5, .04, .35}, {G5, .55, .08, .35}},
        win = {{C5, .14, 0, .8}, {E5, .14, .12, .8}, {G5, .14, .24, .8}, {C6, .5, .36, .9}, {E6, .5, .36, .45}, {G5, .5, .36, .45}},
        lose = {{G5, .2, 0, .7}, {E5, .2, .18, .7}, {C5, .2, .36, .7}, {261.63, .5, .54, .8}},
    }
    function R.play(name, level)
        if R.sound == false or not sfx.enabled() then return end
        local bank = sounds[name]
        if name == "match" then   -- climbs a major scale with each cascade
            local hz = notes[num.clampi((level or 1) - 1, 0, 4) + 1]
            bank = {{hz, .16, 0, .9}, {hz * 1.5, .12, .03, .4}}
        elseif name == "kudos" then   -- a rising arpeggio, longer and brighter for bigger praise
            bank = {}
            local scale = {C5, E5, G5, C6, E6, G6}
            for k = 1, 3 + (level or 1) do
                local hz = scale[(k - 1) % #scale + 1] * (k > #scale and 2 or 1)
                bank[#bank + 1] = {hz, .18, (k - 1) * .055, .75}
            end
            bank[#bank + 1] = {scale[math.min(#scale, 2 + (level or 1))], .6, (2 + (level or 1)) * .055, .6}
        end
        for _, n in ipairs(bank or {}) do sfx.note(n[1], n[2], n[3], n[4]) end
    end

    -- Praise for long cascades and special combos. Games may replace the words.
    R.kudos_words = R.kudos_words or {"Nice!", "Great!", "Amazing!", "Spectacular!"}
    local function kudos(level)
        level = math.min(level, #R.kudos_words)
        R.kudos = {text = R.kudos_words[level], level = level, t = 0}
        R.play("kudos", level)
        haptic.play(haptic.COMBO, 1)
    end
    R.award_kudos = kudos

    function R.finish_wave()
        snapshot()
        local old_score = R.g.score
        rules.game_apply(R.g, R.pending)
        R.phase = PH_CLEAR
        R.phase_time = 0
        R.shake = R.reduced_motion and 0 or R.g.combo > 1 and .13 or .06
        local fx_combo = R.fx_combo or 0   -- vfx_wave consumes the combo swap's effect
        R.vfx_wave(old_score)
        local special, made = false, false
        for i = 0, CELLS - 1 do
            if R.pending.mask[i] and R.old_tiles[i].special ~= NORMAL then special = true end
            if R.pending.make[i] then made = true end
        end
        R.play(special and "blast" or made and "special" or "match", R.g.combo)
        -- Cascades earn praise from the third wave, a special combo swap at once;
        -- the word waits until the whole cascade has settled (see settle).
        local praise = R.g.combo >= 3 and R.g.combo - 2 or 0
        if fx_combo > 0 and R.g.combo == 1 then praise = math.max(praise, fx_combo == 3 and 3 or 2) end
        R.kudos_level = math.max(R.kudos_level or 0, praise)
        haptic.play((R.g.combo > 1 or special) and haptic.COMBO or haptic.MATCH,
            math.min(1, .6 + .1 * R.g.combo))
    end

    function R.attempt_swap(a, b)
        if R.phase ~= PH_IDLE or R.overlay ~= R.OV_NONE or R.on_island then return end
        R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
        R.idle_time = 0
        R.swap_a, R.swap_b = a, b
        snapshot()
        if rules.game_swap(R.g, a, b, R.pending) then
            local sa, sb = R.old_tiles[a].special, R.old_tiles[b].special
            R.fx_origin = sa == PRISM and b or sb == PRISM and a or b
            R.fx_combo = (sa == PRISM or sb == PRISM) and 3 or (sa ~= NORMAL and sb ~= NORMAL) and ((sa == BOMB or sb == BOMB) and 2 or 1) or 0
            R.phase = PH_SWAP
            R.phase_time = 0
            R.play("swap")
        elseif rules.game_can_swap(R.g, a, b) then
            R.phase = PH_REJECT
            R.phase_time = 0
            R.play("reject")
            haptic.play(haptic.ERROR, .5)
        else
            R.notice(R.locked_notice or "Ice and chains must be broken first.")
        end
    end

    local function settle()
        rules.game_matches(R.g, R.pending, -1)
        if R.pending.hits > 0 then
            R.finish_wave()
            return
        end
        R.phase = PH_IDLE
        if (R.kudos_level or 0) > 0 then kudos(R.kudos_level); R.kudos_level = 0 end   -- the move has resolved
        if rules.game_check_end(R.g) then
            R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
            R.notice("No moves. Board reshuffled.")
        end
        if R.g.won then R.overlay = R.OV_RESULT; R.play("win"); haptic.play(haptic.SUCCESS)
        elseif R.g.lost then R.overlay = R.OV_FAILED; R.play("lose"); haptic.play(haptic.ERROR) end
        R.idle_time = 0
    end

    function R.board_update(dt)
        if R.art_review then return end
        R.shake = math.max(0, R.shake - dt)
        if R.overlay ~= R.OV_NONE or R.on_island then return end
        R.idle_time = R.idle_time + dt
        if R.phase == PH_IDLE and not R.g.won and not R.g.lost then   -- ready groups resolve before any input
            rules.game_matches(R.g, R.pending, -1)
            if R.pending.hits > 0 then
                R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
                R.finish_wave()
            end
        end
        if flags & E.NO_HINTS == 0 and R.idle_time > 5 and R.hint_a < 0 and R.phase == PH_IDLE and not R.g.won and not R.g.lost then
            local ok, a, b = rules.game_hint(R.g)
            if ok then R.hint_a, R.hint_b = a, b
            else settle() end   -- idle/resumed dead boards need the same recovery as a completed fall
        end
        if R.phase == PH_IDLE then return end
        R.phase_time = R.phase_time + dt
        local speed = R.reduced_motion and .35 or 1
        if R.phase == PH_SWAP and R.phase_time > .17 * speed then R.finish_wave()
        elseif R.phase == PH_REJECT and R.phase_time > .32 * speed then R.phase = PH_IDLE
        elseif R.phase == PH_CLEAR and R.phase_time > .24 * speed then
            R.fall_from, R.fall_steps = rules.game_collapse(R.g)
            R.phase = PH_FALL
            R.phase_time = 0
            R.fall_landed = 0
        elseif R.phase == PH_FALL then
            -- One tick per completed simultaneous step, never per tile or draw.
            -- A slow frame coalesces skipped steps into one current landing.
            local landed = math.min(R.fall_steps and #R.fall_steps or 0,
                math.floor(R.phase_time / (rules.FALL_STEP * speed)))
            if landed > (R.fall_landed or 0) then
                R.fall_landed = landed
                haptic.play(haptic.TICK, .35)
            end
            if R.phase_time > ((R.fall_steps and #R.fall_steps * rules.FALL_STEP or .27) + .08) * speed then settle() end
        end
    end

    function R.piece_pose(i, sx)
    local g = R.g
    local at = cell_pos(i) + vec2(sx, 0)
    local scale, alpha, aspect = 1, 255, 1
    local t = g.tiles[i]
    local clip = nil
    if R.phase == PH_SWAP or R.phase == PH_REJECT then
        t = R.old_tiles[i]
        if i == R.swap_a or i == R.swap_b then
            local other = i == R.swap_a and R.swap_b or R.swap_a
            local f = R.phase_time / (R.phase == PH_SWAP and .17 or .16)
            if R.phase == PH_REJECT and f > 1 then f = 2 - f end
            at = at:lerp(cell_pos(other) + vec2(sx, 0), ease.out_cubic(f))
        end
    elseif R.phase == PH_CLEAR and R.pending.mask[i] then
        t = R.old_tiles[i]
        if R.wave_chain[i] == 0 and R.wave_ice[i] == 0 and not R.pending.make[i] then   -- a small pop, then shrink away
            local f = num.saturate(R.phase_time / .24)
            scale = f < .22 and 1 + .18 * math.sin(f / .22 * PI) or 1 - .92 * ease.out_cubic((f - .22) / .78)
            alpha = 255 * (1 - f * f)
        end
    elseif R.phase == PH_FALL then
        local steps = R.fall_steps or {}
        local elapsed = R.phase_time / (R.reduced_motion and .35 or 1)
        local step_index = math.floor(elapsed / rules.FALL_STEP) + 1
        local step = steps[step_index]
        if step then
            t = step.tiles[i]
            local from = step.from[i]
            local f = num.saturate(elapsed / rules.FALL_STEP - (step_index - 1))
            local source = from >= 0 and cell_pos(from) or cell_pos(i) - vec2(0, HEX_DY)
            at = (source + vec2(sx, 0)):lerp(at, f)
            if from < 0 then
                -- Clip only the inlet; sideways moves need the whole board.
                local top = cell_pos(i).y - HEX_DY / 2
                clip = rect(at.x - CELL_SIZE / 2 - 1, top, CELL_SIZE + 2, R.BOARD_CLIP.h)
            end
        elseif not R.reduced_motion and #steps > 0 then
            local f = num.saturate((elapsed - #steps * rules.FALL_STEP) / .08)
            aspect = 1 + .08 * math.sin(f * PI)
        end
    end
    return t, at, scale, alpha, aspect, clip
    end
    end

    return M
end
return E
