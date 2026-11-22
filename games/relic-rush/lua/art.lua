-- Named presentation contract; tools/check_art_catalogue.py checks its coverage.
-- Board pieces and wallet icons have separate presentation keys.
local buttons = require("match3.buttons")
local economy = require("economy")
local A = {}
A.menu_backdrop = "menu/valley.jpg"
A.resident_keepsakes = {["meeting-map_room-aviary.after-92"]="story/scenes/facing-sketches.jpg"}
A.board_backdrops = {[economy.opening_backdrop] = "board/backs/" .. economy.opening_backdrop .. ".jpg"}
for _, unlock in ipairs(economy.unlocks) do
    A.board_backdrops[unlock.building] = "board/backs/" .. unlock.building .. ".jpg"
end

function A.bind_board_backdrops(scenes)
    if app.arg("default-match3") then return end
    -- Load each painting only when its expedition is drawn.
    setmetatable(scenes, {__index = function(cache, key)
        local path = A.board_backdrops[key]
        if not path then return end
        local picture = texture.load(path)
        assert(picture.tex, "missing board backdrop: " .. path)
        cache[key] = picture
        return picture
    end})
end
A.story={cast={"elena","mara","tomas","adrian","keeper","marisol","lio","nera"},
    keeper_source="art/art-direction/ancient-keeper.png",marisol_source="art/art-direction/marisol.png",source="art/art-direction/expedition-cast.png",
    scenes="existing-island-and-board-paintings",text_scale=1.5,states={"speaking","listening","thought","shout"}}
A.finale = {plate="signal-plate", landing="safe-landing", lantern=vec2(.459,.423)}
A.quest_handoffs = {
    chart={title="The Harbor Chart", path="story/scenes/harbor-chart.jpg"},
    cable={title="The Broken Cable", path="story/scenes/broken-cable.jpg"},
    shutter={title="The view from Mara’s skiff", path="story/scenes/reef-warning.jpg"},
}
A.story_pieces = {"chart", "supplies", "lens", "cable", "tools", "note", "gear", "marker"}
A.story_campaign_frames = {"pliers"}
A.resource_pieces = {"coin", "berries", "water", "rations", "timber", "emerald", "stone"}
A.campaign_pieces = {
    "coin", "berries", "apple", "timber", "stone",
    "amphora", "water", "cut-blocks", "rations", "helmet",
    "grain", "quartz", "shrimp", "emerald", "lens",
    "cable", "chart", "marker", "tools", "pliers",
    "supplies", "gear", "note", "leaf", "flower",
    "silver-coin", "ring", "scarab", "harp", "sandal",
    "pearl", "fish",
}
A.campaign_resources = {"apple", "helmet", "shrimp", "silver-coin", "ring", "scarab", "harp", "sandal"}
-- Upgraded resources reuse pieces of the optional packs: their pieces-atlas frames.
A.resource_upgrades = {
    ["cut-blocks"]="resources-4",
    grain="resources-5", quartz="relics-4",
}
-- Local comparison art uses the exact source crops and the same board states.
A.rome_reference = {leaf=1, flower=2, ["silver-coin"]=3, coin=4, water=5, timber=6, rations=7, stone=8, grain=9,
    shrimp=10, helmet=11, ring=12, scarab=13, sandal=14, harp=15, emerald=16, amphora=17}
A.bonus_atlas_order = {"bonus-hammer", "bonus-bomb", "bonus-shield", "bonus-hourglass", "bonus-lightning", "bonus-plus", "bonus-mixer", "bonus-star"}
-- World layers: procedural animated density; separate Blender ground PNGs.
A.island_layers = {"cloud-fog", "building-shadows", "placement-guides"}
A.buildings = {catalogue="buildings", shadows="building_sprites", states={"restored", "valid-placement", "blocked-placement", "held", "card-and-reward"}}
A.states = {"normal", "selected", "pressed", "hover", "disabled"}
A.placement_controls = {cancel="placement_cancel", confirm="placement_confirm", states={"normal","hover","pressed","focused","disabled-confirm"}}
A.wallet_icons={coins="coin", supplies="wallet-supplies", food="wallet-food"}
A.result_icons = {"discovery-star", "next-clue"}
A.navigation={source="../../art/match3-buttons/manifest.json",roles={"navigation_build","navigation_play", "navigation_pause"},states=A.states}
A.settings={states=A.states,source="art/expedition-hud/settings-lives.png",legacy_key="pause"}

-- Nil override uses the engine's neutral resource skin. A game skin supplies
-- graphics only; behavior is the integer flags field in rules.lua.
local board_skin
function A.skin()
    if board_skin then return board_skin end
    local match3 = require("match3")
    local skin = app.arg("default-match3") and match3.skin() or match3.skin(require("match3_skin"))
    local gear = skin["action-pause"]
    local frame = texture.rect(gear)
    -- Use less transparent padding so the gear draws 20% larger on the same face.
    local crop = rect.centered(frame:center(), frame:size():scale(1 / 1.2))
    skin["action-pause"] = texture.region(gear, crop)
    board_skin = skin
    return board_skin
end

-- The game's own atlases, even when the board borrows the engine's neutral skin.
local function own_board() return require("match3").skin(require("match3_skin")) end

function A.load_hud()
    local match3 = require("match3")
    local neutral = app.arg("default-match3")
    local theme = match3.hud(not neutral and require("match3_hud") or nil)
    assert(neutral or theme.signboard, "missing jade signboard")
    return theme
end

function A.draw_hud_catalogue(R)
    gfx.round_rect(rect(18,220,444,620),18,color(12,47,41,250))
    R.say_at("EXPEDITION ARTWORK",vec2(240,248),25,R.PAL_GOLD,420)
    for i,state in ipairs(A.states) do
        local x=62+(i-1)*89
        buttons.paint(rect(x-32,280,64,64), R.skin.images["action-pause"], state)
        R.say_at(state,vec2(x,365),12,R.PAL_CREAM,85)
    end
    gfx.image(R.hud_art.score,rect(56,397,46,46),color.WHITE)
    gfx.image(R.hud_art.complete,rect(148,397,46,46),color.WHITE)
    R.say_at("score",vec2(79,464),14,R.PAL_CREAM,90)
    R.say_at("complete",vec2(171,464),14,R.PAL_CREAM,90)
    for row,role in ipairs{"navigation_build","navigation_play","navigation_pause","popup_close"} do
        for i,state in ipairs(A.states) do
            local st={selected=state=="selected",held=state=="pressed",hot=state=="hover",disabled=state=="disabled"}
            R.skin:paint_button(rect(28+(i-1)*89,495+(row-1)*82,72,72),st,{role=role})
        end
    end
end

function A.load()
    local textures = {}
    local own = own_board()
    local function piece(name) return assert(own[name], "missing pieces frame: " .. name) end
    require("skin").images["action-close"] = piece("action-close")
    for _, key in ipairs(A.bonus_atlas_order) do textures[key] = piece(key) end
    -- The packed Hammer bounds are centered. Its heavier head pulls the
    -- opacity anchor upward, making the whole silhouette sit low on the face.
    buttons.centers[textures["bonus-hammer"]] = nil
    for _, key in ipairs(A.result_icons) do textures[key] = piece(key) end
    for _, key in ipairs(A.story_pieces) do textures["story-" .. key] = piece("story-" .. key) end
    for _, key in ipairs(A.resource_pieces) do textures["resource-" .. key] = piece("resource-" .. key) end
    for _, key in ipairs(A.campaign_pieces) do textures["campaign-" .. key] = piece("campaign-" .. key) end
    for _, key in ipairs(A.campaign_resources) do
        textures["resource-" .. key] = textures["campaign-" .. key]
    end
    for _, key in ipairs(A.story_campaign_frames) do
        textures["story-" .. key] = textures["campaign-" .. key]
    end
    for _, key in pairs(A.wallet_icons) do
        local name = "resource-" .. key
        textures[name] = textures[name] or piece(name)
    end
    for key, frame in pairs(A.resource_upgrades) do textures["resource-" .. key] = piece(frame) end
    local rome_reference = app.arg("rome-reference-art")
    if rome_reference then
        for key, id in pairs(A.rome_reference) do
            local source = ("%s/gmbn_%d.png"):format(rome_reference, id)
            local image = texture.load(source)
            assert(texture.size(image).w > 0, "Missing Rome reference sprite: " .. source)
            textures["resource-" .. key] = image
        end
    end
    textures[A.finale.plate] = texture.load("story/finale/" .. A.finale.plate .. ".png")
    textures[A.finale.landing] = texture.load("story/finale/" .. A.finale.landing .. ".jpg")
    return textures
end

function A.draw_bonus_catalogue(R)
    local top = 204
    gfx.round_rect(rect(13, top, 454, 496), 18, color(12, 47, 41, 250))
    R.say_at("BONUS ARTWORK", vec2(240, top + 25), 24, R.PAL_GOLD, 440)
    -- Every bonus column, centred in the panel at a size that fits all of them.
    local count = #A.bonus_atlas_order
    local side = math.min(56, 400 / count)
    local step = side + math.min(14, (430 - side * count) / math.max(1, count - 1))
    local left = 240 - (step * (count - 1) + side) / 2
    for col, key in ipairs(A.bonus_atlas_order) do
        local x = left + (col - 1) * step
        gfx.image(R.board_art[key], rect(x, top + 55, side, side), color.WHITE)
        for row, state in ipairs(A.states) do
            buttons.paint(rect(x, top + 118 + (row - 1) * 69, side, side), R.board_art[key], state)
        end
    end
end

-- Rendered by the game, so review covers the same textures as the live board.
function A.draw_catalogue(R)
    gfx.rect(rect(18, 100, 444, 770), color(12, 47, 41, 250))
    R.say_at("ARTWORK CATALOGUE", vec2(240, 125), 26, R.PAL_GOLD, 420)
    local packs = {"relics", "jewels", "resources"}
    for row, pack in ipairs(packs) do
        R.say_at(pack:upper(), vec2(240, 175 + (row - 1) * 60), 13, R.PAL_CREAM, 0)
        for k = 0, #R.art_packs[pack] - 1 do
            gfx.image(R.art_packs[pack][k + 1], rect(43 + k * 68, 190 + (row - 1) * 60, 38, 38), color.WHITE)
        end
    end
    R.say_at("EXPEDITION RESOURCES", vec2(240, 355), 13, R.PAL_CREAM, 0)
    local campaign = R.campaign_art
    local prefix = campaign and "campaign-" or "resource-"
    for i, key in ipairs(A.resource_pieces) do
        local name = key == "emerald" and "apple" or key
        gfx.image(R.board_art[prefix .. name], rect(38 + (i - 1) * 61, 364, 38, 38), color.WHITE)
    end
    local names = {"chain-square-1", "square-plain", "square-target", "square-selected", "square-double", "stone-1"}
    for i, name in ipairs(names) do
        local x, y = 39 + (i - 1) % 6 * 68, 414
        gfx.image(R.board_art[name], rect(x, y, 48, 48), color.WHITE)
        R.say_at(({"Chain", "Plain", "Plaque", "Selected", "Double", "Stone"})[i],
            vec2(x + 24, y + 60), 11, R.PAL_CREAM, 66)
    end
    for col, state in ipairs(A.states) do
        R.say_at(state, vec2(62 + (col - 1) * 88, 571), 12, R.PAL_GOLD, 86)
    end
    for row = 1, 3 do   -- the first three bonuses' toolbar states
        local bonus = A.bonus_atlas_order[row]
        for col, state in ipairs(A.states) do
            buttons.paint(rect(30 + (col - 1) * 88, 588 + (row - 1) * 83, 66, 66), R.board_art[bonus], state)
        end
    end
    R.say_at("Bonus pieces on enamel controls", vec2(240, 855), 13, R.PAL_CREAM, 420)
end

-- Game-rendered samples at the same size as live board cells.
function A.draw_dressing_catalogue(R)
    gfx.round_rect(rect(28, 300, 424, 300), 18, color(12, 47, 41, 250))
    R.say_at("BOARD TILES", vec2(240, 328), 25, R.PAL_GOLD, 420)
    local side = 2 * (R.HEX_R - R.GROUND.seam_width)
    local samples = {
        {"Plain", "square-plain"}, {"Plaque", "square-target"}, {"Double plaque", "square-double"},
        {"Selected", "square-plain", "square-selected"}, {"Chain", "square-target", "chain-square-1"},
        {"Two chains", "square-target", "chain-square-2"}, {"Cracked ice", "square-target", "ice-square-1"},
        {"Ice", "square-target", "ice-square-2"}, {"Stone", "stone-1"},
    }
    for i, sample in ipairs(samples) do
        local label, floor, overlay = table.unpack(sample)
        local at = vec2(104 + (i - 1) % 3 * 136, 371 + (i - 1) // 3 * 85)
        local area = rect.centered(at, size2.splat(side))
        gfx.image(R.board_art[floor], area, color.WHITE)
        if overlay then gfx.image(R.board_art[overlay], area, color.WHITE) end
        R.say_at(label, at + vec2(0, 38), 12, R.PAL_CREAM, 115)
    end
end

return A
