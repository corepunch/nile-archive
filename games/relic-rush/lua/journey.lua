-- journey.lua — Relic Rush's story track as data: the beats, the levels that
-- fund each wonder, the save version that introduced keyed beats, the recap
-- for older saves, Mara's region lines and the wonders' changing tap lines.
-- The bookkeeping (checkpoints, scheduling, migration) is the engine's
-- (match3.game journey).
return require("match3.game").journey{
    beats = require("story_content"),
    wonder_levels = require("campaign").wonder_levels,
    version = 6,   -- 6: the hundred-expedition script
    clear_before_result = true,
    ready = function(p, beat)
        -- Tomas speaks at the camp only after he has walked up to the well.
        return beat.key ~= "restore-16" or p.user_events and p.user_events.done.city_well
    end,
    recap = {
        {"elena", "Back at the old harbor. It began with a light under the cliff."},
        {100, {"mara", "The quay is safe and the warning works. Ines left a chart of the other stations."}},
        {80, {"tomas", "Ines came back to warn boats away. Her plan can make the quay safe."},
             {"adrian", "My agreement gave Kessler a claim on the discoveries. We need those plans here."}},
        {60, {"tomas", "I. R. is Ines, my sister. She's been working the far shutter by hand."}},
        {40, {"elena", "Someone mends the far station and warns boats by hand. They left us a note: wall unsafe."}},
        {16, {"mara", "The light answered my lamp. Tomas knows the way to the lower quay."}},
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
        {4, 41, "The crews keep their register by the sun court. A porter looking for a berth can find the boat and its sailing day in the same place."},
        {6, 62, "The keeper gives harbour plans a shelf of their own. A mason can lay a drawing flat here and take the measurements down to the quay."},
        {9, 91, "The temple lends its steps to the harbour watch. A warning read aloud here reaches the porters as well as the pilots who can read the tide marks."},
        {9, 100, "Keepers from the outlying stations meet in the sun court. Each takes home a copy of the harbour chart with the safe landings marked."},
    },
}
