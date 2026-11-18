-- town_config.lua — the town screen's layout and wording, merged over the
-- engine's defaults (engine/lua/town.lua): tables merge field by field, lists
-- replace and town.none clears a default.
local town = require("town")

return {
    background = "#2E7F7A",
    header = {role = town.none, align = "right", x = 18, y = 20, height = 42, gap = 22, overhang = 0},
    bottom = {margin = 18, bottom = 18, middle = {kind = "custom", from_bottom = 22}},
    markers = {text = "name", label = 18},
    bubble = {width = 320, fill = "#F6E7C1F5", edge = "#6B4410"},
    focus = {lift = 50, min_zoom = 0.6},
    texts = {
        placing = "Перетащите постройку или коснитесь свободного места",
        unchanged = "Остров без изменений",
        blocked = "Нужно свободное место на открытом берегу",
        cant_afford = "Недостаточно монет. Переиграйте открытую главу.",
        cant_buy = "Эта постройка уже восстановлена",
        no_room = "Откройте берег, чтобы найти свободное место",
    },
}
