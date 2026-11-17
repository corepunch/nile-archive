-- One hundred wishes, authored as hex boards in games/christmas-market/levels
-- and compiled to lua/boards.lua by tools/hex_levels.py (docs/LEVEL_DESIGN.md).
-- Move budgets come from tools/tune_moves.py, which writes lua/level_moves.lua.
-- The requires are relative to this module, so other games' tests can load it.
local here = (... or ""):match("^(.-)campaign$") or ""
local boards, budgets = require(here .. "boards"), require(here .. "level_moves")

local levels = {}
for i, b in ipairs(boards) do
    local floor_marks = {}
    for _, cell in ipairs(b.oil) do floor_marks[cell] = true end
    levels[i] = {name=b.name, tier=b.tier, lesson="Light every pane.", moves=budgets[i] or 30,
        score=0, relics=0, chains=0, ice=0, mask=b.mask, oil=b.oil, oil_double=b.oil_double,
        chain_cells=b.chain_cells, ice_cells=b.ice_cells, stones=b.stones,
        goals={"oil"}, floor_marks=floor_marks}
end

-- The finished board holds a painting before the first-clear scene.
levels[24].reveal = {picture="wish-ribbon", floor="oil", on_clear=true}
levels[25].reveal = {picture="telegram", floor="oil", on_clear=true}
levels[28].reveal = {picture="last-train", floor="oil", on_clear=true}

-- Each find is part of the first-clear scene and results card. It has
-- no colour slot, tally or effect on the goods delivered by the board.
local finds = {
    [9]={key="cocoa", name="Cocoa mug"},
    [16]={key="scarf", name="Blue practice scarf"},
    [19]={key="letter", name="Undelivered letter"},
    [24]={key="ribbon", name="Wish ribbon"},
    [25]={key="telegram", name="Station telegram"},
    [27]={key="lantern", name="Borrowed lantern"},
}
for index, find in pairs(finds) do
    levels[index].story_piece = find
end

local shapes = {}
for i, entry in ipairs(levels) do shapes[i] = entry.name end

return {levels=levels, shapes=shapes, wonder_levels={1,4,7,9,13,16,19,23,26,29}}
