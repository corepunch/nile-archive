-- town_config.lua — the town screen's layout and wording, merged over the
-- engine's defaults (engine/lua/town.lua): tables merge field by field, lists
-- replace and town.none clears a default.
local tool_size = require("match3").TOOL_SIZE
return {
    background = "#166E77",
    header = {
        role = "wallet",
        align = "center",
        interactive = false,
        y = -2,
        band_height = 72,
        x = 18,
        height = 32,
        gap = 18,
        overhang = 12,
    },
    bottom = {
        layout = "play-primary",
        bottom = 9,
        height = 124,
        margin = 8,
        build = tool_size,
        play = 124,
        secondary_height = tool_size,
        pause = true,
        middle = {kind = "button"},
    },
    -- Request and building markers as large as the Options button, with no
    -- readout under them: their gauges and the ready trail say it all.
    rail = {size = tool_size, gap = 4, caption = 0},
    bubble = {width = 300, title = "gold", text = "cream", em = 18, fill = "bubble_face", edge = "bubble_edge"},
    texts = {
        placing = "Drag the building to choose a spot, or scroll the land.",
        unchanged = "Your island is unchanged.",
        blocked = "Choose open grass clear of other buildings.",
        cant_afford = "Earn more expedition treasures to build this.",
        cant_buy = "Earn more expedition treasures to build this.",
        no_room = "Open more land before placing this building.",
    },
}
