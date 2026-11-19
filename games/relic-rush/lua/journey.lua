-- journey.lua — Relic Rush's story track as data: the beats, the levels that
-- fund each wonder, the save version that introduced keyed beats, the recap
-- for older saves, Mara's region lines and the wonders' changing tap lines.
-- The bookkeeping (checkpoints, scheduling, migration) is the engine's
-- (match3.game journey).
local economy = require("economy")

return require("match3.game").journey{
    beats = require("story_content"),
    wonder_levels = require("campaign").wonder_levels,
    version = 5,
    clear_before_result = true,
    ready = function(p, beat)
        return beat.key ~= "restore-04" or p.user_events and p.user_events.done.city_well
    end,
    recap = {
        {"elena", "Back at the old harbor. It began with a light under the cliff."},
        {30, {"mara", "The quay is safe and the warning works. Ines left a chart of the other stations."}},
        {20, {"tomas", "Ines came back to warn boats away. Her repair plan can make the quay safe."},
             {"adrian", "My agreement gave Kessler a claim on the discoveries. We need those plans here."}},
        {10, {"elena", "Someone at the tide room changed the old warning. We need to learn who."}},
        {4, {"mara", "The light answered my lamp. Tomas knows the steps to the lower quay."}},
        {0, {"mara", "The landing is clear. Keep an eye on the light below the cliff."}},
    },
    regions = {
        false,
        false,
        "Sun garden's open. There's a dry place to spread a chart.",
        "The heights are open. From here we can see the boats before they turn in.",
        "Temple ridge is open. We can get to the old warning station from here.",
    },
    -- {kind, from level, line}: the latest reached replaces the catalogue line.
    about = {
        {0, 10, "The village shares the night watch at the quay steps."},
        {economy.WELL_KIND, 4, economy.unlock_text(economy.unlock_of("well"))},
        {economy.WELL_KIND, 6, "Tomas helps keep the well running for the expedition."},
        {economy.WORKSHOP_KIND, 7, economy.unlock_text(economy.unlock_of("workshop"))},
        {economy.WORKSHOP_KIND, 9, "The sawmill cut the timber tread for the quay steps."},
        {3, 9, economy.unlock_text(economy.unlock_of("market"))},
        {4, 13, "The port keeps a register of the harbor crews."},
        {5, 16, "The deckhands have a table in the hall to go over the harbor log."},
        {6, 19, "The inspection cabinet holds the drawings for this aqueduct."},
        {6, 20, "Ines's plan stays here, where the keepers can consult it."},
        {7, 23, "The mausoleum roof gives boats a landmark above the trees."},
        {8, 29, "The bypass feeds the fountain basin."},
        {9, 26, "The Forum posts the warning for everyone working on the quay."},
        {9, 30, "The wall holds and the warning carries. More stations are marked on Ines's chart."},
    },
}
