-- journey.lua — Relic Rush's story track as data: the beats, the levels that
-- fund each wonder, the save version that introduced keyed beats, the recap
-- for older saves, Mara's region lines and the wonders' changing tap lines.
-- The bookkeeping (checkpoints, scheduling, migration) is the engine's
-- (match3.game journey).
return require("match3.game").journey{
    beats = require("story_content"),
    wonder_levels = require("campaign").wonder_levels,
    version = 5,
    clear_before_result = true,
    recap = {
        {"elena", "Back in the Lost Valley. It began with a light under the cliff."},
        {30, {"mara", "The quay is safe and the warning works. Ines left a chart of the other stations."}},
        {20, {"tomas", "Ines came back to warn boats away. Her repair plan can make the quay safe."},
             {"adrian", "My agreement gave Kessler a claim on the discoveries. We need those plans here."}},
        {10, {"elena", "Someone at the tide room changed the old warning. We need to learn who."}},
        {4, {"mara", "The light answered my lamp. The chart from the well shows a route to the lower quay."}},
        {0, {"mara", "The landing is clear. Keep an eye on the light below the cliff."}},
    },
    regions = {
        "Sunlit coast is clear. We can see where the old quay meets the water.",
        "Fern meadow's open. Watch for old shore marks under the leaves.",
        "Sun garden's open. There is room here to lay out the repair plans.",
        "The heights are open. From here we can see the boats before they turn in.",
        "Temple ridge is open. We can get to the old warning station from here.",
    },
    -- {kind, from level, line}: the latest reached replaces the catalogue line.
    about = {
        {0, 1, "Mara's lamp fits the bracket. The light under the cliff can see it."},
        {1, 4, "A chart in the pump cover traces the old cable to the tide room."},
        {2, 7, "The tools Tomas used to maintain the tide room are ready again."},
        {3, 9, "The crew stocks up here before taking the old path to the tide room."},
        {4, 13, "A dry place to lay out the note that led the crew to Ines."},
        {5, 16, "There is a dry bunk here for the keeper when she can get ashore."},
        {6, 19, "Tomas keeps the old records here. Elena is looking for the signed plan."},
        {6, 20, "Ines's plan stays here, where the keepers can consult it."},
        {7, 23, "From the lookout, a lamp can guide boats away from the damaged quay."},
        {8, 26, "Ines's diversion brings water through the old channel again."},
        {9, 29, "The restored station can warn boats all the way out at sea."},
        {9, 30, "The wall holds and the warning carries. More stations are marked on Ines's chart."},
    },
}
