local E = require('match3')
local geo = E.new{radius=2}
local function cell(q,r) return geo.hex_index(q,r) end
local function level()
    return {name='elements',moves=20,score=0,relics=0,chains=0,ice=0,
        stones={{cell=cell(-1,0)}}}
end
local function rules(l) return E.new{radius=2,flags=E.LINE_MATCHES,levels={l}} end
local R = rules(level())
do
    local g, m = R.game_start(0,123), R.new_match()
    check(g.obstacles==1, 'one obstacle per stone')
    check(not R.game_can_swap(g,cell(-1,0),cell(0,0)), 'stone blocks swaps')
    m.mask[cell(0,0)] = true; g.tiles[cell(0,0)] = R.tile(0)
    R.game_apply(g,m)
    check(g.stone_hp[cell(-1,0)]==0 and g.obstacles==0, 'an adjacent match breaks the stone')
    local copy=R.game_copy(g);copy.stone_hp[cell(-1,0)]=1
    check(g.stone_hp[cell(-1,0)]==0, 'copy owns mutable element state')
end

do
    local g=R.game_start(0, 351)
    for i=0,R.CELLS-1 do g.tiles[i]=R.tile(-1) end
    local a,b=cell(0,0),cell(0,-1)
    g.tiles[a],g.tiles[b]=R.tile(3),R.tile(2)
    g.tiles[cell(1,0)],g.tiles[cell(2,0)]=R.tile(2),R.tile(2)
    local before=R.game_copy(g)
    check(R.game_hint(g), 'hint finds the swap that completes a line')
    for i=0,R.CELLS-1 do
        check(g.tiles[i].kind==before.tiles[i].kind
            and g.chain[i]==before.chain[i] and g.ice[i]==before.ice[i] and g.stone_hp[i]==before.stone_hp[i],
            'hint cannot mutate tiles or elements')
    end
    check(g.rng==before.rng and g.moves==before.moves and g.obstacles==before.obstacles, 'hint preserves counters')
end

do
    local g = R.game_start(0, 357)
    local stone = cell(-1,0)
    R.game_shuffle(g)
    check(g.stone_hp[stone]==1, 'shuffle preserves fixed blockers')
end

do
    local g, m = R.game_start(0, 789), R.new_match()
    local left, upper, blocker = cell(0,0), cell(-1,1), cell(-1,0)
    g.tiles[left], g.tiles[upper] = R.tile(0), R.tile(0)
    m.mask[left], m.mask[upper] = true, true
    R.game_apply(g,m)
    check(g.stone_hp[blocker]==0 and g.obstacles==0, 'two adjacent hits clear one obstacle')
end

do
    local l = level()
    local stone, neighbor = cell(-1, 0), cell(-1, 1)
    l.stones[2] = {cell=neighbor}
    local ruleset = rules(l)
    local g = ruleset.game_start(0, 789)
    local m = ruleset.new_match()
    m.mask[stone], m.direct[stone] = true, true
    ruleset.game_apply(g, m)
    check(g.stone_hp[stone] == 0, 'a direct tool hit breaks the stone')
    check(g.stone_hp[neighbor] == 1 and g.obstacles == 1, 'the neighbouring stone remains in the goal')
end

do
    local g=R.game_start(0,721)
    local left, stone = cell(0,0),cell(-1,0)
    g.tiles[left]=R.tile(1);g.ice[left]=1;g.obstacles=g.obstacles+1
    local m=R.new_match();m.mask[left],m.ordinary[left]=true,true
    R.game_apply(g,m)
    check(g.ice[left]==0 and g.stone_hp[stone]==0, 'a matched frozen piece still breaks an adjacent stone')
end

do
    local invalid=level();invalid.stones[2]={cell=invalid.stones[1].cell}
    check(not pcall(function() rules(invalid).game_start(0,1) end), 'overlapping stones are rejected')
end
-- Compare the fast hint search with the actual swap operation in both match
-- modes, including live blockers.
for _, flags in ipairs({0,E.LINE_MATCHES}) do
    local r=E.new{radius=2,flags=flags,levels={level()}}
    for seed=1,4 do
        local g=r.game_start(0,seed)
        local expected,a,b=false,nil,nil
        for i=0,r.CELLS-1 do
            for d=0,2 do
                local j=r.hex_neighbor(i,d)
                if r.game_can_swap(g,i,j) and r.game_swap(r.game_copy(g),i,j,r.new_match()) then
                    expected,a,b=true,i,j
                    break
                end
            end
            if expected then break end
        end
        local found,x,y=r.game_hint(g)
        check(found==expected and (not found or x==a and y==b), 'fast hint agrees with full swap oracle')
    end
end
-- Tablets clear under a match on them and never spread.
do
    local C = rules{name='oil',moves=20,score=0,relics=0,chains=0,ice=0,oil={cell(0,0),cell(0,1)},goals={'oil'}}
    local g = C.game_start(0,9)
    check(g.oil_left==2, 'tablet count')
    for i=0,C.CELLS-1 do g.tiles[i]=C.tile(-1) end
    for _,i in ipairs({cell(-1,0),cell(0,0),cell(1,0)}) do g.tiles[i]=C.tile(3) end
    local m=C.new_match();C.game_matches(g,m);C.game_apply(g,m)
    check(g.oil[cell(0,0)]==0 and g.oil_left==1, 'a match on a tablet clears it')
    C.game_check_end(g)
    check(g.oil_left==1 and g.oil[cell(0,1)]==1, 'tablets never spread')
    check(C.game_copy(g).oil ~= g.oil, 'copy owns the tablet layer')
    g.oil_left = 0
    C.game_check_end(g)
    check(g.won, 'clearing every tablet wins a tablet-only level')
end

-- A story mosaic shows its picture on every play; only a first clear speaks
-- once at half and holds the finished picture before the first-clear beat.
do
    local V = require('match3.elements_view')
    local C = rules{name='reveal',moves=20,score=0,relics=0,chains=0,ice=0,oil={cell(0,0),cell(0,1)},goals={'oil'},
        reveal={picture='p',bark='half',floor='oil',object=true}}
    local said = {}
    local view = {now=0, prog={level=1}, notice=function(s) said[#said+1]=s end}
    view.g = C.game_start(0,7); view.g.won = true
    check(V.reveal_cover(view,C)==1 and not V.reveal_holding(view,C), 'a replay keeps its pieces and does not hold')
    view.prog.level, view.g = 0, C.game_start(0,7)
    check(V.reveal_cover(view,C)==1 and #said==0, 'pieces stay and nobody speaks before half')
    view.g.oil_left = 1
    V.reveal_cover(view,C); V.reveal_cover(view,C)
    check(#said==1 and said[1]=='half', 'the bark is said once at half')
    view.g.won = true
    check(V.reveal_holding(view,C) and V.reveal_cover(view,C)==1, 'the win starts the hold with pieces still shown')
    view.now = 1
    check(V.reveal_cover(view,C)==0 and V.reveal_holding(view,C), 'pieces are gone while the picture holds')
    view.now = 5
    check(not V.reveal_holding(view,C), 'the hold ends and lets the beat play')
end

-- A frame tile is placed once at the centre of each neighbouring empty
-- cell. Include a diagonal cap outside the grid and a planted notch.
do
    local view = require('match3.elements_view')
    local board = E.new{square=true, columns=3, rows=3}
    local g = {active={}, oil={}}
    local step, origin = 24, vec2(80, 100)
    local expected = {}
    for _, pos in ipairs{{-1,-1}, {0,-1}, {-1,0}} do
        local q, row = pos[1], pos[2]
        local cell_id = board.hex_index(q, row)
        g.active[cell_id], g.oil[cell_id] = true, 0
        for dx = -1, 1 do
            for dy = -1, 1 do
                expected[(q + dx) * 16 + row + dy] = true
            end
        end
    end
    for i in pairs(g.active) do expected[board.hex_q(i) * 16 + board.hex_r(i)] = nil end

    local art = {}
    local skin = setmetatable({}, {__index=function(_, key)
        if key:sub(-5) ~= "-leaf" or key == "square-frame-5-leaf" then return key end
    end})
    view.load_square(art, skin)
    local model = {g=g, HEX_R=step/2, board_origin=origin, board_art=art, GROUND={seam_width=.5}}
    model.cell_pos = function(i) return origin + vec2(board.hex_q(i) * step, board.hex_r(i) * step) end
    local frame_draws, draw = {}, gfx.image_rot
    gfx.image_rot = function(sprite, box, angle) -- luacheck: ignore 122
        if sprite:match("^square%-frame%-") then
            frame_draws[#frame_draws + 1] = {sprite=sprite, box=box, angle=angle}
        end
    end
    local ok, err = pcall(view.ground, model, board, 0, {normal="square-plain"})
    gfx.image_rot = draw -- luacheck: ignore 122
    check(ok, err)
    local planted, cap
    for _, frame in ipairs(frame_draws) do
        local centre = frame.box:center() - origin
        local q, row = centre.x / step, centre.y / step
        local key = q * 16 + row
        check(frame.box.w == step and frame.box.h == step, 'frame uses the full tile footprint')
        check(q % 1 == 0 and row % 1 == 0 and expected[key], 'frame is drawn once in an empty cell')
        expected[key] = nil
        if q == 0 and row == 0 then planted = frame.sprite end
        if q == -2 and row == -2 then cap = frame end
    end
    check(next(expected) == nil, 'frame covers the entire empty ring')
    check(planted == "square-frame-5-leaf", 'the notch uses a single tile with baked foliage')
    check(cap and cap.sprite == "square-frame-2", 'the diagonal cap uses its own tile')
    near(cap.angle, math.pi / 2, 0.0001)
end

print('match3 elements: stones, tablets and square frame passed')
return 0
