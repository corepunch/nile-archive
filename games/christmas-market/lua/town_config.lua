-- town_config.lua — the town screen's layout and wording, merged over the
-- engine's defaults (engine/lua/town/screen.lua): tables merge field by field, lists
-- replace and town.none clears a default.
return {
    background = "#738FB5",
    header = {
        role = "wallet",
        align = "center",
        interactive = false,
        y = -2,
        band_height = 72,
        menu = {size = 52, inset = 8, y = 8},
        x = 14,
        height = 32,
        gap = 18,
        overhang = 16,
    },
    bottom = {
        layout = "projects",
        gap = 4,
        bottom = 12,
        margin = 5,
    },
    bubble = {width = 300, title = "gold"},
    weather = {
        snow = {
            height = 0.86,
            fade_from = 0.7,
            layers = {
                {count = 84, radius = 1.4, fall = 36, drift = 11, opacity = 175},
                {count = 44, radius = 2.6, fall = 62, drift = 19, opacity = 235},
            },
        },
    },
    texts = {
        placing = "Drag the building to choose a spot, or scroll the land.",
        unchanged = "Your market is unchanged.",
        blocked = "Choose open snow clear of other buildings.",
        cant_afford = "Match more pieces to earn the resources for this.",
        cant_buy = "Match more pieces to earn the resources for this.",
        no_room = "Open more land before placing this building.",
    },
}
