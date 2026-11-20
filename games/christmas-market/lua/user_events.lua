-- user_events.lua — Christmas Market's user events, after Cradle of Rome's
-- settings/user_events.xml: the sixteen citizens of docs/CAMPAIGN_DESIGN.md#citizens.
--
-- Every entry is one event: when its If is met it runs each Then, once per
-- profile, and is done. engine/lua/match3/user_events.lua implements the
-- conditions and effects and lists every type it knows. Placing a stall arms
-- its citizen (city_<stall>); meeting the feat brings them: the stall
-- upgrades, a trophy is awarded and one perk lasts for good, either more of
-- one currency in every win or a tool that charges faster. Ids man_01 to
-- man_16 are Rome's. Resource ids are coins (Tokens), food (Treats) and
-- supplies (Materials); stalls are buildings.lua keys. The citizen's
-- arrival scene is its `## Citizens` section in docs/story.md.
local function income(id, amount) return {"THEN_PLAYER_ADD_RESOURCE_PER_LEVEL", id=id, amount=amount} end
local function tool(id) return {"THEN_GAME_CHARGE_TOOL", id=id, amount=1} end

local citizens = {
    {id="man_03", building="arch", who="clem", name="Clem", job="the lamplighter",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=150}, perk=income("food", 10)},
    {id="man_04", building="reindeer_stable", who="ned", name="Ned", job="the farrier",
        If={"IF_PLAYER_MAKE_MATCH", length=5}, perk=tool("hammer")},
    {id="man_02", building="lumber", who="ivar", name="Big Ivar", job="the woodcutter",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="supplies", amount=300}, perk=income("supplies", 60)},
    {id="man_01", building="firework_stall", who="dot", name="Dot", job="the firework maker",
        If={"IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES", amount=10}, perk=tool("bomb")},
    {id="man_05", building="bakery", who="hettie", name="Hettie", job="the icer",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=240}, perk=income("food", 40)},
    {id="man_06", building="chapel", who="mags", name="Old Mags", job="the stonemason",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="supplies", amount=360}, perk=income("supplies", 70)},
    {id="man_07", building="cocoa", who="alder", name="Mrs Alder",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=325}, perk=income("food", 65)},
    {id="man_08", building="igloo", who="olaf", name="Olaf", job="the ice cutter",
        If={"IF_PLAYER_MAKE_MATCH_IN_LEVEL", amount=5, min_length=5}, perk=tool("shield")},
    {id="man_09", building="log_cabin", who="finch", name="Mr Finch", job="the fisherman",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=375}, perk=income("food", 75)},
    {id="man_10", building="toys", who="lotte", name="Lotte", job="the toymaker's apprentice",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="coins", amount=700}, perk=income("coins", 140)},
    {id="man_11", building="candles", who="lucia", name="Lucia", job="the candle girl",
        If={"IF_PLAYER_MAKE_MATCH_SERIES", amount=2, min_length=5}, perk=tool("lightning")},
    {id="man_12", building="post_office", who="penny", name="Mr Penny", job="the postmaster",
        If={"IF_PLAYER_MAKE_MATCH_IN_TIME", amount=15, min_length=3, time=20}, perk=tool("plus")},
    {id="man_13", building="glassblower", who="gianna", name="Gianna", job="the glassblower",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="coins", amount=760}, perk=income("coins", 150)},
    {id="man_14", building="carousel", who="sid", name="Sid", job="the organ-grinder",
        If={"IF_PLAYER_COMPLETE_LEVELS_WITHOUT_LIFE_LOSS", amount=3}, perk=tool("mixer")},
    {id="man_15", building="santa_workshop", who="rolf", name="Rolf", job="the woodcarver",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="coins", amount=875}, perk=income("coins", 175)},
    {id="man_16", building="tree", who="bellamy", name="Mr Bellamy", job="the Fenwick choirmaster",
        If={"IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES", amount=15}, perk=tool("star")},
}

local events = require("match3.user_events").citizen_events(citizens)

-- Rome kept trophy names in locale.xml: one trophy per citizen, TROPHY_NN for man_NN.
local trophies = {}
for _, row in ipairs(citizens) do
    trophies["TROPHY_" .. row.id:sub(5)] = row.job and row.name .. " " .. row.job or row.name
end

return {events=events, trophies=trophies}
