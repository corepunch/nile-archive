-- Campaign content only; all match mechanics live in engine/lua/match3.lua.
-- One hundred expeditions, authored as hex boards in games/relic-rush/levels
-- and compiled to lua/boards.lua by tools/hex_levels.py (docs/LEVEL_DESIGN.md).
-- Move budgets come from tools/tune_moves.py, which writes lua/level_moves.lua.
-- The requires are relative to this module, so other games' tests can load it.
local here = (... or ""):match("^(.-)campaign$") or ""
local boards, budgets = require(here .. "boards"), require(here .. "level_moves")

local dress = {floor={normal="tile-cell-normal", covered="tile-tablet-single", tablet_hint=true}}
local levels = {}
for i, b in ipairs(boards) do
    levels[i] = {name=b.name, tier=b.tier, lesson="Clear every blue plaque.", moves=budgets[i] or 30,
        score=0, relics=0, chains=0, ice=0, mask=b.mask, oil=b.oil, oil_double=b.oil_double,
        chain_cells=b.chain_cells, ice_cells=b.ice_cells, stones=b.stones,
        goals={"oil"}, dress=dress, background=(i - 1) // 5 % 2 + 1}
end

-- Later chapters still use a story piece in one of the five colour slots.
levels[13].story_piece, levels[13].goal_kind = "note", 0 -- gold replaces the sun idol
levels[3].score_pieces = {[2]="leaf"}
levels[4].score_pieces = {[2]="flower"}
levels[6].score_pieces = {[1]="flower"}
levels[7].score_pieces = {[2]="flower"}
levels[9].score_pieces = {[2]="leaf"}
for _, i in ipairs{12,18,24} do levels[i].score_pieces = {[2]="leaf"} end
for _, i in ipairs{15,21,27} do levels[i].score_pieces = {[2]="flower"} end
levels[30].signal = "landing"
-- The final board's signal plate is its tablet nearest the centre, a bare
-- single one when the board has one.
local function signal_plate(l)
    local double, best = {}, nil
    for _, cell in ipairs(l.oil_double) do double[cell] = true end
    for _, e in ipairs(l.chain_cells) do double[e.cell] = true end
    for _, e in ipairs(l.ice_cells) do double[e.cell] = true end
    for _, cell in ipairs(l.oil) do
        local q, r = 0, 0
        local i = 0
        for x = -4, 4 do
            for y = math.max(-4, -x - 4), math.min(4, -x + 4) do
                if i == cell then q, r = x, y end
                i = i + 1
            end
        end
        local d = (math.abs(q) + math.abs(r) + math.abs(q + r)) // 2
        local rank = (double[cell] and 100 or 0) + d
        if not best or rank < best[2] then best = {cell, rank} end
    end
    return best and best[1]
end
levels[30].signal_cell = signal_plate(levels[30])

local shapes = {}
for i, l in ipairs(levels) do shapes[i] = l.name end

return {levels=levels, colors=5, shapes=shapes, wonder_levels={1,4,7,10,13,16,19,23,26,29}}
