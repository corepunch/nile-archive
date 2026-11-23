-- screens.lua — Christmas Market's art in the shared dialogs: the results card, the
-- guide's rows and icons, and the wallet and town icons. The dialogs, their
-- motion, the paint helpers and every other popup are the engine's
-- (engine/lua/match3/game.lua); words are lua/game_config.lua.
local R = require("match3.game").bind(require("state"))
local match3 = require("match3")
local l10n = require("l10n")
local tr = l10n.tr
local rules = require("rules")
local economy = require("economy")
local island = require("island")
local picture = R.picture

local function currency_icon(slot)
    return R.board_art[economy.currencies[slot].frame]
end

R.currency_icon = currency_icon   -- the citizens' perks on the building card

function R.wallet_icons() return {R.life_art, currency_icon(economy.GOLD), R.hud_art.complete} end
function R.town_middle_icon(at) gfx.image(R.hud_art.complete, rect.centered(at, size2(44, 44)), color.WHITE) end

function R.currency_capsules(balance)
    local out = {}
    local earned = not R.on_island and R.g and not R.g.lost and not R.g.reward_claimed and R.g.earnings
    for slot, currency in ipairs(economy.currencies) do
        out[slot] = {id=currency.id, icon=currency_icon(slot), value=tostring(balance[slot] + (earned and earned[slot] or 0)), width=90,
            -- TRANSLATORS: %s is a currency: Tokens, Treats or Materials
            note=(earned and tr("%s from matches are banked on a win.")
                or tr("%s from matches pay for stalls and decorations.")):format(currency.name)}
    end
    return out
end

function R.currency_prices(cost)
    local parts = {}
    for slot, currency in ipairs(economy.currencies) do
        if cost[slot] > 0 then
            parts[#parts + 1] = {id=currency.id, name=currency.name, slot=slot, amount=cost[slot], icon=currency_icon(slot)}
        end
    end
    return parts
end

function R.funding_shortfall(cost)
    local missing = purse()
    for slot in ipairs(economy.currencies) do missing[slot] = math.max(0, cost[slot] - R.prog.wallet[slot]) end
    return R.currency_prices(missing)
end

function R.building_reward(kind)
    local step = island.ladder[island.ladder_position[kind]]
    if not step then return end
    local unlock = step.unlock
    local bonus = unlock.bonus
    if bonus then return {id=bonus.key, name=bonus.name, icon=R.board_art[bonus.icon]} end
    local frame = "market-" .. unlock.kind
    local piece = economy.pieces[unlock.kind]
    return {id=frame, name=piece.name, icon=R.board_art[frame], amount=piece.amount, unit=currency_icon(piece.slot)}
end

R.register_result(function()
    local breakdown = rules.reward_breakdown(R.g, R.wonders, R.prog)
    local reward, first = breakdown.total, breakdown.first
    local resources = {}
    for slot, currency in ipairs(economy.currencies) do
        local amount = reward[slot] - (slot == economy.GOLD and breakdown.decoration or 0)
        resources[slot] = {id=currency.id, amount=amount, icon=currency_icon(slot)}
    end
    local bonus = breakdown.decoration > 0
        and {id="decoration", amount="+" .. breakdown.decoration, icon=currency_icon(economy.GOLD)} or nil
    return {
        title=first and tr("Wish granted!") or tr("Replay complete"),
        resources=resources, bonus=bonus, action=R.result_action(first, reward),
    }
end)

-- One data source and one row resource; the engine measures and stacks every
-- row. Composite icon painting uses the same authored layers as the board.
local guide_entries = {
    {id="neighbors", title=tr("Line up three or more"), description=tr("Match identical pieces in a straight line horizontally or vertically."),
     icon={front="market-3"}},
    {id="panes", title=tr("Light the panes"), description=tr("Match on a pane or hit it with a tool to light it. Light them all to finish."),
     icon={back="square-target"}},
    {id="double-panes", title=tr("Green panes"), description=tr("A green pane turns blue after its first hit. Match again to light it."),
     icon={back="square-double"}},
    {id="blockers", title=tr("Untangle tinsel"), description=tr("Match the tied piece or hit it with a tool. Then clear the piece to light the pane."),
     icon={back="square-target", piece="market-1", front="chain-square-1"}},
    {id="line-gem", title=tr("Four in a line: line gem"), description=tr("It keeps its color. Match it again to sweep its whole row or column."),
     icon={banded="market-3"}},
    {id="rainbow-gem", title=tr("Five in a line: rainbow gem"), description=tr("Swap it with a neighbor to clear every piece of that kind."),
     icon={special="color_bomb"}},
    {id="supplies", title=tr("Stock the market"), description=tr("Match coins to fund the arch. Its mulled wine earns treats. The lumber workshop adds pine for materials."),
     icon={front="market-3"}},
    {id="banking", title=tr("Bank your matches"), description=tr("Each matched piece pays its own value. Clear the board to bank what you earned."),
     icon={front="market-4"}},
    {id="hammer", title=tr("Farrier's hammer"), description=tr("Build the Reindeer stable. Match 30 hammers to charge one blow. Tap a cell to hit it."), icon={tool=economy.bonuses.hammer.icon}},
    {id="boosters", title=tr("Firework Bomb"), description=tr("The Firework stall replaces the hammer and keeps its charge. Tap a cell to hit a 3×3 square."),
     icon={tool="booster-firework"}},
    {id="bakery", title=tr("Winter treats"), description=tr("The bakery swaps mulled wine for gingerbread men. The cocoa kiosk puts hot cocoa on the board."), icon={front="market-7"}},
}
local function guide_icon(box, icon)
    local at = box:center()
    local layer = rect.centered(at, size2(48, 48))
    if icon.back then picture(R.board_art[icon.back], layer, 255) end
    if icon.piece then picture(R.board_art[icon.piece], layer, 255) end
    if icon.front then picture(R.board_art[icon.front], layer, 255) end
    if icon.tool then picture(R.board_art[icon.tool], layer, 255) end
    if icon.banded then R.draw_banded(R.board_art[icon.banded], layer, 0, 255) end
    if icon.special then R.draw_match_special({special=icon.special}, at, 48 / (R.HEX_R * 2), 255) end
end
local guide_form = match3.guide_form({
    title = tr("Market keeper's guide"),
}, guide_icon)
assert(guide_form:set_items("topics",guide_entries))
R.guide_form,R.guide_entries=guide_form,guide_entries -- measured bounds and the source rows are checked by the input smoke test
R.register_guide(guide_form)

return R
