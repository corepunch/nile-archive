-- Reusable deterministic hex match-3 engine. Game configuration is data and
-- integer behavior flags; graphics never implement matching, gravity or input.
local E = {
    NO_TRICKLE=1, NO_TOOLS=4, NO_HINTS=8, NO_RESHUFFLE=16, LINE_MATCHES=64, COLOR_TOOL=256,
    GOAL=1, WOOD=4, STONE=8, -- per-kind behavior bits
}

-- Engine-owned interaction state; a game adds only its screen/presentation data.
function E.view(state)
    state = state or {}
    state.SCREEN_W, state.SCREEN_H = state.SCREEN_W or 480, state.SCREEN_H or 900
    state.HEX_R, state.drop = state.HEX_R or 32, 0
    state.PH_IDLE, state.PH_SWAP, state.PH_REJECT, state.PH_CLEAR, state.PH_FALL = 0, 1, 2, 3, 4
    state.old_tiles, state.fall_from, state.wave_ice, state.wave_chain, state.wave_oil = {}, {}, {}, {}, {}
    state.phase, state.phase_time, state.idle_time, state.shake = 0, 0, 0, 0
    state.selected, state.swap_a, state.swap_b, state.tool, state.hint_a, state.hint_b = -1, -1, -1, -1, -1, -1
    return state
end

-- The two match-3 cities share the same view templates. Game code supplies
-- localized copy, skin colors, and records with stable keys via set_items.
E.CATALOGUE_COLUMNS = 3

function E.catalogue_form(title, hint, close, detail_color, paint_tile)
    -- A record is one row, {id, cells={building records}}. Each tile is its
    -- painted icon under a flat button.
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
            for j = 1, E.CATALOGUE_COLUMNS do
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

-- Every named image borrows the atlas's GPU texture.
local atlases = {}
function E.atlas(definition)
    local key = definition or "default"
    if atlases[key] then return atlases[key] end
    local atlas = definition and texture.load(definition.path) or texture.match3_default()
    assert(atlas.tex, "cannot load match3 atlas")
    local frames = definition and definition.frames or require("match3.frames")
    local images = {atlas=atlas}
    for name, box in pairs(frames) do
        local image = texture.region(atlas, rect(box[1], box[2], box[3], box[4]))
        assert(image.tex, "invalid match3 frame: " .. name)
        images[name] = image
    end
    atlases[key] = images
    return images
end

function E.skin(override)
    local skin = E.atlas(override)
    for _, name in ipairs({"kind-0", "kind-1", "kind-2", "kind-3", "kind-4", "kind-5", "ray-row", "ray-column", "ray-diagonal",
        "bomb", "prism", "chain", "ice-1", "ice-2", "selected", "hint", "guide", "cell-mask", "background", "glow"}) do
        assert(skin[name], "missing match3 frame: " .. name)
    end
    return skin
end

function E.hud(override)
    local hud = E.atlas(override)
    assert(hud.score and hud.complete, "missing match3 HUD icons")
    for _, tool in ipairs({"pickaxe", "dynamite", "sunburst", "pause"}) do
        for _, state in ipairs({"normal", "selected", "pressed", "hover", "disabled"}) do
            assert(hud[tool .. "-" .. state], "missing authored match3 control state")
        end
    end
    return hud
end

-- Both campaign skins use the same generated action atlas.
local action_atlas = {path="campaign-buttons.png", frames={}}
local action_states = {"normal", "selected", "pressed", "hover", "disabled"}
for col, name in ipairs{"build", "play", "levels", "pause"} do
    for row, state in ipairs(action_states) do
        action_atlas.frames["action-" .. name .. "-" .. state] = {(col - 1) * 128, row * 128, 128, 128}
    end
end

function E.navigation_button(name)
    local spec = {}
    for _, state in ipairs(action_states) do
        spec[state] = {offset={0, 0}, layers={{image="action-" .. name .. "-" .. state, fit="contain"}}}
    end
    return spec
end

function E.load_action_buttons(skin, hud)
    local art = E.atlas(action_atlas)
    for key in pairs(action_atlas.frames) do skin.images[key], hud[key] = art[key], art[key] end
end

E.TOOL_SIZE = 76
local GOAL_W, GOAL_GAP = 70, 16

function E.tool_state(charges, selected, inside, down, started_inside, hover, idle)
    if charges <= 0 or not idle then return "disabled" end
    if inside and down and started_inside then return "pressed" end
    if selected then return "selected" end
    if inside and hover then return "hover" end
    return "normal"
end

function E.pause_button(R, bounds, prefix)
    local st = ui.hit(bounds, 0)
    local state = st.held and "pressed" or st.hot and "hover" or "normal"
    gfx.image(R.hud_art[(prefix or "pause-") .. state], bounds, color.WHITE)
    return st.clicked
end

local goal_icon_adjustments = {
    chain = {scale = 1.12, x = 2},
    ["stone-1"] = {scale = .9},
}

function E.bind_board_ui(R, rules, tool_art, icon_adjustments)
    local rgba, PI = color, math.pi
    local PAL_GOLD, PAL_CREAM, PAL_WHITE = R.PAL_GOLD, R.PAL_CREAM, R.PAL_WHITE
    function R.goal_entries()
        local g, l = R.g, rules.level_of(R.g)
        if g.hs then
            local icons={CELL_JELLY="goal-carpet",CELL_OIL="goal-oil",BOX="goal-box",TRASH="goal-trash",ICE="ice-1",LOCK="goal-lock",CARRY="goal-carry",COLLECT_PIGGY="goal-piggy",TARGET_GENERATOR="goal-target-generator",TRASHSTONE="hazelnut-3",STATUE="statue-1",BUBBLE_MEMBRANE="membrane-fill-2",SHUTTERS="blind-body"}
            local entries={}
            for n,goal in ipairs(g.hs.goals) do entries[#entries+1]={id="source-"..n,
                kind=goal.type=='CHIPS' and goal.subtype or nil, icon=icons[goal.type],
                remaining=math.max(0,goal.max-goal.current)} end
            return entries
        end
        local entries = {{id="score",icon="score",remaining=math.max(0,l.score-g.score)},
            {id="idols",icon=not g.goal_kind and "idols" or nil,kind=g.goal_kind,
                remaining=math.max(0,l.relics-g.relics)}}
        if g.delivery_total>0 then
            local icon = l.deliveries and l.deliveries.icon or "delivery"
            entries[#entries+1]={id="deliveries",icon=icon,remaining=g.delivery_total-g.delivered}
        end
        if g.initial_obstacles>0 then
            local stone_only = (l.chains or 0)==0 and (l.ice or 0)==0 and l.stones and #l.stones>0
            local icon = (R.board_goal_icon and R.board_goal_icon(l, "locks"))
                or (stone_only and "stone-1" or "chain")
            entries[#entries+1]={id="locks",icon=icon,remaining=math.max(0,g.obstacles)}
        end
        if (g.carpet_total or 0)>0 then
            local icon = R.board_goal_icon and R.board_goal_icon(l, "carpet")
            entries[#entries+1]={id="carpet",icon=icon or "goal-carpet",remaining=g.carpet_total-g.carpeted}
        end
        if g.oil_left>0 or l.oil and #l.oil>0 then
            -- A buried find (reveal.object) is its own goal icon.
            local find = l.reveal and l.reveal.object and l.reveal.icon
            local floor = R.board_goal_icon and R.board_goal_icon(l, "oil")
            entries[#entries+1]={id="oil",icon=find or floor or "goal-oil",remaining=g.oil_left}
        end
        if l.goals then   -- a level that names its goals shows only those, in its order
            local by_id = {}
            for _, entry in ipairs(entries) do by_id[entry.id] = entry end
            entries = {}
            for _, id in ipairs(l.goals) do entries[#entries+1] = assert(by_id[id], "level goal not on the board: " .. id) end
        end
        return entries
    end
    local goal_centers = {}
    local function goal_panel(box, entry)
        local role = R.hud_art.signboard and "signboard_goal" or "goal"
        local adjustment = icon_adjustments and icon_adjustments[entry.icon] or goal_icon_adjustments[entry.icon]
        local offset = adjustment and adjustment.x and vec2(adjustment.x, 0)
        local center = R.skin:resource_icon_box(box, role):center()
        goal_centers[entry.id] = offset and center + offset or center
        if entry.kind then goal_centers["chip-" .. entry.kind] = goal_centers[entry.id] end
        local icon = entry.icon=="score" and R.hud_art.score
            or entry.icon=="idols" and R.relics[rules.RELIC_IDOL+1]
            or entry.kind and ((R.board_piece_texture and R.board_piece_texture(entry.kind)) or R.relics[entry.kind+1])
            or R.board_art[entry.icon]
        -- Collections landing on a goal make it bounce.
        local pulse = entry.id=="idols" and R.goal_pulse or entry.id=="score" and R.score_pulse or 0
        local met = entry.remaining==0
        R.skin:draw_resource(box, icon, tostring(entry.remaining), {role=role, interactive=false,
            icon_scale=(adjustment and adjustment.scale or 1) * (1 + math.sin(num.saturate(pulse / .22) * PI) * .16),
            icon_offset=offset,
            done=met})
        if entry.label then R.say_at(entry.label,goal_centers[entry.id],9,R.PAL_WHITE,45) end
    end
    local function goal_form()
        return ui.form{kind="row",gap=6,align="center",children={
            {kind="spacer",grow=1},
            {kind="list",id="goals",direction="row",gap=GOAL_GAP,item=function(entry)
                return {kind="custom",width=GOAL_W,height=30,paint=function(box) goal_panel(box,entry) end}
            end},
            {kind="spacer",grow=1},
        }}
    end
    local hud_form, hud_second = goal_form(), goal_form()

    -- Hexagonal medallion, echoing the board cells: gold rim, jade face, the
    -- remaining moves large inside. It warms to red over the last five moves.
    function R.draw_moves(c, arrive, radius)
        radius = radius or 40
        local scale = radius / 40
        local r, a = radius * arrive, (arrive - 1) * PI / 3   -- flat-top, like the cells
        local moves = R.g.moves
        local urgent = moves <= 5 and not R.g.won
        if urgent and not R.reduced_motion then
            gfx.additive(true)
            gfx.glow(c, r + 14 * scale, rgba(255, 92, 40, 70 + 50 * math.sin(R.now * 6)), rgba(255, 92, 40, 0))
            gfx.additive(false)
        end
        gfx.ngon(c + vec2(0, 5 * scale), r, 6, a, rgba(3, 20, 18, 150))
        gfx.ngon(c, r, 6, a, rgba(116, 74, 33))
        gfx.ngon(c, r - 2 * scale, 6, a, rgba(236, 196, 112))
        gfx.ngon(c + vec2(0, 2 * scale), r - 5 * scale, 6, a, rgba(176, 120, 48))
        local face = R.skin:color(urgent and "moves_low" or "moves_face")
        local glow = R.skin:color(urgent and "moves_low_glow" or "moves_glow")
        gfx.ngon(c, r - 7 * scale, 6, a, face)
        gfx.glow(c + vec2(0, -4 * scale), r - 12 * scale, glow, color.alpha(face, 0))
        if arrive < .8 then return end   -- the numbers come with the settled medallion
        text.inside(R.pal(PAL_CREAM, 9), rect.centered(c + vec2(0, -17 * arrive * scale), size2(56, 12)), vec2(.5, .5), "MOVES")
        local s = R.pal(urgent and PAL_WHITE or PAL_GOLD, 29 * arrive * scale)
        text.inside(s, rect.centered(c + vec2(0, 5 * arrive * scale), size2(62, 34)), vec2(.5, .5), tostring(moves))
    end

    function R.goal_target(kind)
        -- Collection flights land on the goal they advance.
        return goal_centers["chip-" .. kind] or goal_centers[rules.is_goal_kind(R.g, kind) and "idols" or "score"]
            or R.hud_rect:center()
    end
    function R.draw_board_hud()
        local top = R.intro and R.intro:arrive(0, 2.8, .58) or 1
        if top <= 0 then return end
        local offset = vec2(0, (top - 1) * (R.hud_rect.y + 110))
        local centre = R.hud_rect:center() + offset
        local signboard = R.hud_art.signboard
        local entries, first, second = R.goal_entries(), {}, {}
        goal_centers = {}
        local moves_x = signboard and 65 or 56
        local goals_left, goals_right = moves_x + 46, R.board_pause.x - 8
        local room = goals_right - goals_left
        local columns = math.max(1, math.floor((room - 12) / GOAL_W))
        for i, entry in ipairs(entries) do
            local row = #entries > columns and i > math.ceil(#entries / 2) and second or first
            row[#row + 1] = entry
        end
        local two_rows = #second > 0
        if signboard then
            local width = R.hud_rect.w - 20
            local height = width * signboard.h / signboard.w + (two_rows and 30 or 0)
            gfx.image(signboard, rect.centered(centre, size2(width, height)), color.WHITE)
        end
        local goal_position = vec2((goals_left + goals_right) / 2, centre.y)
        for form, row in pairs{[hud_form]=first, [hud_second]=second} do
            if #row > 0 then
                local gap = #row > 1 and num.clamp((room - #row * GOAL_W - 12) / (#row - 1), 0, GOAL_GAP) or GOAL_GAP
                if form.nodes.goals.gap ~= gap then form.nodes.goals.gap = gap; form:invalidate_layout() end
                assert(form:set_items("goals", row))
                local dy = two_rows and (form == hud_form and -15 or 15) or 0
                form:draw(rect.centered(goal_position + vec2(0,dy), size2(room,30)), R.skin, {interactive=false})
            end
        end
        local medallion = R.intro and R.intro:arrive(.16, 3, .42) or 1
        if medallion > .05 then R.draw_moves(vec2(moves_x, centre.y), medallion) end
        if R.draw_earnings then R.draw_earnings(centre) end
        local pause_art = signboard and R.hud_art["board-pause-normal"] and "board-pause-"
        if not R.g.tool_slots and E.pause_button(R, R.board_pause:offset(offset), pause_art) then
            R.overlay = R.OV_PAUSE
        end
    end

    -- The level's mission arrives across the middle of the screen, holds,
    -- then slides away, once any dialogue has finished. A tap sends it on.
    function R.mission(text, title)
        R.mission_banner = {text = text, title = title, t = 0}
    end
    local MISSION_IN, MISSION_HOLD, MISSION_OUT = .3, 1.4, .3   -- two seconds, then it goes on its own
    local function draw_mission(dt)
        local m = R.mission_banner
        if not m or R.overlay ~= R.OV_NONE or story.active() or (R.diving and R.diving()) then return end
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
        local slots = R.g.tool_slots
        for i, entry in ipairs(slots or tool_art) do
            local icon = slots and entry.icon or entry
            local k = i - 1
            local meter = R.g.tool_meter and R.g.tool_meter[i]
            if not slots and R.g.tool_meter and not meter then goto next_tool end
            local r = R.board_tool_bounds(k)
            local x, y = r:center().x, r.y
            local charges = R.g.tools[i]
            if meter then
                local points = R.bonus_display_charge(i)
                charges = points // R.g.tool_threshold
                meter = points % R.g.tool_threshold
            end
            local state = E.tool_state(charges, R.tool == k, r:contains(inp.pos), inp.down,
                                       inp.press_pos ~= nil and r:contains(inp.press_pos), inp.hover,
                                       R.phase == R.PH_IDLE or R.phase == R.PH_PRESENT)
            -- The tools spring up from the bottom edge one by one; they take taps at rest.
            local rise = R.intro and R.intro:arrive(.14 + (slots and 0 or k * .07), 3, .48) or 1
            local up = vec2(0, (1 - rise) * 120)
            local drawn = r:offset(up)
            if slots then
                if charges > 0 then
                    gfx.image(R.hud_art[icon .. "-" .. (state == "disabled" and "normal" or state)], drawn, color.WHITE)
                else
                    gfx.image(R.hud_art[icon .. "-disabled"], drawn, color.WHITE)
                    if meter and meter > 0 then
                        -- The charged painting rises inside the empty socket.
                        local fill = drawn.h * meter / R.g.tool_threshold
                        gfx.clip(rect(drawn.x, drawn.y + drawn.h - fill, drawn.w, fill))
                        gfx.image(R.hud_art[icon .. "-normal"], drawn, color.WHITE)
                        gfx.unclip()
                    end
                end
                if entry.rank == 2 then
                    local rank = rect(drawn:max().x - 25, drawn.y + 8, 17, 16)
                    gfx.round_rect(rank, 4, rgba(59, 41, 23, 242))
                    R.say("II", rank, 11, PAL_CREAM)
                elseif charges > 1 then
                    local at = vec2(drawn.x + drawn.w * .78, drawn.y + drawn.h * .22)
                    gfx.circle(at, 10, rgba(116, 74, 33))
                    gfx.circle(at, 8, rgba(46, 112, 70))
                    R.say(tostring(charges), rect.centered(at, size2(20, 20)), 12, PAL_CREAM)
                end
            else
                gfx.shadow(drawn:offset(vec2(0, 4)), 20, 10, rgba(0, 0, 0, 90))
                gfx.image(R.hud_art[icon .. "-" .. state], drawn:inflate(5), color.WHITE)
                gfx.circle(vec2(x + 31, y + 4) + up, 14, rgba(116, 74, 33))
                gfx.circle(vec2(x + 31, y + 4) + up, 12, charges > 0 and rgba(46, 112, 70) or rgba(75, 94, 80))
                R.say(tostring(charges), rect(x + 18, y - 9, 26, 26):offset(up), 16, PAL_CREAM)
                if meter then
                    R.say(("%d/%d"):format(meter, R.g.tool_threshold),
                        rect(x - 37, drawn.y + drawn.h + 2, 74, 16), 12, PAL_CREAM)
                end
            end
            if ui.hit(r, 0).clicked and R.phase == R.PH_IDLE and charges == R.g.tools[i] then R.select_tool(k) end
            ::next_tool::
        end
        if slots then
            local rise = R.intro and R.intro:arrive(.14, 3, .48) or 1
            local button = R.board_pause:offset(vec2(0, (1 - rise) * 120))
            if E.pause_button(R, button, "action-pause-") then R.overlay = R.OV_PAUSE end
        end
    end
end

local BOARD_HEADER = {
    role="wallet", align="center", interactive=false, x=12, y=-2, height=32, band_height=72,
    gap=18, overhang=16, width=90, leading_width=66,
}

function E.bind_town_board_hud(R)
    local goal_hud, goal_target, mission = R.draw_board_hud, R.goal_target, R.mission
    local neutral = app.arg("default-match3")

    function R.draw_board_hud()
        if neutral or R.g.hs then return goal_hud() end
        local box = R.town:header(R.header_capsules(true), BOARD_HEADER)
        local arrive = R.intro and R.intro:arrive(.16, 3, .42) or 1
        if arrive > .05 then R.draw_moves(box:center(), arrive, box.w * .5) end
    end

    function R.goal_target(kind)
        if neutral or R.g.hs then return goal_target(kind) end
    end

    if not neutral and R.currency_capsules then
        function R.resource_target(kind)
            local piece = R.g.resource_yields and R.g.resource_yields[kind]
            local targets = R.town.resource_targets
            return piece and targets and targets[piece.slot]
        end
    end

    function R.mission(...)
        if app.arg("mission") or R.g.hs then mission(...) end
    end
end

-- The results and Item recovered cards are vertical stacks: groups sit one
-- equal gap apart, so no part can crowd the next. The game paints into the
-- boxes; the header tab rides 26 above the card's top edge.
local function slot(id, height, side)
    return {kind="column", padding={side, 0, side, 0}, children={{kind="custom", id=id, height=height}}}
end
local function group(gap, children) return {kind="column", gap=gap, children=children} end
local card_layouts = {}
local function card_layout(name, screen_w, screen_h, gap, children)
    local w = math.min(408, screen_w - 48)
    local key = ("%s:%g:%g"):format(name, w, screen_h)
    local cached = card_layouts[key]
    if cached then return cached end
    local function build(g) return ui.form{kind="column", padding={0, 0, 0, 24}, gap=g, children=children} end
    local form = build(gap)
    local _, h = form:measure(w)
    local spare = screen_h - 80 - h   -- short screens close the gaps up, never the parts
    if spare < 0 then
        local count = #children - 1
        gap = math.max(6, gap + spare / count)
        form = build(gap)
        _, h = form:measure(w)
    end
    local x, y = (screen_w - w) / 2, (screen_h - h) / 2 + 8
    local boxes = form:layout(rect(x, y, w, h))
    local out = {card = rect(x, y + 26, w, h - 26)}
    for id, box in pairs(boxes) do out[id] = box end
    card_layouts[key] = out
    return out
end

function E.result_rects(screen_w, screen_h)
    return card_layout("result", screen_w, screen_h, 16, {
        slot("header", 74, 22),
        slot("stars", 64, 70),
        group(0, {slot("score_label", 18, 66), slot("score", 53, 60)}),
        group(4, {slot("treasure_label", 18, 30), slot("rewards", 91, 22), slot("bonus", 16, 22)}),
        slot("progress", 36, 44),
        slot("next", 65, 28),
        slot("claim", 56, 40),
    })
end

function E.award_rects(screen_w, screen_h)
    return card_layout("award", screen_w, screen_h, 20, {
        slot("header", 74, 22),
        slot("image", 210, 20),
        group(2, {slot("name", 42, 20), slot("subtitle", 18, 20)}),
        slot("claim", 56, 40),
    })
end

function E.guide_form(copy, guide_icon)
    return ui.form{kind="column",panel=true,padding=20,children={
        {kind="label",text=copy.title,height=44,em=34},
        {kind="label",text=copy.instructions,height=26,em=13,text_style="white"},
        {kind="spacer",height=14},
        {kind="list",id="topics",scroll=true,height=520,gap=6,item=function(entry)
            local align=entry.icon and "start" or "center"
            return {kind="row",gap=10,align="center",children={
                {kind="custom",width=52,height=52,visible=entry.icon~=nil,paint=function(r) guide_icon(r,entry.icon) end},
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
    local flags, kind_flags = config.flags or E.LINE_MATCHES, config.kind_flags or {}
    assert(math.type(flags) == "integer" and flags >= 0 and flags < 512, "invalid match3 flags")
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
    M.levels = config.levels or {{name="Resources", lesson="Connect matching resources.", moves=30, score=1000, relics=0, chains=0, ice=0}}
    M.LEVELS, M.level_shapes = #M.levels, config.level_shapes or {}
    assert(M.LEVELS > 0, "match3 needs a level")
    local LEVELS, COLORS, MATCH_MIN = M.LEVELS, M.COLORS, M.MATCH_MIN
    M.DELIVERY = -2
    local shapes = require("match3.shapes")
    function M.level_of(g) return M.levels[g.level + 1] end
    function M.is_goal_kind(g, kind)
        if g.goal_kind ~= nil then return kind == g.goal_kind end
        return (kind_flags[kind] or 0) & E.GOAL ~= 0
    end
    local default_kinds = {}
    for kind = 0, COLORS - 1 do default_kinds[#default_kinds + 1] = kind end
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
    local function spawn_kind(g)
        local kinds = g.spawn_kinds or default_kinds
        return kinds[randn(g, #kinds) + 1]
    end
    local home = require("match3.homescapes").bind(M,randn)

    -- Matches only clear. As in Cradle of Rome, power is earned through tools,
    -- never made by a longer line, so a piece is just its kind.
    local function tile(kind) return {kind = kind} end
    M.tile = tile

    local function swap_tiles(g, a, b) g.tiles[a], g.tiles[b] = g.tiles[b], g.tiles[a] end
    local function solid(g, i) return home.solid(g,i) or (g.stone_hp[i] or 0) > 0 end
    local function locked(g, i) return (g.chain[i] or 0) > 0 or (g.ice[i] or 0) > 0 or solid(g, i) end

    local function cell_active(g, cell) return cell >= 0 and cell < CELLS and g.active[cell] end
    M.game_cell_active = cell_active

    local function equal(g, a, b)
        return cell_active(g, a) and cell_active(g, b) and not solid(g,a) and not solid(g,b)
            and not g.tiles[a].element and not g.tiles[b].element
            and g.tiles[a].kind >= 0 and g.tiles[a].kind == g.tiles[b].kind
    end

    -- An empty match: which cells clear (mask), which a match cleared
    -- (ordinary) and which a tool hit directly (direct).
    local function new_match() return {mask = {}, direct = {}, ordinary = {}, spread = {}, hits = 0} end
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
        if cell_active(g, cell) then m.mask[cell], m.direct[cell] = true, true end
        for sign = 0, 1 do
            local d = axis + (sign == 1 and 3 or 0)
            local c = hex_neighbor(cell, d)
            while c >= 0 do
                if cell_active(g, c) then m.mask[c], m.direct[c] = true, true end
                if g.tiles[c].element == "cookie" then break end
                c = hex_neighbor(c, d)
            end
        end
    end

    local function mark_area(g, m, cell, blast_radius)
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and hex_distance(cell, i) <= blast_radius then m.mask[i], m.direct[i] = true, true end
        end
    end

    local function mark_color(g, m, kind)
        for i = 0, CELLS - 1 do
            if equal(g,i,i) and g.tiles[i].kind == kind then m.mask[i], m.direct[i] = true, true end
        end
    end

    local function reset_match(m)
        m.mask, m.direct, m.ordinary, m.spread, m.hits = {}, {}, {}, {}, 0
        m.match_lengths, m.pierce_kind = nil, nil
    end

    function M.game_matches(g, m)
        reset_match(m)
        m.match_lengths = g.resource_multipliers and {}
        if flags & E.LINE_MATCHES ~= 0 then
            shapes.matches(M, g, m, MATCH_MIN, equal)
            return
        end
        local seen = {}
        local cells = {}
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and g.tiles[i].kind >= 0 and not seen[i] then
                local n = collect_group(g, i, cells)
                for k = 1, n do seen[cells[k]] = true end
                if n >= MATCH_MIN then
                    for k = 1, n do
                        local a = cells[k]
                        m.mask[a], m.ordinary[a] = true, true
                        m.hits = m.hits + 1
                    end
                end
            end
        end
    end
    local game_matches = M.game_matches

    local function movable_for_swap(g, i)
        return not locked(g, i) and g.tiles[i].kind ~= -1 and g.tiles[i].element ~= "cherry"
    end

    function M.game_can_swap(g, a, b)
        return cell_active(g, a) and cell_active(g, b) and hex_distance(a, b) == 1
            and movable_for_swap(g, a) and movable_for_swap(g, b)
    end
    local game_can_swap = M.game_can_swap

    -- false (and the board unchanged) if nothing would clear
    function M.game_swap(g, a, b, m)
        if g.won or g.lost or not game_can_swap(g, a, b) then return false end
        swap_tiles(g, a, b)
        game_matches(g, m)
        if not m.mask[a] and not m.mask[b] then
            swap_tiles(g, a, b)
            reset_match(m)
            return false
        end
        g.moves = g.moves - 1
        g.combo, g.turn_pending, g.oil_cleared = 0, true, false
        return true
    end
    local game_swap = M.game_swap
    local function hit_gem_protection(g, i)
        local layers = g.ice[i] > 0 and g.ice or g.chain
        if layers[i] == 0 then return false end
        layers[i], g.obstacles, g.score = layers[i] - 1, g.obstacles - 1, g.score + 20
        return true
    end

    -- Clear one wave; returns the relics cleared.
    function M.game_apply(g, m)
        local pierce_kind = m.pierce_kind
        m.bonus_charge_by_cell, m.pierce_kind = nil, nil
        m.direct, m.ordinary = m.direct or {}, m.ordinary or {}
        -- A wave deals at most one hit per blocker, even when several matches touch it.
        local damage = {}
        for i = 0, CELLS - 1 do
            if m.mask[i] then
                if m.direct[i] then damage[i] = true end
                if (m.ordinary[i] or not next(m.ordinary) and not m.direct[i]) and g.tiles[i].kind >= 0 then
                    for d = 0, 5 do
                        local j = hex_neighbor(i, d)
                        if j >= 0 then damage[j] = true end
                    end
                end
            end
        end
        for i = 0, CELLS - 1 do
            if damage[i] and g.stone_hp[i] > 0 then g.stone_hp[i], g.obstacles = 0, g.obstacles - 1 end
        end
        local protected = home.apply(g,m)
        local cleared = 0
        g.last_gold, g.last_wood, g.last_stone = 0, 0, 0
        g.combo = g.combo + 1
        for i = 0, CELLS - 1 do
            if cell_active(g, i) then
                -- A match touching carpet, or a move begun on it, carpets every cell it hits.
                if not g.hs and g.carpet and m.mask[i] and g.carpet[i] == 0 and not solid(g, i)
                    and (m.spread or {})[i] then
                    g.carpet[i], g.carpeted = 1, g.carpeted + 1
                end
                if m.mask[i] and not protected[i] and not solid(g, i) and g.tiles[i].kind ~= M.DELIVERY then
                    local absorbed = hit_gem_protection(g, i)
                    if not absorbed or (g.tiles[i].kind == pierce_kind and equal(g, i, i) and not locked(g, i)) then
                        if g.oil and g.oil[i] > 1 then   -- a double tablet loses one layer per hit
                            g.oil[i], g.score = g.oil[i] - 1, g.score + 30
                        elseif g.oil and g.oil[i] > 0 then
                            g.oil[i], g.oil_left, g.oil_cleared, g.score = 0, g.oil_left - 1, true, g.score + 30
                            if g.hs then home.credit(g, 'CELL_OIL') end
                        end
                        local k = g.tiles[i].kind
                        if k >= 0 then
                            if g.resource_yields then
                                local resource = g.resource_yields[k]
                                if resource then
                                    local length = m.match_lengths and m.match_lengths[i]
                                    local amount = resource.amount * (length and g.resource_multipliers[length] or 1)
                                    if resource.slot then
                                        g.earnings[resource.slot] = g.earnings[resource.slot] + amount
                                    elseif resource.tool and m.ordinary[i] and g.tool_meter and g.tool_meter[resource.tool] then
                                        local tool = resource.tool
                                        local meter = g.tool_meter[tool]
                                        if g.single_charge_tools then amount = math.min(amount, g.tool_threshold - meter) end
                                        m.bonus_charge_by_cell = m.bonus_charge_by_cell or {}
                                        m.bonus_charge_by_cell[i] = amount
                                        local charge = meter + amount
                                        if g.single_charge_tools then
                                            g.tool_meter[tool], g.tools[tool] = charge, charge // g.tool_threshold
                                        else
                                            g.tools[tool] = g.tools[tool] + charge // g.tool_threshold
                                            g.tool_meter[tool] = charge % g.tool_threshold
                                        end
                                    end
                                end
                            end
                            if M.is_goal_kind(g,k) then g.relics, g.last_gold = g.relics + 1, g.last_gold + 1 end
                            if (kind_flags[k] or 0) & E.WOOD ~= 0 then g.wood, g.last_wood = g.wood + 1, g.last_wood + 1 end
                            if (kind_flags[k] or 0) & E.STONE ~= 0 then g.stone, g.last_stone = g.stone + 1, g.last_stone + 1 end
                            g.score = g.score + 50 * g.combo
                            cleared = cleared + 1
                            g.tiles[i] = tile(-1)
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

    local damp_refills   -- defined with shape_at below
    function M.game_collapse(g)
        local from, steps, spawned = {}, {}, 0
        for i = 0, CELLS - 1 do from[i] = i end
        local function collect_deliveries()
            for i = 0, CELLS - 1 do
                if g.delivery_exits[i] and g.tiles[i].kind == M.DELIVERY and not locked(g,i) then
                    home.credit(g,"CARRY")
                    g.tiles[i], g.delivered = tile(-1), g.delivered + 1
                end
            end
        end
        collect_deliveries()
        local function movable(i) return cell_active(g, i) and not locked(g, i) and g.tiles[i].element ~= "cherry" end
        local function donor(i) return movable(i) and g.tiles[i].kind ~= -1 end
        local function side_donor(i)
            if not donor(i) or g.tiles[i].kind == M.DELIVERY then return false end
            local down = hex_neighbor(i, 1)
            return not movable(down) or g.tiles[down].kind ~= -1
        end
        while true do
            local step, used, empty, progress = {tiles = {}, from = {}}, {}, 0, false
            local next_from = {}
            for i = 0, CELLS - 1 do
                step.tiles[i], step.from[i], next_from[i] = g.tiles[i], i, from[i]
            end
            for _, i in ipairs(fall_order) do
                if movable(i) and g.tiles[i].kind == -1 then
                    empty = empty + 1
                    -- Alternate equal left/right choices spatially, without using RNG.
                    local left, right = -1, -1
                    if flags & E.NO_TRICKLE == 0 then left, right = hex_neighbor(i, 3), hex_neighbor(i, 5) end
                    if (hex_q(i) + hex_r(i)) % 2 == 0 then left, right = right, left end
                    local above, source = hex_neighbor(i, 4), nil
                    local inlet = home.source(g,i) or not cell_active(g, above)
                    if not inlet then
                        if donor(above) and not used[above] then source = above
                        elseif side_donor(left) and not used[left] then source = left
                        elseif side_donor(right) and not used[right] then source = right end
                    end
                    if source then
                        step.tiles[i], step.from[i], next_from[i] = g.tiles[source], source, from[source]
                        step.tiles[source], next_from[source], used[source] = tile(-1), source, true
                        progress = true
                    elseif inlet or not movable(left) and not movable(right) and not movable(above) then
                        spawned = spawned + 1
                        step.tiles[i], step.from[i], next_from[i] = home.spawn(g,i,step.tiles) or tile(spawn_kind(g)), -1, -spawned
                        progress = true
                    end
                end
            end
            if empty == 0 then break end
            if not progress then
                -- A whole pass moved and made nothing, so no neighbour will ever give these
                -- holes a piece (seen on a deliveries board with locks). Fill them as blocked cells do.
                for _, i in ipairs(fall_order) do
                    if movable(i) and g.tiles[i].kind == -1 then
                        spawned = spawned + 1
                        step.tiles[i], step.from[i], next_from[i] = home.spawn(g,i,step.tiles) or tile(spawn_kind(g)), -1, -spawned
                    end
                end
            end
            steps[#steps + 1] = step
            g.tiles, from = step.tiles, next_from
            local has_delivery = false
            for i = 0, CELLS - 1 do
                if g.delivery_exits[i] and g.tiles[i].kind == M.DELIVERY then has_delivery = true; break end
            end
            if has_delivery then
                local next_tiles = {}
                for i = 0, CELLS - 1 do next_tiles[i] = g.tiles[i] end
                g.tiles = next_tiles
                collect_deliveries()
            end
            assert(#steps <= CELLS * CELLS, "gravity failed to settle")
        end
        local before = g.tiles
        g.tiles = {}
        for i=0,CELLS-1 do g.tiles[i]=before[i] end
        home.release(g)
        local step,changed={tiles=g.tiles,from={}},false
        for i=0,CELLS-1 do
            local a,b=before[i],g.tiles[i]
            local born=a.kind~=b.kind or a.element~=b.element
            step.from[i]=born and -1 or i
            if born then from[i]=-1 end
            changed=changed or born
        end
        if changed then steps[#steps+1]=step end
        damp_refills(g, from)
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
        for i = 0, CELLS - 1 do c.tiles[i] = home.copy(g.tiles[i]) end
        c.hs = home.copy(g.hs)
        c.active, c.chain, c.ice = copy_array(g.active), copy_array(g.chain), copy_array(g.ice)
        c.carpet = g.carpet and copy_array(g.carpet)
        c.oil = g.oil and copy_array(g.oil)
        c.stone_hp = copy_array(g.stone_hp)
        c.tools = {table.unpack(g.tools)}
        if g.tool_meter then
            c.tool_meter = {}
            for tool, charge in pairs(g.tool_meter) do c.tool_meter[tool] = charge end
        end
        if g.earnings then c.earnings = {table.unpack(g.earnings)} end
        return c
    end
    local game_copy = M.game_copy

    -- Only lines through a swapped cell can validate its move. Avoid a
    -- whole-board scan for each hint candidate and each generated gem.
    local function shape_at(g,i)
        if not equal(g,i,i) then return false end
        for axis=0,2 do if run_length(g,i,axis)>=MATCH_MIN then return true end end
        return false
    end

    -- config.refill_damping = N: once a move's cascade reaches wave N, pieces
    -- spawned by the refill take a kind that completes no match where one
    -- exists. Pieces already on the board still fall and may match, so long
    -- cascades become rare without disappearing. Spawned tables are recolored
    -- in place, so every recorded fall step shows the final kind.
    local DAMPING = config.refill_damping
    assert(DAMPING == nil or math.type(DAMPING) == "integer" and DAMPING >= 1, "invalid refill damping")
    damp_refills = function(g, from)
        if not DAMPING or (g.combo or 0) < DAMPING then return end
        local kinds, cells = g.spawn_kinds or default_kinds, {}
        for _, i in ipairs(fall_order) do
            local t = g.tiles[i]
            if from[i] < 0 and cell_active(g, i) and not locked(g, i) and t.kind >= 0
                and not t.element then
                local matches = flags & E.LINE_MATCHES ~= 0 and shape_at(g, i)
                    or flags & E.LINE_MATCHES == 0 and collect_group(g, i, cells) >= MATCH_MIN
                if matches then
                    local choices, original = {}, t.kind
                    for _, k in ipairs(kinds) do
                        t.kind = k
                        local valid
                        if flags & E.LINE_MATCHES ~= 0 then valid = not shape_at(g, i)
                        else valid = collect_group(g, i, cells) < MATCH_MIN end
                        if valid then choices[#choices + 1] = k end
                    end
                    t.kind = #choices > 0 and choices[randn(g, #choices) + 1] or original
                end
            end
        end
    end

    -- Any move that clears something: ok, a, b. Only matches containing a
    -- swapped cell make a normal swap legal, so inspect those two cells rather
    -- than cloning and resolving the entire board for each candidate.
    function M.game_hint(g)
        if g.won or g.lost then return false end
        local cells = {}
        for i = 0, CELLS - 1 do
            for d = 0, 2 do
                local j = hex_neighbor(i, d)
                if game_can_swap(g, i, j) then
                    swap_tiles(g, i, j)
                    local matched
                    if flags & E.LINE_MATCHES ~= 0 then
                        matched=shape_at(g,i) or shape_at(g,j)
                    else matched=collect_group(g,i,cells)>=MATCH_MIN or collect_group(g,j,cells)>=MATCH_MIN end
                    swap_tiles(g, i, j)
                    if matched then return true, i, j end
                end
            end
        end
        return false
    end
    local game_hint = M.game_hint

    local function fill_without_matches(g)
        local cells, kinds = {}, g.spawn_kinds or default_kinds
        for i = 0, CELLS - 1 do
            if not locked(g, i) and g.tiles[i].kind ~= M.DELIVERY then g.tiles[i] = tile(-1) end
        end
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and not locked(g, i) and g.tiles[i].kind ~= M.DELIVERY then
                local choices, n = {}, 0
                if flags & E.LINE_MATCHES ~= 0 and MATCH_MIN==3 then
                    local forbidden={}
                    local function forbid(a,b)
                        if equal(g,a,b) then forbidden[g.tiles[a].kind]=true end
                    end
                    for axis=0,2 do
                        local a,b=hex_neighbor(i,axis),hex_neighbor(i,axis+3)
                        forbid(a,b);forbid(a,hex_neighbor(a,axis));forbid(b,hex_neighbor(b,axis+3))
                    end
                    for _, k in ipairs(kinds) do if not forbidden[k] then n=n+1;choices[n]=k end end
                else
                    for _, k in ipairs(kinds) do
                        g.tiles[i] = tile(k)
                        local valid
                        if flags & E.LINE_MATCHES ~= 0 then valid=not shape_at(g,i)
                        else valid = collect_group(g, i, cells) < MATCH_MIN end
                        if valid then n = n + 1; choices[n] = k end
                    end
                end
                if n == 0 then return false end
                g.tiles[i] = tile(choices[randn(g, n) + 1])
            end
        end
        return true
    end

    local function generate_board(g)
        -- never erase blockers or fill a hole merely to manufacture a move
        local m = new_match()
        for _ = 1, 2000 do
            if fill_without_matches(g) then
                game_matches(g, m)
                if m.hits == 0 and game_hint(g) then return end
            end
        end
    end

    -- Recovery moves whole pieces. Locked pieces
    -- and terrain stay put; an unsuccessful search restores the original board.
    function M.game_shuffle(g)
        local cells, pieces, original = {}, {}, {}
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and not locked(g, i) and g.tiles[i].kind ~= M.DELIVERY and not g.tiles[i].element then
                cells[#cells + 1], pieces[#pieces + 1] = i, g.tiles[i]
                original[i] = g.tiles[i]
            end
        end
        local distinct=false
        for i=2,#pieces do
            if pieces[i].kind~=pieces[1].kind then distinct=true;break end
        end
        if not distinct then return false end -- every permutation would be identical
        local m = new_match()
        for _ = 1, 2000 do
            for i = #pieces, 2, -1 do
                local j = randn(g, i) + 1
                pieces[i], pieces[j] = pieces[j], pieces[i]
            end
            for i, cell in ipairs(cells) do g.tiles[cell] = pieces[i] end
            game_matches(g, m)
            if m.hits == 0 and game_hint(g) then return true end
        end
        for cell, piece in pairs(original) do g.tiles[cell] = piece end
        return false
    end
    local game_shuffle = M.game_shuffle

    function M.game_start(lvl, seed, resource_yields, loadout)
        lvl = math.max(0, math.min(lvl, LEVELS - 1))
        local g = {
            tiles = {}, active = {}, chain = {}, ice = {}, carpet = {}, carpeted = 0, carpet_total = 0,
            oil = {}, oil_left = 0, oil_cleared = false, stone_hp = {},
            delivery_exits = {}, delivered = 0, delivery_total = 0,
            level = lvl, moves = 0, score = 0, relics = 0, obstacles = 0, initial_obstacles = 0,
            combo = 0, cleared = 0, last_gold = 0, last_wood = 0, last_stone = 0, wood = 0, stone = 0,
            rng = (seed and seed ~= 0) and (seed & 0xFFFFFFFF) or 12345,
            won = false, lost = false,
            tools = {2, 2, 2},   -- pickaxe, dynamite, sunburst charges
        }
        local l = M.levels[lvl + 1]
        g.resource_yields = resource_yields
        if g.resource_yields then g.earnings = {0, 0, 0} end
        if loadout then
            g.spawn_kinds = loadout.kinds
            g.resource_multipliers = loadout.multipliers
            g.tool_threshold, g.tool_meter = loadout.tool_threshold, loadout.tool_meter
            g.single_charge_tools = loadout.single_charge_tools
            g.tool_slots = loadout.tool_slots
            g.tools = {}
            local count = g.tool_slots and #g.tool_slots or 3 + #(config.extra_tools or {})
            for i = 1, count do
                g.tools[i] = g.single_charge_tools and (g.tool_meter[i] or 0) // g.tool_threshold or 0
            end
        elseif l.omit_kind ~= nil then
            -- The palette contains stable colour slots. Board copies share it read-only.
            assert(math.type(l.omit_kind) == "integer" and l.omit_kind >= 0
                and l.omit_kind < COLORS and COLORS > 3, "invalid omitted match3 kind")
            g.spawn_kinds = {}
            for _, kind in ipairs(default_kinds) do
                if kind ~= l.omit_kind then g.spawn_kinds[#g.spawn_kinds + 1] = kind end
            end
        end
        assert(l.goal_kind == nil or math.type(l.goal_kind) == "integer" and l.goal_kind >= 0
            and l.goal_kind < COLORS and l.goal_kind ~= l.omit_kind, "collection goal kind must spawn")
        g.goal_kind = l.goal_kind
        g.moves = l.moves
        local order, n = {}, 0
        for i = 0, CELLS - 1 do
            g.active[i] = not l.mask or l.mask:sub(i + 1, i + 1) == "1"
            g.tiles[i] = tile(-1)
            g.chain[i], g.ice[i], g.stone_hp[i], g.carpet[i], g.oil[i] = 0, 0, 0, 0, 0
            if g.active[i] then n = n + 1; order[n] = i end
        end
        if l.homescapes then home.init(g,l.homescapes);return g end
        local used = {}
        local function valid_cell(cell)
            assert(math.type(cell) == "integer" and cell_active(g, cell), "element cell must be active")
        end
        local function reserve(cell)
            valid_cell(cell)
            assert(not used[cell], "overlapping elements")
            used[cell] = true
        end
        for _, entry in ipairs(l.stones or {}) do
            reserve(entry.cell)
            g.stone_hp[entry.cell] = 1
        end
        local delivery = l.deliveries or {}
        for _, cell in ipairs(delivery.exits or {}) do reserve(cell); g.delivery_exits[cell] = true end
        for _, cell in ipairs(delivery.tokens or {}) do reserve(cell); g.delivery_total = g.delivery_total + 1 end
        if g.delivery_total > 0 then
            assert(#(delivery.exits or {}) > 0, "delivery requires an exit")
            -- Delivery tokens fall vertically. Check the route after removable
            -- locks clear, without relying on sideways trickling.
            for _, token in ipairs(delivery.tokens) do
                local here = token
                while cell_active(g, here) and not g.delivery_exits[here] do here = hex_neighbor(here, 1) end
                assert(g.delivery_exits[here], "delivery exit is unreachable")
            end
        end
        -- Solid cells cannot receive terrain or generated pieces.
        local eligible = {}
        for _, cell in ipairs(order) do if not solid(g, cell) then eligible[#eligible + 1] = cell end end
        order, n = eligible, #eligible
        assert(n > 0, "empty playable board")
        generate_board(g)
        for _, cell in ipairs(delivery.tokens or {}) do g.tiles[cell] = tile(M.DELIVERY) end
        for i = 1, n do   -- selection sort, exactly as the original orders ties
            for j = i + 1, n do
                if l.terrain and l.terrain[order[j] + 1] < l.terrain[order[i] + 1] then order[i], order[j] = order[j], order[i] end
            end
        end
        local taken = {}
        for cell in pairs(used) do taken[cell] = true end
        local chain_count = 0
        for k = 0, n * 3 - 1 do
            if chain_count >= l.chains then break end
            local cell = order[(k * 3 + 1) % n + 1]
            if not taken[cell] then
                -- The first double_chains strands placed take two hits.
                g.chain[cell] = chain_count < (l.double_chains or 0) and 2 or 1
                taken[cell], chain_count = true, chain_count + 1
            end
        end
        assert(chain_count == l.chains, "not enough chain cells")
        assert((l.double_chains or 0) <= l.chains, "double chains are counted within chains")
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
        assert(count == l.ice, "not enough ice cells")
        for i = 0, CELLS - 1 do
            g.initial_obstacles = g.initial_obstacles + g.ice[i] + g.chain[i] + g.stone_hp[i]
        end
        g.obstacles = g.initial_obstacles
        -- Carpet (Homescapes' CELL_JELLY): seed cells start covered and every
        -- active cell must be covered by spreading it.
        if l.carpet and #l.carpet > 0 then
            for _, cell in ipairs(l.carpet) do
                valid_cell(cell)
                assert(cell_active(g, cell), "carpet seed outside the board")
                if g.carpet[cell] == 0 then g.carpet[cell], g.carpeted = 1, g.carpeted + 1 end
            end
            for i = 0, CELLS - 1 do if cell_active(g, i) then g.carpet_total = g.carpet_total + 1 end end
        end
        -- Oil (Homescapes' CELL_OIL): one layer under a piece. `oil_still`
        -- keeps it from spreading: the cover over a buried find.
        for _, cell in ipairs(l.oil or {}) do
            valid_cell(cell)
            assert(cell_active(g, cell), "oil outside the board")
            if g.oil[cell] == 0 then g.oil[cell], g.oil_left = 1, g.oil_left + 1 end
        end
        -- `oil_double` lists cells among `oil` that take two hits: Cradle of Rome's double tablets.
        for _, cell in ipairs(l.oil_double or {}) do
            assert(g.oil[cell] == 1, "double tablet outside the level's oil cells")
            g.oil[cell] = 2
        end
        if l.homescapes then home.init(g,l.homescapes); return g end
        local m = new_match()
        game_matches(g, m)
        if m.hits > 0 or not game_hint(g) then generate_board(g) end
        if loadout then g.moves = g.moves + (loadout.extra_moves or 0) end
        return g
    end

    -- Oil spreads after a turn that cleared none of it (Homescapes'
    -- GrowsByInactivity): one random neighbouring cell, under its piece.
    local function grow_oil(g)
        if not g.oil or (g.oil_left or 0) == 0 or g.oil_cleared then return false end
        if M.levels[g.level + 1].oil_still then return false end   -- the cover over a buried find stays put
        local seen, options = {}, {}
        for i = 0, CELLS - 1 do
            if g.oil[i] > 0 then
                for d = 0, 5 do
                    local j = hex_neighbor(i, d)
                    if not seen[j] and cell_active(g, j) and g.oil[j] == 0 and not solid(g, j) then
                        seen[j], options[#options + 1] = true, j
                    end
                end
            end
        end
        if #options == 0 then return false end
        local j = options[randn(g, #options) + 1]
        g.oil[j], g.oil_left, g.oil_grew = 1, g.oil_left + 1, j
        return true
    end

    function M.game_end_turn(g)
        if not g.turn_pending then return false end
        g.turn_pending = false
        return grow_oil(g)
    end

    function M.game_check_end(g)
        M.game_end_turn(g)
        local l = M.levels[g.level + 1]
        local done = {score = g.score >= l.score, idols = g.relics >= l.relics,
            locks = g.obstacles == 0, deliveries = g.delivered == g.delivery_total,
            carpet = g.carpeted >= g.carpet_total, oil = g.oil_left == 0}
        -- A level's own goal list is all it needs; otherwise every counter must be done.
        local cleared = true
        for _, id in ipairs(l.goals or {"score", "idols", "locks", "deliveries", "carpet", "oil"}) do cleared = cleared and done[id] end
        g.won = g.hs and home.won(g) or not g.hs and cleared
        g.lost = not g.won and g.moves <= 0
        if flags & E.NO_RESHUFFLE == 0 and not g.won and not g.lost and not game_hint(g) then
            return game_shuffle(g)   -- discard stale selection/hints only after recovery
        end
        return false
    end

    local extra_tools = config.extra_tools or {}
    local default_tools = {"hit", "blast", "sunburst"}
    local function tool_slot(g, tool)
        return g and g.tool_slots and g.tool_slots[tool + 1]
    end
    local function tool_ready(g, tool)
        local count = g.tool_slots and #g.tool_slots or #default_tools + #extra_tools
        return flags & E.NO_TOOLS == 0 and tool >= 0 and tool < count
            and (g.tools[tool + 1] or 0) > 0 and not g.won and not g.lost
    end
    local INSTANT = {shuffle=true, lightning=true, moves=true, charge=true}
    function M.game_tool_effect(tool, g)
        local descriptor = tool_slot(g, tool)
        return descriptor and descriptor.action or default_tools[tool + 1] or extra_tools[tool - 2]
    end
    function M.game_tool_untargeted(tool, g)
        return INSTANT[M.game_tool_effect(tool, g)] == true
    end
    local function charge_others(g, tool, amount)
        local charged = false
        for i, meter in pairs(g.tool_meter) do
            if i ~= tool + 1 and meter < g.tool_threshold then
                g.tool_meter[i] = math.min(g.tool_threshold, meter + amount)
                g.tools[i] = g.tool_meter[i] // g.tool_threshold
                charged = true
            end
        end
        return charged
    end
    local function lightning(g, m, limit, random)
        local candidates = {}
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and not m.mask[i] and g.tiles[i].kind ~= M.DELIVERY then
                candidates[#candidates + 1] = i
            end
        end
        for i = 1, math.min(limit, #candidates) do
            local pick = i + randn(random, #candidates - i + 1)
            candidates[i], candidates[pick] = candidates[pick], candidates[i]
            local cell = candidates[i]
            m.mask[cell], m.direct[cell] = true, true
        end
    end
    local function target_tool(g, effect, cell, m, preview)
        if not cell or not cell_active(g, cell) then return false end
        if effect == "hit" then m.mask[cell], m.direct[cell] = true, true
        elseif effect == "blast" then mark_area(g, m, cell, 1)
        elseif effect == "row" or effect == "row_lightning" then
            mark_line(g, m, cell, 0)
            if effect == "row_lightning" then
                lightning(g, m, 20 - count_hits(m), preview and {rng=g.rng} or g)
            end
        elseif effect == "sunburst" and config.sunburst_targets and g.tool_meter and g.tool_meter[3] then
            m.mask = config.sunburst_targets(g, cell, CELLS)
        elseif effect == "color" or effect == "color_pierce" or flags & E.COLOR_TOOL ~= 0 then
            if not equal(g, cell, cell) then return false end
            local kind = g.tiles[cell].kind
            mark_color(g, m, kind)
            if effect == "color_pierce" then m.pierce_kind = kind end
        else for z = 0, 2 do mark_line(g, m, cell, z) end end
        return true
    end

    function M.game_tool(g, tool, cell, m)
        if not tool_ready(g, tool) then return false end
        local effect = M.game_tool_effect(tool, g)
        reset_match(m)
        if effect == "shuffle" then
            if not game_shuffle(g) then return false end
        elseif effect == "moves" then g.moves = g.moves + (config.extra_moves or 5)
        elseif effect == "charge" then
            if not g.tool_meter or not g.single_charge_tools then return false end
            local descriptor = tool_slot(g, tool)
            local amount = g.tool_threshold // (descriptor and descriptor.charge_divisor or 2)
            if not charge_others(g, tool, amount) then return false end
        elseif effect == "lightning" then lightning(g, m, 20, g)
        elseif not target_tool(g, effect, cell, m) then return false end
        g.tools[tool + 1] = g.tools[tool + 1] - 1
        if g.single_charge_tools and g.tool_meter[tool + 1] then g.tool_meter[tool + 1] = 0 end
        g.combo = 0
        count_hits(m)
        -- Effects that clear nothing skip the clearing animation.
        local still = (effect == "shuffle" or effect == "moves" or effect == "charge") and effect or nil
        return true, still
    end

    -- Preview the same cells a targeted tool will hit without advancing the RNG.
    function M.game_tool_area(g, tool, cell)
        if not tool_ready(g, tool) or M.game_tool_untargeted(tool, g) then return nil end
        local m = {mask = {}, direct = {}}
        if target_tool(g, M.game_tool_effect(tool, g), cell, m, true) then return m.mask end
    end

    -- How good a move is for a greedy player: score plus weighted goal progress.
    function M.game_evaluate_move(g, a, b)
        if not game_can_swap(g, a, b) then return -1 end
        local c = game_copy(g)
        local m = new_match()
        if not game_swap(c, a, b, m) then return -1 end
        game_apply(c, m)
        local level = M.levels[g.level + 1]
        local goal = level.relics
        local relics = math.min(c.relics, goal) - math.min(g.relics, goal)
        local delivery_access = 0
        for i = 0, CELLS - 1 do
            if g.tiles[i].kind == M.DELIVERY then
                local below = hex_neighbor(i, 1)
                if cell_active(c, below) and not locked(c, below) and c.tiles[below].kind == -1
                    and g.tiles[below].kind ~= -1 then delivery_access = delivery_access + 1 end
            end
        end
        return c.score - g.score + relics * 90 + (c.carpeted - g.carpeted) * 160 + (g.oil_left - c.oil_left) * 200
            + (g.obstacles - c.obstacles) * 220 + delivery_access * 350
    end


    -- Presentation adapter: callbacks below emit graphics, sound, haptics and notices.
    -- The engine owns selection, gestures, phase timing and all piece poses.
    function M.bind_view(R)
        local elements = require("match3.elements_view")
    local function noop() end
    R.tone, R.vfx_wave = R.tone or noop, R.vfx_wave or noop
    R.notice = R.notice or function(message) R.toast, R.toast_time = message, 3.6 end
    R.tool_notes = R.tool_notes or {"Choose a piece to remove.", "Choose the centre of a blast.", "Choose a piece to clear its axes."}
    -- What an untargeted bonus did, and why it could not act, by effect name.
    R.tool_done_notes = R.tool_done_notes or {shuffle="Pieces reshuffled.", moves="More moves added.",
        charge="Your other bonuses gained charge."}
    R.tool_refused_notes = R.tool_refused_notes or {shuffle="No shuffle available.",
        charge="Your other bonuses are already charged."}
    function R.reset_board(g)
        R.g, R.pending = g, M.new_match()
        R.phase, R.phase_time, R.idle_time, R.shake = 0, 0, 0, 0
        R.swap_a, R.swap_b, R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1, -1, -1
        R.hover_cell, R.aim_cell = -1, -1
        R.fall_steps, R.fall_from = nil, {}
        R.kudos, R.kudos_level, R.mission_banner = nil, 0, nil
    end
    local rules = M
    -- The engine owns the HUD, field and tool bands. The scenery is painted
    -- from the bottom at its original scale. Single-charge bonuses have a
    -- compact tray at the bottom, below the centred playable field.
    assert(R.layout == nil, "the match3 board layout is engine-owned; games must not define R.layout")
    local REF_H, HUD_FROM_BOTTOM, BOARD_FROM_BOTTOM, TOOLS_FROM_BOTTOM, HUD_H = 1040, 772, 409, 100, 64
    local BONUS_GAP, BONUS_MARGIN = 8, 8
    local neutral_hud = app.arg("default-match3")
    -- Imported boards can occupy only part of their enclosing hex grid. Fit
    -- their actual cells, including the hex faces, into the space between HUD
    -- and tools; empty grid padding must not shrink or displace the field.
    local fitted, offset = nil, vec2(0,0)
    if #M.levels==1 and M.levels[1].homescapes then
        local mask=M.levels[1].mask
        local minx,maxx,miny,maxy=math.huge,-math.huge,math.huge,-math.huge
        for i=0,CELLS-1 do if mask:sub(i+1,i+1)=='1' then
            local x,y=hex_q(i)*1.5,(hex_r(i)+hex_q(i)*.5)*math.sqrt(3)
            minx,maxx=math.min(minx,x-1),math.max(maxx,x+1)
            miny,maxy=math.min(miny,y-math.sqrt(3)/2),math.max(maxy,y+math.sqrt(3)/2)
        end end
        assert(minx<maxx,"source board has no active cells")
        local width,height=maxx-minx,maxy-miny
        local available_h=HUD_FROM_BOTTOM-HUD_H-16-TOOLS_FROM_BOTTOM-18
        local face_radius=math.min(((R.SCREEN_W or 480)-16)/width,available_h/height)
        if R.piece_width then R.piece_width=R.piece_width*face_radius/R.HEX_R end
        R.HEX_R=face_radius
        offset=vec2((minx+maxx)*face_radius/2,(miny+maxy)*face_radius/2)
        fitted=size2(width*face_radius,height*face_radius)
    end
    local HEX_R, HEX_DY = R.HEX_R, math.sqrt(3) * R.HEX_R
    local board_size = size2(((1.5 * M.HEX_RADIUS + 1) * HEX_R + 6) * 2, ((M.HEX_RADIUS + .5) * HEX_DY + 6) * 2)
    local centred_game, centre_q, centre_row = nil, 0, 0
    local function layout()
        local w, design_h = R.SCREEN_W or 480, R.SCREEN_H or 900
        local h = math.max(design_h, app.screen().h)
        local g = R.g
        local bonuses = g and g.tool_slots
        R.drop = h - design_h
        R.tools_y = h - TOOLS_FROM_BOTTOM
        if g ~= centred_game then
            centred_game, centre_q, centre_row = g, 0, 0
            if g and not fitted then
                local min_q, max_q, min_row, max_row = math.huge, -math.huge, math.huge, -math.huge
                for i = 0, CELLS - 1 do
                    if cell_active(g, i) then
                        local q = hex_q(i)
                        local row = hex_r(i) + q * .5
                        min_q, max_q = math.min(min_q, q), math.max(max_q, q)
                        min_row, max_row = math.min(min_row, row), math.max(max_row, row)
                    end
                end
                if min_q <= max_q then centre_q, centre_row = (min_q + max_q) / 2, (min_row + max_row) / 2 end
            end
        end
        local board_center = vec2(w / 2, bonuses and h / 2 or h - BOARD_FROM_BOTTOM)
        local shift = vec2(centre_q * 1.5 * HEX_R, bonuses and centre_row * HEX_DY or 0)
        R.board_origin = board_center - shift
        R.BOARD_CLIP = rect.centered(board_center, board_size)
        local hud_y = h - HUD_FROM_BOTTOM
        local toast_y = hud_y + HUD_H + 4
        if bonuses then
            toast_y = math.min(toast_y, R.BOARD_CLIP.y - 36)
            if neutral_hud then hud_y = toast_y - HUD_H - 4 end
        end
        R.hud_rect = rect(0, hud_y, w, HUD_H)
        R.board_pause = bonuses and R.board_tool_bounds(#bonuses)
            or rect.centered(vec2(w - 46, R.hud_rect:center().y), size2(64, 64))
        R.board_toast = rect(38, toast_y, w - 76, 28)
        if fitted then
            local top,bottom=R.hud_rect.y+HUD_H+16,R.tools_y-18
            local center=vec2(w/2,(top+bottom)/2)
            R.board_origin=center-offset
            R.BOARD_CLIP=rect.centered(center,size2(fitted.w+12,fitted.h+12))
        end
    end
    -- Where a backdrop of this pixel size goes in the bleed rect `full`:
    -- Covering the screen on the bottom edge, normally at least 1040 tall.
    function R.backdrop_rect(size, full, min_height)
        local s = math.max(math.max(min_height or REF_H, full.h) / size.h, full.w / size.w)
        local sw, sh = size.w * s, size.h * s
        return rect(full.x + (full.w - sw) / 2, full.y + full.h - sh, sw, sh)
    end
    function R.board_tool_bounds(k)
        local w, side = R.SCREEN_W or 480, E.TOOL_SIZE
        local offset_x = (k - 1) * 120
        if R.g and R.g.tool_slots then
            local count = #R.g.tool_slots + 1   -- four boosters and Pause
            side = math.min(side, (w - 2 * BONUS_MARGIN - (count - 1) * BONUS_GAP) / count)
            offset_x = (k - (count - 1) / 2) * (side + BONUS_GAP)
        end
        return rect(w / 2 + offset_x - side / 2, R.tools_y + (E.TOOL_SIZE - side) / 2, side, side)
    end
    R.layout = layout
    layout()
    local CELL_SIZE = R.piece_width or HEX_DY
    local PI = math.pi
    local PH_IDLE, PH_SWAP, PH_REJECT, PH_CLEAR, PH_FALL = 0, 1, 2, 3, 4
    local REJECT_LEG = .16
    R.PH_IDLE, R.PH_SWAP, R.PH_REJECT, R.PH_CLEAR, R.PH_FALL = PH_IDLE, PH_SWAP, PH_REJECT, PH_CLEAR, PH_FALL
    function R.cell_pos(i) return R.board_origin + vec2(hex_q(i) * 1.5 * HEX_R, (hex_r(i) + hex_q(i) * .5) * HEX_DY) end
    local cell_pos = R.cell_pos

    R.GROUND = {seam = color(69, 73, 80), face = color(82, 86, 93)}

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

    local function use_tool(k, cell)
        local used, still = rules.game_tool(R.g, k, cell, R.pending)
        if used then
            R.tool = -1
            R.play("tool")
            if R.g.single_charge_tools then R.toast_time = 0 end
            if still then
                R.hint_a, R.hint_b, R.idle_time = -1, -1, 0
                R.notice(R.tool_done_notes[still])
                if R.update_bonus_charges then R.update_bonus_charges() end
            else R.finish_wave() end
        elseif rules.game_tool_untargeted(k, R.g) then R.notice(R.tool_refused_notes[rules.game_tool_effect(k, R.g)] or "Nothing to do.") end
    end

    function R.select_tool(k)
        if R.phase ~= PH_IDLE then return end
        if (R.g.tools[k + 1] or 0) > 0 and flags & E.NO_TOOLS == 0 then
            R.selected = -1
            if rules.game_tool_untargeted(k, R.g) then use_tool(k); return end
            R.tool = R.tool == k and -1 or k
            local descriptor = tool_slot(R.g, k)
            R.notice(R.tool < 0 and "Tool put away." or descriptor and descriptor.effect or R.tool_notes[k + 1])
        elseif R.g.opening_tools and R.g.opening_tools[k + 1] then
            R.notice("This booster has been used for this wish.")
        elseif R.g.tool_meter then
            R.notice(R.g.tool_meter[k + 1] and "Match its pieces to charge this tool." or "Restore its building to unlock this tool.")
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
            use_tool(R.tool, cell)
            return
        end
        if R.selected >= 0 and R.selected~=cell and hex_distance(R.selected,cell)==1 then R.attempt_swap(R.selected,cell)
        elseif R.selected == cell then R.selected=-1
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
        -- A mouse hovers a cell; with a tool armed, the hovered or pressed cell is its aim.
        local ready = R.overlay == R.OV_NONE and R.phase == PH_IDLE and R.BOARD_CLIP:contains(inp.pos)
        local at = ready and R.cell_at(inp.pos) or -1
        R.hover_cell = inp.hover and not inp.down and at or -1
        R.aim_cell = R.tool >= 0 and (inp.hover or inp.down) and at or -1
        if R.cell_state_review then R.hover_cell, R.aim_cell = R.cell_state_review.hover, R.cell_state_review.aim end
        if not inp.released or R.overlay ~= R.OV_NONE then return end
        local d = inp.pos - inp.press_pos
        if R.phase == PH_IDLE and R.cell_at(inp.press_pos) >= 0 and (math.abs(d.x) > 16 or math.abs(d.y) > 16) then swipe(inp.press_pos, inp.pos)
        elseif R.phase == PH_IDLE and R.BOARD_CLIP:contains(inp.pos) then tap_cell(inp.pos) end
    end

    ---------------------------------------------------------------------- rules

    local function snapshot()
        for i = 0, CELLS - 1 do
            local t = R.g.tiles[i]
            R.old_tiles[i] = {}
            for k,v in pairs(t) do R.old_tiles[i][k]=v end
            R.wave_ice[i], R.wave_chain[i] = R.g.ice[i], R.g.chain[i]
            R.wave_oil[i] = R.g.oil and R.g.oil[i] or 0
        end
    end

    local notes = {523.25, 659.25, 783.99, 1046.5, 1318.5}
    -- The board's sound bank on the polyphonic synth: {hz, seconds, delay, volume}.
    local C5, E5, G5, C6, E6, G6 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1567.98
    local sounds = {
        select = {{880, .05, 0, .45}},
        swap = {{392, .07, 0, .6}, {587.33, .09, .045, .6}},
        reject = {{311.13, .09, 0, .75}, {233.08, .15, .08, .75}},
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

    -- Praise for long cascades. Games may replace the words.
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
        elements.maker_observe(R)
        rules.game_apply(R.g, R.pending)
        if R.update_bonus_charges then R.update_bonus_charges() end
        elements.maker_observe(R)
        R.phase = PH_CLEAR
        R.phase_time = 0
        R.shake = R.reduced_motion and 0 or R.g.combo > 1 and .13 or .06
        R.vfx_wave(old_score)
        R.play("match", R.g.combo)
        -- Cascades earn praise from the third wave; the word waits until the
        -- whole cascade has settled (see settle).
        local praise = R.g.combo >= 3 and R.g.combo - 2 or 0
        R.kudos_level = math.max(R.kudos_level or 0, praise)
        -- Breaking ice or a blue/green tablet layer lands harder than a plain match.
        local broke = false
        for i = 0, CELLS - 1 do
            if R.wave_ice[i] > R.g.ice[i] or (R.g.oil and R.wave_oil[i] > R.g.oil[i]) then broke = true; break end
        end
        if broke then haptic.play(haptic.COMBO, 1)
        else
            haptic.play(R.g.combo > 1 and haptic.COMBO or haptic.MATCH,
                math.min(1, .6 + .1 * R.g.combo))
        end
    end

    local function reject_swap(chain)
        R.phase, R.phase_time, R.reject_chain = PH_REJECT, 0, chain
        R.play("reject")
        haptic.play(haptic.ERROR, .5)
    end

    function R.attempt_swap(a, b)
        if R.phase ~= PH_IDLE or R.overlay ~= R.OV_NONE or R.on_island then return end
        R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
        R.idle_time = 0
        R.swap_a, R.swap_b = a, b
        snapshot()
        local g = R.g
        if rules.game_swap(g, a, b, R.pending) then
            R.phase = PH_SWAP
            R.phase_time = 0
            R.play("swap")
        elseif rules.game_can_swap(g, a, b) then
            reject_swap(false)
        else
            R.notice(R.locked_notice or "Ice and chains must be broken first.")
            if not g.won and not g.lost and cell_active(g, a) and cell_active(g, b) and hex_distance(a, b) == 1
                and (g.chain[b] or 0) > 0 and movable_for_swap(g, a) then
                reject_swap(true)
            end
        end
    end

    local function settle()
        rules.game_matches(R.g, R.pending)
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
        if R.g.won then
            R.overlay = R.OV_RESULT
            if R.stash_completed then R.stash_completed() end
            R.play("win"); haptic.play(haptic.SUCCESS)
        elseif R.g.lost then R.overlay = R.OV_FAILED; R.play("lose"); haptic.play(haptic.ERROR) end
        R.idle_time = 0
    end

    function R.idle_hint_age()
        local age = R.idle_time - 5
        if flags & E.NO_HINTS == 0 and R.phase == PH_IDLE and age > 0 and not R.g.won and not R.g.lost then
            return age
        end
    end

    function R.board_update(dt)
        if R.art_review then return end
        R.shake = math.max(0, R.shake - dt)
        if R.overlay ~= R.OV_NONE or R.on_island then return end
        elements.maker_update(R,dt)
        R.idle_time = R.idle_time + dt
        if R.phase == PH_IDLE and not R.g.won and not R.g.lost then   -- ready groups resolve before any input
            rules.game_matches(R.g, R.pending)
            if R.pending.hits > 0 then
                R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
                R.finish_wave()
            end
        end
        if R.hint_a < 0 and R.idle_hint_age() then
            local ok, a, b = rules.game_hint(R.g)
            if ok then R.hint_a, R.hint_b = a, b
            else settle() end   -- idle/resumed dead boards need the same recovery as a completed fall
        end
        if R.phase == PH_IDLE then return end
        R.phase_time = R.phase_time + dt
        local speed = R.reduced_motion and .35 or 1
        if R.phase == PH_SWAP and R.phase_time > .17 * speed then R.finish_wave()
        elseif R.phase == PH_REJECT and R.phase_time >= 2 * REJECT_LEG * speed then R.phase = PH_IDLE
        elseif R.phase == PH_CLEAR and R.phase_time > .24 * speed and not elements.maker_busy(R) then
            R.fall_from, R.fall_steps = rules.game_collapse(R.g)
            elements.maker_observe(R)
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
        local into_chain = R.phase == PH_REJECT and R.reject_chain
        if i == R.swap_a or (i == R.swap_b and not into_chain) then
            local other = i == R.swap_a and R.swap_b or R.swap_a
            local leg = R.phase == PH_SWAP and .17 or REJECT_LEG * (R.reduced_motion and .35 or 1)
            local f = R.phase_time / leg
            if R.phase == PH_REJECT and f > 1 then f = 2 - f end
            at = at:lerp(cell_pos(other) + vec2(sx, 0), (into_chain and .5 or 1) * ease.out_cubic(num.saturate(f)))
        end
    elseif R.phase == PH_CLEAR and R.pending.mask[i] then
        t = R.old_tiles[i]
        if ((R.wave_chain[i] == 0 and R.wave_ice[i] == 0) or g.tiles[i].kind < 0)
            and t.kind ~= M.DELIVERY then   -- a small pop, then shrink away
            local f = num.saturate(R.phase_time / .24)
            scale = f < .22 and 1 + .18 * math.sin(f / .22 * PI) or 1 - .92 * ease.out_cubic((f - .22) / .78)
            alpha = 255 * (1 - f * f)
        end
    elseif R.phase == PH_FALL then
        local steps = R.fall_steps or {}
        local elapsed_steps = R.phase_time / ((R.reduced_motion and .35 or 1) * rules.FALL_STEP)
        local completed = math.floor(elapsed_steps)
        local step, landed = steps[completed + 1], steps[completed]
        local from = step and step.from[i] or i
        local f = elapsed_steps - completed
        if step then t = step.tiles[i] end
        if from ~= i then
            local source = from >= 0 and cell_pos(from) or cell_pos(i) - vec2(0, HEX_DY)
            at = (source + vec2(sx, 0)):lerp(at, f)
            if from < 0 then
                -- Clip only the inlet; sideways moves need the whole board.
                local top = cell_pos(i).y - HEX_DY / 2
                clip = rect(at.x - CELL_SIZE / 2 - 1, top, CELL_SIZE + 2, R.BOARD_CLIP.h)
            end
        elseif not R.reduced_motion and landed and landed.from[i] ~= i
            and t == landed.tiles[i] and t.kind >= 0 and t.kind ~= M.DELIVERY then
            -- Rebound only while the piece rests in the cell it just reached.
            at.y = at.y - HEX_DY * .07 * (4 * f * (1 - f))
            aspect = 1 + .08 * (1 - f)^3
        end
    end
    return t, at, scale, alpha, aspect, clip
    end
    end

    return M
end
return E
