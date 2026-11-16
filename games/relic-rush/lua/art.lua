-- Named presentation contract; tools/check_art_catalogue.py checks its coverage.
-- Board pieces and wallet icons have separate presentation keys.
local elements_view = require("match3.elements_view")
local A = {}
A.board_frame = require("board_frame_atlas")
A.story={cast={"elena","mara","tomas","adrian"},source="art/art-direction/expedition-cast.png",
    scenes="existing-island-and-board-paintings",text_scale=1.5,states={"speaking","listening","thought","shout"}}
A.specials = {[1] = "ray-row", [2] = "ray-column", [3] = "ray-diagonal", [4] = "bomb", [5] = "prism", [6] = "plane"}
-- Standalone power-ups, with one authored rocket per hex axis.
-- Both ice frames come from the shared painted overlay atlas.
A.layers = {"chain", "ice-2", "ice-1", "selected", "hint", "guide"}
A.finale = {plate="signal-plate", landing="safe-landing", lantern=vec2(.459,.423)}
-- The shared Cradle of Rome tile set, baked by tools/board_tiles.py from
-- engine/art/board-tiles/tiles.json and loaded under "tile-" keys.
A.floor_tiles = {"cell-normal", "tablet-single", "tablet-double", "light-wave", "hover", "selected", "ice", "bonus-area"}
-- Authored element states shared by live boards, goals and the guide.
A.elements = elements_view.assets
A.quest_objects = {"timber", "lens", "cable", "chart", "marker", "tools", "supplies", "gear"}
A.story_pieces = {"chart", "supplies", "lens", "cable", "tools", "note", "gear", "broken-cable", "marker"}
A.separate_rewards = {"note", "broken-cable"}
A.resource_pieces = {"coin", "berries", "stone", "water", "rations", "timber", "emerald"}
A.resource_upgrades = {
    ["cut-blocks"]="tile-sets/resources/4.png", ["trade-coins"]="tile-sets/resources/0.png",
    grain="tile-sets/resources/5.png", quartz="tile-sets/relics/4.png",
    springwater="tile-sets/resources/3.png", ["sun-gem"]="tile-sets/jewels/0.png",
}
-- Local comparison art uses the exact source crops and the same board states.
A.rome_reference = {coin=4, berries=2, emerald=16, timber=6, stone=8, water=5, rations=9, ["cut-blocks"]=8}
A.tools = {"pickaxe", "dynamite", "sunburst"}
-- World layers: procedural animated density; separate Blender ground PNGs.
A.island_layers = {"cloud-fog", "building-shadows", "placement-guides"}
A.buildings = {catalogue="buildings", shadows="building_sprites", states={"restored", "valid-placement", "blocked-placement", "held", "card-and-reward"}}
A.states = {"normal", "selected", "pressed", "hover", "disabled"}
A.placement_controls = {cancel="placement_cancel", confirm="placement_confirm", states={"normal","hover","pressed","focused","disabled-confirm"}}
A.wallet_icons={coins="coin", supplies="wallet-supplies", food="wallet-food"}
A.result_icons = {"discovery-star", "next-clue"}
A.navigation={source="art/navigation/controls.png",roles={"navigation_build","navigation_play", "navigation_levels"},states=A.states}
A.settings={states=A.states,source="art/expedition-hud/settings-lives.png",legacy_key="pause"}

-- Nil override uses the engine's neutral resource skin. A game skin supplies
-- graphics only; behavior is the integer flags field in rules.lua.
function A.skin()
    local match3 = require("match3")
    if app.arg("default-match3") then return match3.skin() end
    return match3.skin(require("match3_skin"))
end

function A.load_hud()
    local match3 = require("match3")
    if app.arg("default-match3") then return match3.hud() end
    local hud = match3.hud(require("match3_hud"))
    assert(hud.signboard, "missing jade signboard")
    return hud
end

function A.draw_hud_catalogue(R)
    gfx.round_rect(rect(18,220,444,620),18,color(12,47,41,250))
    R.say_at("EXPEDITION ARTWORK",vec2(240,248),25,R.PAL_GOLD,420)
    for i,state in ipairs(A.states) do
        local x=62+(i-1)*89
        gfx.image(R.hud_art["pause-"..state],rect(x-32,280,64,64),color.WHITE)
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
    -- New mechanic art uses this game's authored atlas even with the neutral skin.
    elements_view.load(textures, require("match3").skin(require("match3_skin")))
    for _, key in ipairs(A.floor_tiles) do
        textures["tile-" .. key] = texture.load("board-tiles/" .. key .. ".png")
    end
    elements_view.load_frame(textures, A.board_frame)
    local result_atlas = texture.load("result-icons.png")
    for i, key in ipairs(A.result_icons) do
        textures[key] = texture.region(result_atlas, rect((i - 1) * 128, 0, 128, 128))
    end
    for _, key in ipairs(A.quest_objects) do
        if key ~= "timber" then textures["find-" .. key] = texture.load("finds/" .. key .. ".png") end
    end
    for _, key in ipairs(A.separate_rewards) do
        textures["find-" .. key] = texture.load("finds/" .. key .. ".png")
    end
    for _, key in ipairs(A.story_pieces) do
        textures["story-" .. key] = texture.load("story-pieces/" .. key .. ".png")
    end
    for _, key in ipairs(A.resource_pieces) do
        textures["resource-" .. key] = texture.load("resource-pieces/" .. key .. ".png")
    end
    for _, key in pairs(A.wallet_icons) do
        local name = "resource-" .. key
        textures[name] = textures[name] or texture.load("resource-pieces/" .. key .. ".png")
    end
    for key, path in pairs(A.resource_upgrades) do
        textures["resource-" .. key] = texture.load(path)
    end
    local rome_reference = app.arg("rome-reference-art")
    if rome_reference then
        for key, id in pairs(A.rome_reference) do
            local source = ("%s/gmbn_%d.png"):format(rome_reference, id)
            local image = texture.load(source)
            assert(texture.size(image).w > 0, "Missing Rome reference sprite: " .. source)
            textures["resource-" .. key] = image
        end
    end
    textures["find-timber"] = textures["resource-timber"]
    textures[A.finale.plate] = texture.load(A.finale.plate .. ".png")
    textures[A.finale.landing] = texture.load(A.finale.landing .. ".jpg")
    for _, name in pairs(A.specials) do load(name) end
    for _, name in ipairs(A.layers) do load(name) end
    return textures
end

-- Rendered by the game, so review covers the same textures as the live board.
function A.draw_catalogue(R)
    gfx.rect(rect(18, 100, 444, 770), color(12, 47, 41, 250))
    R.say_at("ARTWORK CATALOGUE", vec2(240, 125), 26, R.PAL_GOLD, 420)
    local packs = {"relics", "jewels", "resources"}
    for row, pack in ipairs(packs) do
        R.say_at(pack:upper(), vec2(240, 175 + (row - 1) * 60), 13, R.PAL_CREAM, 0)
        for k = 0, 5 do
            gfx.image(R.art_packs[pack][k + 1], rect(43 + k * 68, 190 + (row - 1) * 60, 38, 38), color.WHITE)
        end
    end
    R.say_at("EXPEDITION RESOURCES", vec2(240, 355), 13, R.PAL_CREAM, 0)
    for i, key in ipairs(A.resource_pieces) do
        gfx.image(R.board_art["resource-" .. key], rect(38 + (i - 1) * 61, 364, 38, 38), color.WHITE)
    end
    local names = {"ray-row", "ray-column", "ray-diagonal", "bomb", "prism", "plane",
                   "chain", "tile-cell-normal", "tile-tablet-single", "selected", "hint", "guide"}
    for i, name in ipairs(names) do
        local x, y = 39 + (i - 1) % 6 * 68, 414 + math.floor((i - 1) / 6) * 75
        if i <= 6 then
            R.draw_relic({kind=i-1,special=i},vec2(x+24,y+24),1,255,1)
        else gfx.image(R.board_art[name], rect(x, y, 48, 48), color.WHITE) end
        R.say_at(name, vec2(x + 24, y + 60), 11, R.PAL_CREAM, 66)
    end
    for col, state in ipairs(A.states) do
        R.say_at(state, vec2(62 + (col - 1) * 88, 571), 12, R.PAL_GOLD, 86)
    end
    for row, tool in ipairs(A.tools) do
        for col, state in ipairs(A.states) do
            gfx.image(R.hud_art[tool .. "-" .. state], rect(30 + (col - 1) * 88, 588 + (row - 1) * 83, 66, 66), color.WHITE)
        end
    end
    R.say_at("Authored states - no generated tints", vec2(240, 855), 13, R.PAL_CREAM, 420)
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

-- Actual game rendering, all kinds and axes at board size; no replacement art.
function A.draw_stripe_catalogue(R)
    gfx.round_rect(rect(16,130,448,640),18,color(12,47,41,250))
    R.say_at("SPECIAL PIECES",vec2(240,160),25,R.PAL_GOLD,420)
    local labels={"NORMAL","30 DEGREE ROCKET","VERTICAL ROCKET","150 DEGREE ROCKET","BOMB"}
    for row=0,4 do
        R.say_at(labels[row+1],vec2(240,205+row*106),13,R.PAL_CREAM,420)
        for kind=0,5 do R.draw_relic({kind=kind,special=row},vec2(62+kind*71,252+row*106),1,255,1,true) end
    end
end

return A
