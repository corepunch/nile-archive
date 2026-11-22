-- journey.lua — Relic Rush's story track as data: the beats, the levels that
-- fund each wonder, the save version that introduced keyed beats, the recap
-- for older saves, the wonders' changing tap lines.
-- The bookkeeping (checkpoints, scheduling, migration) is the engine's
-- (match3.game journey).
return require("match3.game").journey{
    beats = require("story_content"),
    wonder_levels = require("campaign").wonder_levels,
    version = 7,   -- Ancient harbour campaign. Older towns resume with a recap.
    clear_before_result = true,
    recap = {
        {"sela", "The flood left our quay without drinking water. My daughter and I came back to mend the pipes."},
        {96, {"oren", "The tide turns my wheel now. Bring Ina's cup down to the fountain."}},
        {80, {"tavi", "Take the night ebb with Oren. Six families are still waiting for their flour."}},
        {60, {"sela", "Help me read Mother's pledge. Can the mill give up the spring?"}},
        {40, {"tavi", "Come to the basin at low tide. The water trapped inside could turn a wheel."}},
        {16, {"oren", "If you turn the spring back to the quay, how do I grind the grain we owe?"}},
        {0, {"oren", "Try the hillside well first. The lower quarter still has to fetch every jar."}},
    },
    regions = {},
    about = {
        {4, 41, "The crews keep their register by the sun court. A porter looking for a berth can find the boat and its sailing day in the same place."},
        {6, 62, "The keeper gives harbour plans a shelf of their own. A mason can lay a drawing flat here and take the measurements down to the quay."},
        {9, 91, "Neighbours bring their witnesses to the temple steps. Both sides can hear the terms before they press a seal into the clay."},
        {9, 100, "Bakers share the temple ovens on feast days. Children waiting for the first loaves fetch water from the quay."},
    },
}
