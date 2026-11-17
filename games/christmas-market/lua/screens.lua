-- screens.lua — Christmas Market's art in the shared dialogs: the results card, the
-- guide's rows and icons, and the wallet and town icons. The dialogs, their
-- motion, the paint helpers and every other popup are the engine's
-- (engine/match3_game.lua); words are lua/game_config.lua.
local R = require("match3.game").bind(require("state"))
local match3 = require("match3")
local rules = require("rules")
local economy = require("economy")
local PAL_GOLD, PAL_CREAM = R.PAL_GOLD, R.PAL_CREAM
local rgba = color
local P, pp = R.P, R.pp
local rrect, picture, picture_fit = R.rrect, R.picture, R.picture_fit
local say, say_left, button, panel = R.say, R.say_left, R.button, R.panel
local set_paint, section = R.set_paint, R.section

function R.star_icon(center, radius)
    picture(R.hud_art.complete, rect.centered(center, size2(radius*2.6,radius*2.6)), 255)
end
local star_icon = R.star_icon

function R.wallet_icons() return {R.life_art, R.board_art["market-3"], R.hud_art.complete} end
function R.town_middle_icon(at) gfx.image(R.hud_art.complete, rect.centered(at, size2(44, 44)), color.WHITE) end

local function currency_icon(slot)
    return R.board_art["market-" .. economy.currencies[slot].kind]
end

function R.currency_capsules(balance)
    local out = {}
    local earned = not R.on_island and R.g and not R.g.lost and not R.g.reward_claimed and R.g.earnings
    for slot, currency in ipairs(economy.currencies) do
        out[slot] = {id=currency.name:lower(), icon=currency_icon(slot), value=tostring(balance[slot] + (earned and earned[slot] or 0)), width=90,
            note=earned and currency.name .. " from matches is banked on a win."
                or currency.name .. " from matches pays for stalls and decorations."}
    end
    return out
end

function R.currency_prices(cost)
    local parts = {}
    for slot, currency in ipairs(economy.currencies) do
        if cost[slot] > 0 then
            parts[#parts + 1] = {id=currency.name, name=currency.name, amount=cost[slot], icon=currency_icon(slot)}
        end
    end
    return parts
end

function R.cost_text(parts)
    local prices = {}
    for i, part in ipairs(parts) do prices[i] = ("%d %s"):format(part.amount, part.name) end
    return table.concat(prices, " + ")
end

local RESULT = {card = rect(40, 238, 400, 534), header = rect(64, 210, 352, 72), stars = rect(110, 310, 260, 74),
                score = rect(90, 388, 300, 62), chips = rect(68, 462, 344, 92), next = rect(64, 572, 352, 72),
                claim = rect(70, 676, 340, 60)}
local function reward_chip(box, icon, value, label)
    rrect(box:offset(vec2(0, 3)), 16, rgba(201, 164, 100))
    rrect(box, 16, rgba(255, 246, 214))
    rrect(box:inflate(-3), 13, rgba(255, 238, 190))
    picture_fit(icon, rect.centered(vec2(box:center().x, box.y + 24), size2.splat(42)), 255)
    say(value, rect(box.x + 4, box.y + 43, box.w - 8, 25), 24, PAL_GOLD)
    say(label, rect(box.x + 4, box.y + 70, box.w - 8, 15), 12, PAL_CREAM)
end
local function result_screen()
    local l = RESULT
    local spec = rules.level_of(R.g)
    local breakdown = rules.reward_breakdown(R.g, R.wonders, R.prog)
    local w = breakdown.wonder
    local reward = breakdown.total
    local first = breakdown.first
    local s
    panel(l.card)
    rrect(l.header:offset(vec2(0, 5)), 18, rgba(77, 58, 31))
    rrect(l.header, 18, rgba(31, 83, 69))
    rrect(l.header:inflate(-3), 15, rgba(44, 108, 84))
    say(first and "Wish granted!" or "Replay complete", rect(l.header.x + 14, l.header.y + 8, l.header.w - 28, 36), 32, PAL_GOLD)
    say(("%d. %s"):format(R.g.level + 1, rules.level_of(R.g).name), rect(l.header.x + 12, l.header.y + 46, l.header.w - 24, 16), 15, PAL_CREAM)
    for k = 0, first and 2 or -1 do
        local slot = l.stars:col(3, k, 8)
        local part
        s, part = section(.24 + k * .13, .32, 13)
        local pop = 1 + math.sin(part.u * math.pi) * .14
        local at = slot:center() + vec2(0, k == 1 and -6 or 4)
        R.vfx_halo(pp(at), 48 * P.scale, rgba(255, 201, 77, 65 * P.alpha))
        star_icon(at, (k == 1 and 31 or 25) * pop)
        set_paint(s)
    end
    if first then
        say("+3 CHRISTMAS STARS", rect(l.stars.x, l.stars.y + 62, l.stars.w, 16), 12, PAL_CREAM)
    else
        say("SUPPLIES FOR YOUR MARKET", l.stars, 21, PAL_GOLD)
    end
    s = section(.43, .3, 9)
    say("SCORE", rect(l.score.x, l.score.y, l.score.w, 16), 13, PAL_CREAM)
    local count = R.dialog_part(.43, .65).f   -- the score counts up
    say(tostring(math.floor(R.g.score * count + .5)), rect(l.score.x, l.score.y + 16, l.score.w, 46), 42, PAL_GOLD)
    set_paint(s)
    s = section(.62, .28, 10)
    for slot, currency in ipairs(economy.currencies) do
        reward_chip(l.chips:col(#economy.currencies, slot - 1, 8), currency_icon(slot),
            ("+%d"):format(reward[slot]), currency.name)
    end
    set_paint(s)
    s = section(.9, .26, 8)
    rrect(l.next, 14, rgba(240, 225, 180))
    local find = first and spec.story_piece
    local next_icon = find and R.board_art["story-" .. find.key] or first and w and w.sprite
    if next_icon then picture_fit(next_icon, rect(l.next.x + 8, l.next.y + 4, 66, l.next.h - 8), 255)
    else star_icon(vec2(l.next.x + 40, l.next:center().y), 22) end
    local heading = find and "RECOVERED  ·  " .. find.name or first and (w and "NEXT: BUILD" or "NEXT") or "SPEND IT IN THE"
    local next_name = first and (w and w.name or "The market has news") or "Build shop"
    if first and w then
        local stock = R.prog.wallet + reward
        local value = stock:covers(w.cost) and "Ready to build" or "Replay a wish for more goods"
        say(value, rect(l.chips.x, 554, l.chips.w, 16), 13, PAL_CREAM)
    end
    say_left(heading, rect(l.next.x + 84, l.next.y + 10, l.next.w - 96, 18), 13, PAL_CREAM)
    say_left(next_name, rect(l.next.x + 84, l.next.y + 31, l.next.w - 96, 30), 24, PAL_GOLD)
    set_paint(s)
    s = section(1.02, .22, 8)
    if button(l.claim, "COLLECT", not R.modal_closing) and not R.modal_closing then
        if not R.dialog_settled() then R.dialog_skip()   -- first tap fast-forwards
        else R.close_dialog() end
    end
    set_paint(s)
end
R.dialogs[R.OV_RESULT] = result_screen

-- One data source and one row resource; the engine measures and stacks every
-- row. Composite icon painting uses the same authored layers as the board.
local guide_entries = {
    {id="neighbors", title="Line up three or more", description="Match treats in a straight line along any of the three axes.",
     icon={front="market-3"}},
    {id="panes", title="Light the panes", description="Match on a pane or hit it with a tool to light it. Light them all to finish.",
     icon={back="tile-tablet-single"}},
    {id="blockers", title="Untangle tinsel", description="Match the tied treat or hit it with a tool. Then clear the treat to light the pane.",
     icon={back="tile-tablet-single", piece="market-1", front="chain"}},
    {id="supplies", title="Stock the market", description="Coins pay Gold. After you build stalls, their wood, food and other goods appear on the board. Holly and mittens earn score.",
     icon={front="market-3"}},
    {id="long-lines", title="Long lines pay more", description="A line of four pays twice per piece. A line of five pays four times per piece.",
     icon={front="market-4"}},
    {id="double-panes", title="Green double panes", description="A green pane turns blue after the first hit. Match again to light it.", icon={back="tile-tablet-double"}},
    {id="hammer", title="Hammer", description="Build Theo's workshop and match toy hammers to charge a hit on one cell.", icon={tool="booster-hammer"}},
    {id="wand", title="Lantern lightning", description="Build the candle shop and match lantern stars to charge a strike across 15 cells.", icon={tool="booster-lantern"}},
    {id="boosters", title="One use per wish", description="The reindeer stable gives you a Shooting Star to clear a row and Santa's workshop a Firework Bomb to blast a cell and its neighbors. The sleigh and the Christmas tree add a second of each. Choose a booster and tap the board.",
     icon={tool="booster-firework"}},
    {id="treasures", title="Bells and baubles", description="The chapel, the igloo and the giant bauble change gold coins into golden bells, snowflake baubles and plum baubles: 6, 7 and 8 Gold each.",
     icon={front="market-12"}},
    {id="helpers", title="Market helpers", description="The gingerbread house adds 3 moves to every wish and the post office charges tools twice as fast. The skating rink and the presents pay on every win.",
     icon={front="market-7"}},
}
local function guide_icon(box, icon)
    local at = box:center()
    local layer = rect.centered(at, size2(48, 48))
    if icon.back then picture(R.board_art[icon.back], layer, 255) end
    if icon.piece then picture(R.board_art[icon.piece], layer, 255) end
    if icon.front then picture(R.board_art[icon.front], layer, 255) end
    if icon.tool then picture(R.hud_art[icon.tool .. "-normal"], layer, 255) end
end
local guide_form = match3.guide_form({
    title = "Market keeper's guide", instructions = "SWIPE OR TAP TWO NEIGHBORING TREATS",
    done = "LET'S MAKE MAGIC",
}, guide_icon)
assert(guide_form:set_items("topics",guide_entries))
R.guide_form,R.guide_entries=guide_form,guide_entries -- measured bounds and the source rows are checked by the input smoke test
local function guide_screen() match3.draw_guide(R, guide_form) end
R.dialogs[R.OV_GUIDE] = guide_screen

return R
