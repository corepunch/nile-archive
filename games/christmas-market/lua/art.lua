-- Named presentation contract; tools/check_assets.py checks its coverage.
-- The gold bell artwork also identifies spendable Gold in the island purse.
-- The same painted pieces identify wallet resources and story finds.
local A = {}
A.specials = {[1] = "ray-row", [2] = "ray-column", [3] = "ray-diagonal", [4] = "bomb", [5] = "prism", [6] = "plane"}
-- Standalone power-ups, with one authored rocket per hex axis.
A.layers = {"chain", "ice-2", "ice-1", "selected", "hint", "guide"}
-- Authored element states shared by live boards, goals and the guide.
A.elements = require("match3.elements_view").assets
A.tools = {"pickaxe", "dynamite", "sunburst"}
A.states = {"normal", "selected", "pressed", "hover", "disabled"}
A.navigation = {source="art/navigation/controls.png", roles={"navigation_build", "navigation_play", "navigation_levels"}, states=A.states}
A.festive = {"Bell", "Candy cane", "Holly", "Mitten", "Bauble", "Gingerbread"}
-- Shared engine land fog; painted directional buildings await Blender renders.
A.island_layers = {"land-fog"}

-- Nil override uses the engine's neutral resource skin. A game skin supplies
-- graphics only; behavior is the integer flags field in rules.lua.
function A.skin()
    local match3 = require("match3")
    if app.arg("default-match3") then return match3.skin() end
    return match3.skin(require("match3_skin"))
end

function A.load_hud()
    local match3 = require("match3")
    if app.arg("default-match3") then
        local hud = match3.hud()
        return setmetatable({score=hud.complete}, {__index=hud})
    end
    local hud = match3.hud(require("match3_hud"))
    assert(hud.signboard, "missing spruce signboard")
    for _, state in ipairs(A.states) do
        assert(hud["board-pause-" .. state], "missing board Settings state: " .. state)
    end
    return hud
end

function A.draw_hud_catalogue(R)
    gfx.round_rect(rect(18,220,444,640),18,color(12,47,41,250))
    R.say_at("CHRISTMAS HUD ARTWORK",vec2(240,248),25,R.PAL_GOLD,420)
    for i,state in ipairs(A.states) do
        local x=62+(i-1)*89
        gfx.image(R.hud_art["pause-"..state],rect(x-32,280,64,64),color.WHITE)
        R.say_at(state,vec2(x,365),12,R.PAL_CREAM,85)
    end
    gfx.image(R.hud_art.score,rect(56,414,66,66),color.WHITE)
    gfx.image(R.hud_art.complete,rect(148,414,66,66),color.WHITE)
    R.skin:draw_resource(rect(236,432,70,30),R.relics[1],"",{role="goal",interactive=false,done=true})
    R.say_at("score",vec2(89,502),14,R.PAL_CREAM,90)
    R.say_at("stars",vec2(181,502),14,R.PAL_CREAM,90)
    R.say_at("goal met",vec2(273,502),14,R.PAL_CREAM,90)
    local portrait = R.hud_art.character
    if portrait then gfx.image(portrait,rect(318,398,124,125):fit(texture.size(portrait)),color.WHITE) end
    for row,kind in ipairs{"build","play","levels"} do
        for i,state in ipairs(A.states) do
            local st={selected=state=="selected",held=state=="pressed",hot=state=="hover",disabled=state=="disabled"}
            R.skin:paint_button(rect(28+(i-1)*89,540+(row-1)*88,72,72),st,{role="navigation_"..kind})
        end
    end
    R.say_at("Noelle, market keeper",vec2(240,835),17,R.PAL_CREAM,400)
end

function A.load()
    local textures, skin = {}, A.skin()
    local function load(name) textures[name] = skin[name] end
    -- New mechanic art uses this game's authored atlas even with the neutral skin.
    require("match3.elements_view").load(textures, require("match3").skin(require("match3_skin")))
    for _, level in ipairs(require("campaign").levels) do
        local name = level.reveal and level.reveal.picture
        if name then textures[name] = texture.load("story-floors/" .. name .. ".jpg") end
        local find = level.story_piece
        if find then textures["story-" .. find.key] = texture.load("story-pieces/" .. find.key .. ".png") end
    end
    -- The shared Cradle of Rome tile set, baked by tools/board_tiles.py from
    -- engine/art/board-tiles/tiles.json, under "tile-" keys.
    for _, key in ipairs{"cell-normal", "tablet-single", "tablet-double", "light-wave", "hover", "selected", "ice", "bonus-area"} do
        textures["tile-" .. key] = texture.load("board-tiles/" .. key .. ".png")
    end
    textures["frame-leaves"] = texture.load("board-tiles/frame-leaves.png")
    textures["frame-stone"] = texture.load("board-tiles/frame-stone.png")
    for _, name in pairs(A.specials) do load(name) end
    for _, name in ipairs(A.layers) do load(name) end
    if not app.arg("default-match3") then load("chain-board") end
    return textures
end

-- Rendered by the game, so review covers the same textures as the live board.
function A.draw_catalogue(R)
    gfx.rect(rect(18, 100, 444, 770), color(12, 47, 41, 250))
    R.say_at("ARTWORK CATALOGUE", vec2(240, 125), 26, R.PAL_GOLD, 420)
    local packs = {"festive"}
    for row, pack in ipairs(packs) do
        R.say_at(pack:upper(), vec2(240, 175 + (row - 1) * 60), 13, R.PAL_CREAM, 0)
        for k = 0, 5 do
            local x = 39 + k * 68
            gfx.image(R.art_packs[pack][k + 1], rect(x, 190 + (row - 1) * 60, 46, 46), color.WHITE)
            R.say_at(A.festive[k + 1], vec2(x + 23, 245), 10, R.PAL_CREAM, 66)
        end
    end
    for i, name in ipairs{"cell-normal", "tablet-single", "tablet-double"} do
        local x = 104 + (i - 1) * 112
        gfx.image(R.board_art["tile-" .. name], rect(x, 272, 48, 48), color.WHITE)
        R.say_at(name, vec2(x + 24, 330), 11, R.PAL_CREAM, 88)
    end
    local names = {"ray-row", "ray-column", "ray-diagonal", "bomb", "prism", "plane",
                   "chain", "ice-2", "ice-1", "selected", "hint", "guide"}
    for i, name in ipairs(names) do
        local x, y = 39 + (i - 1) % 6 * 68, 385 + math.floor((i - 1) / 6) * 85
        gfx.image(R.board_art[name], rect(x, y, 48, 48), color.WHITE)
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

return A
