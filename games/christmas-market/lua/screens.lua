-- screens.lua — Christmas Market's art in the shared dialogs: the results card, the
-- guide's rows and icons, and the wallet and town icons. The dialogs, their
-- motion, the paint helpers and every other popup are the engine's
-- (engine/lua/match3/game.lua); words are lua/game_config.lua.
local R = require("match3.game").bind(require("state"))
local match3 = require("match3")
local rules = require("rules")
local economy = require("economy")
local island = require("island")
local picture = R.picture

local function currency_icon(slot)
    return R.board_art["market-" .. economy.currencies[slot].kind]
end

R.currency_icon = currency_icon   -- the citizens' perks on the building card

function R.wallet_icons() return {R.life_art, currency_icon(economy.GOLD), R.hud_art.complete} end
function R.town_middle_icon(at) gfx.image(R.hud_art.complete, rect.centered(at, size2(44, 44)), color.WHITE) end

function R.currency_capsules(balance)
    local out = {}
    local earned = not R.on_island and R.g and not R.g.lost and not R.g.reward_claimed and R.g.earnings
    for slot, currency in ipairs(economy.currencies) do
        out[slot] = {id=currency.name:lower(), icon=currency_icon(slot), value=tostring(balance[slot] + (earned and earned[slot] or 0)), width=90,
            note=earned and currency.name .. " from matches are banked on a win."
                or currency.name .. " from matches pay for stalls and decorations."}
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
    if bonus then return {id=bonus.key, icon=R.board_art[bonus.icon]} end
    local frame = "market-" .. unlock.kind
    local piece = economy.pieces[unlock.kind]
    return {id=frame, icon=R.board_art[frame], amount=piece.amount, unit=currency_icon(piece.slot)}
end

R.register_result(function()
    local spec = rules.level_of(R.g)
    local breakdown = rules.reward_breakdown(R.g, R.wonders, R.prog)
    local reward, first = breakdown.total, breakdown.first
    local resources = {}
    for slot, currency in ipairs(economy.currencies) do
        resources[slot] = {id=currency.name, amount=reward[slot], icon=currency_icon(slot)}
    end
    -- A first clear's story find, or else the next stall on the ladder: what
    -- it still needs after this win, or its picture once the wallet covers it.
    local find = first and spec.story_piece
    local kind = island.next_step(R.island, first and R.g.level + 1 or R.prog.level)
    local w = kind and R.buildings[kind + 1]
    local next_step
    if find then
        next_step = {icon=R.board_art["story-" .. find.key], heading="RECOVERED", title=find.name}
    elseif w then
        local have, missing = R.prog.wallet + reward, purse()
        for slot in ipairs(economy.currencies) do missing[slot] = math.max(0, w.cost[slot] - have[slot]) end
        next_step = R.result_next(w, R.currency_prices(missing))
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
    {id="neighbors", title="Line up three or more", description="Match identical pieces in a straight line horizontally or vertically.",
     icon={front="market-3"}},
    {id="panes", title="Light the panes", description="Match on a pane or hit it with a tool to light it. Light them all to finish.",
     icon={back="square-target"}},
    {id="double-panes", title="Green panes", description="A green pane turns blue after its first hit. Match again to light it.",
     icon={back="square-double"}},
    {id="blockers", title="Untangle tinsel", description="Match the tied piece or hit it with a tool. Then clear the piece to light the pane.",
     icon={back="square-target", piece="market-1", front="chain-square-1"}},
    {id="line-gem", title="Four in a line: line gem", description="It keeps its color. Match it again to sweep its whole row or column.",
     icon={banded="market-3"}},
    {id="rainbow-gem", title="Five in a line: rainbow gem", description="Swap it with a neighbor to clear every piece of that kind.",
     icon={special="color_bomb"}},
    {id="supplies", title="Stock the market", description="Match coins to fund the arch. Its mulled wine earns treats. The lumber workshop adds pine for materials.",
     icon={front="market-3"}},
    {id="banking", title="Bank your matches", description="Each matched piece pays its own value. Clear the board to bank what you earned.",
     icon={front="market-4"}},
    {id="hammer", title="Reindeer", description="Build the Reindeer stable. Match 30 reindeer to charge one kick. Tap a cell to hit it.", icon={tool=economy.bonuses.hammer.icon}},
    {id="boosters", title="Firework Bomb", description="The Firework stall replaces the reindeer and keeps its charge. Tap a cell to hit a 3×3 square.",
     icon={tool="booster-firework"}},
    {id="bakery", title="Winter treats", description="The bakery swaps mulled wine for gingerbread men. The cocoa kiosk puts hot cocoa on the board.", icon={front="market-7"}},
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
    title = "Market keeper's guide", instructions = "SWIPE OR TAP TWO NEIGHBORING PIECES",
    done = "LET'S MAKE MAGIC",
}, guide_icon)
assert(guide_form:set_items("topics",guide_entries))
R.guide_form,R.guide_entries=guide_form,guide_entries -- measured bounds and the source rows are checked by the input smoke test
R.register_guide(guide_form)

return R
