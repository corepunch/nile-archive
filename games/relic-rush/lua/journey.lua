-- journey.lua — Relic Rush's story track as data: the beats, the levels that
-- fund each wonder, the save version that introduced keyed beats, the recap
-- for older saves, Mara's region lines and the wonders' changing tap lines.
-- The bookkeeping (checkpoints, scheduling, migration) is the engine's
-- (match3.game journey).
return require("match3.game").journey{
    beats = require("story_content"),
    wonder_levels = require("campaign").wonder_levels,
    version = 4,
    -- The opening line, then the first step whose level the player has reached.
    recap = {
        {"elena", "Back in the Lost Valley. We came to record its people, and nothing leaves this island."},
        {10, {"mara", "The golden sun was only a socket. Someone cut its Heart out with a Vale and Sons chisel."},
             {"adrian", "My father's chisel. He came here thirty years ago. None of his expedition came home."}},
        {6, {"elena", "The sunstones split from inside. Frost is climbing from the lower halls, even in this heat."},
            {"mara", "And all three valley roads lead to the beach. Where did everyone go?"}},
        {3, {"elena", "Tomas says the valley once sang at noon. Someone silenced the temple. We need to learn why."}},
        {0, {"mara", "The Marigold is ready. And Tomas, our island archivist, knows more than he's telling."}},
    },
    regions = {
        "Sunlit coast is clear! Good beach for a landing, if you don't mind the crabs.",
        "Fern meadow's open. I've found three snakes so far, and named them all.",
        "Sun garden's open. Everything's still in rows, as if someone meant to come back.",
        "The heights are open. You can see the whole valley from up here, frost and all.",
        "Temple ridge is open. Nothing between you and that temple now but stairs.",
    },
    -- {kind, from level, line}: the latest reached replaces the catalogue line.
    about = {
        {1, 15, "The frost is above the second terrace. The well cannot last much longer."},
        {1, 30, "The well is filling. Warm water runs through the valley again."},
        {4, 13, "Eleven names remain on the wall. The twelfth has been carefully cut away."},
        {6, 19, "A photograph of twelve men. Beside Cornelius Vale stands a young Tomas Reed."},
        {7, 23, "Six bearings, not stars. One is this island. Five are still out at sea."},
        {8, 26, "Under the old fountain: the only warm room, where Tomas kept the Heart."},
        {9, 30, "At noon the valley sings again. Five lights answer from the sea."},
    },
}
