-- Named presentation contract; tools/check_art_catalogue.py checks its coverage.
-- Resource pieces appear at board size and also identify wallet currencies.
local A = {}
A.story={cast={"elena","mara","tomas","adrian"},source="art/art-direction/expedition-cast.png",
    scenes="existing-island-and-board-paintings",text_scale=1.5,states={"speaking","listening","thought","shout"}}
A.specials = {[1] = "ray-row", [2] = "ray-column", [3] = "ray-diagonal", [4] = "bomb", [5] = "prism", [6] = "plane"}
-- Standalone power-ups, with one authored rocket per hex axis.
-- Both ice frames come from the shared painted overlay atlas.
A.layers = {"chain", "ice-2", "ice-1", "selected", "hint", "guide"}
-- Row-major; packed by tools/prepare_board_dressing.py with a 2 px gutter.
A.dressing_frames = {
    "salt-crust-2", "barnacle-crust-2", "wall-rubble-2",
    "salt-crust-1", "barnacle-crust-1", "wall-rubble-1",
    "creeper-vine-1", "rope-lashing-1", "cable-snarl-1",
    "creeper-vine-1-mirror", "rope-lashing-1-mirror", "cable-snarl-1-mirror",
    "creeper-vine-2", "rope-lashing-2", "cable-snarl-2",
    "dig-sand", "trench-earth", "well-mud", "tide-silt",
    "drift-sand", "swept-stone",
    "sandstone-floor", "blue-plaque",
}
A.finale = {plate="signal-plate", landing="safe-landing", lantern=vec2(.459,.423)}
A.dressing_colors = {
    ["salt-crust"]=color(255, 235, 198), ["barnacle-crust"]=color(217, 205, 183),
    ["wall-rubble"]=color(238, 186, 116), ["creeper-vine"]=color(157, 216, 104),
    ["rope-lashing"]=color(242, 188, 104), ["cable-snarl"]=color(194, 177, 223),
}
-- Authored element states shared by live boards, goals and the guide.
A.elements = require("match3.elements_view").assets
A.quest_objects = {"timber", "lens", "cable", "chart", "marker", "tools", "supplies", "gear"}
A.story_pieces = {"timber", "chart", "supplies", "lens", "cable", "marker", "tools", "note", "gear", "broken-cable"}
A.separate_rewards = {"note", "broken-cable"}
A.resource_pieces = {"coin", "berries", "plantains", "timber", "stone", "water"}
A.tools = {"pickaxe", "dynamite", "sunburst"}
-- World layers: procedural animated density; separate Blender ground PNGs.
A.island_layers = {"cloud-fog", "building-shadows", "placement-guides"}
A.buildings = {catalogue="buildings", shadows="building_sprites", states={"restored", "valid-placement", "blocked-placement", "held", "card-and-reward"}}
A.states = {"normal", "selected", "pressed", "hover", "disabled"}
A.placement_controls = {cancel="placement_cancel", confirm="placement_confirm", states={"normal","hover","pressed","focused","disabled-confirm"}}
A.wallet_icons={life="match3-hud.png",gold="resource-coin",provisions="resource-berries",supplies="resource-timber",stars="discovery-star"}
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
    require("match3.elements_view").load(textures, require("match3").skin(require("match3_skin")))
    local result_atlas = texture.load("result-icons.png")
    for i, key in ipairs(A.result_icons) do
        textures[key] = texture.region(result_atlas, rect((i - 1) * 128, 0, 128, 128))
    end
    local dressing = texture.load("board-dressing.png")
    for i, key in ipairs(A.dressing_frames) do
        textures[key] = texture.region(dressing, rect((i - 1) % 5 * 132 + 2, (i - 1) // 5 * 132 + 2, 128, 128))
    end
    for _, key in ipairs(A.quest_objects) do
        textures["find-" .. key] = texture.load("finds/" .. key .. ".png")
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
            gfx.image(R.art_packs[pack][k + 1], rect(39 + k * 68, 190 + (row - 1) * 60, 46, 46), color.WHITE)
        end
    end
    local names = {"ray-row", "ray-column", "ray-diagonal", "bomb", "prism", "plane",
                   "chain", "ice-2", "ice-1", "selected", "hint", "guide"}
    for i, name in ipairs(names) do
        local x, y = 39 + (i - 1) % 6 * 68, 385 + math.floor((i - 1) / 6) * 85
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

-- Game-rendered samples at the same size as live board cells.
function A.draw_dressing_catalogue(R)
    gfx.round_rect(rect(16, 145, 448, 675), 18, color(12, 47, 41, 250))
    R.say_at("BOARD MATERIALS", vec2(240, 173), 25, R.PAL_GOLD, 420)
    local labels = {"Salt 2", "Barnacles 2", "Rubble 2", "Salt 1", "Barnacles 1", "Rubble 1",
        "Vine 1", "Rope 1", "Cable 1", "Vine 1 reversed", "Rope 1 reversed", "Cable 1 reversed",
        "Vine 2", "Rope 2", "Cable 2", "Dig sand", "Trench earth", "Well mud", "Tide silt",
        "Drift sand", "Swept stone", "Sandstone", "Blue plaque"}
    local side = 2 * (R.HEX_R - .65)
    for i, name in ipairs(A.dressing_frames) do
        local at
        if i <= 15 then at = vec2(110 + (i - 1) % 3 * 130, 230 + (i - 1) // 3 * 88)
        else at = vec2(80 + (i - 16) % 4 * 106, 660 + (i - 16) // 4 * 84) end
        R.draw_ground("face", at, R.HEX_R, 0, 1)
        if i <= 15 then R.draw_relic({kind=(i - 1) % 6,special=0}, at, 1, 255, 1, true) end
        gfx.image(R.board_art[name], rect.centered(at, size2.splat(side)), color.WHITE)
        R.say_at(labels[i], at + vec2(0, 37), 13, R.PAL_CREAM, 100)
    end
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
