-- Nile Archive's search lists, island buildings, and cast.
local economy = require("archive_economy")
local catalogue = require("archive_catalogue")
local sprites = require("building_sprites")
local rgba = color

local M = {}

M.scenes = {
    {title = "Двор хранителя", teaser = "На столах двора остались вещи отца. Начните с них.",
     clues = {"c1s1a"},
     background = "scene0.png",
     names = {"Анх", "Веер", "Гранат", "Скарабей", "Ключ", "Кошка", "Свиток", "Перо"},
     at = {vec2(133, 133), vec2(268, 422), vec2(491, 316), vec2(574, 660), vec2(1150, 368), vec2(965, 575), vec2(195, 598), vec2(1094, 170)},
     radius = {vec2(27, 55), vec2(82, 42), vec2(30, 30), vec2(40, 24), vec2(45, 20), vec2(95, 70), vec2(90, 42), vec2(42, 55)}},
    {title = "Библиотека писца", teaser = "В библиотеке спрятан второй след.",
     clues = {"c1s2a", "c1s2b"},
     background = "scene1.png",
     names = {"Анх", "Веер", "Гранат", "Скарабей", "Ключ", "Кошка", "Карта", "Перо"},
     at = {vec2(180, 78), vec2(1023, 617), vec2(115, 430), vec2(513, 163), vec2(450, 617), vec2(1063, 453), vec2(273, 500), vec2(1070, 226)},
     radius = {vec2(25, 52), vec2(115, 55), vec2(35, 35), vec2(30, 42), vec2(45, 22), vec2(90, 70), vec2(195, 55), vec2(45, 55)}},
    {title = "Храм на закате", teaser = "План привёл к старому храму.",
     clues = {"c1s3a", "c1s3b"},
     background = "scene2.png",
     names = {"Анх", "Веер", "Яблоко", "Скарабей", "Ключ", "Кошка", "Свиток", "Перо"},
     at = {vec2(61, 109), vec2(1027, 530), vec2(120, 514), vec2(527, 334), vec2(1109, 114), vec2(656, 574), vec2(234, 98), vec2(379, 634)},
     radius = {vec2(30, 72), vec2(95, 50), vec2(35, 35), vec2(42, 24), vec2(25, 62), vec2(105, 58), vec2(70, 28), vec2(95, 30)}},
    {title = "Двор, второй круг", teaser = "Яблоко указало на сад.",
     clues = {"c1s4a", "c1s4b"}, background = "scene0.png",
     names = {"Лейка", "Вилы", "Золотой кувшин", "Корзина с зеленью", "Инжир", "Фонтан", "Виноград", "Ладья"},
     at = {vec2(757, 385), vec2(791, 405), vec2(316, 254), vec2(863, 444), vec2(477, 530), vec2(609, 229), vec2(432, 298), vec2(387, 153)},
     radius = {vec2(31, 34), vec2(24, 45), vec2(41, 52), vec2(35, 57), vec2(48, 28), vec2(54, 37), vec2(44, 24), vec2(23, 32)}},
    {title = "Библиотека, второй круг", teaser = "Весы отца что-то взвешивали.",
     clues = {"c1s5a", "c1s5b"}, background = "scene1.png",
     names = {"Весы", "Чаша с огнём", "Бюст", "Ибис", "Ларец у бюста", "Бусы на ларце", "Каламы", "Большая амфора"},
     at = {vec2(327, 323), vec2(490, 407), vec2(227, 251), vec2(922, 197), vec2(132, 283), vec2(726, 415), vec2(985, 251), vec2(778, 544)},
     radius = {vec2(85, 95), vec2(47, 36), vec2(30, 51), vec2(31, 70), vec2(50, 36), vec2(21, 47), vec2(28, 48), vec2(47, 107)}},
}
M.SCENES = #M.scenes
M.CACHE = M.SCENES + 1
local temple = M.scenes[3]
local cache = {title = "Дверь под крылатым солнцем", background = temple.background,
    names = {}, at = {}, radius = {}}
for i, item in ipairs({5, 4, 1, 8}) do
    cache.names[i], cache.at[i], cache.radius[i] = temple.names[item], temple.at[item], temple.radius[item]
end
M.scenes[M.CACHE] = cache

-- Sprites are rendered by name from the Blender master, which registers each
-- one's pivot, base width and size (docs/BUILDINGS.md); this adds the economy.
M.TILE = 34   -- a tile's side on the ground, in world units

local function building(id, title, key)
    local balance = economy.buildings[id]
    local def = {name = title, cost = purse(balance.coins), reward = purse(0, balance.influence), needs = purse(0, 0, balance.chapters)}
    for field, value in pairs(sprites[key]) do def[field] = value end
    return def
end

M.buildings = {
    building(1, "Дом садовника", "gardener_house"),
    building(2, "Храм Исиды", "isis_temple"),
    building(3, "Архив", "archive"),
    building(4, "Фонтан", "fountain"),
    building(5, "Мастерская", "workshop"),
}

-- Decorations keep their catalogue indices and Star requirements.
M.RESTORATIONS = #M.buildings
M.restoration_beats = {[2] = "restore-temple", [3] = "restore-archive", [4] = "restore-fountain", [5] = "restore-workshop"}
M.kinds = {}   -- per type: category, Star unlock and key (the engine's defs keep only the city fields)
for i = 1, M.RESTORATIONS do M.kinds[i] = {category = "story", stars = 0} end
for _, e in ipairs(catalogue) do
    M.buildings[#M.buildings + 1] = {name = e.name, sprite_path = e.sprite_path, size = e.size, pivot = e.pivot,
        base_width = e.base_width, shadow_path = e.shadow_path, shadow_pivot = e.shadow_pivot, shadow_base_width = e.shadow_base_width,
        cost = purse(e.coins), reward = purse(0, economy.decoration_influence(e.coins)), needs = purse(0, 0, 0, e.stars)}
    M.kinds[#M.buildings] = {category = e.category, stars = e.stars, key = e.key}
end

M.cast = {
    {id = "nefra", name = "Нефра", role = "Дочь хранителя · ищет отца и архив", portrait_path = "characters/nefra.png",
     color = rgba(46, 140, 134), mouth = vec2(.48, .23)},
    {id = "horem", name = "Хорем", role = "Пропавший хранитель · оставил подсказки", portrait_path = "characters/horem.png",
     color = rgba(185, 134, 46), right = true, mouth = vec2(.42, .21)},
    {id = "merit", name = "Мерит", role = "Лодочница · проводник будущих глав", portrait_path = "characters/merit.png",
     color = rgba(181, 84, 58), right = true, mouth = vec2(.40, .22)},
}

M.merit_shore = {"merit", "Открыт новый берег! Перетащите остров влево, чтобы его осмотреть.", story.SHOUT}

return M
