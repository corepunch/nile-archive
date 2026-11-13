-- Direct shared-engine tests: no game modules, campaign or artwork involved.
local E=require('match3')
local H=require('support')
local t=H.suite('engine match3 factory and flags')
local function config(flags)
    return {flags=flags, radius=4, colors=6, match_min=4,
        levels={{name='Test',moves=20,score=1000,relics=3,chains=0,ice=0}},
        kind_flags={[0]=E.GOAL,[2]=E.WOOD,[4]=E.STONE}}
end
for _,bad in ipairs({-1,128,1.5,'1'}) do
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
for _, extra in ipairs({0,E.NO_SPECIALS}) do
    t:case('straight matching flags='..extra,function()
        local R=E.new{flags=E.LINE_MATCHES|extra,match_min=3}
        local g,m=H.board(R),R.new_match()
        local c=R.hex_center()
        for q=-2,1 do g.tiles[R.hex_index(q,0)]=R.tile(0) end
        local branch=R.hex_index(0,1)
        g.tiles[branch]=R.tile(0)
        R.game_matches(g,m,c)
        t:check(m.hits==4 and not m.mask[branch],'branch excluded from line and reward length')
        t:check(m.make[c]==(extra==0 and R.ROW or nil),'line reward respects NO_SPECIALS')
        for seed=1,8 do
            g=R.game_start(0,seed)
            R.game_matches(g,m,-1)
            t:check(m.hits==0 and R.game_hint(g),'line-mode generator produces stable playable boards')
        end
    end)
end
-- Every combination exercises interactions between all six behavior bits.
for flags=0,31 do
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
    t:case('flags='..flags..' diagonal or vertical gravity',function()
        local g=H.board(R)
        for i=0,R.CELLS-1 do g.active[i]=false end
        local center,side,above=R.hex_center(),R.hex_index(-1,0),R.hex_index(0,-1)
        g.active[center],g.active[side],g.active[above]=true,true,true
        g.tiles[side],g.tiles[above]=R.tile(2,R.BOMB),R.tile(4,R.ROW)
        local from=R.game_collapse(g)
        t:check(from[center]==above,'straight down wins with every flag combination')
        g.chain[above]=1
        g.tiles[center]=R.tile(-1);g.tiles[side]=R.tile(2,R.BOMB)
        from=R.game_collapse(g)
        t:check(flags&E.NO_TRICKLE~=0 and from[center]<0 or flags&E.NO_TRICKLE==0 and from[center]==side,
            'NO_TRICKLE controls diagonal fallback around a lock')
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
        for i=0,R.CELLS-1 do g.tiles[i]=R.tile((R.hex_q(i)+2*R.hex_r(i)+12)%R.COLORS) end
        local before=g.rng
        local changed=R.game_check_end(g)
        t:check((not not changed)==(flags&E.NO_RESHUFFLE==0),'NO_RESHUFFLE controls automatic recovery')
        t:check((g.rng==before)==(flags&E.NO_RESHUFFLE~=0),'disabled recovery retains RNG')
    end)
    t:case('flags='..flags..' idle hints',function()
        local g=H.board(R)
        for i=0,R.CELLS-1 do g.tiles[i]=R.tile((R.hex_q(i)+2*R.hex_r(i)+12)%R.COLORS) end
        local view={HEX_R=26.5,g=g,pending=R.new_match(),phase=0,phase_time=0,idle_time=6,
            shake=0,overlay=0,OV_NONE=0,OV_RESULT=1,OV_FAILED=2,hint_a=-1,hint_b=-1,
            tone=function()end,notice=function()end}
        R.bind_view(view)
        view.board_update(.01)
        t:check((view.idle_time>6)==(flags&E.NO_HINTS~=0),'NO_HINTS stops the automatic idle search')
    end)
end
-- A played swap must create its power-up at the matched swapped gem, not
-- whichever end of the run happens to be visited first in board order.
for _, mode in ipairs({{name='straight lines',flags=E.LINE_MATCHES},
                       {name='connected groups',flags=0}}) do
    for length=4,5 do
        for _, direction in ipairs({'into match','out of match'}) do
            t:case(('%s: match %d %s'):format(mode.name,length,direction),function()
                local R=E.new{flags=mode.flags}
                local g,m=H.board(R),R.new_match()
                local matched,other=R.hex_index(0,0),R.hex_index(0,1)
                for q=-2,length-3 do
                    if q~=0 then g.tiles[R.hex_index(q,0)]=R.tile(1) end
                end
                g.tiles[matched],g.tiles[other]=R.tile(2),R.tile(1)
                local a,b=other,matched
                if direction=='out of match' then a,b=matched,other end
                t:check(R.game_swap(g,a,b,m),'the swap completes the line')
                local special=length==4 and R.ROW or R.PRISM
                t:check(m.hits==length and m.make[matched]==special,
                    'special appears on the swapped gem in the match')
                for i=0,R.CELLS-1 do
                    if i~=matched then t:check(m.make[i]==nil,'no power-up at the end of the run') end
                end
                R.game_apply(g,m)
                t:check(g.tiles[matched].kind==1 and g.tiles[matched].special==special,
                    'the matched swapped gem retains the power-up after clearing')
            end)
        end
    end
    for _, reverse in ipairs({false,true}) do
        t:case(('%s: two matches from one swap, reverse=%s'):format(mode.name,tostring(reverse)),function()
            local R=E.new{flags=mode.flags}
            local g,m=H.board(R),R.new_match()
            local center,side=R.hex_index(0,0),R.hex_index(0,1)
            for q=-2,1 do
                if q~=0 then g.tiles[R.hex_index(q,0)]=R.tile(1) end
            end
            for r=2,4 do g.tiles[R.hex_index(0,r)]=R.tile(2) end
            g.tiles[center],g.tiles[side]=R.tile(2),R.tile(1)
            local a,b=reverse and side or center,reverse and center or side
            t:check(R.game_swap(g,a,b,m),'both crossing directions form a match')
            t:check(m.hits==8 and m.make[center]==R.ROW and m.make[side]==R.COLUMN,
                'each run leaves its special on its own swapped endpoint')
            R.game_apply(g,m)
            t:check(g.tiles[center].special==R.ROW and g.tiles[side].special==R.COLUMN,
                'both swapped gems survive with their respective specials')
        end)
    end
end
local failures=t:finish()
return failures+require('contracts/puzzle')(E.new(config(0)),
    {name='engine match3',extended=testing.extended,goal_kind=0,wood_kind=2,stone_kind=4})
