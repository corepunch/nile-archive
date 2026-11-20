-- journey.lua — Christmas Market's story track as data: the beats, the levels
-- that fund each stall, the save version that introduced keyed beats, the
-- recap for older saves, Pip's region lines (docs/story.md#small-lines) and
-- the tap lines that change as the threads move. The bookkeeping is the
-- engine's (match3.game journey).
return require("match3.game").journey{
    beats = require("story_content"),
    wonder_levels = require("campaign").wonder_levels,
    version = 4,   -- 4: the hundred-wish script
    -- The opening line, then the first step whose level the player has reached.
    recap = {
        {"noelle", "Back in Bellmere! Gran sent me to get her old market going for Christmas. Just till the twenty-sixth."},
        {21, {"agnes", "The oven's lit, the lights are going up, and you've still got that parcel. There's buns."},
            {"pip", "And the Kind Word box is busy! You never ask who. That's the rule."}},
        {0, {"agnes", "You're Rosa's girl. Come in when you can't feel your nose. There's buns."}},
    },
    regions = {
        "Lantern Lane's clear! There's a lamp post that still works if you kick it.",
        "Gingerbread Green's open! It doesn't smell of gingerbread yet. Give it a week.",
        "Carolers Court's open! Mrs Alder's already in it, singing flat.",
        "Starlight Terrace is open! You can hear the Fenwick choir from up here. Nearly in tune.",
        "Evergreen Hill's open! You can see the whole line from up here!",
    },
    -- {kind, from level, line}: the latest reached replaces the catalogue line.
    about = {
        {0, 30, "Theo's trees go round it now. He says it was his idea."},
        {2, 66, "Two cups on the windowsill."},
        {3, 32, "A cup waiting on the counter. Mrs Alder made sure of it."},
        {4, 66, "The window's been cleaned. On both sides of the square."},
        {7, 77, "Pip keeps a wind-up top in his pocket for anyone too small to ride."},
        {9, 100, "A lamp for the last walker home. There's one left by the fir."},
    },
}
