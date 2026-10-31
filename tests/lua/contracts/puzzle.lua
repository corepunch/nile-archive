-- Shared engine puzzle contract. Accept a rules instance configured by the caller.
return function(R, options)
    local H=require('support')
    local t=H.suite(options.name..' board matrix')
    local goal_kind=options.goal_kind or R.RELIC_IDOL
    local wood_kind=options.wood_kind or R.RELIC_LEAF
    local stone_kind=options.stone_kind or R.RELIC_CRYSTAL
    local N=R.CELLS
    local function blank()return H.board(R)end
    local function coord(i)return R.hex_q(i),R.hex_r(i)end
    local function distance(a,b)
        local aq,ar=coord(a);local bq,br=coord(b)
        return math.max(math.abs(aq-bq),math.abs(ar-br),math.abs(aq+ar-bq-br))
    end
    local function same_axis(a,b,axis)
        local aq,ar=coord(a);local bq,br=coord(b)
        return axis==0 and ar==br or axis==1 and aq==bq or axis==2 and aq+ar==bq+br
    end

    -- All legal straight runs, both directions, all six colours, every length.
    for start=0,N-1 do
        for dir=0,5 do
            local cells,at={},start
            while at>=0 do cells[#cells+1]=at;at=R.hex_neighbor(at,dir) end
            for length=1,#cells do
                for kind=0,R.COLORS-1 do
                    t:case(('line start=%d dir=%d n=%d colour=%d'):format(start,dir,length,kind),function()
                        local g,m=blank(),R.new_match()
                        for k=1,length do g.tiles[cells[k]]=R.tile(kind) end
                        local pick=cells[(length+1)//2]
                        R.game_matches(g,m,pick)
                        t:check(m.hits==(length>=R.MATCH_MIN and length or 0),'exact match threshold')
                        local special=length>=R.MATCH_MIN+2 and R.PRISM or length==R.MATCH_MIN+1 and dir%3+1 or nil
                        t:check(m.make[pick]==special,'correct special and preferred cell')
                        for i=0,N-1 do
                            local expected=false
                            if length>=R.MATCH_MIN then
                                for k=1,length do if i==cells[k] then expected=true end end
                            end
                            t:check((not not m.mask[i])==expected,'only group cells marked: '..i)
                        end
                    end)
                end
            end
        end
    end

    -- Independent component oracle: pairwise axial distances, no engine neighbour
    -- traversal. Replays a fixed stream and reports the seed on failure.
    for seed=1,options.extended and 1000 or 80 do
        t:case('component oracle seed='..seed,function()
            local g,m=blank(),R.new_match()
            local rng=seed
            local function rand(n)rng=(rng*1664525+1013904223)&0xFFFFFFFF;return (rng>>8)%n end
            for i=0,N-1 do
                g.active[i]=rand(5)~=0
                g.tiles[i]=R.tile(rand(4))
                if rand(6)==0 then g.tiles[i].kind=-1 end
            end
            local seen,expected={},{}
            for i=0,N-1 do
                if g.active[i] and g.tiles[i].kind>=0 and not seen[i] then
                    local group={i};seen[i]=true;local head=1
                    while head<=#group do
                        local a=group[head];head=head+1
                        for b=0,N-1 do
                            if not seen[b] and g.active[b] and g.tiles[b].kind==g.tiles[i].kind and distance(a,b)==1 then
                                seen[b]=true;group[#group+1]=b
                            end
                        end
                    end
                    if #group>=R.MATCH_MIN then for _,cell in ipairs(group) do expected[cell]=true end end
                end
            end
            R.game_matches(g,m,-1)
            local count=0
            for i=0,N-1 do
                t:check((not not m.mask[i])==(not not expected[i]), 'component membership cell='..i)
                if expected[i] then count=count+1 end
            end
            t:check(m.hits==count,'exact component hit count')
            local before=R.game_copy(g)
            R.game_hint(g)
            t:check(H.same(g,before),'hint search never mutates board, counters or RNG')
        end)
    end

    -- Tools have exact spatial masks at corners, edges and the centre, including holes.
    for cell=0,N-1 do
        for tool=0,2 do
            for _,holes in ipairs({false,true}) do
                t:case(('tool=%d cell=%d holes=%s'):format(tool,cell,tostring(holes)),function()
                    local g,m=blank(),R.new_match()
                    if holes then for i=0,N-1 do if i~=cell and i%4==0 then g.active[i]=false end end end
                    t:check(R.game_tool(g,tool,cell,m),'charged tool accepted')
                    local count=0
                    for i=0,N-1 do
                        local hit=g.active[i] and (tool==0 and i==cell or tool==1 and distance(i,cell)<=1
                            or tool==2 and (same_axis(i,cell,0) or same_axis(i,cell,1) or same_axis(i,cell,2)))
                        t:check((not not m.mask[i])==(not not hit),'tool exact cell mask '..i)
                        if hit then count=count+1 end
                    end
                    t:check(m.hits==count and g.moves==20 and g.tools[tool+1]==1,'one charge, no move cost')
                    for j=1,3 do if j~=tool+1 then t:check(g.tools[j]==2,'other tools untouched') end end
                    g.tools[tool+1]=0
                    local before=R.game_copy(g)
                    t:check(not R.game_tool(g,tool,cell,m) and H.same(before,g),'exhausted tool is inert')
                end)
            end
        end
    end

    -- Every occupancy of the nine-cell central column retains survivor order.
    for mask=0,511 do
        t:case('gravity occupancy='..mask,function()
            local g=blank();local survivors={}
            -- Isolate this lane: lateral flow belongs to the shared trickling suite.
            for i=0,N-1 do g.active[i]=R.hex_q(i)==0 end
            for r=-4,4 do
                local cell=R.hex_index(0,r)
                if mask&(1<<(r+4))~=0 then
                    g.tiles[cell]=R.tile((r+4)%R.COLORS,(r+4)%6)
                    survivors[#survivors+1]={cell=cell,tile=g.tiles[cell]}
                end
            end
            local from=R.game_collapse(g)
            local first=5-#survivors
            for k,old in ipairs(survivors) do
                local dst=R.hex_index(0,first+k-1)
                t:check(g.tiles[dst]==old.tile and from[dst]==old.cell,'stable survivor identity and source')
            end
            for r=-4,first-1 do
                local cell=R.hex_index(0,r)
                t:check(from[cell]<0 and g.tiles[cell].kind>=0 and g.tiles[cell].kind<R.COLORS
                    and g.tiles[cell].special==R.NORMAL,'new ordinary piece spawns above survivors')
            end
        end)
    end
    for barrier=-3,3 do
        for _,mode in ipairs({'hole','chain','ice'}) do
            t:case(('gravity barrier %s r=%d'):format(mode,barrier),function()
                local g=blank();local at=R.hex_index(0,barrier)
                for i=0,N-1 do g.active[i]=R.hex_q(i)==0 end
                g.tiles[at]=R.tile(4,R.BOMB)
                if mode=='hole' then g.active[at]=false else g[mode][at]=1 end
                local upper=R.hex_index(0,barrier-1)
                g.tiles[upper]=R.tile(3,R.ROW)
                local old,stop=g.tiles[upper],g.tiles[at]
                local from=R.game_collapse(g)
                t:check(g.tiles[at]==stop and from[at]==at,'barrier stays fixed')
                t:check(g.tiles[upper]==old and from[upper]==upper,'piece cannot fall across barrier')
            end)
        end
    end

    for kind=0,R.COLORS-1 do
        for ice=0,2 do
            for chain=0,2 do
                t:case(('layers kind=%d ice=%d chain=%d'):format(kind,ice,chain),function()
                    local g,m=blank(),R.new_match();local cell=R.hex_center()
                    g.tiles[cell]=R.tile(kind)
                    g.ice[cell],g.chain[cell],g.soil[cell],g.obstacles=ice,chain,2,ice+chain
                    for hit=1,ice+chain do
                        m.mask={[cell]=true};m.make={}
                        t:check(R.game_apply(g,m)==0 and g.tiles[cell].kind==kind,'blocker absorbs hit before relic')
                        t:check(g.obstacles==ice+chain-hit and g.soil[cell]==2,'one blocker layer per hit, soil untouched')
                    end
                    m.mask={[cell]=true}
                    t:check(R.game_apply(g,m)==1 and g.tiles[cell].kind==-1,'unlocked piece clears')
                    t:check(g.dug==1 and g.soil[cell]==1 and g.cleared==1,'one soil layer per clear')
                    t:check(g.relics==(kind==goal_kind and 1 or 0),'goal accounting')
                    t:check(g.wood==(kind==wood_kind and 1 or 0),'wood accounting')
                    t:check(g.stone==(kind==stone_kind and 1 or 0),'stone accounting')
                    t:check(g.score==20*(ice+chain)+30+50*(ice+chain+1),'blocker, soil and combo score')
                end)
            end
        end
    end

    -- Every ordered special pair, all axes, both swap orders; chains fire once.
    for sa=R.ROW,R.PRISM do
        for sb=R.ROW,R.PRISM do
            t:case(('special pair %d + %d'):format(sa,sb),function()
                local g,m=blank(),R.new_match()
                local a,b=R.hex_center(),R.hex_neighbor(R.hex_center(),0)
                for i=0,N-1 do g.tiles[i]=R.tile((R.hex_q(i)+2*R.hex_r(i)+18)%6) end
                g.tiles[a],g.tiles[b]=R.tile(2,sa),R.tile(4,sb)
                t:check(R.game_swap(g,a,b,m) and g.moves==19,'special combination uses one move')
                t:check(m.mask[a] and m.mask[b] and m.hits>0,'both specials participate')
                R.game_apply(g,m)
                t:check(g.cleared>0 and g.cleared<=N and g.score==g.cleared*50,'each hit cell scores once')
                if sa==R.PRISM and sb==R.PRISM then t:check(g.cleared==N,'double prism clears whole board') end
            end)
        end
    end

    for _,terminal in ipairs({'won','lost'}) do
        for tool=-1,3 do
            t:case(terminal..' rejects actions '..tool,function()
                local g,m=blank(),R.new_match();g[terminal]=true
                g.tiles[30],g.tiles[31]=R.tile(0,R.PRISM),R.tile(1,R.BOMB)
                local old=R.game_copy(g)
                t:check(not R.game_tool(g,tool,30,m),'terminal tool rejected')
                t:check(not R.game_swap(g,30,31,m) and H.same(g,old),'terminal swap is inert')
            end)
        end
    end
    for _,pair in ipairs({{-1,30},{30,N},{30,30},{0,N-1}}) do
        t:case(('invalid swap %d,%d'):format(pair[1],pair[2]),function()
            local g=blank();local before=R.game_copy(g)
            t:check(not R.game_swap(g,pair[1],pair[2],R.new_match()) and H.same(g,before),'invalid swap has no side effects')
        end)
    end
    for level=0,R.LEVELS-1 do
        for _,missing in ipairs({'none','score','relics','dug','obstacles'}) do
            t:case(('last move level=%d missing=%s'):format(level,missing),function()
                local g=blank();g.level=level;local l=R.levels[level+1]
                g.score,g.relics,g.dug,g.obstacles,g.moves=l.score,l.relics,l.soil,0,0
                if missing=='obstacles' then g.obstacles=1
                elseif missing~='none' then g[missing]=g[missing]-1 end
                local rng=g.rng
                R.game_check_end(g)
                t:check(g.won==(missing=='none') and g.lost==(missing~='none'),'win takes precedence on last move')
                t:check(g.rng==rng,'terminal board never shuffles')
            end)
        end
    end
    return t:finish()
end
