-- town_config.lua — the town screen's layout and wording, merged over the
-- engine's defaults (engine/lua/town/screen.lua): tables merge field by field, lists
-- replace and town.none clears a default.
local l10n = require("l10n")
local tr = l10n.tr

return {
    background = "#166E77",
    smooth_pan = true,
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
        build = 86, play = 100, height = 100, secondary_height = 86,   -- Build and Pause match the board's bonus buttons (match3.TOOL_SIZE)
        bottom = 12, pause = true,
    },
    bubble = {width = 300, title = "gold", text = "cream", em = 18, fill = "bubble_face", edge = "bubble_edge"},
    texts = {
        placing = tr("Drag the building to choose a spot, or scroll the land."),
        unchanged = tr("Your island is unchanged."),
        blocked = tr("Choose open grass clear of other buildings."),
        cant_afford = tr("Earn more expedition treasures to build this."),
        cant_buy = tr("Earn more expedition treasures to build this."),
        no_room = tr("Open more land before placing this building."),
    },
}
