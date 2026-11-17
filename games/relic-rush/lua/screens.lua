-- screens.lua — Relic Rush's art in the shared dialogs: the results card, the
-- guide's rows and icons, and the wallet and town icons. The dialogs, their
-- motion, the paint helpers and every other popup are the engine's
-- (engine/match3_game.lua); words are lua/game_config.lua.
local R = require("match3.game").bind(require("state"))
local match3 = require("match3")
local rules = require("rules")
local economy = require("economy")
local art = require("art")
local wallet_art = art.wallet_icons
local island = require("island")
local SCREEN_W, SCREEN_H = R.SCREEN_W, R.SCREEN_H
local PAL_GOLD, PAL_CREAM = R.PAL_GOLD, R.PAL_CREAM
local rgba = color
local pp, pc = R.pp, R.pc
local rrect, disc, picture, picture_fit = R.rrect, R.disc, R.picture, R.picture_fit
local say, say_left, button, panel = R.say, R.say_left, R.button, R.panel
local set_paint, section = R.set_paint, R.section

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
        out[i] = {id=currency.key, slot=slot, icon=currency_icon(slot), value=tostring(balance[slot] + pending), width=90,
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
    -- The next ladder restoration this result opens, or one still waiting.
    local next_kind = island.next_step(R.island, breakdown.first and R.g.level + 1 or R.prog.level)
    local w = next_kind and R.buildings[next_kind + 1]
    local s
    panel(l.card)
    rrect(l.header:offset(vec2(0, 5)), 18, rgba(77, 58, 31))
    rrect(l.header, 18, rgba(31, 83, 69))
    rrect(l.header:inflate(-3), 15, rgba(44, 108, 84))
    say(breakdown.first and "Expedition complete" or "Replay complete", rect(l.header.x + 14, l.header.y + 9, l.header.w - 28, 34), 31, PAL_GOLD)
    say(("LEVEL %d  -  WELL EXPLORED"):format(R.g.level + 1), rect(l.header.x + 12, l.header.y + 48, l.header.w - 24, 15), 14, PAL_GOLD)
    s = section(.24, .32, 13)
    say(breakdown.first and "SITE CLEARED" or "SUPPLY RUN", l.stars, 23, PAL_GOLD)
    set_paint(s)
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
    if breakdown.decoration_bonus > 0 then
        bonuses = bonuses .. ("  ·  Decorations +%d Coins"):format(breakdown.decoration_bonus)
    end
    for _, part in ipairs(breakdown.citizens and economy.price_parts(breakdown.citizens) or {}) do   -- user_events.lua
        bonuses = bonuses .. ("  ·  Citizens +%d %s"):format(part.amount, part.name)
    end
    say(bonuses, l.bonus, 11, PAL_CREAM)
    s = section(1.01, .26, 8)
    rrect(l.next, 12, rgba(240, 225, 180))
    local next_icon = rect(l.next.x + 8, l.next.y + 5, 60, l.next.h - 10)
    local heading, next_step = "BUILD SHOP", "Choose your next treasure"
    if w then
        picture_fit(w.sprite, next_icon, 255)
        local missing = R.currency_prices(economy.shortfall(w.cost, R.prog.wallet + reward))
        local unlock = island.buildings[next_kind + 1].unlock_text
        heading = #missing == 0 and (unlock or "NEXT RESTORATION") or "REPLAY TO EARN THE REST"
        next_step = w.name
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
    {id="score", title="Leaves and flowers", description="These pieces earn score only. See your score at the end of the expedition.",
     icon={front="campaign-leaf"}},
}
local function guide_piece(unlock, title, availability)
    local description = economy.unlock_text(unlock) .. " " .. availability
    guide_entries[#guide_entries+1] = {id=unlock.key, title=title,
        description=description, icon={front=chip_prefix .. unlock.key}}
end
guide_piece(economy.silver_coin, "Silver coins", ("On expedition %d."):format(economy.silver_coin.first_level))
for n, unlock in ipairs(economy.unlocks) do
    local building = island.buildings[island.ladder[n].kind + 1].name
    if unlock.kind then guide_piece(unlock, building, ("From expedition %d."):format(unlock.first_level)) end
    local bonus = unlock.bonus
    if bonus then
        guide_entries[#guide_entries + 1] = {id=bonus.key, title=bonus.name,
            description=("Restore %s. %s %s"):format(building, economy.bonus_lesson(bonus), bonus.effect),
            icon={front=bonus.icon}}
    end
end
local function guide_icon(box, icon)
    local layer = rect.centered(box:center(), size2.splat(48))
    if icon.floor then picture(R.board_art[icon.floor], layer, 255) end
    if icon.piece then picture(R.board_art[icon.piece], layer:inflate(-4), 255) end
    if icon.front then picture(R.board_art[icon.front], layer, 255) end
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
