-- Campaign content only; all match mechanics live in engine/lua/match3.lua.
-- One hundred expeditions, authored as hex boards in games/relic-rush/levels
-- and compiled to lua/boards.lua by tools/hex_levels.py (docs/LEVEL_DESIGN.md).
-- Move budgets come from tools/tune_moves.py, which writes lua/level_moves.lua.
-- The requires are relative to this module, so other games' tests can load it.
local here = (... or ""):match("^(.-)campaign$") or ""
local boards, budgets = require(here .. "boards"), require(here .. "level_moves")

local dress = {floor={normal="tile-cell-normal", covered="tile-tablet-single", tablet_hint=true}}
local double_lesson = "Green plaques take two hits. Clear both layers of every plaque."
local opening_lessons = {
    [4] = "Match four through the chained piece to free it. Then clear its plaque.",
    [9] = "Break the chain at the entrance to feed the empty terrace below.",
    [10] = double_lesson,
    [12] = "Match frozen pieces to break the ice. Match beside carved stones to break them.",
    [20] = double_lesson,
    [30] = double_lesson,
}
local levels = {}
for i, b in ipairs(boards) do
    levels[i] = {name=b.name, tier=b.tier, lesson=opening_lessons[i] or "Clear every blue plaque.", moves=budgets[i] or 30,
        score=0, relics=0, chains=0, ice=0, mask=b.mask, oil=b.oil, oil_double=b.oil_double,
        chain_cells=b.chain_cells, ice_cells=b.ice_cells, stones=b.stones,
        goals={"oil"}, dress=dress, background=(i - 1) // 5 % 2 + 1}
end

-- Later chapters still use a story piece in one of the five colour slots.
levels[13].story_piece, levels[13].goal_kind = "note", 0 -- gold replaces the sun idol
levels[30].signal = "landing"

local shapes = {}
for i, l in ipairs(levels) do shapes[i] = l.name end

return {levels=levels, colors=5, shapes=shapes, wonder_levels={1,4,7,10,13,16,19,23,26,29}}
