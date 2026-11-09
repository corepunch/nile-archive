-- screens.lua — Relic Rush's art in the shared dialogs: the results card, the
-- guide's rows and icons, and the wallet and town icons. The dialogs, their
-- motion, the paint helpers and every other popup are the engine's
-- (engine/match3_game.lua); words are data/game.json.
local R = require("match3.game").bind(require("state"))
local match3 = require("match3")
local rules = require("rules")
local SCREEN_W, SCREEN_H = R.SCREEN_W, R.SCREEN_H
local PAL_GOLD, PAL_CREAM = R.PAL_GOLD, R.PAL_CREAM
local RELIC_IDOL, RELIC_LEAF, RELIC_CRYSTAL = rules.RELIC_IDOL, rules.RELIC_LEAF, rules.RELIC_CRYSTAL
local rgba = color
local P, pp, pc = R.P, R.pp, R.pc
local rrect, disc, picture, picture_fit = R.rrect, R.disc, R.picture, R.picture_fit
local say, say_left, button, panel = R.say, R.say_left, R.button, R.panel
local set_paint, section = R.set_paint, R.section

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
local star_icon = R.star_icon

-- One prominent medallion and matching touch area on the town and board.
function R.wallet_icons()
    return {R.life_art, R.relics[RELIC_IDOL + 1], function(box) star_icon(box:center(), box.w * .45) end}
end
function R.town_middle_icon(at) R.compass_icon(at, 17) end

local function result_screen()
    local l = match3.result_rects(SCREEN_W, SCREEN_H)
    local kind=rules.wonder_at(R.g.level+1)
    local w=kind and R.wonders[kind]
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
        local part
        s, part = section(.24 + k * .13, .32, 13)
        local pop = 1 + math.sin(part.u * math.pi) * .14
        R.vfx_halo(pp(slot:center()), 45 * P.scale, rgba(255, 201, 77, 65 * P.alpha))
        star_icon(slot:center(), (k == 1 and 29 or 24) * pop)
        set_paint(s)
    end
    if not breakdown.first then say("AMULETS FOR YOUR ISLAND",l.stars,23,PAL_GOLD) end
    s = section(.43, .3, 9)
    say("EXPEDITION SCORE", l.score_label, 12, PAL_CREAM)
    local count = R.dialog_part(.43, .65).f   -- the score counts up
    say(tostring(math.floor(R.g.score * count + .5)), l.score, 46, PAL_GOLD)
    set_paint(s)
    s = section(.62, .25, 8)
    say(breakdown.first and "RESTORATION GRANT + SPARE AMULETS" or "REPLAYS AWARD AMULETS ONLY", l.treasure_label, 12, PAL_CREAM)
    set_paint(s)
    local kinds = {RELIC_IDOL, RELIC_LEAF, RELIC_CRYSTAL}
    local columns=1
    for k = 0, columns-1 do
        local r = l.rewards:col(columns, k, 10)
        s = section(.66 + k * .1, .28, 10)
        rrect(r, 12, rgba(241, 218, 157))
        rrect(r:inflate(-2), 10, rgba(255, 242, 201))
        picture_fit(R.relics[kinds[k + 1] + 1], rect(r.x + (r.w - 40) / 2, r.y + 8, 40, 40), 255)
        say(("+%d"):format(reward[k + 1]), rect(r.x + 6, r.y + 56, r.w - 12, 26), 26, PAL_GOLD)
        set_paint(s)
    end
    say(breakdown.first and ("%d restoration Amulets + %d spendable"):format(breakdown.grant[1],breakdown.base+breakdown.bonus) or
        ("%d base Amulets + %d move bonus"):format(breakdown.base,breakdown.bonus),
        rect(l.rewards.x,l.rewards.y+l.rewards.h+2,l.rewards.w,15),13,PAL_CREAM)
    s = section(.93, .24, 8)
    if breakdown.first then
        local r=l.progress
        rrect(r,16,rgba(221,228,182));star_icon(vec2(r.x+24,r:center().y),14)
        say("+3 DISCOVERY STARS",rect(r.x+44,r.y,r.w-52,r.h),18,PAL_CREAM)
    end
    if not breakdown.first then say("DISCOVERY REWARDS ARE FIRST-CLEAR ONLY",l.progress,13,PAL_CREAM) end
    set_paint(s)
    s = section(1.01, .26, 8)
    rrect(l.next, 12, rgba(240, 225, 180))
    if w then picture_fit(w.sprite, rect(l.next.x + 8, l.next.y + 5, 60, l.next.h - 10), 255)
    else star_icon(vec2(l.next.x+38,l.next:center().y),24) end
    say_left(breakdown.first and (w and "READY TO RESTORE" or "THE INVESTIGATION CONTINUES") or "BUILD SHOP", rect(l.next.x + 78, l.next.y + 9, l.next.w - 88, 18), 11, PAL_CREAM)
    say_left(breakdown.first and (w and w.name or "Return for the next clue") or "Choose your next treasure", rect(l.next.x + 78, l.next.y + 32, l.next.w - 88, 24), 22, PAL_GOLD)
    set_paint(s)
    s = section(1.12, .22, 8)
    if button(l.claim, "COLLECT & RETURN", not R.modal_closing) and not R.modal_closing then
        if not R.dialog_settled() then R.dialog_skip()   -- first tap fast-forwards
        else R.close_dialog() end
    end
    set_paint(s)
end
R.dialogs[R.OV_RESULT] = result_screen

-- One data source and one row resource; the engine measures and stacks every
-- row. Composite icon painting uses the same authored layers as the board.
local guide_entries = {
    {id="neighbors", title="Line up 3+ relics", description="Match straight lines along any of three axes.",
     icon={tiles={{kind=0,special=rules.NORMAL}}}},
    {id="lightning", title="Line of 4: lightning", description="Stripes show the line it clears.",
     icon={tiles={{kind=1,special=rules.ROW}}}},
    {id="specials", title="Line of 5+: sun prism", description="Swap a prism with a relic to clear its color.",
     icon={tiles={{kind=2,special=rules.PRISM}}}},
    {id="blockers", title="Chains & ancient sand", description="Match on them to break or excavate.",
     icon={back="sand",front="chain",tiles={{kind=3,special=rules.NORMAL}}}},
    {id="ice", title="Frozen gems", description="Ice rims the cell. The number shows hits left; matches and nearby fire thaw it.",
     icon={front="ice-2",tiles={{kind=4,special=rules.NORMAL}}}},
}
local function guide_icon(box, icon)
    local at=box:center()
    local layer=rect.centered(at,size2(52,52))
    if icon.back then
        local edge = R.board_art[icon.back .. "-edge"]
        picture(edge or R.board_art[icon.back],edge and layer:inflate(4) or layer,255)
    end
    for _,tile in ipairs(icon.tiles) do
        R.draw_relic(rules.tile(tile.kind,tile.special),pp(at+vec2(tile.x or 0,0)),P.scale*(tile.scale or 1),255*P.alpha,1)
    end
    if icon.front and icon.front:sub(1,4)=="ice-" then
        R.draw_ice(tonumber(icon.front:sub(5)),pp(at),P.scale,P.alpha)
    elseif icon.front then picture(R.board_art[icon.front],layer:inflate(-2),255) end
end
local guide_form = match3.guide_form({
    title = "Explorer's guide", instructions = "SWIPE OR TAP TWO NEIGHBORING RELICS",
    done = "LET'S EXPLORE",
}, guide_icon)
assert(guide_form:set_items("topics",guide_entries))
R.guide_form=guide_form -- measured control bounds are also used by the input smoke test
local function guide_screen() match3.draw_guide(R, guide_form) end
R.dialogs[R.OV_GUIDE] = guide_screen

return R
