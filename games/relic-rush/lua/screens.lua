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

function R.funding_shortfall(cost)
    local missing = R.currency_prices(economy.shortfall(cost, R.prog.wallet))
    if #missing > 0 then return "Need " .. R.cost_text(missing) end
end

function R.town_middle_icon(at) R.compass_icon(at, 17) end

R.register_result(function()
    local breakdown = rules.reward_breakdown(R.g, R.prog)
    local reward = breakdown.total
    local resources = {}
    for _, slot in ipairs(economy.currency_order) do
        local kind = economy.currencies[slot]
        resources[#resources+1] = {id=kind.key, name=kind.name, amount=("+%d"):format(reward[slot]), icon=currency_icon(slot)}
    end
    local level = breakdown.first and R.g.level + 1 or R.prog.level
    local quest, step = island.next_quest(R.island, level)
    local next_kind = quest and step.kind or island.next_step(R.island, level)
    local w = next_kind and R.buildings[next_kind + 1]
    local next_step
    if w then
        local missing = R.currency_prices(economy.shortfall(w.cost, R.prog.wallet + reward))
        local unlock = island.buildings[next_kind + 1].unlock_text
        next_step = {
            icon=w.sprite, title=w.name,
            heading=quest and quest.title or #missing == 0 and (unlock or "NEXT RESTORATION") or "REPLAY TO EARN THE REST",
            detail=(quest and quest.request .. "\n" or "") ..
                (#missing == 0 and R.cost_text(R.currency_prices(w.cost)) or "Need " .. R.cost_text(missing)),
        }
    end
    return {
        title=breakdown.first and "Expedition complete" or "Replay complete",
        subtitle=("LEVEL %d · %s"):format(R.g.level + 1, rules.level_of(R.g).name),
        resources=resources, next_step=next_step, action="COLLECT & RETURN",
    }
end)

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
for _, unlock in ipairs(economy.unlocks) do
    local building = island.buildings[island.kinds[unlock.building] + 1].name
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
R.register_guide(guide_form)

return R
