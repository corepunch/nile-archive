-- screens.lua — Relic Rush's art in the shared dialogs: the results card, the
-- guide's rows and icons, and the wallet and town icons. The dialogs, their
-- motion, the paint helpers and every other popup are the engine's
-- (engine/lua/match3/game.lua); words are lua/game_config.lua.
local l10n = require("l10n")
local tr = l10n.tr
local R = require("match3.game").bind(require("state"))
local match3 = require("match3")
local rules = require("rules")
local economy = require("economy")
local art = require("art")
local wallet_art = art.wallet_icons
local island = require("island")
local rgba = color
local disc, picture = R.disc, R.picture
local pp, pc = R.pp, R.pc

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

R.currency_icon = currency_icon   -- the citizens' perks on the building card

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
            -- TRANSLATORS: %s is a currency: Coins, Supplies or Food
            note=earned and tr("%s from matches is banked on a win."):format(currency.name)
                or tr("%s earned from matches. Spend it on the island."):format(currency.name)}
    end
    return out
end

function R.currency_prices(cost)
    local parts = economy.price_parts(cost)
    for _, part in ipairs(parts) do part.id, part.icon = part.name, currency_icon(part.slot) end
    return parts
end

-- What the wallet still lacks of a price, as resource amounts: each currency
-- the price asks for, by what is left to gather, and a currency already
-- covered marked done (a check in place of 0). Empty once all are covered.
function R.funding_shortfall(cost)
    local missing = economy.shortfall(cost, R.prog.wallet)
    local parts, short = R.currency_prices(cost), false
    for _, part in ipairs(parts) do
        part.amount = missing[part.slot]
        part.done = part.amount == 0 or nil
        short = short or not part.done
    end
    return short and parts or {}
end

function R.town_middle_icon(at) R.compass_icon(at, 17) end

R.register_result(function()
    local breakdown = rules.reward_breakdown(R.g, R.prog)
    local reward = breakdown.total
    local resources = {}
    for _, slot in ipairs(economy.currency_order) do
        local kind = economy.currencies[slot]
        local amount = reward[slot] - (slot == economy.GOLD and breakdown.decoration or 0)
        resources[#resources+1] = {id=kind.key, amount=amount, icon=currency_icon(slot)}
    end
    local bonus = breakdown.decoration > 0
        and {id="decoration", amount="+" .. breakdown.decoration, icon=currency_icon(economy.GOLD)} or nil
    return {
        title=breakdown.first and tr("Expedition complete") or tr("Replay complete"),
        resources=resources, bonus=bonus, action=R.result_action(breakdown.first, reward),
    }
end)

-- One data source and one row resource; the engine measures and stacks every
-- row. Composite icon painting uses the same authored layers as the board.
local chip_prefix = R.campaign_art and "campaign-" or "resource-"
local guide_entries = {
    {id="neighbors", title=tr("Line up 3+ pieces"), description=tr("Match straight lines horizontally or vertically."),
     icon={front=chip_prefix .. "coin"}},
    {id="plaques", title=tr("Turquoise plaques"), description=tr("Clear every turquoise plaque to win. Match pieces on a plaque or hit it with a tool."),
     icon={floor="square-target"}},
    {id="double-plaques", title=tr("Green plaques"), description=tr("Match twice to clear a green plaque. Its first hit turns it turquoise."),
     icon={floor="square-double"}},
    {id="chains", title=tr("Chains"), description=tr("Match the chained piece or hit it with a tool. If the cell has a plaque, clear it with another hit."),
     icon={floor="square-target", piece=chip_prefix .. "coin", front="chain-square-1"}},
    {id="line-gem", title=tr("Four in a line: line gem"), description=tr("It keeps its color. Match it again to sweep its whole row or column."),
     icon={banded=chip_prefix .. "coin"}},
    {id="rainbow-gem", title=tr("Five in a line: rainbow gem"), description=tr("Swap it with a neighbor to clear every piece of that kind."),
     icon={special="color_bomb"}},
    {id="earnings", title=tr("Stock the expedition"), description=tr("Match resource pieces and win to bank Coins, Supplies and Food."),
     icon={front="resource-wallet-supplies"}},
    {id="score", title=tr("Leaves, flowers and amphoras"), description=tr("These pieces earn score only. See your score at the end of the expedition."),
     icon={front="campaign-leaf"}},
}
local function guide_piece(unlock, title, availability)
    local description = economy.unlock_text(unlock) .. " " .. availability
    guide_entries[#guide_entries+1] = {id=unlock.key, title=title,
        description=description, icon={front=chip_prefix .. unlock.key}}
end
guide_piece(economy.pieces[0], tr("Gold coins"), tr("From expedition %d."):format(1))
guide_piece(economy.pieces[1], tr("Silver coins"), tr("From expedition %d."):format(1))
for _, unlock in ipairs(economy.unlocks) do
    local building = island.buildings[island.kinds[unlock.building] + 1].name
    if unlock.kind and unlock.first_level <= rules.LEVELS then guide_piece(unlock, building, tr("From expedition %d."):format(unlock.first_level)) end
    local bonus = unlock.bonus
    if bonus and unlock.after <= rules.LEVELS then
        guide_entries[#guide_entries + 1] = {id=bonus.key, title=bonus.name,
            -- TRANSLATORS: %s is a building's name, then two sentences: how the bonus charges and what it does
            description=tr("Restore %s. %s %s"):format(building, economy.bonus_lesson(bonus), bonus.effect),
            icon={front=bonus.icon}}
    end
end
local function guide_icon(box, icon)
    local layer = rect.centered(box:center(), size2.splat(48))
    if icon.floor then picture(R.board_art[icon.floor], layer, 255) end
    if icon.piece then picture(R.board_art[icon.piece], layer:inflate(-4), 255) end
    if icon.front then picture(R.board_art[icon.front], layer, 255) end
    if icon.banded then R.draw_banded(R.board_art[icon.banded], layer, 0, 255) end
    if icon.special then R.draw_match_special({special=icon.special}, box:center(), 48 / (R.HEX_R * 2), 255) end
end
function R.building_reward(kind)
    local step = island.ladder[island.ladder_position[kind]]
    if not step then return end
    local unlock = step.unlock
    local bonus = unlock.bonus
    if bonus then return {id=bonus.key, name=bonus.name, icon=R.board_art[bonus.icon]} end
    return {id=unlock.key, name=unlock.name, icon=R.board_art[chip_prefix .. unlock.key],
        amount=unlock.amount, unit=currency_icon(unlock.slot)}
end

local guide_form = match3.guide_form({
    title = tr("Explorer's guide"),
}, guide_icon)
assert(guide_form:set_items("topics",guide_entries))
R.guide_form,R.guide_entries=guide_form,guide_entries -- measured bounds and the source rows are checked by the input smoke test
R.register_guide(guide_form)

return R
