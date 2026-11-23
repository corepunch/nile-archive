-- journey.lua — Christmas Market's story track as data: the scenes
-- (docs/story.md), the levels that fund each stall, the save version and
-- Pip's region lines. The bookkeeping is the engine's (match3.game journey).
local l10n = require("l10n")
local tr = l10n.tr
return require("match3.game").journey{
    beats = require("story_content"),
    wonder_levels = require("campaign").wonder_levels,
    version = 5,   -- 5: simple scenes; older saves start from their current wish
    -- A first clear's scene plays before its result card, never holding a board back.
    clear_before_result = true,
    regions = {
        tr("Lantern Lane's clear! There's a lamp post that still works if you kick it."),
        tr("Gingerbread Green's open! It doesn't smell of gingerbread yet. Give it a week."),
        tr("Carolers Court's open! Mrs Alder's already in it, singing flat."),
        tr("Starlight Terrace is open! You can hear the Fenwick choir from up here. Nearly in tune."),
        tr("Evergreen Hill's open! You can see the whole line from up here!"),
    },
}
