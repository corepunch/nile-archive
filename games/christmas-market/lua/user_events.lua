-- user_events.lua — Christmas Market's user events, after Cradle of Rome's
-- settings/user_events.xml: the sixteen upgrades of docs/CAMPAIGN_DESIGN.md#upgrades.
--
-- Every entry is one event: when its If is met it runs each Then, once per
-- profile, and is done. engine/lua/match3/user_events.lua implements the
-- conditions and effects and lists every type it knows. Placing a stall arms
-- its upgrade (city_<stall>); meeting the feat upgrades the stall,
-- a trophy is awarded and one perk lasts for good, either more of
-- one currency in every win or a tool that charges faster. Ids man_01 to
-- man_16 are Rome's. Resource ids are coins (Tokens), food (Treats) and
-- supplies (Materials); stalls are buildings.lua keys. The upgrade's
-- scene, played by its keeper, is its `## Upgrades` section in docs/story.md.
local function income(id, amount) return {"THEN_PLAYER_ADD_RESOURCE_PER_LEVEL", id=id, amount=amount} end
local function tool(id) return {"THEN_GAME_CHARGE_TOOL", id=id, amount=1} end

local upgrades = {
    {id="man_03", building="arch", title="a mulled-wine hatch in the arch", keeper="noelle",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=150}, perk=income("food", 10)},
    {id="man_04", building="reindeer_stable", title="a new harness and bells for the reindeer", keeper="pip",
        If={"IF_PLAYER_MAKE_MATCH", length=5}, perk=tool("hammer")},
    {id="man_02", building="lumber", title="a drying shed for the pine", keeper="theo",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="supplies", amount=230}, perk=income("supplies", 45)},
    {id="man_01", building="firework_stall", title="a rocket rack, ready in threes", keeper="pip",
        If={"IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES", amount=10}, perk=tool("bomb")},
    {id="man_05", building="bakery", title="a second oven", keeper="agnes",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=240}, perk=income("food", 40)},
    {id="man_06", building="chapel", title="the masons' yard behind the chapel", keeper="wren",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="supplies", amount=360}, perk=income("supplies", 70)},
    {id="man_07", building="cocoa", title="Mrs Alder's ladle and second pot", keeper="alder",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=325}, perk=income("food", 65)},
    {id="man_08", building="igloo", title="a second ice saw on the lake", keeper="theo",
        If={"IF_PLAYER_MAKE_MATCH_IN_LEVEL", amount=5, min_length=5}, perk=tool("shield")},
    {id="man_09", building="log_cabin", title="a second smoking rack", keeper="finch",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=375}, perk=income("food", 75)},
    {id="man_10", building="toys", title="a second bench and a shop bell", keeper="henrik",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="coins", amount=700}, perk=income("coins", 140)},
    {id="man_11", building="candles", title="Mr Wren trims every wick", keeper="wren",
        If={"IF_PLAYER_MAKE_MATCH_SERIES", amount=2, min_length=5}, perk=tool("lightning")},
    {id="man_12", building="post_office", title="a second sorting rack", keeper="pip",
        If={"IF_PLAYER_MAKE_MATCH_IN_TIME", amount=15, min_length=3, time=20}, perk=tool("plus")},
    {id="man_13", building="glassblower", title="a second furnace", keeper="theo",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="coins", amount=760}, perk=income("coins", 150)},
    {id="man_14", building="carousel", title="a band organ", keeper="pip",
        If={"IF_PLAYER_COMPLETE_LEVELS_WITHOUT_LIFE_LOSS", amount=3}, perk=tool("mixer")},
    {id="man_15", building="santa_workshop", title="Henrik's old apprentices come back", keeper="henrik",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="coins", amount=875}, perk=income("coins", 175)},
    {id="man_16", building="tree", title="a star for the top", keeper="theo",
        If={"IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES", amount=15}, perk=tool("star")},
}

local events = require("match3.user_events").upgrade_events(upgrades)

-- Rome kept trophy names in locale.xml: one trophy per upgrade, TROPHY_NN for man_NN.
local trophies = {}
local island = require("island")
for _, row in ipairs(upgrades) do
    trophies["TROPHY_" .. row.id:sub(5)] = island.buildings[island.kinds[row.building] + 1].name .. ": " .. row.title
end

return {events=events, trophies=trophies}
