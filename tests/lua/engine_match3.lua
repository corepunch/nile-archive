-- Direct shared-engine tests: no game modules, campaign or artwork involved.
local E=require('match3')
local H=require('support')
local t=H.suite('engine match3 factory and flags')
local function config(flags)
    return {flags=flags, radius=4, colors=6, match_min=4,
        levels={{name='Test',moves=20,score=1000,relics=3,soil=2,chains=0,ice=0}},
        kind_flags={[0]=E.GOAL,[1]=E.THAW,[2]=E.WOOD,[4]=E.STONE}}
end
for _,bad in ipairs({-1,64,1.5,'1'}) do
    t:case('invalid flags '..tostring(bad),function()
        t:check(not pcall(E.new,config(bad)),'invalid flag mask rejected')
    end)
end
for _,radius in ipairs({1,2,3,4,8,16}) do
    t:case('hex radius '..radius,function()
        local R=E.new{radius=radius}
        t:check(R.CELLS==1+3*radius*(radius+1),'cell count follows radius')
        for cell=0,R.CELLS-1 do
            t:check(R.hex_index(R.hex_q(cell),R.hex_r(cell))==cell,'coordinate round trip')
            for dir=0,5 do
                local n=R.hex_neighbor(cell,dir)
                if n>=0 then t:check(R.hex_neighbor(n,(dir+3)%6)==cell and R.hex_distance(cell,n)==1,'neighbor symmetry') end
            end
        end
    end)
end
t:case('default engine uses match-3',function()
    local R=E.new()
    local g,m=H.board(R),R.new_match()
    for q=-1,1 do g.tiles[R.hex_index(q,0)]=R.tile(0) end
    R.game_matches(g,m,R.hex_center())
    t:check(R.MATCH_MIN==3 and m.hits==3 and next(m.make)==nil,'three pieces clear without a special')
end)
for threshold=3,6 do
    for colors=3,8 do
        t:case(('threshold=%d colors=%d'):format(threshold,colors),function()
            local R=E.new{match_min=threshold,colors=colors}
            for count=threshold-1,threshold+2 do
                local g,m=H.board(R),R.new_match()
                for offset=0,count-1 do g.tiles[R.hex_index(-4+offset,0)]=R.tile(colors-1) end
                R.game_matches(g,m,R.hex_index(-4,0))
                t:check(m.hits==(count>=threshold and count or 0),'configured threshold')
                local special=m.make[R.hex_index(-4,0)]
                if count==threshold+1 then t:check(special==R.ROW,'one extra makes ray')
                elseif count==threshold+2 then t:check(special==R.PRISM,'two extras in line make prism')
                else t:check(next(m.make)==nil,'small group makes no special') end
            end
        end)
    end
end
-- Every combination exercises interactions between all six behavior bits.
for flags=0,63 do
    local R=E.new(config(flags))
    t:case('flags='..flags..' special creation',function()
        local g,m=H.board(R),R.new_match()
        for q=-2,2 do g.tiles[R.hex_index(q,0)]=R.tile(0) end
        R.game_matches(g,m,R.hex_center())
        t:check(m.hits==5,'flag does not change the configured match threshold')
        t:check((next(m.make)==nil)==(flags&E.NO_SPECIALS~=0),'NO_SPECIALS controls creation')
    end)
    t:case('flags='..flags..' tool charges',function()
        local g,m=H.board(R),R.new_match()
        local allowed=flags&E.NO_TOOLS==0
        t:check(R.game_tool(g,0,R.hex_center(),m)==allowed,'NO_TOOLS blocks use')
        t:check(g.tools[1]==(allowed and 1 or 2),'blocked tool retains charge')
    end)
    t:case('flags='..flags..' thaw',function()
        local g,m=H.board(R),R.new_match()
        local center=R.hex_center();local neighbor=R.hex_neighbor(center,0)
        g.tiles[center]=R.tile(1);g.tiles[neighbor]=R.tile(3)
        g.ice[neighbor],g.obstacles=1,1
        m.mask[center]=true
        R.game_apply(g,m)
        t:check(g.ice[neighbor]==(flags&E.NO_THAW~=0 and 1 or 0),'NO_THAW controls adjacent ice damage')
        t:check(g.tiles[neighbor].kind==3,'thaw leaves the adjacent gem')
    end)
    t:case('flags='..flags..' diagonal or vertical gravity',function()
        local g=H.board(R)
        for i=0,R.CELLS-1 do g.active[i]=false end
        local center,side,above=R.hex_center(),R.hex_index(-1,0),R.hex_index(0,-1)
        g.active[center],g.active[side],g.active[above]=true,true,true
        g.tiles[side],g.tiles[above]=R.tile(2,R.BOMB),R.tile(4,R.ROW)
        local from=R.game_collapse(g)
        t:check(from[center]==(flags&E.NO_TRICKLE~=0 and above or side),'NO_TRICKLE selects the expected original donor')
    end)
    t:case('flags='..flags..' exposed top inlets',function()
        local g=H.board(R)
        for i=0,R.CELLS-1 do g.active[i]=false end
        local center,side=R.hex_center(),R.hex_index(-1,0)
        g.active[center],g.active[side]=true,true
        g.tiles[side]=R.tile(2,R.BOMB)
        local _,steps=R.game_collapse(g)
        t:check(steps[1].from[center]<0,'top cell spawns instead of borrowing diagonally')
        t:check(g.tiles[side].kind==2 and g.tiles[side].special==R.BOMB,'side donor stays put')
    end)
    t:case('flags='..flags..' dead-board recovery',function()
        local g=H.board(R)
        for i=0,R.CELLS-1 do g.tiles[i]=R.tile(i) end
        local before=g.rng
        local changed=R.game_check_end(g)
        t:check((not not changed)==(flags&E.NO_RESHUFFLE==0),'NO_RESHUFFLE controls automatic recovery')
        t:check((g.rng==before)==(flags&E.NO_RESHUFFLE~=0),'disabled recovery retains RNG')
    end)
    t:case('flags='..flags..' idle hints',function()
        local g=H.board(R)
        for i=0,R.CELLS-1 do g.tiles[i]=R.tile(i) end
        local view={HEX_R=26.5,g=g,pending=R.new_match(),phase=0,phase_time=0,idle_time=6,
            shake=0,overlay=0,OV_NONE=0,OV_RESULT=1,OV_FAILED=2,hint_a=-1,hint_b=-1,
            tone=function()end,notice=function()end}
        R.bind_view(view)
        view.board_update(.01)
        t:check((view.idle_time>6)==(flags&E.NO_HINTS~=0),'NO_HINTS stops the automatic idle search')
    end)
end
local failures=t:finish()
return failures+require('contracts/puzzle')(E.new(config(0)),
    {name='engine match3',extended=testing.extended,goal_kind=0,wood_kind=2,stone_kind=4})
