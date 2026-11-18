-- Reusable deterministic hex match-3 engine. Game configuration is data and
-- integer behavior flags; graphics never implement matching, gravity or input.
local buttons = require("match3.buttons")
local E = {
    NO_TRICKLE=1, NO_TOOLS=4, NO_HINTS=8, NO_RESHUFFLE=16, LINE_MATCHES=64, COLOR_TOOL=256,
    GOAL=1, WOOD=4, STONE=8, -- per-kind behavior bits
}

-- Engine-owned interaction state; a game adds only its screen/presentation data.
function E.view(state)
    state = state or {}
    state.SCREEN_W, state.SCREEN_H = state.SCREEN_W or 480, state.SCREEN_H or 900
    state.HEX_R, state.drop = state.HEX_R or 32, 0
    state.PH_IDLE, state.PH_SWAP, state.PH_REJECT, state.PH_CLEAR, state.PH_FALL, state.PH_SHUFFLE = 0, 1, 2, 3, 4, 6
    state.old_tiles, state.fall_from, state.wave_ice, state.wave_chain, state.wave_oil = {}, {}, {}, {}, {}
    state.phase, state.phase_time, state.idle_time, state.shake = 0, 0, 0, 0
    state.selected, state.swap_a, state.swap_b, state.tool, state.hint_a, state.hint_b = -1, -1, -1, -1, -1, -1
    return state
end

-- The two match-3 cities share the same view templates. Game code supplies
-- localized copy, skin colors, and records with stable keys via set_items.
E.CATALOGUE_ROW, E.CATALOGUE_SLIM = 84, 56

-- The subtitle value also owns its row's visibility. Hidden rows take no gap.
local function header_title(title)
    assert(type(title) == "string" and title:find("%S"), "popup title must contain text")
    return title
end

local function header_subtitle(text)
    assert(text == nil or type(text) == "string", "popup subtitle must be text")
    if text and text:find("%S") then return text end
end

function E.popup_header(title, subtitle)
    return {kind="column",id="header",panel=true,role="popup_header",padding={12,8,12,10},gap=2,children={
        {kind="label",id="title",value=header_title(title),wrap=true,em=31,text_style="gold"},
        {kind="label",id="subtitle",value=header_subtitle(subtitle),visible_field="subtitle",
            wrap=true,em=14,text_style="cream"},
    }}
end

function E.set_popup_header(form, title, subtitle)
    form:set("title", header_title(title)):set("subtitle", header_subtitle(subtitle))
end

-- One resource amount: the icon above its figure, in the skin's
-- resource_indicator border. The icon names the resource, so there is no
-- caption. Results, prices and what a building brings all list these. `unit`
-- is a second icon beside the figure (a new piece and the resource each match
-- of it banks); without an amount the icon stands alone. Only an amount with
-- no art of its own takes a `label`: a larger figure over one word. A width
-- fixes the element, and a narrow one sets a smaller figure; without a width
-- it fills its cell.
ui.prefab("resource_indicator", function(p)
    local narrow = p.width and p.width < 76
    local figure = p.amount and {kind="label",text=tostring(p.amount),em=narrow and 21 or 25,text_style="gold"}
    local children = {}
    if p.icon then
        children[1] = {kind="image",image=p.icon,height=figure and 36 or 62}
        if figure and p.unit then
            local side = narrow and 18 or 24
            figure = {kind="row",gap=narrow and 2 or 3,align="center",children={
                {kind="spacer",grow=1},{kind="image",image=p.unit,width=side,height=side},figure,{kind="spacer",grow=1},
            }}
        end
    elseif figure then
        figure.em, figure.height = narrow and 28 or 34, 46
    end
    children[#children + 1] = figure
    if p.label then children[#children + 1] = {kind="label",text=p.label,height=15,em=12,text_style="caption"} end
    return {kind="border",role="resource_indicator",padding={4,5,4,7},children={
        {kind="column",gap=1,children=children},
    }}
end)

-- A resource record ({icon, amount, unit, label}) as that element.
function E.resource_indicator(entry, width)
    return {kind="resource_indicator",width=width,icon=entry.icon,amount=entry.amount,unit=entry.unit,label=entry.label}
end

-- Full-screen sheets under the wallet row. One building per row: the whole
-- row is the button (id 'pick') and paint_row draws its art, name, price and
-- action. A record marked slim (already built) takes a short row.
function E.catalogue_form(title, close, paint_row)
    return ui.form{kind='column',panel=true,padding={14,12,14,14},gap=8,children={
        E.popup_header(title),
        {kind='row',height=38,gap=8,children={
            {kind='button',id='category_prev',text='<',width=42,em=22},
            {kind='label',id='category',grow=1,em=21},
            {kind='button',id='category_next',text='>',width=42,em=22},
        }},
        {kind='list',id='stock',scroll=true,grow=1,gap=6,item=function(record)
            return {kind='overlay',height=record.slim and E.CATALOGUE_SLIM or E.CATALOGUE_ROW,children={
                {kind='custom',paint=function(box) paint_row(box, record) end},
                {kind='button',id='pick',text='',flat=true,enabled=record.available},
            }}
        end},
        {kind='button',id='close',text=close,height=42,em=21},
    }}
end

-- A skin is one flat table of named images. Its definition lists typed
-- atlases ({path=, frames=}, each a set drawn together in one style) under
-- sheets, and standalone images such as backgrounds under images; a plain
-- {path=, frames=} is a definition of one sheet. engine=true reads every path
-- from the engine's resource directory. Every named image borrows its sheet's
-- GPU texture.
local atlases, sheets = {}, {}
local function load_sheet(sheet, engine)
    local id = (engine and "engine:" or "") .. sheet.path
    if not sheets[id] then
        sheets[id] = (engine and texture.load_engine or texture.load)(sheet.path)
        assert(sheets[id].tex, "cannot load match3 atlas: " .. sheet.path)
    end
    return sheets[id]
end
function E.atlas(definition)
    local key = definition or "default"
    if atlases[key] then return atlases[key] end
    definition = definition or require("match3.frames")
    local images, load = {}, definition.engine and texture.load_engine or texture.load
    for _, sheet in ipairs(definition.sheets or {definition}) do
        local atlas = load_sheet(sheet, definition.engine)
        for name, box in pairs(sheet.frames) do
            local image = texture.region(atlas, rect(box[1], box[2], box[3], box[4]))
            assert(image.tex, "invalid match3 frame: " .. name)
            images[name] = image
        end
    end
    for name, path in pairs(definition.images or {}) do
        images[name] = load(path)
        assert(images[name].tex, "cannot load match3 image: " .. path)
    end
    for name, target in pairs(definition.aliases or {}) do
        images[name] = assert(images[target], "match3 alias of a missing frame: " .. target)
    end
    for name, point in pairs(definition.button_centers or {}) do
        buttons.centers[assert(images[name], "missing button frame: " .. name)] = vec2(point[1], point[2])
    end
    atlases[key] = images
    return images
end

function E.skin(override)
    local skin = E.atlas(override)
    for _, name in ipairs({"kind-0", "kind-1", "kind-2", "kind-3", "kind-4", "kind-5",
        "chain", "ice-1", "ice-2", "selected", "hint", "guide", "cell-mask", "background", "glow"}) do
        assert(skin[name], "missing match3 frame: " .. name)
    end
    return skin
end

function E.hud(override)
    local hud = E.atlas(override)
    assert(hud.score and hud.complete, "missing match3 HUD icons")
    return hud
end

-- Toolbar buttons: their glyphs draw about a fifth larger than board pieces.
-- Five buttons and their gaps fit 480 points; narrower screens shrink them.
E.TOOL_SIZE = 86
local GOAL_W, GOAL_GAP = 70, 16

function E.tool_state(charges, selected, inside, down, started_inside, hover, idle)
    if charges <= 0 or not idle then return "disabled" end
    if inside and down and started_inside then return "pressed" end
    if selected then return "selected" end
    if inside and hover then return "hover" end
    return "normal"
end

local function pause_button(bounds, icon)
    local st = ui.hit(bounds, 0)
    local state = st.held and "pressed" or st.hot and "hover" or "normal"
    buttons.paint(bounds, icon, state)
    return st.clicked
end

local goal_icon_adjustments = {
    chain = {scale = 1.12, x = 2},
    ["stone-1"] = {scale = .9},
}

-- tool_art names the toolbar buttons of a board without booster slots; the
-- engine's default skin draws pickaxe, dynamite and sunburst.
function E.bind_board_ui(R, rules, tool_art, icon_adjustments)
    tool_art = tool_art or {"pickaxe", "dynamite", "sunburst"}
    local rgba, PI = color, math.pi
    local PAL_GOLD, PAL_CREAM, PAL_WHITE = R.PAL_GOLD, R.PAL_CREAM, R.PAL_WHITE
    function R.goal_entries()
        local g, l = R.g, rules.level_of(R.g)
        local entries = {{id="score",icon="score",remaining=math.max(0,l.score-g.score)},
            {id="idols",icon=not g.goal_kind and "idols" or nil,kind=g.goal_kind,
                remaining=math.max(0,l.relics-g.relics)}}
        if g.initial_obstacles>0 then
            local stone_only = (l.chains or 0)==0 and (l.ice or 0)==0 and l.stones and #l.stones>0
            local icon = (R.board_goal_icon and R.board_goal_icon(l, "locks"))
                or (stone_only and "stone-1" or "chain")
            entries[#entries+1]={id="locks",icon=icon,remaining=math.max(0,g.obstacles)}
        end
        if g.oil_left>0 or l.oil and #l.oil>0 then
            -- A buried find (reveal.object) is its own goal icon.
            local find = l.reveal and l.reveal.object and l.reveal.icon
            local floor = R.board_goal_icon and R.board_goal_icon(l, "oil")
            entries[#entries+1]={id="oil",icon=find or floor or "tile-tablet-single",remaining=g.oil_left}
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

    -- The row vertically centres the column by its visible lettering.
    local moves_form = ui.form{kind="row", align="center", children={
        {kind="column", id="stack", grow=1, children={
            {kind="label", id="caption", text="MOVES", text_style=PAL_CREAM, em=9},
            {kind="label", id="count", text_style=PAL_GOLD},
        }},
    }}

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
        local caption, count = moves_form.nodes.caption, moves_form.nodes.count
        count.em, count.text_style = 29 * arrive * scale, urgent and PAL_WHITE or PAL_GOLD
        local value = tostring(moves)
        caption.height = text.ink(R.skin:measure_text(caption.text_style, caption.em), caption.text).h
        count.height = text.ink(R.skin:measure_text(count.text_style, count.em), value).h
        moves_form.nodes.stack.gap = 6 * arrive * scale
        moves_form:set("count", value)
        moves_form:draw(rect.centered(c, size2(r * 1.5, r * math.sqrt(3))), R.skin, {interactive=false})
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
        if not R.g.tool_slots and pause_button(R.board_pause:offset(offset), R.skin.images["action-pause"]) then
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
                    -- A stored charge stays visible while the board is resolving.
                    buttons.paint(drawn, R.board_art[icon], state == "disabled" and "normal" or state)
                else
                    buttons.paint(drawn, R.board_art[icon], "disabled")
                    if meter and meter > 0 then
                        -- Reveal the ready face from the bottom as the meter fills.
                        local fill = drawn.h * meter / R.g.tool_threshold
                        gfx.clip(rect(drawn.x, drawn.y + drawn.h - fill, drawn.w, fill))
                        buttons.paint(drawn, R.board_art[icon], "normal")
                        gfx.unclip()
                    end
                end
                if charges > 1 and not R.g.single_charge_tools then
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
            if pause_button(button, R.skin.images["action-pause"]) then R.overlay = R.OV_PAUSE end
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
        if neutral then return goal_hud() end
        local box = R.town:header(R.header_capsules(true), BOARD_HEADER)
        local arrive = R.intro and R.intro:arrive(.16, 3, .42) or 1
        if arrive > .05 then R.draw_moves(box:center(), arrive, box.w * .5) end
    end

    function R.goal_target(kind)
        if neutral then return goal_target(kind) end
    end

    if not neutral and R.currency_capsules then
        function R.resource_target(kind)
            local piece = R.g.resource_yields and R.g.resource_yields[kind]
            local targets = R.town.resource_targets
            return piece and targets and targets[piece.slot]
        end
    end

    function R.mission(...)
        if app.arg("mission") then mission(...) end
    end
end

function E.guide_form(copy, guide_icon)
    return ui.form{kind="column",panel=true,padding=20,children={
        E.popup_header(copy.title, copy.instructions),
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
            E.popup_header("Settings"),
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

function E.new(config)
    config = config or {}
    local flags, kind_flags = config.flags or E.LINE_MATCHES, config.kind_flags or {}
    assert(math.type(flags) == "integer" and flags >= 0 and flags < 512, "invalid match3 flags")
    assert(not config.radius or math.type(config.radius) == "integer" and config.radius >= 1 and config.radius <= 16, "invalid hex radius")
    assert((config.columns == nil) == (config.rows == nil), "a rectangular board needs both columns and rows")
    assert(not config.columns or math.type(config.columns) == "integer" and config.columns % 2 == 1
        and config.columns <= 31 and math.type(config.rows) == "integer" and config.rows >= 2 and config.rows <= 31,
        "a rectangular board has an odd number of columns")
    local M = {flags=flags}
    -- Axial hex grid of flat-top cells; neighbours are numbered 0..5 and
    -- opposite directions differ by 3. The envelope is a hexagon of `radius`
    -- or a rectangle of `columns` x `rows`, whose odd columns sit half a cell
    -- lower (as in Blossom Blast). Cells are numbered by q, then r, ascending.
    local qs, rs, index = {}, {}, {}
    local function key(q, r) return q * 1024 + r end
    local CELLS
    do
        local n = 0
        local function add(q, r) qs[n], rs[n], index[key(q, r)] = q, r, n; n = n + 1 end
        if config.columns then
            M.COLUMNS, M.ROWS = config.columns, config.rows
            local half = (config.columns - 1) // 2
            for q = -half, half do
                for row = 0, config.rows - 1 do add(q, row - q // 2 - config.rows // 2) end
            end
            M.HEX_RADIUS = math.max(half, config.rows // 2)
        else
            local radius = config.radius or 4
            for q = -radius, radius do
                for r = math.max(-radius, -q - radius), math.min(radius, -q + radius) do add(q, r) end
            end
            M.HEX_RADIUS = radius
        end
        CELLS = n
    end
    M.CELLS = CELLS
    local radius = M.HEX_RADIUS
    -- direction d: 0 = (+1, 0), 1 = (0, +1), 2 = (-1, +1), 3..5 the opposites
    local dirs = {[0] = {1, 0}, {0, 1}, {-1, 1}, {-1, 0}, {0, -1}, {1, -1}}
    local neighbors = {}
    for i = 0, CELLS - 1 do
        neighbors[i] = {}
        for d = 0, 5 do
            neighbors[i][d] = index[key(qs[i] + dirs[d][1], rs[i] + dirs[d][2])] or -1
        end
    end

    function M.hex_index(q, r) return index[key(q, r)] or -1 end
    function M.hex_q(cell) return qs[cell] or 0 end
    function M.hex_r(cell) return rs[cell] or 0 end
    function M.hex_neighbor(cell, d)
        local n = neighbors[cell]
        return n and n[d] or -1
    end
    -- The cell nearest the envelope's middle.
    local centre = index[key(0, 0)]
    function M.hex_center() return centre end
    function M.hex_distance(a, b)
        if a < 0 or a >= CELLS or b < 0 or b >= CELLS then return 10000 end
        local q, r = qs[a] - qs[b], rs[a] - rs[b]
        return (math.abs(q) + math.abs(r) + math.abs(q + r)) // 2
    end
    -- The envelope's extent in cell units: q, and screen rows (r + q / 2).
    do
        local min_q, max_q, min_y, max_y = math.huge, -math.huge, math.huge, -math.huge
        for i = 0, CELLS - 1 do
            local y = rs[i] + qs[i] * .5
            min_q, max_q, min_y, max_y = math.min(min_q, qs[i]), math.max(max_q, qs[i]), math.min(min_y, y), math.max(max_y, y)
        end
        M.envelope = {min_q=min_q, max_q=max_q, min_y=min_y, max_y=max_y}
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
    local shapes = require("match3.shapes")
    local lines = flags & E.LINE_MATCHES ~= 0 and shapes.lines(M, MATCH_MIN)
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
    -- Matches only clear. As in Cradle of Rome, power is earned through tools,
    -- never made by a longer line, so a piece is just its kind.
    local function tile(kind) return {kind = kind} end
    M.tile = tile

    local function swap_tiles(g, a, b) g.tiles[a], g.tiles[b] = g.tiles[b], g.tiles[a] end
    local function solid(g, i) return (g.stone_hp[i] or 0) > 0 end
    local function locked(g, i) return (g.chain[i] or 0) > 0 or (g.ice[i] or 0) > 0 or solid(g, i) end

    local function cell_active(g, cell) return cell >= 0 and cell < CELLS and g.active[cell] end
    M.game_cell_active = cell_active

    local function match_kind(g, cell)
        if g.active[cell] and not solid(g, cell) then
            local kind = g.tiles[cell].kind
            if kind >= 0 then return kind end
        end
    end

    local function equal(g, a, b)
        local kind = match_kind(g, a)
        return kind ~= nil and kind == match_kind(g, b)
    end

    -- An empty match: which cells clear (mask), which a match cleared
    -- (ordinary) and which a tool hit directly (direct).
    local function new_match() return {mask = {}, direct = {}, ordinary = {}, hits = 0} end
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

    local function mark_line(g, m, cell, axis)
        if cell_active(g, cell) then m.mask[cell], m.direct[cell] = true, true end
        for sign = 0, 1 do
            local d = axis + (sign == 1 and 3 or 0)
            local c = hex_neighbor(cell, d)
            while c >= 0 do
                if cell_active(g, c) then m.mask[c], m.direct[c] = true, true end
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
        m.mask, m.direct, m.ordinary, m.hits = {}, {}, {}, 0
        m.match_lengths, m.pierce_kind = nil, nil
    end

    function M.game_matches(g, m)
        reset_match(m)
        m.match_lengths = g.resource_multipliers and {}
        if lines then
            local kinds = {}
            for i = 0, CELLS - 1 do
                kinds[i] = match_kind(g, i)
            end
            shapes.matches(lines, kinds, m, MATCH_MIN)
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
        return not locked(g, i) and g.tiles[i].kind ~= -1
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
        g.combo = 0
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
        local cleared = 0
        g.last_gold, g.last_wood, g.last_stone = 0, 0, 0
        g.combo = g.combo + 1
        for i = 0, CELLS - 1 do
            if cell_active(g, i) then
                if m.mask[i] and not solid(g, i) then
                    local absorbed = hit_gem_protection(g, i)
                    if not absorbed or (g.tiles[i].kind == pierce_kind and equal(g, i, i) and not locked(g, i)) then
                        if g.oil and g.oil[i] > 1 then   -- a double tablet loses one layer per hit
                            g.oil[i], g.score = g.oil[i] - 1, g.score + 30
                        elseif g.oil and g.oil[i] > 0 then
                            g.oil[i], g.oil_left, g.score = 0, g.oil_left - 1, g.score + 30
                        end
                        local k = g.tiles[i].kind
                        if k >= 0 then
                            if g.resource_yields then
                                local resource = g.resource_yields[k]
                                if resource then
                                    local length = m.match_lengths and m.match_lengths[i]
                                    local amount = resource.amount * (length and g.resource_multipliers[length] or 1)
                                    if resource.slot and (not g.match_only_resources or not m.direct[i] or m.ordinary[i]) then
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

    local rise_order = {}   -- top row first
    for k = #fall_order, 1, -1 do rise_order[#rise_order + 1] = fall_order[k] end

    -- An inlet is open to the sky: no active cell anywhere above it in its
    -- column. A hole inside the board is a roof, not an inlet.
    local function inlet_of(g, i)
        local above = hex_neighbor(i, 4)
        while above >= 0 do
            if cell_active(g, above) then return false end
            above = hex_neighbor(above, 4)
        end
        return true
    end
    M.game_inlet = inlet_of

    -- Cells gravity can feed: an inlet, or a cell below
    -- a fed, unlocked donor straight above or (with trickling) on an upper
    -- diagonal. Chains, ice and stones are gates: cells reachable only through
    -- them get no new pieces until they break.
    local function fed_cells(g)
        local fed = {}
        local function open(i) return cell_active(g, i) and not locked(g, i) end
        for _, i in ipairs(rise_order) do
            if open(i) then
                local above = hex_neighbor(i, 4)
                local yes = inlet_of(g, i) or fed[above]
                if not yes and flags & E.NO_TRICKLE == 0 then
                    local left, right = hex_neighbor(i, 3), hex_neighbor(i, 5)
                    yes = fed[left] or fed[right]
                end
                fed[i] = yes or nil
            end
        end
        return fed
    end
    M.game_fed_cells = fed_cells

    -- Empty every unlocked cell no gate-free path can feed.
    local function clear_unfed(g)
        local fed = fed_cells(g)
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and not locked(g, i) and not fed[i] then g.tiles[i] = tile(-1) end
        end
    end
    M.game_clear_unfed = clear_unfed

    local damp_refills   -- defined with shape_at below
    function M.game_collapse(g)
        local from, steps, spawned = {}, {}, 0
        for i = 0, CELLS - 1 do from[i] = i end
        local fed = fed_cells(g)
        local function movable(i) return cell_active(g, i) and not locked(g, i) end
        local function donor(i) return movable(i) and g.tiles[i].kind ~= -1 end
        local function side_donor(i)
            if not donor(i) then return false end
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
                    local inlet = inlet_of(g, i)
                    if not inlet then
                        if donor(above) and not used[above] then source = above
                        elseif side_donor(left) and not used[left] then source = left
                        elseif side_donor(right) and not used[right] then source = right end
                    end
                    if source then
                        step.tiles[i], step.from[i], next_from[i] = g.tiles[source], source, from[source]
                        step.tiles[source], next_from[source], used[source] = tile(-1), source, true
                        progress = true
                    elseif inlet then
                        spawned = spawned + 1
                        step.tiles[i], step.from[i], next_from[i] = tile(spawn_kind(g)), -1, -spawned
                        progress = true
                    end
                end
            end
            if empty == 0 then break end
            if not progress then
                -- A whole pass moved and made nothing: the rest wait behind gates.
                -- A fed hole no neighbour can reach still takes a new piece.
                local filled = false
                for _, i in ipairs(fall_order) do
                    if movable(i) and fed[i] and g.tiles[i].kind == -1 then
                        spawned, filled = spawned + 1, true
                        step.tiles[i], step.from[i], next_from[i] = tile(spawn_kind(g)), -1, -spawned
                    end
                end
                if not filled then break end
            end
            steps[#steps + 1] = step
            g.tiles, from = step.tiles, next_from
            assert(#steps <= CELLS * CELLS, "gravity failed to settle")
        end
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
        for i = 0, CELLS - 1 do c.tiles[i] = tile(g.tiles[i].kind) end
        c.active, c.chain, c.ice = copy_array(g.active), copy_array(g.chain), copy_array(g.ice)
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
    local function shape_at(g, cell)
        local kind = match_kind(g, cell)
        if not kind then return false end
        for axis = 0, 2 do
            local length = 1
            for dir = axis, axis + 3, 3 do
                local side = neighbors[cell][dir]
                while match_kind(g, side) == kind do
                    length = length + 1
                    if length >= MATCH_MIN then return true end
                    side = neighbors[side][dir]
                end
            end
        end
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
            if from[i] < 0 and cell_active(g, i) and not locked(g, i) and t.kind >= 0 then
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
    local hint_cells = {}
    -- Whether swapping a and b makes a match, tested in place without a board copy.
    function M.game_swap_matches(g, a, b)
        if not game_can_swap(g, a, b) then return false end
        swap_tiles(g, a, b)
        local matched
        if flags & E.LINE_MATCHES ~= 0 then
            matched = shape_at(g, a) or shape_at(g, b)
        else matched = collect_group(g, a, hint_cells) >= MATCH_MIN or collect_group(g, b, hint_cells) >= MATCH_MIN end
        swap_tiles(g, a, b)
        return matched
    end
    local game_swap_matches = M.game_swap_matches

    function M.game_hint(g)
        if g.won or g.lost then return false end
        for i = 0, CELLS - 1 do
            for d = 0, 2 do
                local j = hex_neighbor(i, d)
                if game_swap_matches(g, i, j) then return true, i, j end
            end
        end
        return false
    end
    local game_hint = M.game_hint

    local function fill_without_matches(g)
        local cells, kinds = {}, g.spawn_kinds or default_kinds
        for i = 0, CELLS - 1 do
            if not locked(g, i) then g.tiles[i] = tile(-1) end
        end
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and not locked(g, i) then
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
                clear_unfed(g)
                game_matches(g, m)
                if m.hits == 0 and game_hint(g) then return end
            end
        end
    end

    -- Recovery moves whole pieces. Locked pieces and terrain stay put.
    -- Return source cells by destination on success; restore every cell on failure.
    function M.game_shuffle(g)
        local cells, pieces, original = {}, {}, {}
        for i = 0, CELLS - 1 do
            if cell_active(g, i) and not locked(g, i) and g.tiles[i].kind >= 0 then
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
        -- A random deal on a large board with five kinds nearly always holds a
        -- line somewhere, so each deal is repaired: a piece in a line swaps with
        -- a random piece whenever that leaves fewer matched cells.
        local function repair()
            game_matches(g, m)
            for _ = 1, #cells * 4 do
                if m.hits == 0 then return end
                local hits, matched = m.hits, {}
                for _, cell in ipairs(cells) do if m.mask[cell] then matched[#matched + 1] = cell end end
                local a = matched[randn(g, #matched) + 1]
                local b = cells[randn(g, #cells) + 1]
                g.tiles[a], g.tiles[b] = g.tiles[b], g.tiles[a]
                game_matches(g, m)
                if m.hits >= hits then
                    g.tiles[a], g.tiles[b] = g.tiles[b], g.tiles[a]
                    game_matches(g, m)
                end
            end
        end
        for _ = 1, 200 do
            for i = #pieces, 2, -1 do
                local j = randn(g, i) + 1
                pieces[i], pieces[j] = pieces[j], pieces[i]
            end
            for i, cell in ipairs(cells) do g.tiles[cell] = pieces[i] end
            repair()
            if m.hits == 0 and game_hint(g) then
                local source, from = {}, {}
                for cell, piece in pairs(original) do source[piece] = cell end
                for _, cell in ipairs(cells) do
                    local previous = source[g.tiles[cell]]
                    if previous ~= cell then from[cell] = previous end
                end
                return true, from
            end
        end
        for cell, piece in pairs(original) do g.tiles[cell] = piece end
        return false
    end
    local game_shuffle = M.game_shuffle

    function M.game_start(lvl, seed, resource_yields, loadout)
        lvl = math.max(0, math.min(lvl, LEVELS - 1))
        local g = {
            tiles = {}, active = {}, chain = {}, ice = {}, oil = {}, oil_left = 0, stone_hp = {},
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
            g.match_only_resources = loadout.match_only_resources
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
            g.chain[i], g.ice[i], g.stone_hp[i], g.oil[i] = 0, 0, 0, 0
            if g.active[i] then n = n + 1; order[n] = i end
        end
        local used = {}
        local function valid_cell(cell)
            assert(math.type(cell) == "integer" and cell_active(g, cell), "level cell must be active")
        end
        local function reserve(cell)
            valid_cell(cell)
            assert(not used[cell], "overlapping stones")
            used[cell] = true
        end
        for _, entry in ipairs(l.stones or {}) do
            reserve(entry.cell)
            g.stone_hp[entry.cell] = 1
        end
        -- Solid cells cannot receive terrain or generated pieces.
        local eligible = {}
        for _, cell in ipairs(order) do if not solid(g, cell) then eligible[#eligible + 1] = cell end end
        order, n = eligible, #eligible
        assert(n > 0, "empty playable board")
        generate_board(g)
        for i = 1, n do   -- selection sort, exactly as the original orders ties
            for j = i + 1, n do
                if l.terrain and l.terrain[order[j] + 1] < l.terrain[order[i] + 1] then order[i], order[j] = order[j], order[i] end
            end
        end
        local taken = {}
        for cell in pairs(used) do taken[cell] = true end
        -- `chain_cells` places authored chains: {cell=id, hits=1 or 2}. They
        -- are counted apart from the scalar `chains`, which terrain rank places.
        for _, entry in ipairs(l.chain_cells or {}) do
            valid_cell(entry.cell)
            assert(not taken[entry.cell], "overlapping chains")
            g.chain[entry.cell], taken[entry.cell] = entry.hits or 1, true
        end
        -- `ice_cells` places authored ice: {cell=id, layers=1 or 2}.
        for _, entry in ipairs(l.ice_cells or {}) do
            valid_cell(entry.cell)
            assert(not taken[entry.cell], "ice overlaps a chain or stone")
            g.ice[entry.cell], taken[entry.cell] = entry.layers or 1, true
        end
        local chain_count = 0
        for k = 0, n * 3 - 1 do
            if chain_count >= (l.chains or 0) then break end
            local cell = order[(k * 3 + 1) % n + 1]
            if not taken[cell] then
                -- The first double_chains strands placed take two hits.
                g.chain[cell] = chain_count < (l.double_chains or 0) and 2 or 1
                taken[cell], chain_count = true, chain_count + 1
            end
        end
        assert(chain_count == (l.chains or 0), "not enough chain cells")
        assert((l.double_chains or 0) <= l.chains, "double chains are counted within chains")
        local count = 0
        for k = 0, n - 1 do
            if count >= (l.ice or 0) then break end
            local cell = order[(k + 4) % n + 1]
            if not taken[cell] and hex_distance(cell, hex_center()) <= math.max(1, radius - 1) then
                g.ice[cell] = (l.ice_layers == 2 and count % 3 == 0) and 2 or 1
                taken[cell] = true
                count = count + 1
            end
        end
        assert(count == (l.ice or 0), "not enough ice cells")
        for i = 0, CELLS - 1 do
            g.initial_obstacles = g.initial_obstacles + g.ice[i] + g.chain[i] + g.stone_hp[i]
        end
        g.obstacles = g.initial_obstacles
        -- Tablets (`oil`): one layer under a piece, cleared by a match on its
        -- cell or a hit. They never spread.
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
        clear_unfed(g)   -- cells behind a gate start empty
        local m = new_match()
        game_matches(g, m)
        if m.hits > 0 or not game_hint(g) then generate_board(g) end
        if loadout then g.moves = g.moves + (loadout.extra_moves or 0) end
        return g
    end

    function M.game_check_end(g)
        local l = M.levels[g.level + 1]
        local done = {score = g.score >= l.score, idols = g.relics >= l.relics,
            locks = g.obstacles == 0, oil = g.oil_left == 0}
        -- A level's own goal list is all it needs; otherwise every counter must be done.
        local cleared = true
        for _, id in ipairs(l.goals or {"score", "idols", "locks", "oil"}) do cleared = cleared and done[id] end
        g.won = cleared
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
            if cell_active(g, i) and not m.mask[i] then
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
        elseif effect == "replenish" then
            local piece = g.resource_yields[g.tiles[cell].kind]
            if not piece or not (piece.slot or piece.tool) then return false end
            m.mask[cell] = true
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

    function M.game_tool(g, tool, cell, m, other_slot)
        if not tool_ready(g, tool) then return false end
        local effect = M.game_tool_effect(tool, g)
        reset_match(m)
        local shuffle_from
        if effect == "shuffle" then
            local shuffled
            shuffled, shuffle_from = game_shuffle(g)
            if not shuffled then return false end
        elseif effect == "moves" then g.moves = g.moves + (config.extra_moves or 5)
        elseif effect == "replenish" then
            local piece = cell and cell_active(g, cell) and g.resource_yields[g.tiles[cell].kind]
            local slot = other_slot or piece and piece.tool
            if slot then
                local meter = g.tool_meter[slot]
                if slot == tool + 1 or not meter or meter >= g.tool_threshold then return false end
                g.tool_meter[slot] = math.min(g.tool_threshold, meter + g.tool_threshold // 4)
                g.tools[slot] = g.tool_meter[slot] // g.tool_threshold
            elseif piece and piece.slot then
                g.earnings[piece.slot] = g.earnings[piece.slot] + tool_slot(g, tool).resource_amount
            else return false end
        elseif effect == "charge" then
            if not g.tool_meter or not g.single_charge_tools then return false end
            local descriptor = tool_slot(g, tool)
            local amount = g.tool_threshold // (descriptor and descriptor.charge_divisor or 2)
            if not charge_others(g, tool, amount) then return false end
        elseif effect == "lightning" then lightning(g, m, config.lightning_hits or 20, g)
        elseif not target_tool(g, effect, cell, m) then return false end
        g.tools[tool + 1] = g.tools[tool + 1] - 1
        if g.single_charge_tools and g.tool_meter[tool + 1] then g.tool_meter[tool + 1] = 0 end
        g.combo = 0
        count_hits(m)
        -- Effects that clear nothing skip the clearing animation.
        local still = (effect == "shuffle" or effect == "moves" or effect == "charge" or effect == "replenish") and effect or nil
        return true, still, shuffle_from
    end

    -- Preview the same cells a targeted tool will hit without advancing the RNG.
    function M.game_tool_area(g, tool, cell)
        if not tool_ready(g, tool) or M.game_tool_untargeted(tool, g) then return nil end
        local m = {mask = {}, direct = {}}
        if target_tool(g, M.game_tool_effect(tool, g), cell, m, true) then return m.mask end
    end

    -- How good a move is for a greedy player: score plus weighted goal progress.
    -- A caller that also needs the matched cells can supply its own probe.
    function M.game_evaluate_move(g, a, b, probe)
        if not M.game_swap_matches(g, a, b) then return -1 end
        local c = game_copy(g)
        local m = probe or new_match()
        if not game_swap(c, a, b, m) then return -1 end
        game_apply(c, m)
        local level = M.levels[g.level + 1]
        local goal = level.relics
        local relics = math.min(c.relics, goal) - math.min(g.relics, goal)
        return c.score - g.score + relics * 90 + (g.oil_left - c.oil_left) * 200
            + (g.obstacles - c.obstacles) * 220
    end


    -- Presentation adapter: callbacks below emit graphics, sound, haptics and notices.
    -- The engine owns selection, gestures, phase timing and all piece poses.
    function M.bind_view(R)
    local function noop() end
    R.tone, R.vfx_wave = R.tone or noop, R.vfx_wave or noop
    R.notice = R.notice or function(message) R.toast, R.toast_time = message, 3.6 end
    R.tool_notes = R.tool_notes or {"Choose a piece to remove.", "Choose the centre of a blast.", "Choose a piece to clear its axes."}
    -- What an untargeted bonus did, and why it could not act, by effect name.
    R.tool_done_notes = R.tool_done_notes or {shuffle="Pieces reshuffled.", moves="More moves added.",
        replenish="Bonus collected.", charge="Your other bonuses gained charge."}
    R.tool_refused_notes = R.tool_refused_notes or {shuffle="No shuffle available.",
        charge="Your other bonuses are already charged."}
    function R.reset_board(g)
        R.g, R.pending = g, M.new_match()
        R.phase, R.phase_time, R.idle_time, R.shake = 0, 0, 0, 0
        R.swap_a, R.swap_b, R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1, -1, -1
        R.hover_cell, R.aim_cell = -1, -1
        R.fall_steps, R.fall_from = nil, {}
        R.shuffle_from = nil
        R.kudos, R.kudos_level, R.mission_banner = nil, 0, nil
    end
    local rules = M
    -- The engine owns the HUD, field and tool bands. The scenery is painted
    -- from the bottom at its original scale. Single-charge bonuses have a
    -- compact tray at the bottom, below the centred playable field.
    assert(R.layout == nil, "the match3 board layout is engine-owned; games must not define R.layout")
    local REF_H, HUD_FROM_BOTTOM, BOARD_FROM_BOTTOM, TOOLS_FROM_BOTTOM, HUD_H = 1040, 772, 409, 100, 64
    local BONUS_GAP, BONUS_MARGIN = 4, 4   -- the round button art carries its own clear border
    local neutral_hud = app.arg("default-match3")
    local HEX_R, HEX_DY = R.HEX_R, math.sqrt(3) * R.HEX_R
    local env = M.envelope
    local board_size = size2(((env.max_q - env.min_q) * 1.5 + 2) * HEX_R + 12, (env.max_y - env.min_y + 1) * HEX_DY + 12)
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
            if g then
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
    local PH_IDLE, PH_SWAP, PH_REJECT, PH_CLEAR, PH_FALL, PH_SHUFFLE = 0, 1, 2, 3, 4, 6
    local REJECT_LEG = .16
    local SHUFFLE_FLIGHT, SHUFFLE_STAGGER, SHUFFLE_GROUPS = .49, .015, 7
    local SHUFFLE_DURATION = SHUFFLE_FLIGHT + SHUFFLE_STAGGER * (SHUFFLE_GROUPS - 1)
    R.PH_IDLE, R.PH_SWAP, R.PH_REJECT, R.PH_CLEAR, R.PH_FALL, R.PH_SHUFFLE =
        PH_IDLE, PH_SWAP, PH_REJECT, PH_CLEAR, PH_FALL, PH_SHUFFLE
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

    local function animate_shuffle(from)
        R.hover_cell, R.aim_cell = -1, -1
        if R.reduced_motion then return end
        R.shuffle_from = from
        R.phase, R.phase_time = PH_SHUFFLE, 0
    end

    local function use_tool(k, cell, other_slot)
        local used, still, shuffle_from = rules.game_tool(R.g, k, cell, R.pending, other_slot)
        if used then
            R.tool = -1
            R.play("tool")
            if R.g.single_charge_tools then R.toast_time = 0 end
            if still then
                R.hint_a, R.hint_b, R.idle_time = -1, -1, 0
                if shuffle_from then animate_shuffle(shuffle_from) end
                R.notice(R.tool_done_notes[still])
                if R.update_bonus_charges then R.update_bonus_charges() end
            else R.finish_wave() end
        elseif rules.game_tool_untargeted(k, R.g) then R.notice(R.tool_refused_notes[rules.game_tool_effect(k, R.g)] or "Nothing to do.") end
    end

    function R.select_tool(k)
        if R.phase ~= PH_IDLE then return end
        if R.tool >= 0 and R.tool ~= k and rules.game_tool_effect(R.tool, R.g) == "replenish" then
            use_tool(R.tool, nil, k + 1)
            return
        end
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
        R.play("kudos", level)   -- sound only: the cascade's waves already buzzed
    end
    R.award_kudos = kudos

    function R.finish_wave()
        snapshot()
        local old_score = R.g.score
        rules.game_apply(R.g, R.pending)
        if R.update_bonus_charges then R.update_bonus_charges() end
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

    -- `blocked`: the far cell cannot move, so only the incoming piece slides,
    -- halfway to it and back.
    local function reject_swap(blocked)
        R.phase, R.phase_time, R.reject_blocked = PH_REJECT, 0, blocked
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
        elseif not g.won and not g.lost and cell_active(g, a) and cell_active(g, b) and hex_distance(a, b) == 1
            and (locked(g, a) or g.tiles[a].kind ~= -1) and (locked(g, b) or g.tiles[b].kind ~= -1) then
            -- A chain, ice or a carved stone holds one of the two. A free piece
            -- slides to the blocker and back; a held one only refuses. A hole
            -- or an empty cell is no swap at all and stays silent.
            R.notice(R.locked_notice or "Ice and chains must be broken first.")
            if movable_for_swap(g, a) then
                reject_swap(true)
            else
                R.play("reject")
                haptic.play(haptic.ERROR, .5)
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
        local shuffled, from = rules.game_check_end(R.g)
        if shuffled then
            R.selected, R.tool, R.hint_a, R.hint_b = -1, -1, -1, -1
            animate_shuffle(from)
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
        if R.phase == PH_SHUFFLE then
            if R.reduced_motion or R.phase_time >= SHUFFLE_DURATION then
                R.phase, R.phase_time, R.idle_time, R.shuffle_from = PH_IDLE, 0, 0, nil
            end
        elseif R.phase == PH_SWAP and R.phase_time > .17 * speed then R.finish_wave()
        elseif R.phase == PH_REJECT and R.phase_time >= 2 * REJECT_LEG * speed then R.phase = PH_IDLE
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
    if R.phase == PH_SHUFFLE then
        local from = R.shuffle_from[i]
        if from then
            local delay = from % SHUFFLE_GROUPS * SHUFFLE_STAGGER
            local f = num.saturate((R.phase_time - delay) / SHUFFLE_FLIGHT)
            local u = ease.in_out_sine(f)
            local start = cell_pos(from) + vec2(sx, 0)
            local delta = at - start
            local bend = math.min(HEX_R * 1.9, delta:len() * .5) * (from % 2 == 0 and 1 or -1)
            local control = start:lerp(at, .5) + vec2(-delta.y, delta.x):norm():scale(bend)
            local bounds = R.BOARD_CLIP:inflate(-CELL_SIZE / 2)
            local limit = bounds:max()
            control.x = num.clamp(control.x, bounds.x, limit.x)
            control.y = num.clamp(control.y, bounds.y, limit.y)
            at = start:lerp(control, u):lerp(control:lerp(at, u), u)
            scale = 1 - .24 * math.sin(PI * f)
        end
    elseif R.phase == PH_SWAP or R.phase == PH_REJECT then
        t = R.old_tiles[i]
        local blocked = R.phase == PH_REJECT and R.reject_blocked
        if i == R.swap_a or (i == R.swap_b and not blocked) then
            local other = i == R.swap_a and R.swap_b or R.swap_a
            local leg = R.phase == PH_SWAP and .17 or REJECT_LEG * (R.reduced_motion and .35 or 1)
            local f = R.phase_time / leg
            if R.phase == PH_REJECT and f > 1 then f = 2 - f end
            at = at:lerp(cell_pos(other) + vec2(sx, 0), (blocked and .5 or 1) * ease.out_cubic(num.saturate(f)))
        end
    elseif R.phase == PH_CLEAR and R.pending.mask[i] then
        t = R.old_tiles[i]
        if ((R.wave_chain[i] == 0 and R.wave_ice[i] == 0) or g.tiles[i].kind < 0)
            then   -- a small pop, then shrink away
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
            and t == landed.tiles[i] and t.kind >= 0 then
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
