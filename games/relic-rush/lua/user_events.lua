-- user_events.lua — Cradle of Rome's settings/user_events.xml, in Lua.
--
-- Every entry is one <UserEvent>: when its If is met it runs each Then, once
-- per profile, and is done. Ids, condition and effect names follow the XML;
-- engine/lua/match3/user_events.lua implements them and lists every type it knows.
-- Rome kept the city half of this flow in other files (city_view.xml's
-- <Upgrade enable_user_events=...>); here the city_* entries below do that,
-- so the whole tutorial-and-citizen flow reads from this one table.
--
--   id         a unique name; it is also the save key, so never rename one
--   available  false: waits until a THEN_USER_EVENT_AVAILABLE turns it on
--              (Rome's available_by_default="0")
--   from_level, to_level   expeditions (1-based) it counts on, inclusive
--   test       true: --user-events-test fires it at once (Rome's F5 cheat)
--   citizen    {who, name, job, building}: the person a building gains (cast id,
--              display name, trade and the buildings.lua key; see the citizens below)
--   If         {type, attributes...}
--   Then       a list of {type, attributes...}
--
-- Resource ids are names, not Rome's numbers: coins (Rome 1, gold), food (3),
-- supplies (2, materials) and score (4). Piece and bonus ids are economy.lua
-- keys (water, cut-blocks, hammer, mixer ...); buildings are buildings.lua
-- keys. Rome's mode attribute is gone: Relic Rush has one mode.
--
-- What is not ported: Rome's per-piece "first appearance" hints (hint_04_*)
-- are progress.lua's opening notices, which already name the building that
-- unlocked the piece. A timer hint becomes a moves hint: Relic Rush counts
-- moves, not seconds. Rome's duplicate trophy ids (TROPHY_19 three times,
-- TROPHY_25 twice) are given one trophy per citizen.
--
-- The citizens' feats and perks are docs/CAMPAIGN_DESIGN.md#citizens, scaled
-- to Relic Rush's boards.
local economy = require("economy")

local events = {
    ---------------------------------------------------------------- tutorials
    -- The move hint: shown with the board's 1st, 2nd, 3rd and 5th suggestion
    -- until the player makes a first line of three.
    {id="hint_01_1",
        If={"IF_GAME_SHOW_MOVE_HINT", amount=1},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text="Swap the two glowing gems to line up three."}}},
    {id="hint_01_2",
        If={"IF_GAME_SHOW_MOVE_HINT", amount=2},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text="Swipe a gem onto its neighbour to make a line of three."}}},
    {id="hint_01_3",
        If={"IF_GAME_SHOW_MOVE_HINT", amount=3},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text="Lines run three ways on the hex board. Try the glowing pair."}}},
    {id="hint_01_4",
        If={"IF_GAME_SHOW_MOVE_HINT", amount=5},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text="Tap a gem, then the neighbour to swap it with."}}},
    {id="hint_01_close",
        If={"IF_PLAYER_MAKE_MATCH", length=3},
        Then={
            {"THEN_USER_EVENT_AVAILABLE", id="hint_01_1 hint_01_2 hint_01_3 hint_01_4", available=false},
            {"THEN_USER_EVENT_AVAILABLE", id="hint_02_1 hint_10", available=true},
        }},

    -- Board features, the first time a board opens with one.
    {id="hint_02_1", available=false,
        If={"IF_GAME_PUZZLE_TILE_APPEAR"},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", delay=7,
            text="Match on the turquoise plaques to clear them. Clear every plaque to finish the expedition."}}},
    {id="hint_02_2",
        If={"IF_GAME_DOUBLE_PUZZLE_TILE_APPEAR"},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text="A double plaque needs two matches on it."}}},
    {id="hint_07",
        If={"IF_GAME_LOCK_APPEAR"},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text="A chain holds its gem in place and takes the first hit."}}},
    {id="hint_08",
        If={"IF_GAME_DOUBLE_LOCK_APPEAR"},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text="A double chain takes two hits before its gem is free."}}},
    {id="hint_09",
        If={"IF_GAME_FREEZE_APPEAR"},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text="Ice holds its gem and takes the first hit."}}},
    -- Rome's hint_10 fires below 900 seconds; Relic Rush runs out of moves instead.
    {id="hint_10", available=false, from_level=2,
        If={"IF_GAME_MOVES_FALL_BELOW", moves=4},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", delay=1,
            text="Three moves left. A charged bonus can clear the last plaques."}}},
    -- hint_11_<bonus> follow after this table: one per bonus.
    {id="hint_12",
        If={"IF_GAME_SHOP_ENTER"},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_CITY",
            text="Restorations cost Coins, Supplies and Food. Winning an expedition opens the next one."}}},

}

-- The sixteen citizens (docs/CAMPAIGN_DESIGN.md#citizens), one per Cradle of
-- Rome 2 building that has one: man_01 to man_16 are Rome's ids. Placing the
-- building arms the citizen (city_<building>); the feat brings them.
local function income(id, amount) return {"THEN_PLAYER_ADD_RESOURCE_PER_LEVEL", id=id, amount=amount} end
local function tool(id) return {"THEN_GAME_CHARGE_TOOL", id=id, amount=1} end

local citizens = {
    {id="man_03", building="well", who="lupe", name="Lupe", job="the water-carrier",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=150}, perk=income("food", 10)},
    {id="man_04", building="log_cabin", who="bastian", name="Old Bastian", job="the trapper",
        If={"IF_PLAYER_MAKE_MATCH", length=5}, perk=tool("hammer")},
    {id="man_02", building="workshop", who="joaquin", name="Joaquín", job="the carpenter",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="supplies", amount=300}, perk=income("supplies", 60)},
    {id="man_01", building="camp", who="dita", name="Dita", job="the blaster",
        If={"IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES", amount=10}, perk=tool("bomb")},
    {id="man_05", building="market", who="marisol", name="Auntie Marisol", job="the trader",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=325}, perk=income("food", 55)},
    {id="man_06", building="trading_post", who="basile", name="Basile", job="the stonecutter",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="supplies", amount=300}, perk=income("supplies", 60)},
    {id="man_07", building="water_mill", who="hana", name="Hana", job="the miller",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=430}, perk=income("food", 85)},
    {id="man_08", building="clock_tower", who="ferro", name="Ferro", job="the clockmender",
        If={"IF_PLAYER_MAKE_MATCH_IN_LEVEL", amount=5, min_length=5}, perk=tool("shield")},
    {id="man_09", building="gateway", who="nilo", name="Nilo", job="the fisher",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=700}, perk=income("food", 140)},
    {id="man_10", building="amphitheater", who="zaza", name="Zaza", job="the drummer",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="coins", amount=330}, perk=income("coins", 65)},
    {id="man_11", building="map_room", who="ruth", name="Ruth", job="the cartographer",
        If={"IF_PLAYER_MAKE_MATCH_SERIES", amount=2, min_length=5}, perk=tool("lightning")},
    {id="man_12", building="lighthouse", who="ulla", name="Captain Ulla",
        If={"IF_PLAYER_MAKE_MATCH_IN_TIME", amount=15, min_length=3, time=20}, perk=tool("plus")},
    {id="man_13", building="beached_ship", who="pike", name="Pike", job="the shipwright",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="coins", amount=575}, perk=income("coins", 115)},
    {id="man_14", building="observatory", who="amani", name="Dr Amani", job="the astronomer",
        If={"IF_PLAYER_COMPLETE_LEVELS_WITHOUT_LIFE_LOSS", amount=3}, perk=tool("mixer")},
    {id="man_15", building="museum", who="sato", name="Mr Sato", job="the curator",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="coins", amount=775}, perk=income("coins", 155)},
    {id="man_16", building="temple", who="ixchel", name="Ixchel", job="the storyteller",
        If={"IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES", amount=15}, perk=tool("star")},
}
for _, event in ipairs(require("match3.user_events").citizen_events(citizens)) do table.insert(events, event) end

-- hint_11_<bonus>: Rome's IF_GAME_BONUS_READY hints, one per bonus.
for _, slot in ipairs(economy.bonus_slots) do
    for _, bonus in ipairs(slot.levels) do
        table.insert(events, {id="hint_11_" .. bonus.key,
            If={"IF_GAME_BONUS_READY", id=bonus.key},
            Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text=bonus.name .. " is charged. Tap it. " .. bonus.effect}}})
    end
end

-- Rome kept trophy names in locale.xml: one trophy per citizen, TROPHY_NN for man_NN.
local trophies = {}
for _, row in ipairs(citizens) do
    trophies["TROPHY_" .. row.id:sub(5)] = row.job and row.name .. " " .. row.job or row.name
end

return {events=events, trophies=trophies}
