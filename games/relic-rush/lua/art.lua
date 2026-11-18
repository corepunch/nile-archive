-- Named presentation contract; tools/check_art_catalogue.py checks its coverage.
-- Board pieces and wallet icons have separate presentation keys.
local elements_view = require("match3.elements_view")
local buttons = require("match3.buttons")
local A = {}
A.board_frame = require("board_frame_atlas")
A.story={cast={"elena","mara","tomas","adrian","keeper"},keeper_source="art/art-direction/ancient-keeper.png",source="art/art-direction/expedition-cast.png",
    scenes="existing-island-and-board-paintings",text_scale=1.5,states={"speaking","listening","thought","shout"}}
-- Both ice frames come from the shared painted overlay atlas.
A.layers = {"chain", "ice-2", "ice-1", "selected", "hint", "guide"}
A.finale = {plate="signal-plate", landing="safe-landing", lantern=vec2(.459,.423)}
-- The shared Cradle of Rome tile set, baked by tools/board_tiles.py from
-- engine/art/board-tiles/tiles.json and loaded under "tile-" keys.
A.floor_tiles = {"cell-normal", "tablet-single", "tablet-double", "light-wave", "hover", "selected", "ice", "bonus-area"}
-- Authored element states shared by live boards, goals and the guide.
A.elements = elements_view.assets
A.story_pieces = {"chart", "supplies", "lens", "cable", "tools", "note", "gear", "marker"}
A.story_campaign_frames = {"pliers"}
A.resource_pieces = {"coin", "berries", "stone", "water", "rations", "timber", "emerald"}
A.campaign_pieces = {
    "coin", "berries", "apple", "timber", "stone",
    "amphora", "water", "cut-blocks", "rations", "helmet",
    "grain", "quartz", "shrimp", "emerald", "lens",
    "cable", "chart", "marker", "tools", "pliers",
    "supplies", "gear", "note", "leaf", "flower",
    "silver-coin", "ring", "scarab", "harp", "sandal",
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
A.moves_icon = "moves"
A.result_icons = {"discovery-star", "next-clue"}
A.navigation={source="../../art/match3-buttons/manifest.json",roles={"navigation_build","navigation_play", "navigation_levels","navigation_pause"},states=A.states}
A.settings={states=A.states,source="art/expedition-hud/settings-lives.png",legacy_key="pause"}

function A.use_campaign_pieces()
    local pack = app.arg("tiles")
    return not app.arg("default-match3") and not app.arg("rome-reference-art") and (not pack or pack == "relics")
end

-- Nil override uses the engine's neutral resource skin. A game skin supplies
-- graphics only; behavior is the integer flags field in rules.lua.
function A.skin()
    local match3 = require("match3")
    if app.arg("default-match3") then return match3.skin() end
    return match3.skin(require("match3_skin"))
end

-- The game's own atlases, even when the board borrows the engine's neutral skin.
local function own_board() return require("match3").skin(require("match3_skin")) end
local function own_hud() return require("match3").hud(require("match3_hud")) end

function A.load_hud()
    local match3 = require("match3")
    local neutral = app.arg("default-match3")
    local theme = match3.hud(not neutral and require("match3_hud") or nil)
    assert(neutral or theme.signboard, "missing jade signboard")
    assert(neutral or theme[A.moves_icon], "missing Moves icon")
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
    for row,kind in ipairs{"build","play","levels"} do
        for i,state in ipairs(A.states) do
            local st={selected=state=="selected",held=state=="pressed",hot=state=="hover",disabled=state=="disabled"}
            R.skin:paint_button(rect(28+(i-1)*89,505+(row-1)*94,72,72),st,{role="navigation_"..kind})
        end
    end
end

function A.load()
    local textures, skin = {}, A.skin()
    local function load(name) textures[name] = skin[name] end
    local own, hud = own_board(), own_hud()
    local function piece(name) return assert(own[name], "missing pieces frame: " .. name) end
    for _, key in ipairs(A.bonus_atlas_order) do textures[key] = piece(key) end
    -- New mechanic art uses this game's authored atlas even with the neutral skin.
    elements_view.load(textures, own)
    for _, key in ipairs(A.floor_tiles) do textures["tile-" .. key] = piece("tile-" .. key) end
    elements_view.load_frame(textures, A.board_frame)
    for _, key in ipairs(A.result_icons) do textures[key] = assert(hud[key], "missing hud frame: " .. key) end
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
    for _, name in ipairs(A.layers) do load(name) end
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
    local campaign = A.use_campaign_pieces()
    local prefix = campaign and "campaign-" or "resource-"
    for i, key in ipairs(A.resource_pieces) do
        local name = key == "emerald" and "apple" or key
        gfx.image(R.board_art[prefix .. name], rect(38 + (i - 1) * 61, 364, 38, 38), color.WHITE)
    end
    local names = {"chain", "tile-cell-normal", "tile-tablet-single", "selected", "hint", "guide"}
    for i, name in ipairs(names) do
        local x, y = 39 + (i - 1) % 6 * 68, 414
        gfx.image(R.board_art[name], rect(x, y, 48, 48), color.WHITE)
        R.say_at(name, vec2(x + 24, y + 60), 11, R.PAL_CREAM, 66)
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

-- Game-rendered samples at the same size as live board cells: the eight
-- shared tiles in Cradle of Rome's slot order, then a chained plaque.
local TILE_LABELS = {"Normal", "Tablet", "Double", "Light wave", "Hover", "Selected", "Ice", "Bonus area"}
function A.draw_dressing_catalogue(R)
    gfx.round_rect(rect(28, 300, 424, 300), 18, color(12, 47, 41, 250))
    R.say_at("BOARD TILES", vec2(240, 328), 25, R.PAL_GOLD, 420)
    local side = 2 * (R.HEX_R - .65)
    for i, key in ipairs(A.floor_tiles) do
        local at = vec2(87 + (i - 1) % 4 * 102, 380 + (i - 1) // 4 * 92)
        gfx.image(R.board_art["tile-" .. key], rect.centered(at, size2.splat(side)), color.WHITE)
        R.say_at(TILE_LABELS[i], at + vec2(0, 42), 12, R.PAL_CREAM, 100)
    end
    local at = vec2(240, 552)
    local area = rect.centered(at, size2.splat(side))
    gfx.image(R.board_art["tile-tablet-single"], area, color.WHITE)
    gfx.image(R.board_art["resource-coin"], area:inflate(-5), color.WHITE)
    gfx.image(R.board_art.chain, area, color.WHITE)
end

return A
