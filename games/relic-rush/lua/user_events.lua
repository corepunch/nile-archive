-- user_events.lua — Cradle of Rome's settings/user_events.xml, in Lua.
--
-- Every entry is one <UserEvent>: when its If is met it runs each Then, once
-- per profile, and is done. Ids, condition and effect names follow the XML;
-- user_events_runtime.lua implements them and lists every type it knows.
-- Rome kept the city half of this flow in other files (city_view.xml's
-- <Upgrade enable_user_events=...>); here the city_* entries below do that,
-- so the whole tutorial-and-citizen flow reads from this one table.
--
--   id         a unique name; it is also the save key, so never rename one
--   available  false: waits until a THEN_USER_EVENT_AVAILABLE turns it on
--              (Rome's available_by_default="0")
--   from_level, to_level   expeditions (1-based) it counts on, inclusive
--   test       true: --user-events-test fires it at once (Rome's F5 cheat)
--   citizen    the person a building gains (for trophies and the docs)
--   If         {type, attributes...}
--   Then       a list of {type, attributes...}
--
-- Resource ids are names, not Rome's numbers: coins (Rome 1, gold), food (3),
-- supplies (2, materials) and score (4). Piece and bonus ids are economy.lua
-- keys (water, cut-blocks, hammer, star-ii ...); buildings are buildings.lua
-- keys. Rome's mode attribute is gone: Relic Rush has one mode.
--
-- What is not ported: Rome's per-piece "first appearance" hints (hint_04_*)
-- are progress.lua's opening notices, which already name the building that
-- unlocked the piece. A timer hint becomes a moves hint: Relic Rush counts
-- moves, not seconds. Rome's duplicate trophy ids (TROPHY_19 three times,
-- TROPHY_25 twice) are given one trophy per citizen.
--
-- The citizens' amounts are a first pass, scaled to Relic Rush's purses
-- (a ladder building costs a few hundred of each resource): tune them with
-- the economy plan in docs/resource-expedition.md.
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
            text="Match on the blue plaques to clear them. Clear every plaque to finish the expedition."}}},
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
            text="Restorations cost Coins, Supplies and Food. Story buildings open the next expedition."}}},

    ---------------------------------------------------------------- the city
    -- Placing a building lets its citizen arrive (Rome: city_view.xml).
    {id="city_workshop", If={"IF_PLAYER_BUILT_CONSTRUCTION", id="workshop"},
        Then={{"THEN_USER_EVENT_AVAILABLE", id="man_01", available=true}}},
    {id="city_log_cabin", If={"IF_PLAYER_BUILT_CONSTRUCTION", id="log_cabin"},
        Then={{"THEN_USER_EVENT_AVAILABLE", id="man_02", available=true}}},
    {id="city_archive", If={"IF_PLAYER_BUILT_CONSTRUCTION", id="archive"},
        Then={{"THEN_USER_EVENT_AVAILABLE", id="man_03", available=true}}},
    {id="city_market", If={"IF_PLAYER_BUILT_CONSTRUCTION", id="market"},
        Then={{"THEN_USER_EVENT_AVAILABLE", id="man_04", available=true}}},
    {id="city_lodge", If={"IF_PLAYER_BUILT_CONSTRUCTION", id="lodge"},
        Then={{"THEN_USER_EVENT_AVAILABLE", id="man_05", available=true}}},
    {id="city_water_mill", If={"IF_PLAYER_BUILT_CONSTRUCTION", id="water_mill"},
        Then={{"THEN_USER_EVENT_AVAILABLE", id="man_06", available=true}}},
    {id="city_observatory", If={"IF_PLAYER_BUILT_CONSTRUCTION", id="observatory"},
        Then={{"THEN_USER_EVENT_AVAILABLE", id="man_07", available=true}}},
    {id="city_map_room", If={"IF_PLAYER_BUILT_CONSTRUCTION", id="map_room"},
        Then={{"THEN_USER_EVENT_AVAILABLE", id="man_08", available=true}}},
    {id="city_fountain", If={"IF_PLAYER_BUILT_CONSTRUCTION", id="fountain"},
        Then={{"THEN_USER_EVENT_AVAILABLE", id="man_09", available=true}}},
    {id="city_amphitheater", If={"IF_PLAYER_BUILT_CONSTRUCTION", id="amphitheater"},
        Then={{"THEN_USER_EVENT_AVAILABLE", id="man_010", available=true}}},
    {id="city_trading_post", If={"IF_PLAYER_BUILT_CONSTRUCTION", id="trading_post"},
        Then={{"THEN_USER_EVENT_AVAILABLE", id="man_011", available=true}}},

    ---------------------------------------------------------------- citizens
    -- A citizen comes for a feat of play and stays: they upgrade their
    -- building and pay something on every later expedition.

    -- Rome: carpenter, Saw-Mill, first match of five.
    {id="man_01", available=false, test=true, citizen="The carpenter",
        If={"IF_PLAYER_MAKE_MATCH", length=5},
        Then={
            {"THEN_SHOW_HINT", id="HINT_INFO", text="Line of five! The carpenter joins the workshop: +5 Supplies per expedition."},
            {"THEN_PLAYER_ADD_TROPHY", id="TROPHY_01"},
            {"THEN_CITY_UPGRADE_BUILDING", id="workshop"},
            {"THEN_PLAYER_ADD_RESOURCE_PER_LEVEL", id="supplies", amount=5},
        }},
    -- Rome: smith, Forge, 10,000 points within levels 0–10.
    {id="man_02", available=false, citizen="The trapper", to_level=12,
        If={"IF_PLAYER_GET_RESOURCE", id="coins", amount=250},
        Then={
            {"THEN_SHOW_HINT", id="HINT_INFO", text="250 Coins banked early! The trapper packs more powder: Dynamite gems charge faster."},
            {"THEN_PLAYER_ADD_TROPHY", id="TROPHY_02"},
            {"THEN_CITY_UPGRADE_BUILDING", id="log_cabin"},
            {"THEN_GAME_CHANGE_CHIP_WEIGHT", id="dynamite", amount=9},
        }},
    -- Rome: miner, Quarry, 2,000 materials in a level.
    {id="man_03", available=false, citizen="The stonecutter",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="supplies", amount=120},
        Then={
            {"THEN_SHOW_HINT", id="HINT_INFO", text="120 Supplies in one go! The stonecutter joins the archive: +10 Supplies per expedition."},
            {"THEN_PLAYER_ADD_TROPHY", id="TROPHY_03"},
            {"THEN_CITY_UPGRADE_BUILDING", id="archive"},
            {"THEN_PLAYER_ADD_RESOURCE_PER_LEVEL", id="supplies", amount=10},
        }},
    -- Rome: miller, Mill, 15 matches in rapid succession.
    {id="man_04", available=false, citizen="The trader",
        If={"IF_PLAYER_MAKE_MATCH_IN_TIME", min_length=3, amount=15, time=90},
        Then={
            {"THEN_SHOW_HINT", id="HINT_INFO", text="15 lines in 90 seconds! The trader opens a stall: +5 Food per expedition."},
            {"THEN_PLAYER_ADD_TROPHY", id="TROPHY_04"},
            {"THEN_CITY_UPGRADE_BUILDING", id="market"},
            {"THEN_PLAYER_ADD_RESOURCE_PER_LEVEL", id="food", amount=5},
        }},
    -- Rome: peasant, Field, 3,000 food in a level.
    {id="man_05", available=false, citizen="The forager",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=80},
        Then={
            {"THEN_SHOW_HINT", id="HINT_INFO", text="80 Food in one go! The forager joins the lodge: +8 Food per expedition."},
            {"THEN_PLAYER_ADD_TROPHY", id="TROPHY_05"},
            {"THEN_CITY_UPGRADE_BUILDING", id="lodge"},
            {"THEN_PLAYER_ADD_RESOURCE_PER_LEVEL", id="food", amount=8},
        }},
    -- Rome: wine maker, Tavern, a combo of two.
    {id="man_06", available=false, citizen="The miller",
        If={"IF_PLAYER_MAKE_COMBO", length=2},
        Then={
            {"THEN_SHOW_HINT", id="HINT_INFO", text="A cascade! The miller turns the wheel: +3 Food per expedition."},
            {"THEN_PLAYER_ADD_TROPHY", id="TROPHY_06"},
            {"THEN_CITY_UPGRADE_BUILDING", id="water_mill"},
            {"THEN_PLAYER_ADD_RESOURCE_PER_LEVEL", id="food", amount=3},
        }},
    -- Rome: priest, Pantheon, a level in under three minutes.
    {id="man_07", available=false, citizen="The astronomer",
        If={"IF_PLAYER_COMPLETE_LEVELS_IN_TIME", amount=1, time=120},
        Then={
            {"THEN_SHOW_HINT", id="HINT_INFO", text="Done in two minutes! The astronomer tunes the lens: Star II gems charge faster."},
            {"THEN_PLAYER_ADD_TROPHY", id="TROPHY_07"},
            {"THEN_CITY_UPGRADE_BUILDING", id="observatory"},
            {"THEN_GAME_CHANGE_CHIP_WEIGHT", id="star-ii", amount=9},
        }},
    -- Rome: scholar, Tabularium, a combo of three.
    {id="man_08", available=false, citizen="The cartographer",
        If={"IF_PLAYER_MAKE_COMBO", length=3},
        Then={
            {"THEN_SHOW_HINT", id="HINT_INFO", text="Three waves from one move! The cartographer joins: Plus gems charge faster."},
            {"THEN_PLAYER_ADD_TROPHY", id="TROPHY_08"},
            {"THEN_CITY_UPGRADE_BUILDING", id="map_room"},
            {"THEN_GAME_CHANGE_CHIP_WEIGHT", id="plus", amount=9},
            {"THEN_GAME_CHANGE_CHIP_WEIGHT", id="plus-ii", amount=9},
        }},
    -- Rome: fisherman, Port, three matches of five in a level.
    {id="man_09", available=false, citizen="The fisher",
        If={"IF_PLAYER_MAKE_MATCH_IN_LEVEL", min_length=5, amount=2},
        Then={
            {"THEN_SHOW_HINT", id="HINT_INFO", text="Two lines of five! The fisher works the fountain pool: +10 Food per expedition."},
            {"THEN_PLAYER_ADD_TROPHY", id="TROPHY_09"},
            {"THEN_CITY_UPGRADE_BUILDING", id="fountain"},
            {"THEN_PLAYER_ADD_RESOURCE_PER_LEVEL", id="food", amount=10},
        }},
    -- Rome: gladiator, Colosseum, a chain reaction of 15 blows. Relic Rush's
    -- refill damps long cascades, so two follow-up waves is the feat.
    {id="man_010", available=false, citizen="The performer",
        If={"IF_PLAYER_MAKE_AUTOMATCH_CHAIN", amount=2},
        Then={
            {"THEN_SHOW_HINT", id="HINT_INFO", text="A chain reaction! The performer fills the amphitheatre: Shield gems charge faster."},
            {"THEN_PLAYER_ADD_TROPHY", id="TROPHY_10"},
            {"THEN_CITY_UPGRADE_BUILDING", id="amphitheater"},
            {"THEN_GAME_CHANGE_CHIP_WEIGHT", id="shield", amount=9},
            {"THEN_GAME_CHANGE_CHIP_WEIGHT", id="lightning", amount=9},
        }},
    -- Rome: orator, Forum, 3,000 gold in a level: every bonus piece pays more.
    {id="man_011", available=false, citizen="The trader's clerk",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="coins", amount=150},
        Then={
            {"THEN_SHOW_HINT", id="HINT_INFO", text="150 Coins in one go! The clerk keeps the books: every bonus gem charges faster."},
            {"THEN_PLAYER_ADD_TROPHY", id="TROPHY_11"},
            {"THEN_CITY_UPGRADE_BUILDING", id="trading_post"},
            {"THEN_GAME_CHANGE_CHIP_WEIGHT", id="hammer", amount=8},
            {"THEN_GAME_CHANGE_CHIP_WEIGHT", id="shield", amount=8},
            {"THEN_GAME_CHANGE_CHIP_WEIGHT", id="star", amount=8},
            {"THEN_GAME_CHANGE_CHIP_WEIGHT", id="plus", amount=8},
        }},
}

-- hint_11_<bonus>: Rome's IF_GAME_BONUS_READY hints, one per bonus.
for _, slot in ipairs(economy.bonus_slots) do
    for _, bonus in ipairs(slot.levels) do
        table.insert(events, {id="hint_11_" .. bonus.key,
            If={"IF_GAME_BONUS_READY", id=bonus.key},
            Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text=bonus.name .. " is charged. Tap it. " .. bonus.effect}}})
    end
end

-- Rome kept trophy names in locale.xml.
local trophies = {
    TROPHY_01="Carpenter", TROPHY_02="Trapper", TROPHY_03="Stonecutter", TROPHY_04="Trader",
    TROPHY_05="Forager", TROPHY_06="Miller", TROPHY_07="Astronomer", TROPHY_08="Cartographer",
    TROPHY_09="Fisher", TROPHY_10="Performer", TROPHY_11="Clerk",
}

return {events=events, trophies=trophies}
