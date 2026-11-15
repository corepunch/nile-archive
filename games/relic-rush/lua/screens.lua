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

local function star_icon(center, side)
    picture(R.board_art["discovery-star"], rect.centered(center, size2.splat(side)), 255)
end

function R.compass_icon(center, radius)
    disc(center, radius, rgba(112, 81, 40))
    disc(center, radius - 2, rgba(255, 232, 162))
    local pts = {pp(center + vec2(0, -radius + 4)), pp(center + vec2(4, 3)), pp(center + vec2(0, radius - 4)), pp(center + vec2(-4, -3))}
    local cols = {pc(rgba(33, 114, 102)), pc(rgba(33, 114, 102)), pc(rgba(185, 92, 47)), pc(rgba(185, 92, 47))}
    app.mesh(pts, cols, {0, 1, 3, 1, 2, 3})
end

-- Art for the island wallet's three capsules.
function R.wallet_icons()
    return {R.life_art, R.relics[RELIC_IDOL + 1], R.board_art["discovery-star"]}
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
        local center = slot:center() + vec2(0, k == 1 and -4 or 2)
        star_icon(center, (k == 1 and 68 or 54) * pop)
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
        local r = l.progress
        rrect(r, 16, rgba(221,228,182))
        star_icon(vec2(r.x + 24, r:center().y), 30)
        say("+3 DISCOVERY STARS",rect(r.x+44,r.y,r.w-52,r.h),18,PAL_CREAM)
    end
    if not breakdown.first then say("DISCOVERY REWARDS ARE FIRST-CLEAR ONLY",l.progress,13,PAL_CREAM) end
    set_paint(s)
    s = section(1.01, .26, 8)
    rrect(l.next, 12, rgba(240, 225, 180))
    local next_icon = rect(l.next.x + 8, l.next.y + 5, 60, l.next.h - 10)
    if breakdown.first and w then
        picture_fit(w.sprite, next_icon, 255)
    elseif breakdown.first then
        picture_fit(R.board_art["next-clue"], next_icon, 255)
    else
        R.skin:paint_button(next_icon, nil, {role = "navigation_build"})
    end
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

-- The quest object a first clear recovers, big on its own card before the
-- story beat that talks about it (engine: R.award_for, R.OV_AWARD).
function R.award_for(g)
    local object = rules.levels[g.level + 1].quest_object
    local art = R.board_art or {}   -- window-free tests play the campaign without art
    return object and {image = art["find-" .. object.key], name = object.name, level = g.level + 1}
end

local function award_screen()
    local a = R.award
    local w, h = 408, 452
    local x, y = (SCREEN_W - w) / 2, (SCREEN_H - h) / 2 + 8
    local card = rect(x, y, w, h)
    panel(card)
    local header = rect(x + 22, y - 26, w - 44, 74)
    rrect(header:offset(vec2(0, 5)), 18, rgba(77, 58, 31))
    rrect(header, 18, rgba(31, 83, 69))
    rrect(header:inflate(-3), 15, rgba(44, 108, 84))
    say("Item recovered!", rect(header.x + 14, header.y + 9, header.w - 28, 34), 31, PAL_GOLD)
    say(("EXPEDITION %d"):format(a.level), rect(header.x + 12, header.y + 48, header.w - 24, 15), 14, PAL_GOLD)
    local at = vec2(SCREEN_W / 2, y + 196)
    local s, part = section(.1, .45, 0)
    local pop = 1 + math.sin(part.u * math.pi) * .12
    R.vfx_halo(pp(at), 150 * P.scale, rgba(255, 201, 77, 110 * P.alpha))
    R.vfx_halo(pp(at), 95 * P.scale, rgba(255, 236, 170, 90 * P.alpha))
    picture_fit(a.image, rect.centered(at, size2.splat(210 * pop * part.f)), 255)
    set_paint(s)
    s = section(.4, .3, 10)
    say(a.name, rect(x + 20, y + 312, w - 40, 42), 36, PAL_GOLD)
    say("FOR YOUR QUEST", rect(x + 20, y + 354, w - 40, 18), 13, PAL_CREAM)
    set_paint(s)
    s = section(.55, .25, 8)
    R.award_continue = rect(x + 40, y + 380, w - 80, 56)   -- the smoke taps it
    if button(R.award_continue, "CONTINUE", true) then
        if not R.dialog_settled() then R.dialog_skip()   -- first tap fast-forwards
        else R.overlay = R.OV_RESULT end
    end
    set_paint(s)
end
R.dialogs[R.OV_AWARD] = award_screen

-- One data source and one row resource; the engine measures and stacks every
-- row. Composite icon painting uses the same authored layers as the board.
local guide_entries = {
    {id="neighbors", title="Line up 3+ pieces", description="Match straight lines along any of three axes.",
     icon={tiles={{kind=0,special=rules.NORMAL}}}},
    {id="lightning", title="Line of 4: rocket", description="A multicolor rocket clears its axis. Tap it or swap it to launch.",
     icon={tiles={{kind=1,special=rules.ROW}}}},
    {id="specials", title="Line of 5+: rainbow ball", description="Swap with a piece to clear its color; combine with a power-up to multiply it.",
     icon={tiles={{kind=2,special=rules.PRISM}}}},
    {id="plane", title="Four-cell rhombus: plane", description="Clears neighboring cells, then flies to a target. Two planes launch three flights.",
     icon={tiles={{kind=0,special=rules.PLANE}}}},
    {id="bomb", title="Crossing lines: bomb", description="Blasts the surrounding cells. Combine power-ups for larger effects.",
     icon={tiles={{kind=0,special=rules.BOMB}}}},
    {id="blockers", title="Chains and lashings", description="Match the held piece to break its lock.",
     icon={front="chain",tiles={{kind=3,special=rules.NORMAL}}}},
    {id="ice", title="Salt crust and other covers", description="Match the held piece or hit it with a power-up. One layer per hit.",
     icon={cover="salt-crust",tiles={{kind=4,special=rules.NORMAL}}}},
    {id="stones", title="Carved stone", description="Match beside a stone or hit it with a power-up to break it.",
     icon={front="stone-1",tiles={}}},
    {id="deliveries", title="Tablets and plates", description="Clear the cells below a tablet or plate so it falls to its exit.",
     icon={front="delivery",tiles={}}},
    {id="carpet", title="Sweep sand", description="Include cleared stone in a match to sweep sand from the other cells it hits.",
     icon={front="drift-sand",tiles={}}},
    {id="oil", title="Spreading silt and mud", description="Match over silt or mud to clear it. If a move clears none, it spreads to a neighbouring cell.",
     icon={front="goal-oil",tiles={}}},
    {id="finds", title="Buried finds", description="Match on the sand, mud or silt over a find to uncover it. This ground does not spread.",
     icon={front="lens",tiles={}}},
}
local function guide_icon(box, icon)
    local at=box:center()
    local layer=rect.centered(at,size2(48,48))
    if icon.front=="chain" then R.draw_ground("face",pp(at),layer.w * P.scale * .5,0,P.alpha) end
    for _,tile in ipairs(icon.tiles) do
        R.draw_relic(rules.tile(tile.kind,tile.special),pp(at+vec2(tile.x or 0,0)),P.scale*(tile.scale or 1),255*P.alpha,1)
    end
    if icon.cover then
        R.draw_cover(icon.cover,2,pp(at),P.scale,P.alpha)
    elseif icon.front then picture(R.board_art[icon.front],layer,255) end
end
local guide_form = match3.guide_form({
    title = "Explorer's guide", instructions = "SWIPE OR TAP TWO NEIGHBORING RELICS",
    done = "LET'S EXPLORE",
}, guide_icon)
assert(guide_form:set_items("topics",guide_entries))
R.guide_form,R.guide_entries=guide_form,guide_entries -- measured bounds and the source rows are checked by the input smoke test
local function guide_screen() match3.draw_guide(R, guide_form) end
R.dialogs[R.OV_GUIDE] = guide_screen

return R
