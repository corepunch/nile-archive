-- town_config.lua — the town screen's layout and wording, merged over the
-- engine's defaults (engine/lua/town/screen.lua): tables merge field by field, lists
-- replace and town.none clears a default.
return {
    background = "#166E77",
    header = {
        role = "wallet",
        align = "center",
        interactive = false,
        y = -2,
        band_height = 72,
        menu = {size = 52, inset = 8, y = 8},
        x = 18,
        height = 32,
        gap = 18,
        overhang = 12,
    },
    bottom = {
        layout = "projects",
        bottom = 9,
        height = 120,
        margin = 8,
    },
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
