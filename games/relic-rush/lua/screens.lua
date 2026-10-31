-- screens.lua — Relic Rush's look: text palettes, panels, buttons, the header,
-- toasts and every dialog (guide, pause, results, failure, wonder card, region
-- card, finale).
--
-- Dialogs animate through a paint transform (scale, offset, opacity) applied
-- by the helpers below; hit testing always uses the untransformed layout, so
-- a dialog is clickable where it will come to rest.
local R = require("state")
local rules = require("rules")
local island = require("island")
local SCREEN_W, SCREEN_H = R.SCREEN_W, R.SCREEN_H
local PAL_GOLD, PAL_CREAM, PAL_WHITE = R.PAL_GOLD, R.PAL_CREAM, R.PAL_WHITE
local RELIC_IDOL, RELIC_LEAF, RELIC_CRYSTAL = rules.RELIC_IDOL, rules.RELIC_LEAF, rules.RELIC_CRYSTAL
local rgba = color

local P = {scale = 1, offset = vec2(0, 0), alpha = 1}
R.P = P
local function reset_paint() P.scale, P.offset, P.alpha = 1, vec2(0, 0), 1 end
local function copy_paint() return {scale = P.scale, offset = P.offset, alpha = P.alpha} end
local function set_paint(k) P.scale, P.offset, P.alpha = k.scale, k.offset, k.alpha end
R.copy_paint, R.set_paint = copy_paint, set_paint

local function pp(p) return P.offset + p:scale(P.scale) end
local function pr(r) return rect.make(pp(r:pos()), r:size():scale(P.scale)) end
local function pc(c) return color.alpha(c, P.alpha) end
R.pp, R.pr = pp, pr

function R.fill(r, c) gfx.rect(pr(r), pc(c)) end
function R.rrect(r, radius, c) gfx.round_rect(pr(r), radius * P.scale, pc(c)) end
function R.disc(center, radius, c) gfx.circle(pp(center), radius * P.scale, pc(c)) end
function R.seg(a, b, width, c) gfx.line(pp(a), pp(b), width * P.scale, pc(c)) end
function R.picture(t, r, alpha) gfx.image(t, pr(r), rgba(255, 255, 255, alpha * P.alpha)) end
function R.picture_fit(t, box, alpha)
    if t.w > 0 then R.picture(t, box:fit(texture.size(t)), alpha) end
end
local rrect, disc, picture, picture_fit = R.rrect, R.disc, R.picture, R.picture_fit

---------------------------------------------------------------------- text

-- Lilita One sizes are given in em like the original pipeline; the engine
-- measures ascent to descent, 1.17 em for this font. Every palette shares a
-- dark rim and a drop shadow cast by the rimmed silhouette.
local tops = {[0] = rgba(255, 255, 219), rgba(255, 249, 226), rgba(199, 255, 201), rgba(255, 255, 255)}
local bottoms = {[0] = rgba(239, 169, 57), rgba(244, 221, 166), rgba(91, 198, 130), rgba(196, 232, 220)}
function R.pal(palette, em)
    palette = num.clampi(palette, 0, 3)
    em = em * P.scale
    return style{font = R.font, size = em * 1.171875, fill = tops[palette], fill2 = bottoms[palette],
                 outline = rgba(62, 49, 29), outline_width = em * 4 / 64, shadow = rgba(31, 35, 24, 184),
                 shadow_offset = vec2(0, em * 5 / 64), fade = 1 - P.alpha}
end
local pal = R.pal

function R.say(s, box, em, palette) return text.inside(pal(palette, em), pr(box), vec2(.5, .5), s) end
function R.say_left(s, box, em, palette) return text.inside(pal(palette, em), pr(box), vec2(0, .5), s) end
function R.say_at(s, center, em, palette, max_width)
    local w = max_width > 0 and max_width or 2000
    return R.say(s, rect.centered(center, size2(w, em * 2)), em, palette)
end
function R.paragraph(s, box, em, palette) text.box(pal(palette, em), pr(box), vec2(.5, .5), s) end
local say, say_left, say_at = R.say, R.say_left, R.say_at

-------------------------------------------------------------------- widgets

function R.panel(r)
    rrect(r:offset(vec2(0, 6)), 18, rgba(9, 28, 26, 145))
    rrect(r, 18, rgba(102, 68, 39))
    rrect(r:inflate(-2), 16, rgba(239, 204, 135))
    rrect(r:inflate(-5), 13, rgba(255, 239, 188))
end
local panel = R.panel

function R.tapped(r) return ui.hit(r:offset(vec2(0, R.hit_dy)), 0).clicked end
local tapped = R.tapped

-- Buttons respond even when drawn disabled, so the game can explain why not.
function R.paint_button(r, st, enabled)
    local b = st.held and r:offset(vec2(0, 2)) or r
    rrect(r:offset(vec2(0, 6)), 15, rgba(13, 54, 43))
    rrect(b, 15, enabled and rgba(46, 112, 70) or rgba(75, 94, 80))
    rrect(rect(b.x + 3, b.y + 3, b.w - 6, b.h - 7), 12, enabled and rgba(113, 185, 83) or rgba(110, 126, 108))
    rrect(rect(b.x + 6, b.y + 4, b.w - 12, b.h * .4), 10, enabled and rgba(159, 213, 109) or rgba(130, 145, 125))
end
function R.button(r, label, enabled)
    local st = ui.hit(r:offset(vec2(0, R.hit_dy)), 0)
    R.paint_button(r, st, enabled)
    say(label, (st.held and r:offset(vec2(0, 2)) or r):inflate(-12), 25, PAL_CREAM)
    return st.clicked
end
local button = R.button

-- One game skin; the shared form engine owns layout, hits, focus and bindings.
local form_skin = {
    -- Measurement stays in logical units; painting applies the dialog transform.
    style = function(node)
        local em=node.em or ((node.kind=="button" or node.kind=="toggle") and 25 or node.wrap and 22 or 26)
        return style{font=R.font,size=em*1.171875}
    end,
    panel = panel,
    button = function(r, st, node) if not node.flat then R.paint_button(r, st, not st.disabled) end end,
    button_text = function(r, label, node, st)
        say(label, (st.held and r:offset(vec2(0, 2)) or r):inflate(-8), node.em or 25, PAL_CREAM)
    end,
    label = function(r, label, node)
        local align=vec2(node.text_align=='start' and 0 or node.text_align=='end' and 1 or .5,.5)
        local s=pal(node.palette or (node.wrap and PAL_CREAM or PAL_GOLD),node.em or (node.wrap and 22 or 26))
        if node.wrap then text.box(s,pr(r),align,label)
        else text.inside(s,pr(r),align,label) end
    end,
    focus = function(r) gfx.round_rect_line(pr(r:inflate(3)), 15 * P.scale, 2, pc(rgba(255, 223, 129))) end,
}

R.form_skin = form_skin

-- Two-tone gold star on a darker rim, lit from above.
function R.star_icon(center, radius)
    for layer = 0, 1 do
        local r = (radius - (layer == 1 and 2 or 0)) * P.scale
        local c = pp(center) + vec2(0, layer == 1 and 0 or 2 * P.scale)
        local rim = rgba(129, 78, 27)
        local pts, cols, idx = {c}, {pc(layer == 1 and rgba(255, 224, 100) or rim)}, {}
        for k = 0, 9 do
            local a, rr = -math.pi / 2 + k * math.pi / 5, r * (k % 2 == 1 and .46 or 1)
            pts[k + 2] = c + vec2.polar(a, rr)
            cols[k + 2] = pc(layer == 1 and (k < 5 and rgba(255, 242, 163) or rgba(225, 158, 41)) or rim)
            idx[k * 3 + 1], idx[k * 3 + 2], idx[k * 3 + 3] = 0, k + 1, (k + 1) % 10 + 1
        end
        app.mesh(pts, cols, idx)
    end
end

function R.compass_icon(center, radius)
    disc(center, radius, rgba(112, 81, 40))
    disc(center, radius - 2, rgba(255, 232, 162))
    local pts = {pp(center + vec2(0, -radius + 4)), pp(center + vec2(4, 3)), pp(center + vec2(0, radius - 4)), pp(center + vec2(-4, -3))}
    local cols = {pc(rgba(33, 114, 102)), pc(rgba(33, 114, 102)), pc(rgba(185, 92, 47)), pc(rgba(185, 92, 47))}
    app.mesh(pts, cols, {0, 1, 3, 1, 2, 3})
end
local star_icon, compass_icon = R.star_icon, R.compass_icon

--------------------------------------------------------------------- header

-- On the island the picture runs up to the status bar with a small medallion
-- in the corner; on the board the medallion sits in the HUD band beside the goals.
local function pause_button(island)
    local bounds=island and rect(414,12,52,52) or rect(406,20,52,52)
    local st=ui.hit(bounds,0)
    local state=st.held and "pressed" or st.hot and "hover" or "normal"
    picture(R.hud_art["pause-"..state],bounds,255)
    return st.clicked
end

-- A resource readout: a dark pill with a gold seam, its icon overhanging the left end.
function R.capsule(r, icon, value)
    gfx.shadow(r:offset(vec2(0, 3)), r.h * .5, 6, rgba(0, 0, 0, 90))
    gfx.round_rect(r, r.h * .5, rgba(13, 47, 41, 225))
    gfx.round_rect_line(r, r.h * .5, 1.6, rgba(233, 199, 123, 190))
    icon(vec2(r.x + 6, r:center().y), r.h * .5 + 6)
    say(value, rect(r.x + r.h * .5 + 10, r.y, r.w - r.h * .5 - 18, r.h), 18, PAL_CREAM)
    return tapped(r)
end
local capsule = R.capsule

local function relic_icon(kind)
    return function(c, radius) picture(R.relics[kind + 1], rect.centered(c, size2(radius * 2, radius * 2)), 255) end
end
local capsule_icons = {relic_icon(RELIC_IDOL), relic_icon(RELIC_LEAF), relic_icon(RELIC_CRYSTAL),
                       function(c, radius) star_icon(c, radius * .8) end, function(c, radius) compass_icon(c, radius * .72) end}
local capsule_notes = {"Gold buys buildings. Replay expeditions to earn more.", "Wood funds restorations. First wins grant the full cost.",
                       "Stone funds restorations. First wins grant the full cost.", "Discovery Stars unlock stock and land. First clears only; never spent.",
                       "Compasses are spent to open new land."}

-- The island shows its purse in two rows of capsules; tapping EXPAND opens the
-- next region. An unfinished expedition exposes only pause, never island access.
function R.draw_header(on_island)
    if on_island then
        for k = 1, 5 do
            local r = rect(34 + (k - 1) % 3 * 120, k <= 3 and 14 or 58, 96, 34)
            if capsule(r, capsule_icons[k], tostring(R.prog.wallet[k])) then R.notice(capsule_notes[k]) end
        end
        local r = rect(274, 58, 96, 34)
        gfx.shadow(r:offset(vec2(0, 3)), r.h * .5, 6, rgba(0, 0, 0, 90))
        gfx.round_rect(r, r.h * .5, rgba(47, 105, 67, 240))
        gfx.round_rect_line(r, r.h * .5, 1.6, rgba(233, 199, 123, 190))
        say("EXPAND +", r:inflate2(vec2(-10, 0)), 15, PAL_CREAM)
        if tapped(r) then R.expand() end
    end
    if pause_button(island) then R.overlay = R.OV_PAUSE end
end

function R.draw_toast()
    if R.toast_time <= 0 or R.overlay ~= R.OV_NONE then return end
    if R.on_island then   -- above the map buttons
        rrect(rect(18, 663 + R.drop, 444, 30), 11, rgba(10, 37, 31, 235))
        say_at(R.toast, vec2(240, 677 + R.drop), 14, PAL_CREAM, 424)
    else   -- just below the HUD band, above the board
        rrect(rect(38, 112, 404, 30), 11, rgba(10, 37, 31, 235))
        say_at(R.toast, vec2(240, 127), 14, PAL_CREAM, 388)
    end
end

-------------------------------------------------------------------- dialogs

local function result_rects()
    local w, s = math.min(408, SCREEN_W - 48), math.min(1, (SCREEN_H - 100) / 556)
    local x, y = (SCREEN_W - w) / 2, (SCREEN_H - 556 * s) / 2 + 8
    return {card = rect(x, y, w, 556 * s), header = rect(x + 22, y - 26 * s, w - 44, 74 * s), stars = rect(x + 70, y + 70 * s, w - 140, 64 * s),
            score_label = rect(x + 66, y + 140 * s, w - 132, 20 * s), score = rect(x + 60, y + 163 * s, w - 120, 53 * s),
            treasure_label = rect(x + 30, y + 217 * s, w - 60, 20 * s), rewards = rect(x + 22, y + 243 * s, w - 44, 91 * s),
            progress = rect(x + 44, y + 349 * s, w - 88, 36 * s), next = rect(x + 28, y + 397 * s, w - 56, 65 * s),
            claim = rect(x + 40, y + 480 * s, w - 80, 56 * s)}
end


-- Fade and lift a part of a dialog in after `delay`; returns the paint to restore.
local function section(delay, duration, rise)
    local old = copy_paint()
    local f = R.reduced_motion and 1 or ease.out_cubic((R.modal_clock - delay) / duration)
    P.alpha = P.alpha * f
    P.offset = P.offset + vec2(0, rise * (1 - f) * P.scale)
    return old
end

local function result_screen()
    local l = result_rects()
    local w = R.wonders[R.g.level + 1]
    local breakdown = rules.reward_breakdown(R.g,R.wonders,R.prog)
    local reward = breakdown.total
    local s
    panel(l.card)
    rrect(l.header:offset(vec2(0, 5)), 18, rgba(77, 58, 31))
    rrect(l.header, 18, rgba(31, 83, 69))
    rrect(l.header:inflate(-3), 15, rgba(44, 108, 84))
    say(breakdown.first and "Expedition complete" or "Replay complete", rect(l.header.x + 14, l.header.y + 9, l.header.w - 28, 34), 31, PAL_GOLD)
    say(("LEVEL %d  -  WELL EXPLORED"):format(R.g.level + 1), rect(l.header.x + 12, l.header.y + 48, l.header.w - 24, 15), 14, PAL_GOLD)
    for k = 0, breakdown.first and 2 or -1 do
        local slot = l.stars:col(3, k, 8)
        s = section(.24 + k * .13, .32, 13)
        local t = R.reduced_motion and 1 or num.saturate((R.modal_clock - .24 - k * .13) / .32)
        local pop = 1 + math.sin(t * math.pi) * .14
        R.vfx_halo(pp(slot:center()), 45 * P.scale, rgba(255, 201, 77, 65 * P.alpha))
        star_icon(slot:center(), (k == 1 and 29 or 24) * pop)
        set_paint(s)
    end
    if not breakdown.first then say("GOLD FOR YOUR ISLAND",l.stars,23,PAL_GOLD) end
    s = section(.43, .3, 9)
    say("EXPEDITION SCORE", l.score_label, 12, PAL_CREAM)
    local count = R.reduced_motion and 1 or ease.out_cubic((R.modal_clock - .43) / .65)
    say(tostring(math.floor(R.g.score * count + .5)), l.score, 46, PAL_GOLD)
    set_paint(s)
    s = section(.62, .25, 8)
    say(breakdown.first and "RESTORATION GRANT + SPARE GOLD" or "REPLAYS AWARD GOLD ONLY", l.treasure_label, 12, PAL_CREAM)
    set_paint(s)
    local kinds = {RELIC_IDOL, RELIC_LEAF, RELIC_CRYSTAL}
    local columns=breakdown.first and 3 or 1
    for k = 0, columns-1 do
        local r = l.rewards:col(columns, k, 10)
        s = section(.66 + k * .1, .28, 10)
        rrect(r, 12, rgba(241, 218, 157))
        rrect(r:inflate(-2), 10, rgba(255, 242, 201))
        picture_fit(R.relics[kinds[k + 1] + 1], rect(r.x + (r.w - 40) / 2, r.y + 8, 40, 40), 255)
        say(("+%d"):format(reward[k + 1]), rect(r.x + 6, r.y + 56, r.w - 12, 26), 26, PAL_GOLD)
        set_paint(s)
    end
    say(breakdown.first and ("%d restoration Gold + %d spendable"):format(breakdown.grant[1],breakdown.base+breakdown.bonus) or
        ("%d base Gold + %d move bonus"):format(breakdown.base,breakdown.bonus),
        rect(l.rewards.x,l.rewards.y+l.rewards.h+2,l.rewards.w,15),13,PAL_CREAM)
    s = section(.93, .24, 8)
    for k = 0, breakdown.first and 1 or -1 do
        local r = l.progress:col(2, k, 12)
        rrect(r, 16, rgba(221, 228, 182))
        local icon = vec2(r.x + 20, r:center().y)
        if k == 1 then compass_icon(icon, 12) else star_icon(icon, 11) end
        local value=reward[k==1 and rules.COMPASSES or rules.STARS]
        say(("+%d %s"):format(value,k==1 and (value==1 and "Compass" or "Compasses") or "Stars"), rect(r.x + 38, r.y, r.w - 44, r.h), 16, PAL_CREAM)
    end
    if not breakdown.first then say("DISCOVERY REWARDS ARE FIRST-CLEAR ONLY",l.progress,13,PAL_CREAM) end
    set_paint(s)
    s = section(1.01, .26, 8)
    rrect(l.next, 12, rgba(240, 225, 180))
    picture_fit(w.sprite, rect(l.next.x + 8, l.next.y + 5, 60, l.next.h - 10), 255)
    say_left(breakdown.first and "READY TO RESTORE" or "BUILD SHOP", rect(l.next.x + 78, l.next.y + 9, l.next.w - 88, 18), 11, PAL_CREAM)
    say_left(breakdown.first and w.name or "Choose your next treasure", rect(l.next.x + 78, l.next.y + 32, l.next.w - 88, 24), 22, PAL_GOLD)
    set_paint(s)
    s = section(1.12, .22, 8)
    if button(l.claim, "COLLECT & RETURN", not R.modal_closing) and not R.modal_closing then
        if not R.reduced_motion and R.modal_clock < 1.25 then R.modal_clock = 1.5   -- first tap fast-forwards
        else R.modal_closing, R.modal_exit = true, 0 end
    end
    set_paint(s)
end

local wonder_form = ui.form{
    root = {kind="column", panel=true, padding={24,20,24,13}, children={
        {kind="label", id="name", height=44, em=34},
        {kind="spacer", height=19},
        {kind="image", id="sprite", height=205},
        {kind="spacer", height=18},
        {kind="label", id="about", height=62, wrap=true, em=22, palette=PAL_CREAM},
        {kind="spacer", height=14},
        {kind="row", height=78, padding={16,0,16,0}, gap=10, visible_field="can_build", children={
            {kind="column", grow=1, gap=9, children={{kind="image",id="gold_icon",height=34},{kind="label",id="gold",height=28}}},
            {kind="column", grow=1, gap=9, children={{kind="image",id="wood_icon",height=34},{kind="label",id="wood",height=28}}},
            {kind="column", grow=1, gap=9, children={{kind="image",id="stone_icon",height=34},{kind="label",id="stone",height=28}}},
        }},
        {kind="label",id="notice",height=78,wrap=true,em=15,palette=PAL_CREAM,visible_field="show_notice"},
        {kind="spacer",height=18},
        {kind="button",id="action",height=56},
        {kind="spacer",height=17},
        {kind="button",id="close",text="CLOSE",height=28,flat=true,em=16},
    }},
    bindings={
        {id="name",field="name",readonly=true},{id="sprite",field="sprite",type="texture",readonly=true},
        {id="about",field="about",readonly=true},{id="action",field="action",readonly=true},
        {id="gold",field="cost.1",type="integer",readonly=true},
        {id="wood",field="cost.2",type="integer",readonly=true},
        {id="stone",field="cost.3",type="integer",readonly=true},
    },
}
local function wonder_screen()
    local i = R.inspect >= 0 and R.inspect or island.wonder_count(R.island)
    if i < 0 or i >= #R.buildings then return end
    local w = R.buildings[i + 1]
    local can_build, built = island.can_buy(R.island,R.prog.wallet,R.prog.level,i), R.inspect_item and R.inspect_item>=0
    local ok, message = wonder_form:push{name=w.name, sprite=w.sprite, about=w.about,
        cost={w.cost[1],w.cost[2],w.cost[3]}, action=built and "MOVE THIS BUILDING" or can_build and "CHOOSE A LOCATION" or "BACK TO ISLAND"}
    assert(ok,message)
    wonder_form:set("gold_icon",R.relics[RELIC_IDOL+1]):set("wood_icon",R.relics[RELIC_LEAF+1]):set("stone_icon",R.relics[RELIC_CRYSTAL+1])
    wonder_form.values.can_build, wonder_form.values.show_notice = can_build and not built, built or not can_build
    wonder_form:set("notice",built and "HOLD AND DRAG ON THE ISLAND TO MOVE" or "COMPLETE MORE LEVELS TO RESTORE THIS WONDER")
    local bounds=rect.centered(vec2(240,450),size2(math.min(420,SCREEN_W-48),592))
    R.modal_bounds=pr(bounds)
    local event = wonder_form:draw(bounds,form_skin,{hit_offset=vec2(0,R.hit_dy)})
    if event and event.id == "action" then
        if can_build or built then R.island_begin(i,true,built and R.inspect_item or nil) else R.overlay=R.OV_NONE end
    elseif event and event.id == "close" then R.overlay=R.OV_NONE end
end
R.wonder_form=wonder_form

-- One data source and one row resource; the engine measures and stacks every
-- row. Composite icon painting uses the same authored layers as the board.
local guide_entries = {
    {id="neighbors", title="Connect 4+ neighbors", description="Bends and diamonds count. Three do not.",
     icon={tiles={{kind=0,special=rules.NORMAL}}}},
    {id="lightning", title="Group 5: lightning", description="A sun ray follows the longest axis.",
     icon={tiles={{kind=1,special=rules.ROW}}}},
    {id="specials", title="Group 6+: bomb or prism", description="Six in a line: prism. Other shapes: bomb.",
     icon={tiles={{kind=2,special=rules.BOMB,x=-16,scale=.7},{kind=2,special=rules.PRISM,x=16,scale=.7}}}},
    {id="blockers", title="Chains & ancient sand", description="Match on them to break or excavate.",
     icon={back="sand",front="chain",tiles={{kind=3,special=rules.NORMAL}}}},
    {id="ice", title="Ice & fire", description="Match on ice; nearby flames also thaw it.",
     icon={front="ice-2",tiles={{kind=4,special=rules.NORMAL}}}},
}
local function guide_icon(box, icon)
    local at=box:center()
    local layer=rect.centered(at,size2(52,52))
    if icon.back then picture(R.board_art[icon.back],layer,255) end
    for _,tile in ipairs(icon.tiles) do
        R.draw_relic(rules.tile(tile.kind,tile.special),pp(at+vec2(tile.x or 0,0)),P.scale*(tile.scale or 1),255*P.alpha,1)
    end
    if icon.front then picture(R.board_art[icon.front],layer:inflate(-2),255) end
end
local guide_form=ui.form{kind="column",panel=true,padding=20,children={
    {kind="label",text="Explorer's guide",height=44,em=34},
    {kind="label",text="SWIPE OR TAP TWO NEIGHBORING RELICS",height=26,em=13,palette=PAL_WHITE},
    {kind="spacer",height=14},
    {kind="list",id="topics",gap=12,item=function(entry)
        local align=entry.icon and "start" or "center"
        return {kind="row",gap=14,align="center",children={
            {kind="custom",width=64,height=64,visible=entry.icon~=nil,paint=function(r) guide_icon(r,entry.icon) end},
            {kind="column",grow=1,gap=4,children={
                {kind="label",text=entry.title,wrap=true,text_align=align,em=22,palette=PAL_GOLD},
                {kind="label",text=entry.description,wrap=true,text_align=align,em=16,palette=PAL_CREAM},
            }},
        }}
    end},
    {kind="spacer",height=18},
    {kind="label",text="TOOLS DO NOT COST MOVES. TAP ONE, THEN A TILE.",height=28,em=12,palette=PAL_WHITE},
    {kind="spacer",height=10},
    {kind="button",id="done",text="LET'S EXPLORE",height=45,em=25},
}}
assert(guide_form:set_items("topics",guide_entries))
R.guide_form=guide_form -- measured control bounds are also used by the input smoke test
local function guide_screen()
    local width=432
    local _,height=guide_form:measure(width,form_skin)
    local bounds=rect.centered(vec2(240,460),size2(width,height))
    R.modal_bounds=pr(bounds)
    local action=guide_form:draw(bounds,form_skin,{hit_offset=vec2(0,R.hit_dy)})
    if action and action.id=="done" then R.overlay=R.OV_NONE end
end

local pause_form = ui.form{
    root={kind="column",panel=true,padding={46,20,46,35},gap=20,children={
        {kind="label",text="Take a breath",height=44,em=34},
        {kind="label",id="level",height=30,em=16,palette=PAL_CREAM},
        {kind="button",id="resume",text="RESUME",height=49},
        {kind="toggle",id="sound",on_text="SOUND ON",off_text="SOUND OFF",height=49},
        {kind="toggle",id="motion",on_text="MOTION REDUCED",off_text="FULL ANIMATION",height=49},
        {kind="button",id="guide",text="EXPLORER'S GUIDE",height=49},
    }},
    bindings={{id="sound",field="sound",type="boolean"},{id="motion",field="reduced_motion",type="boolean"}},
}
local function pause_screen()
    local ok,message=pause_form:push(R);assert(ok,message)
    pause_form:set("level",R.on_island and "Your valley" or ("%d. %s"):format(R.g.level+1,rules.level_of(R.g).name))
    local bounds=rect(42,227,396,432)
    R.modal_bounds=pr(bounds)
    local event=pause_form:draw(bounds,form_skin,{hit_offset=vec2(0,R.hit_dy)})
    if not event then return end
    if event.kind=="change" then
        ok,message=pause_form:pull(R);assert(ok,message);sfx.enable(R.sound)
    elseif event.id=="resume" then R.overlay=R.OV_NONE
    elseif event.id=="guide" then R.overlay=R.OV_GUIDE end
end
R.pause_form=pause_form

local function failed_screen()
    panel(rect(38, 272, 404, 333))
    say_at("One more adventure?", vec2(240, 317), 32, PAL_GOLD, 0)
    say_at("THE RUINS WILL WAIT FOR YOU.", vec2(240, 366), 16, PAL_WHITE, 0)
    say_at("Try a special combo or use a tool.", vec2(240, 404), 17, PAL_CREAM, 0)
    if button(rect(83, 448, 314, 50), "TRY AGAIN", true) then R.start_level(R.g.level) end
    if button(rect(115, 520, 250, 42), "VISIT ISLAND", true) then R.on_island, R.overlay = true, R.OV_NONE end
end

local function zone_screen()
    local z = R.zone_card
    local zone = R.island.zones[z + 1]
    local ready = R.island:zone_available(z, R.prog.wallet)
    R.modal_bounds=pr(rect(30,263,420,365))
    panel(rect(30, 263, 420, 365))
    say_at(zone.name, vec2(240, 304), 34, PAL_GOLD, 380)
    say_at("A NEW PLACE TO DISCOVER", vec2(240, 349), 16, PAL_CREAM, 0)
    say_at(("STARS  %d / %d"):format(R.prog.wallet[rules.STARS], zone.needs[rules.STARS]), vec2(240, 397), 24, PAL_GOLD, 0)
    say_at(("COMPASSES  %d / %d"):format(R.prog.wallet[rules.COMPASSES], zone.cost[rules.COMPASSES]), vec2(240, 441), 23, PAL_CREAM, 0)
    if button(rect(72, 487, 336, 47), ready and "OPEN THIS AREA" or "KEEP EXPLORING", true) then
        if R.island:unlock(z, R.prog.wallet) then
            R.island_focus(zone.marker, R.island.cam.zoom)
            R.save_progress()
            story.add({"mara", "New land is yours. Make it your own!", story.SHOUT})
            R.tone(820)
        end
        R.overlay = R.OV_NONE
    end
    say_at("COMPASSES ARE SPENT. STARS STAY WITH YOU.", vec2(240, 559), 12, PAL_WHITE, 0)
    say_at("CLOSE", vec2(240, 592), 15, PAL_WHITE, 0)
    if tapped(rect(180,575,120,38)) then R.overlay = R.OV_NONE end
end

local function finale_screen()
    panel(rect(32, 285, 416, 305))
    say_at("The valley lives again", vec2(240, 330), 31, PAL_GOLD, 0)
    say_at("YOU RESTORED ALL TEN WONDERS.", vec2(240, 386), 16, PAL_WHITE, 0)
    say_at("THANK YOU FOR EXPLORING.", vec2(240, 422), 16, PAL_WHITE, 0)
    if button(rect(82, 489, 316, 50), "BACK TO MY ISLAND", true) then R.overlay = R.OV_NONE end
end

local dialogs = {[R.OV_GUIDE] = guide_screen, [R.OV_PAUSE] = pause_screen, [R.OV_RESULT] = result_screen, [R.OV_FAILED] = failed_screen,
                 [R.OV_WONDER] = wonder_screen, [R.OV_ZONE] = zone_screen, [R.OV_FINALE] = finale_screen}

-- Draws the open dialog over everything; it alone receives input.
function R.overlays(dt)
    if R.overlay ~= R.modal_for then   -- a new dialog starts its entrance
        R.modal_for = R.overlay
        R.modal_clock, R.modal_exit = 0, 0
        R.modal_closing = false
    end
    if R.overlay == R.OV_NONE then return end
    if R.overlay == R.OV_SHOP then R.draw_catalogue(dt); return end
    if R.overlay == R.OV_EXPEDITIONS then R.draw_expeditions(dt); return end
    R.modal_clock = R.modal_clock + dt
    if R.modal_closing then
        R.modal_exit = R.modal_exit + dt
        if R.modal_exit >= .2 or R.reduced_motion then
            R.modal_closing = false
            R.claim_reward()
            R.modal_for = R.overlay
            return
        end
    end
    local entry = R.reduced_motion and 1 or ease.out_cubic(R.modal_clock / .28)
    local exit = R.modal_closing and ease.out_cubic(R.modal_exit / .2) or 0
    ui.modal_layer(7 * entry * (1 - exit), rgba(5, 22, 22, 185 * entry * (1 - exit)))
    local scale = .96 + .04 * entry
    -- dialogs are laid out on the 900-tall design: centre them on a taller screen
    R.hit_dy = R.drop / 2
    P.scale, P.offset, P.alpha = scale, vec2(240 * (1 - scale), 450 * (1 - scale) + 22 * (1 - entry) + 18 * exit + R.hit_dy), entry * (1 - exit)
    local before=R.overlay
    R.modal_bounds=nil
    local draw = dialogs[R.overlay]
    if draw then draw() end
    if R.overlay==before and R.modal_bounds and not R.modal_closing
            and ui.modal_dismiss(R.modal_bounds,{fresh=R.modal_clock<=dt}) then R.overlay=R.OV_NONE end
    reset_paint()
    R.hit_dy = 0
end

return R
