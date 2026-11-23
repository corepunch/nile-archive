-- journey.lua — Christmas Market's story track as data: the scenes
-- (docs/story.md), the levels that fund each stall, the save version and
-- Pip's region lines. The bookkeeping is the engine's (match3.game journey).
return require("match3.game").journey{
    beats = require("story_content"),
    wonder_levels = require("campaign").wonder_levels,
    version = 5,   -- 5: simple scenes; older saves start from their current wish
    -- A first clear's scene plays before its result card, never holding a board back.
    clear_before_result = true,
    regions = {
        "Lantern Lane's clear! There's a lamp post that still works if you kick it.",
        "Gingerbread Green's open! It doesn't smell of gingerbread yet. Give it a week.",
        "Carolers Court's open! Mrs Alder's already in it, singing flat.",
        "Starlight Terrace is open! You can hear the Fenwick choir from up here. Nearly in tune.",
        "Evergreen Hill's open! You can see the whole line from up here!",
    },
}
