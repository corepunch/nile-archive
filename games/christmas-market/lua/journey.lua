-- journey.lua — Christmas Market's story track as data: the beats, the levels
-- that fund each stall, the save version that introduced keyed beats, the
-- recap for older saves, Pip's region lines (docs/story.md#small-lines) and
-- the tap lines that change as the threads move. The bookkeeping is the
-- engine's (match3.game journey).
return require("match3.game").journey{
    beats = require("story_content"),
    wonder_levels = require("campaign").wonder_levels,
    version = 3,
    -- The opening line, then the first step whose level the player has reached.
    recap = {
        {"noelle", "Back in Bellmere! Gran sent me to get her old market going for Christmas. Three weeks, that's all."},
        {7, {"agnes", "The oven's lit, the lights are going up, and you've still got that parcel. There's buns."},
            {"pip", "And the Kind Word box is busy! You never ask who. That's the rule."}},
        {0, {"agnes", "You're Rosa's girl. Come in when you can't feel your nose. There's buns."}},
    },
    regions = {
        "Lantern Lane's clear! There's a lamp post that still works if you kick it.",
        "Gingerbread Green's open! It doesn't smell of gingerbread yet. Give it a week.",
        "Carolers Court's open! Mrs Alder's already in it, singing flat.",
        "Starlight Terrace is open! You can see all the way to Fenwick. We're winning.",
        "Evergreen Hill's open! You can see the whole line from up here!",
    },
    -- {kind, from level, line}: the latest reached replaces the catalogue line.
    about = {
        {0, 22, "Theo's trees go round it now. He says it was his idea."},
        {2, 20, "Two cups on the windowsill."},
        {4, 20, "The window's been cleaned. On both sides of the square."},
        {7, 23, "Twelve horses, twelve families. The third one's a touch to the left."},
        {9, 30, "There's a broom against the arch. Nobody's moved it."},
    },
}
