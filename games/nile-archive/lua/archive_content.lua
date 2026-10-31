-- archive_content.lua — Nile Archive's content: the three hidden-object
-- chapters, the island's buildings, the cast and the scripted dialogue.
local economy = require("archive_economy")
local catalogue = require("archive_catalogue")
local sprites = require("building_sprites")
local rgba = color

local M = {}

M.scenes = {
    {title = "Двор хранителя", teaser = "На столах двора остались вещи отца. Начните с них.",
     clue = {{"nefra", "На свитке — печать семейной мастерской. Отец успел спрятать архив до наводнения."}},
     background = "scene0.png",
     names = {"Анх", "Веер", "Гранат", "Скарабей", "Ключ", "Кошка", "Свиток", "Перо"},
     at = {vec2(133, 133), vec2(268, 422), vec2(491, 316), vec2(574, 660), vec2(1150, 368), vec2(965, 575), vec2(195, 598), vec2(1094, 170)},
     radius = {vec2(27, 55), vec2(82, 42), vec2(30, 30), vec2(40, 24), vec2(45, 20), vec2(95, 70), vec2(90, 42), vec2(42, 55)}},
    {title = "Библиотека писца", teaser = "В библиотеке спрятан второй след. Для доступа нужно 20 влияния.",
     clue = {{"nefra", "На обороте печати проступил план острова. След ведёт к старому храму у восточного берега."}},
     background = "scene1.png",
     names = {"Анх", "Веер", "Гранат", "Скарабей", "Ключ", "Кошка", "Карта", "Перо"},
     at = {vec2(180, 78), vec2(1023, 617), vec2(115, 430), vec2(513, 163), vec2(450, 617), vec2(1063, 453), vec2(273, 500), vec2(1070, 226)},
     radius = {vec2(25, 52), vec2(115, 55), vec2(35, 35), vec2(30, 42), vec2(45, 22), vec2(90, 70), vec2(195, 55), vec2(45, 55)}},
    {title = "Храм на закате", teaser = "Соберите последнюю цепочку улик. Нужно 50 влияния.",
     clue = {{"nefra", "Последняя записка отца раскрыта."},
             {"horem", "Книги спрятаны под храмом. Восстанови остров — и библиотека снова откроется.", story.THOUGHT}},
     background = "scene2.png",
     names = {"Анх", "Веер", "Яблоко", "Скарабей", "Ключ", "Кошка", "Свиток", "Перо"},
     at = {vec2(61, 109), vec2(1027, 530), vec2(120, 514), vec2(527, 334), vec2(1109, 114), vec2(656, 574), vec2(234, 98), vec2(379, 634)},
     radius = {vec2(30, 72), vec2(95, 50), vec2(35, 35), vec2(42, 24), vec2(25, 62), vec2(105, 58), vec2(70, 28), vec2(95, 30)}},
}
for i, scene in ipairs(M.scenes) do scene.gate = economy.gates[i] end
M.SCENES = #M.scenes

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

-- The five restorations above grant Influence. The 96 catalogue objects after
-- them (docs/building-catalogue.md) are decorations: they cost coins, grant
-- nothing and unlock with the best Stars earned across the chapters. Their
-- types follow the restorations' (5..100), so saves stay compatible.
M.RESTORATIONS = #M.buildings
M.kinds = {}   -- per type: category, Star unlock and key (the engine's defs keep only the city fields)
for i = 1, M.RESTORATIONS do M.kinds[i] = {category = "story", stars = 0} end
for _, e in ipairs(catalogue) do
    M.buildings[#M.buildings + 1] = {name = e.name, sprite_path = e.sprite_path, size = e.size, pivot = e.pivot,
        base_width = e.base_width, shadow_path = e.shadow_path, shadow_pivot = e.shadow_pivot, shadow_base_width = e.shadow_base_width,
        cost = purse(e.coins), reward = purse(), needs = purse(0, 0, 0, e.stars)}
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

-- First launch.
M.intro = {
    {"nefra", "Отец исчез после наводнения, а библиотека опустела."},
    {"nefra", "Но он успел спрятать книги и оставил подсказки. Я восстановлю наше поместье — и найду архив."},
}

M.merit_shore = {"merit", "Открыт новый берег! Перетащите остров влево, чтобы его осмотреть.", story.SHOUT}

return M
