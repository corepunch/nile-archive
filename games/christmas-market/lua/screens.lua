-- screens.lua — Christmas Market's art in the shared dialogs: the results card, the
-- guide's rows and icons, and the wallet and town icons. The dialogs, their
-- motion, the paint helpers and every other popup are the engine's
-- (engine/match3_game.lua); words are lua/game_config.lua.
local R = require("match3.game").bind(require("state"))
local match3 = require("match3")
local rules = require("rules")
local economy = require("economy")
local picture = R.picture

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

R.register_result(function()
    local spec = rules.level_of(R.g)
    local breakdown = rules.reward_breakdown(R.g, R.wonders, R.prog)
    local w, reward, first = breakdown.wonder, breakdown.total, breakdown.first
    local resources = {}
    for slot, currency in ipairs(economy.currencies) do
        resources[slot] = {id=currency.name, name=currency.name, amount=("+%d"):format(reward[slot]), icon=currency_icon(slot)}
    end
    local find = first and spec.story_piece
    local next_step = {
        icon=find and R.board_art["story-" .. find.key] or first and w and w.sprite or R.hud_art.complete,
        heading=find and "RECOVERED · " .. find.name or first and (w and "NEXT: BUILD" or "NEXT") or "SPEND IT IN THE",
        title=first and (w and w.name or "The market has news") or "Build shop",
    }
    if first and w then
        next_step.detail = (R.prog.wallet + reward):covers(w.cost) and "Ready to build" or "Replay a wish for more goods"
    end
    return {
        title=first and "Wish granted!" or "Replay complete",
        subtitle=("%d. %s"):format(R.g.level + 1, spec.name),
        resources=resources, next_step=next_step, action="COLLECT",
    }
end)

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
R.register_guide(guide_form)

return R
