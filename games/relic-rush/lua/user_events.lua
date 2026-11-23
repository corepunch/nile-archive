-- user_events.lua — Cradle of Rome's settings/user_events.xml, in Lua.
--
-- Every entry is one <UserEvent>: when its If is met it runs each Then, once
-- per profile, and is done. Ids, condition and effect names follow the XML;
-- engine/lua/match3/user_events.lua implements them and lists every type it knows.
-- Rome kept the city half of this flow in other files (city_view.xml's
-- <Upgrade enable_user_events=...>); here the city_* entries below do that,
-- so the whole tutorial-and-upgrade flow reads from this one table.
--
--   id         a unique name; it is also the save key, so never rename one
--   available  false: waits until a THEN_USER_EVENT_AVAILABLE turns it on
--              (Rome's available_by_default="0")
--   from_level, to_level   expeditions (1-based) it counts on, inclusive
--   test       true: --user-events-test fires it at once (Rome's F5 cheat)
--   upgrade    {title, keeper, building}: what a building gains (the phrase, the cast id
--              of the character who runs it and the buildings.lua key; see below)
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
-- TROPHY_25 twice) are given one trophy per upgrade.
--
-- The upgrades' feats and perks are docs/CAMPAIGN_DESIGN.md#upgrades, scaled
-- to Relic Rush's boards.
local l10n = require("l10n")
local tr = l10n.tr
local economy = require("economy")

local events = {
    ---------------------------------------------------------------- tutorials
    -- The move hint: shown with the board's 1st, 2nd, 3rd and 5th suggestion
    -- until the player makes a first line of three.
    {id="hint_01_1",
        If={"IF_GAME_SHOW_MOVE_HINT", amount=1},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text=tr("Swap the two glowing gems to line up three.")}}},
    {id="hint_01_2",
        If={"IF_GAME_SHOW_MOVE_HINT", amount=2},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text=tr("Swipe a gem onto its neighbour to make a line of three.")}}},
    {id="hint_01_3",
        If={"IF_GAME_SHOW_MOVE_HINT", amount=3},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text=tr("Try the glowing pair. Match three in a row or column.")}}},
    {id="hint_01_4",
        If={"IF_GAME_SHOW_MOVE_HINT", amount=5},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text=tr("Tap a gem, then the neighbour to swap it with.")}}},
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
            text=tr("Match on the turquoise plaques to clear them. Clear every plaque to finish the expedition.")}}},
    {id="hint_02_2",
        If={"IF_GAME_DOUBLE_PUZZLE_TILE_APPEAR"},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text=tr("A double plaque needs two matches on it.")}}},
    {id="hint_07",
        If={"IF_GAME_LOCK_APPEAR"},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text=tr("A chain holds its gem in place and takes the first hit.")}}},
    {id="hint_08",
        If={"IF_GAME_DOUBLE_LOCK_APPEAR"},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text=tr("A double chain takes two hits before its gem is free.")}}},
    {id="hint_09",
        If={"IF_GAME_FREEZE_APPEAR"},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text=tr("Ice holds its gem and takes the first hit.")}}},
    -- Rome's hint_10 fires below 900 seconds; Relic Rush runs out of moves instead.
    {id="hint_10", available=false, from_level=2,
        If={"IF_GAME_MOVES_FALL_BELOW", moves=4},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", delay=1,
            text=tr("Three moves left. A charged bonus can clear the last plaques.")}}},
    -- hint_11_<bonus> follow after this table: one per bonus.
    {id="hint_12",
        If={"IF_GAME_SHOP_ENTER"},
        Then={{"THEN_SHOW_TUTORIAL", id="HINT_CITY",
            text=tr("Restorations cost Coins, Supplies and Food. Winning an expedition opens the next one.")}}},

}

-- The sixteen upgrades (docs/CAMPAIGN_DESIGN.md#upgrades), one per Cradle of
-- Rome 2 building that has one: man_01 to man_16 are Rome's ids. Placing the
-- building arms the upgrade (city_<building>); the feat brings it.
local function income(id, amount) return {"THEN_PLAYER_ADD_RESOURCE_PER_LEVEL", id=id, amount=amount} end
local function tool(id) return {"THEN_GAME_CHARGE_TOOL", id=id, amount=1} end

local upgrades = {
    -- TRANSLATORS: an upgrade's title: what the building gains, shown as "Upgraded: %s." and after the building's name
    {id="man_03", building="well", title=tr("a second rope and pulley"), keeper="oren",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=300}, perk=income("food", 20)},
    {id="man_04", building="log_cabin", title=tr("his father's tools sharpened"), keeper="oren",
        If={"IF_PLAYER_MAKE_MATCH", length=5}, perk=tool("hammer")},
    {id="man_02", building="workshop", title=tr("a second saw bench"), keeper="sela",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="supplies", amount=610}, perk=income("supplies", 120)},
    {id="man_01", building="camp", title=tr("a dry tool store"), keeper="sela",
        If={"IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES", amount=10}, perk=tool("bomb")},
    {id="man_05", building="market", title=tr("the hill farms send their carts"), keeper="tavi",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=690}, perk=income("food", 115)},
    {id="man_06", building="trading_post", title=tr("a cart road to the quarry"), keeper="sela",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="supplies", amount=700}, perk=income("supplies", 140)},
    {id="man_07", building="water_mill", title=tr("a second millstone"), keeper="oren",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=800}, perk=income("food", 155)},
    {id="man_08", building="clock_tower", title=tr("a warning chime"), keeper="tavi",
        If={"IF_PLAYER_MAKE_MATCH_IN_LEVEL", amount=5, min_length=5}, perk=tool("shield")},
    {id="man_09", building="gateway", title=tr("a fish market every morning"), keeper="tavi",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="food", amount=1095}, perk=income("food", 215)},
    {id="man_10", building="amphitheater", title=tr("market-day shows"), keeper="oren",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="coins", amount=570}, perk=income("coins", 110)},
    {id="man_11", building="map_room", title=tr("storm charts on the wall"), keeper="tavi",
        If={"IF_PLAYER_MAKE_MATCH_SERIES", amount=2, min_length=5}, perk=tool("lightning")},
    {id="man_12", building="lighthouse", title=tr("a bronze reflector"), keeper="tavi",
        If={"IF_PLAYER_MAKE_MATCH_IN_TIME", amount=15, min_length=3, time=20}, perk=tool("plus")},
    {id="man_13", building="beached_ship", title=tr("a ferry to the hill villages"), keeper="tavi",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="coins", amount=865}, perk=income("coins", 170)},
    {id="man_14", building="observatory", title=tr("the sighting stones aligned"), keeper="sela",
        If={"IF_PLAYER_COMPLETE_LEVELS_WITHOUT_LIFE_LOSS", amount=3}, perk=tool("mixer")},
    {id="man_15", building="museum", title=tr("a reading room open to all"), keeper="sela",
        If={"IF_PLAYER_GET_RESOURCE_IN_LEVEL", id="coins", amount=1245}, perk=income("coins", 245)},
    {id="man_16", building="temple", title=tr("the keepers' watch roster"), keeper="oren",
        If={"IF_PLAYER_MAKE_EFFECTIVE_MOVES_SERIES", amount=15}, perk=tool("star")},
}
for _, event in ipairs(require("match3.user_events").upgrade_events(upgrades)) do table.insert(events, event) end

-- The first line gem and the first rainbow gem each explain themselves once.
table.insert(events, {id="hint_line_gem",
    If={"IF_PLAYER_MAKE_MATCH", length=4, max_length=4},
    Then={{"THEN_SHOW_TUTORIAL", id="HINT_LINE_GEM", text=tr("Four in a line leave a striped gem. Match it to sweep its line.")}}})
table.insert(events, {id="hint_rainbow_gem",
    If={"IF_PLAYER_MAKE_MATCH", length=5},
    Then={{"THEN_SHOW_TUTORIAL", id="HINT_RAINBOW_GEM", text=tr("Five in a line leave a rainbow gem. Swap it to clear one kind.")}}})

-- hint_11_<bonus>: Rome's IF_GAME_BONUS_READY hints, one per bonus.
for _, slot in ipairs(economy.bonus_slots) do
    for _, bonus in ipairs(slot.levels) do
        table.insert(events, {id="hint_11_" .. bonus.key,
            If={"IF_GAME_BONUS_READY", id=bonus.key},
            -- TRANSLATORS: the first %s is a bonus tool's name, the second the sentence saying what it does
            Then={{"THEN_SHOW_TUTORIAL", id="HINT_ARROW", text=tr("%s is charged. Tap it. %s"):format(bonus.name, bonus.effect)}}})
    end
end

-- Rome kept trophy names in locale.xml: one trophy per upgrade, TROPHY_NN for man_NN.
local trophies = {}
local island = require("island")
for _, row in ipairs(upgrades) do
    trophies["TROPHY_" .. row.id:sub(5)] = island.buildings[island.kinds[row.building] + 1].name .. ": " .. row.title
end

return {events=events, trophies=trophies}
