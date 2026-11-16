-- Bellmere's match rewards and price slots.
local E = {
    GOLD=1, TREATS=2, SUPPLIES=3, STARS=4,
    currencies={
        {name="Gold", kind=0},
        {name="Treats", kind=5},
        {name="Supplies", kind=2},
    },
    pieces={
        [0]={slot=1, amount=3}, -- bell
        {slot=2, amount=1},    -- candy cane
        {slot=3, amount=1},    -- holly
        {slot=3, amount=1},    -- mitten
        {slot=3, amount=1},    -- bauble
        {slot=2, amount=1},    -- gingerbread
    },
}

function E.board_yields(level)
    local yields = {}
    for kind, piece in pairs(E.pieces) do
        if not (level.story_piece and kind == level.goal_kind) then yields[kind] = piece end
    end
    return yields
end

return E
