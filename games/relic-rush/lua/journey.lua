-- journey.lua — Relic Rush's story track as data: the beats, the levels that
-- fund each wonder, the save version that introduced keyed beats, the recap
-- for older saves, the wonders' changing tap lines.
-- The bookkeeping (checkpoints, scheduling, migration) is the engine's
-- (match3.game journey).
local l10n = require("l10n")
local tr = l10n.tr
return require("match3.game").journey{
    beats = require("story_content"),
    wonder_levels = require("campaign").wonder_levels,
    version = 7,   -- Landfall campaign. Older towns resume with a recap.
    clear_before_result = true,
    recap = {
        {"tavi", tr("We came ashore with nothing, builder. Build us a town and I'll send the ship for the families.")},
        {96, {"sela", tr("The families are home. Come and see the new fountain.")}},
        {80, {"oren", tr("The ship's at sea. My birds are watching for her sails.")}},
        {60, {"sela", tr("We keep finding old stones with the same word carved on them.")}},
        {40, {"tavi", tr("Give me a real harbour, builder, and I'll send for the families.")}},
        {16, {"oren", tr("Somebody built harbour steps here long before us. Where did they all go?")}},
        {0, {"sela", tr("There's a spring up in the rocks. Let's start with a well.")}},
    },
    regions = {},
    about = {
        {4, 41, tr("The crews keep their register by the sun court. A porter looking for a berth can find the boat and its sailing day in the same place.")},
        {6, 62, tr("The keeper gives harbour plans a shelf of their own. A mason can lay a drawing flat here and take the measurements down to the quay.")},
        {9, 91, tr("Neighbours bring their witnesses to the temple steps. Both sides can hear the terms before they press a seal into the clay.")},
        {9, 100, tr("Bakers share the temple ovens on feast days. Children waiting for the first loaves fetch water from the quay.")},
    },
}
