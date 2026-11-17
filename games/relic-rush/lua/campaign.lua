-- Campaign content only; all match mechanics live in engine/match3.lua.
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

-- The first clear hands recovered quest objects to the story.
local quest_objects = {
    {key="timber", name="Camp timber"}, {key="lens", name="Lamp lens"},
    {key="cable", name="Relay cable"}, {key="chart", name="Tide chart"},
    {key="marker", name="Quay marker"}, {key="marker", name="Shore marker"},
    {key="tools", name="Tool roll"}, {key="pliers", name="Relay pliers"},
    {key="supplies", name="Supply crate"}, {key="gear", name="Shutter gear"},
}
for i, object in ipairs(quest_objects) do levels[i].quest_object = object end
levels[13].quest_object = {key="note", name="Folded note"}
-- goal_kind registers the slot the story piece replaces. Every board spawns
-- five kinds, as in Cradle of Rome; refill damping keeps cascades rare.
levels[1].goal_kind = 3                                 -- ordinary timber
levels[2].story_piece, levels[2].goal_kind = "lens", 3   -- blue replaces the scarab
levels[3].story_piece, levels[3].goal_kind = "cable", 4  -- purple replaces the crystal
levels[4].story_piece, levels[4].goal_kind = "chart", 0  -- gold replaces the sun idol
levels[5].story_piece, levels[5].goal_kind = "marker", 2 -- green replaces the leaf
levels[6].story_piece, levels[6].goal_kind = "marker", 2
levels[7].story_piece, levels[7].goal_kind = "tools", 1  -- red replaces the flame
levels[8].story_piece, levels[8].goal_kind = "pliers", 2   -- the apple slot
levels[9].story_piece, levels[9].goal_kind = "supplies", 3 -- blue replaces the scarab
levels[10].story_piece, levels[10].goal_kind = "gear", 2 -- the apple slot
levels[13].story_piece, levels[13].goal_kind = "note", 0 -- gold replaces the sun idol
-- Score pieces occupy existing palette slots. Level 6 has both kinds,
-- with the restored Well supplying Food on that expedition.
levels[3].score_pieces = {[2]="leaf"}
levels[4].score_pieces = {[2]="flower"}
levels[6].score_pieces = {[1]="flower"}   -- the marker holds the apple slot
levels[7].score_pieces = {[2]="flower"}
levels[9].score_pieces = {[2]="leaf"}
for _, i in ipairs{12,18,24} do levels[i].score_pieces = {[2]="leaf"} end
for _, i in ipairs{15,21,27} do levels[i].score_pieces = {[2]="flower"} end
levels[3].signal = "cliff"
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

return {levels=levels, colors=5, shapes=shapes, wonder_levels={1,4,7,9,13,16,19,23,26,29}}
