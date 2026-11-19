-- screens.lua — Relic Rush's art in the shared dialogs: the results card, the
-- guide's rows and icons, and the wallet and town icons. The dialogs, their
-- motion, the paint helpers and every other popup are the engine's
-- (engine/lua/match3/game.lua); words are lua/game_config.lua.
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

-- Keep the next purchase's shortfall attached to the existing Build button.
local AMOUNT_WIDTH, AMOUNT_GAP = 48, 3
local build_progress = ui.form{kind="column",children={
    {kind="column",panel=true,role="group",gap=3,padding={6,4,6,5},children={
        {kind="label",id="caption",em=13,text_style="caption"},
        {kind="row",visible_field="show_amounts",children={
            {kind="spacer",grow=1},
            {kind="list",id="shortfall",direction="row",gap=AMOUNT_GAP,item=function(entry)
                return match3.resource_indicator(entry, AMOUNT_WIDTH, true)
            end},
            {kind="spacer",grow=1},
        }},
    }},
}}

local function draw_build_progress(screen)
    if R.island.placing >= 0 then return end
    local _, position = island.next_step(R.island, R.prog.level)
    local step = island.ladder[position]
    if not step or step.after > rules.LEVELS then return end
    local missing = economy.shortfall(island.buildings[step.kind + 1].cost, R.prog.wallet)
    local key = table.concat({position, missing[1], missing[2], missing[3]}, "/")
    local list = build_progress.nodes.shortfall
    if list.funding_key ~= key then
        local parts = R.currency_prices(missing)
        assert(build_progress:set_items("shortfall", parts))
        list.funding_key = key
    end
    local count = #list.children
    if count == 0 and step.after <= R.prog.level then return end
    build_progress.values.show_amounts = count > 0
    build_progress:set("caption", count > 0 and R.words.card.missing or R.words.catalogue.complete:format(step.after))
    local width = count == 0 and 164 or math.max(112, count * (AMOUNT_WIDTH + AMOUNT_GAP) - AMOUNT_GAP + 12)
    local _, height = build_progress:measure(width, R.skin)
    local button = R.town.navigation.boxes.build
    local x = num.clamp(button:center().x - width / 2, screen.x + 6, screen:max().x - width - 6)
    build_progress:draw(rect(x, button.y - height - 6, width, height), R.skin, {interactive=false})
end

local town_setup = R.town_setup
function R.town_setup()
    town_setup()
    R.town.hooks.extras = draw_build_progress
end

function R.town_middle_icon(at) R.compass_icon(at, 17) end

R.register_result(function()
    local breakdown = rules.reward_breakdown(R.g, R.prog)
    local reward = breakdown.total
    local resources = {}
    for _, slot in ipairs(economy.currency_order) do
        local kind = economy.currencies[slot]
        resources[#resources+1] = {id=kind.key, amount=reward[slot], icon=currency_icon(slot)}
    end
    return {
        title=breakdown.first and "Expedition complete" or "Replay complete",
        subtitle=("LEVEL %d · %s"):format(R.g.level + 1, rules.level_of(R.g).name),
        resources=resources, action="COLLECT & RETURN",
    }
end)

-- One data source and one row resource; the engine measures and stacks every
-- row. Composite icon painting uses the same authored layers as the board.
local chip_prefix = art.use_campaign_pieces() and "campaign-" or "resource-"
local guide_entries = {
    {id="neighbors", title="Line up 3+ pieces", description="Match straight lines horizontally or vertically.",
     icon={front=chip_prefix .. "coin"}},
    {id="plaques", title="Turquoise plaques", description="Clear every turquoise plaque to win. Match pieces on a plaque or hit it with a tool.",
     icon={floor="square-target"}},
    {id="double-plaques", title="Green plaques", description="Match twice to clear a green plaque. Its first hit turns it turquoise.",
     icon={floor="square-double"}},
    {id="chains", title="Chains", description="Match the chained piece or hit it with a tool. If the cell has a plaque, clear it with another hit.",
     icon={floor="square-target", piece=chip_prefix .. "coin", front="chain"}},
    {id="earnings", title="Stock the expedition", description="Match resource pieces and win to bank Coins, Supplies and Food.",
     icon={front="resource-wallet-supplies"}},
    {id="score", title="Leaves, flowers and amphoras", description="These pieces earn score only. See your score at the end of the expedition.",
     icon={front="campaign-leaf"}},
}
local function guide_piece(unlock, title, availability)
    local description = economy.unlock_text(unlock) .. " " .. availability
    guide_entries[#guide_entries+1] = {id=unlock.key, title=title,
        description=description, icon={front=chip_prefix .. unlock.key}}
end
guide_piece(economy.pieces[0], "Gold coins", "From expedition 1.")
guide_piece(economy.pieces[1], "Silver coins", "From expedition 1.")
for _, unlock in ipairs(economy.unlocks) do
    local building = island.buildings[island.kinds[unlock.building] + 1].name
    if unlock.kind and unlock.first_level <= rules.LEVELS then guide_piece(unlock, building, ("From expedition %d."):format(unlock.first_level)) end
    local bonus = unlock.bonus
    if bonus and unlock.after <= rules.LEVELS then
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
-- What a campaign building brings to the boards, as icons for its card: the
-- new piece with what each match of it banks, and the bonus gem.
function R.building_gets(kind)
    local gets = {}
    for _, unlock in ipairs(economy.unlocks) do
        if island.kinds[unlock.building] == kind then
            if unlock.kind then
                gets[#gets + 1] = {id=unlock.key, icon=R.board_art[chip_prefix .. unlock.key],
                    amount=unlock.amount, unit=currency_icon(unlock.slot)}
            end
            if unlock.bonus then gets[#gets + 1] = {id=unlock.bonus.key, icon=R.board_art[unlock.bonus.icon]} end
        end
    end
    return gets
end

local guide_form = match3.guide_form({
    title = "Explorer's guide", instructions = "SWIPE OR TAP TWO NEIGHBORING RELICS",
    done = "LET'S EXPLORE",
}, guide_icon, R.words.corner_close)
assert(guide_form:set_items("topics",guide_entries))
R.guide_form,R.guide_entries=guide_form,guide_entries -- measured bounds and the source rows are checked by the input smoke test
R.register_guide(guide_form)

return R
