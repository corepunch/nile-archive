-- Named presentation contract; tools/check_art_catalogue.py checks its coverage.
-- Idol/Leaf/Crystal artwork also identifies Gold/Wood/Stone in the island purse.
-- Board clears score points; the fixed first-clear grant and Gold-only replay
-- payout are separate from colour counts (rules.reward_breakdown).
local A = {}
A.specials = {[1] = "ray-row", [2] = "ray-column", [3] = "ray-diagonal", [4] = "bomb", [5] = "prism"}
A.layers = {"sand", "chain", "ice-2", "ice-1", "selected", "hint", "guide"}
A.tools = {"pickaxe", "dynamite", "sunburst"}
A.states = {"normal", "selected", "pressed", "hover", "disabled"}
A.tool_size = 76   -- square authored artwork and matching square touch targets
A.hud_icons = {"complete"}
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
    local textures = {}
    for _, state in ipairs(A.states) do textures["pause-" .. state] = A.skin()["pause-" .. state] end
    for _, name in ipairs(A.hud_icons) do textures[name] = A.skin()[name] end
    textures.score = textures.complete
    textures.elena = A.skin().character
    return textures
end

function A.draw_hud_catalogue(R)
    gfx.round_rect(rect(18,220,444,490),18,color(12,47,41,250))
    R.say_at("CHRISTMAS HUD ARTWORK",vec2(240,248),25,R.PAL_GOLD,420)
    for i,state in ipairs(A.states) do
        local x=62+(i-1)*89
        gfx.image(R.hud_art["pause-"..state],rect(x-32,280,64,64),color.WHITE)
        R.say_at(state,vec2(x,365),12,R.PAL_CREAM,85)
    end
    gfx.image(R.hud_art.score,rect(56,414,66,66),color.WHITE)
    gfx.image(R.hud_art.complete,rect(148,414,66,66),color.WHITE)
    R.say_at("score",vec2(89,502),14,R.PAL_CREAM,90)
    R.say_at("complete",vec2(181,502),14,R.PAL_CREAM,90)
    if R.hud_art.elena then gfx.image(R.hud_art.elena,rect(258,398,174,268):fit(texture.size(R.hud_art.elena)),color.WHITE) end
    R.say_at("Noelle, market keeper",vec2(240,683),17,R.PAL_CREAM,400)
end

function A.tool_state(charges, selected, inside, down, started_inside, hover, idle)
    if charges <= 0 or not idle then return "disabled" end
    if inside and down and started_inside then return "pressed" end
    if selected then return "selected" end
    if inside and hover then return "hover" end
    return "normal"
end

function A.load()
    local textures = {}
    local function load(name) textures[name] = A.skin()[name] end
    for _, name in pairs(A.specials) do load(name) end
    for _, name in ipairs(A.layers) do load(name) end
    load("cell-mask")
    for _, tool in ipairs(A.tools) do
        for _, state in ipairs(A.states) do load(tool .. "-" .. state) end
    end
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
            gfx.image(R.art_packs[pack][k + 1], rect(39 + k * 68, 190 + (row - 1) * 60, 46, 46), color.WHITE)
        end
    end
    local names = {"ray-row", "ray-column", "ray-diagonal", "bomb", "prism", "sand",
                   "chain", "ice-2", "ice-1", "selected", "hint", "guide"}
    for i, name in ipairs(names) do
        local x, y = 39 + (i - 1) % 6 * 68, 385 + math.floor((i - 1) / 6) * 85
        if i <= 4 then gfx.image(R.relics[i], rect(x + 9, y + 9, 30, 30), color.WHITE) end
        gfx.image(R.board_art[name], rect(x, y, 48, 48), color.WHITE)
        R.say_at(name, vec2(x + 24, y + 60), 11, R.PAL_CREAM, 66)
    end
    for col, state in ipairs(A.states) do
        R.say_at(state, vec2(62 + (col - 1) * 88, 571), 12, R.PAL_GOLD, 86)
    end
    for row, tool in ipairs(A.tools) do
        for col, state in ipairs(A.states) do
            gfx.image(R.board_art[tool .. "-" .. state], rect(30 + (col - 1) * 88, 588 + (row - 1) * 83, 66, 66), color.WHITE)
        end
    end
    R.say_at("Authored states - no generated tints", vec2(240, 855), 13, R.PAL_CREAM, 420)
end

return A
