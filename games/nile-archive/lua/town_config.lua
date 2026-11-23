-- town_config.lua — the town screen's layout and wording, merged over the
-- engine's defaults (engine/lua/town/screen.lua): tables merge field by field, lists
-- replace and town.none clears a default.
local l10n = require("l10n")
local tr = l10n.tr
local town = require("town.screen")

return {
    background = "#2E7F7A",
    header = {role = town.none, align = "right", x = 18, y = 20, height = 42, gap = 22, overhang = 0},
    bottom = {margin = 18, bottom = 18, middle = {kind = "custom", from_bottom = 22}},
    markers = {text = "name", label = 18},
    bubble = {width = 320, fill = "#F6E7C1F5", edge = "#6B4410"},
    focus = {lift = 50, min_zoom = 0.6},
    texts = {
        placing = tr("Перетащите постройку или коснитесь свободного места"),
        unchanged = tr("Остров без изменений"),
        blocked = tr("Нужно свободное место на открытом берегу"),
        cant_afford = tr("Недостаточно монет. Переиграйте открытую главу."),
        cant_buy = tr("Эта постройка уже восстановлена"),
        no_room = tr("Откройте берег, чтобы найти свободное место"),
    },
}
