-- screens.lua — Relic Rush's art in the shared dialogs: the results card, the
-- guide's rows and icons, and the wallet and town icons. The dialogs, their
-- motion, the paint helpers and every other popup are the engine's
-- (engine/match3_game.lua); words are data/game.json.
local R = require("match3.game").bind(require("state"))
local match3 = require("match3")
local rules = require("rules")
local economy = require("economy")
local art = require("art")
local wallet_art = art.wallet_icons
local island = require("island")
local journey = require("journey")
local SCREEN_W, SCREEN_H = R.SCREEN_W, R.SCREEN_H
local PAL_GOLD, PAL_CREAM = R.PAL_GOLD, R.PAL_CREAM
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

local function currency_icon(slot)
    return R.board_art["resource-" .. wallet_art[economy.currencies[slot].key]]
end

function R.wallet_icons()
    return {R.life_art, currency_icon(rules.GOLD), R.board_art["discovery-star"]}
end

function R.currency_capsules(balance)
    local out = {}
    local earned = not R.on_island and R.g and not R.g.lost and not R.g.reward_claimed and R.g.earnings
    for i, slot in ipairs(economy.currency_order) do
        local currency = economy.currencies[slot]
        local pending = earned and earned[slot] or 0
        out[i] = {slot=slot, icon=currency_icon(slot), value=tostring(balance[slot] + pending), width=90,
            note=earned and (currency.name .. " from matches is banked on a win.")
                or (currency.name .. " earned from matches. Spend it on the island.")}
    end
    return out
end

function R.currency_prices(cost)
    local parts = economy.price_parts(cost)
    for _, part in ipairs(parts) do part.id, part.icon = part.name, currency_icon(part.slot) end
    return parts
end

function R.cost_text(parts)
    local amounts = {}
    for i, part in ipairs(parts) do amounts[i] = ("%d %s"):format(part.amount, part.name) end
    return table.concat(amounts, " + ")
end

function R.town_middle_icon(at) R.compass_icon(at, 17) end

local function result_screen()
    local l = match3.result_rects(SCREEN_W, SCREEN_H)
    local breakdown = rules.reward_breakdown(R.g,R.wonders,R.prog,R.island)
    local reward = breakdown.total
    local pending = island.wonder_count(R.island) + 1
    local next_kind = breakdown.first and journey.wonder_at(R.g.level + 1)
        or not breakdown.first and pending <= journey.earned(R.prog.level) and pending
    local w = next_kind and R.wonders[next_kind]
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
    if not breakdown.first then say("SUPPLY RUN",l.stars,23,PAL_GOLD) end
    s = section(.43, .3, 9)
    say("EXPEDITION SCORE", l.score_label, 12, PAL_CREAM)
    local count = R.dialog_part(.43, .65).f   -- the score counts up
    say(tostring(math.floor(R.g.score * count + .5)), l.score, 46, PAL_GOLD)
    set_paint(s)
    s = section(.62, .25, 8)
    say("RESOURCES TO BANK", l.treasure_label, 12, PAL_CREAM)
    set_paint(s)
    local columns = #economy.currency_order
    for i, slot in ipairs(economy.currency_order) do
        local k = i - 1
        local r = l.rewards:col(columns, k, 10)
        s = section(.66 + k * .1, .28, 10)
        rrect(r, 12, rgba(241, 218, 157))
        rrect(r:inflate(-2), 10, rgba(255, 242, 201))
        picture_fit(currency_icon(slot), rect(r.x + (r.w - 36) / 2, r.y + 4, 36, 36), 255)
        say(("+%d"):format(reward[slot]), rect(r.x + 6, r.y + 40, r.w - 12, 27), 25, PAL_GOLD)
        say(economy.currencies[slot].name, rect(r.x + 3, r.y + 70, r.w - 6, 14), 13, PAL_CREAM)
        set_paint(s)
    end
    local bonuses = ("Move bonus +%d Coins"):format(breakdown.bonus)
    if breakdown.happiness > 0 then bonuses = bonuses .. ("  ·  Happiness +%d Coins"):format(breakdown.happiness) end
    say(bonuses, rect(l.rewards.x,l.rewards.y+l.rewards.h+1,l.rewards.w,15), 11, PAL_CREAM)
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
    local heading, next_step = "BUILD SHOP", "Choose your next treasure"
    if w then
        picture_fit(w.sprite, next_icon, 255)
        local missing = R.currency_prices(economy.shortfall(w.cost, R.prog.wallet + reward))
        local unlock = economy.unlocks[next_kind]
        heading, next_step = #missing == 0 and economy.unlock_text(unlock) or "REPLAY TO EARN THE REST", w.name
        local price = #missing == 0 and R.cost_text(R.currency_prices(w.cost)) or "Need " .. R.cost_text(missing)
        say_left(price, rect(l.next.x+78,l.next.y+47,l.next.w-88,14), 11, PAL_GOLD)
    elseif breakdown.first then
        picture_fit(R.board_art["next-clue"], next_icon, 255)
        heading, next_step = "THE INVESTIGATION CONTINUES", "Return for the next clue"
    else
        R.skin:paint_button(next_icon, nil, {role = "navigation_build"})
    end
    say_left(heading, rect(l.next.x + 78, l.next.y + 9, l.next.w - 88, 18), 11, PAL_CREAM)
    say_left(next_step, rect(l.next.x + 78, l.next.y + 24, l.next.w - 88, 24), 22, PAL_GOLD)
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
    local textures = R.board_art or {}   -- window-free tests play the campaign without art
    return object and {image = textures["find-" .. object.key], name = object.name, level = g.level + 1}
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
local chip_prefix = art.use_campaign_pieces() and "campaign-" or "resource-"
local guide_entries = {
    {id="neighbors", title="Line up 3+ pieces", description="Match straight lines along any of the three axes.",
     icon={front=chip_prefix .. "coin"}},
    {id="plaques", title="Blue plaques", description="Clear every blue plaque to win. Match pieces on a plaque or hit it with a tool.",
     icon={floor="tile-tablet-single"}},
    {id="chains", title="Chains", description="Match the chained piece or hit it with a tool. If the cell is blue, clear it with another hit.",
     icon={floor="tile-tablet-single", piece=chip_prefix .. "coin", front="chain"}},
    {id="earnings", title="Stock the expedition", description="Match resource pieces and win to bank Coins, Supplies and Food.",
     icon={front="resource-wallet-supplies"}},
    {id="pickaxe", title="Pickaxe", description="Hits one cell.",
     icon={tool="pickaxe"}},
}
for i, unlock in ipairs(economy.unlocks) do
    local description = economy.unlock_text(unlock) .. (" From expedition %d."):format(unlock.first_level)
    guide_entries[#guide_entries+1] = {id=unlock.key, title=island.wonders[i].name,
        description=description .. (unlock.effect and " " .. unlock.effect or ""),
        icon=unlock.tool and {tool=unlock.key} or {front=chip_prefix .. unlock.key}}
end
local function guide_icon(box, icon)
    local layer = rect.centered(box:center(), size2.splat(48))
    if icon.floor then picture(R.board_art[icon.floor], layer, 255) end
    if icon.piece then picture(R.board_art[icon.piece], layer:inflate(-4), 255) end
    if icon.front then picture(R.board_art[icon.front], layer, 255) end
    if icon.tool then picture(R.hud_art[icon.tool .. "-normal"], layer, 255) end
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
