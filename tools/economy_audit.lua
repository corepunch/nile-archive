-- Run through tools/economy_audit.py (sets an isolated test save directory).
-- Uses the actual rules and economy tables; no engine window or new dependency.
local rules,island,archive=require('rules'),require('island'),require('archive_economy')
local function encode(v)
    if type(v)=='number' then return ('%.4f'):format(v) end
    if type(v)=='string' then return '"'..v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n')..'"' end
    local parts={}
    if #v>0 then
        for _,x in ipairs(v) do parts[#parts+1]=encode(x) end
        return '['..table.concat(parts,',')..']'
    end
    local keys={};for key in pairs(v) do keys[#keys+1]=key end;table.sort(keys)
    for _,key in ipairs(keys) do parts[#parts+1]=encode(key)..':'..encode(v[key]) end
    return '{'..table.concat(parts,',')..'}'
end
local samples=20
local report={samples_per_level=samples,policy='greedy highest evaluated legal swap; no tools; seeds 1..20',
    disclaimer='Automated solvability and payout audit, not measured human difficulty or retention.',relic_levels={},nile={}}
for level=0,9 do
    local row={level=level+1,name=rules.levels[level+1].name,wins=0,samples=samples,moves_left=0,
        previous_spare_gold=0,new_spare_gold=0,replay_gold=0,previous_spare_wood=0,previous_spare_stone=0,
        first_compasses=rules.compass_rewards[level+1]}
    for seed=1,samples do
        local g=rules.game_start(level,seed)
        local m=rules.new_match()
        for _=1,100 do
            if g.won or g.lost then break end
            local best,a,b=-1,-1,-1
            for i=0,rules.CELLS-1 do for d=0,2 do
                local j=rules.hex_neighbor(i,d)
                local value=rules.game_evaluate_move(g,i,j)
                if value>best then best,a,b=value,i,j end
            end end
            if a<0 then rules.game_shuffle(g)
            else
                assert(rules.game_swap(g,a,b,m))
                local settled=false
                for _=1,200 do
                    rules.game_apply(g,m);rules.game_collapse(g);rules.game_matches(g,m,-1)
                    if m.hits==0 then rules.game_check_end(g);settled=true;break end
                end
                assert(settled,'cascade did not settle')
            end
        end
        if g.won then
            row.wins=row.wins+1;row.moves_left=row.moves_left+g.moves
            row.previous_spare_gold=row.previous_spare_gold+20+g.relics
            row.previous_spare_wood=row.previous_spare_wood+5+g.wood
            row.previous_spare_stone=row.previous_spare_stone+5+g.stone
            row.new_spare_gold=row.new_spare_gold+rules.level_reward(g,island.wonders,{level=level})[1]-island.wonders[level+1].cost[1]
            row.replay_gold=row.replay_gold+rules.level_reward(g,island.wonders,{level=10})[1]
        end
    end
    if row.wins>0 then for _,field in ipairs({'moves_left','previous_spare_gold','new_spare_gold','replay_gold','previous_spare_wood','previous_spare_stone'}) do row[field]=row[field]/row.wins end end
    report.relic_levels[#report.relic_levels+1]=row
    print(('Economy audit: level %d, %d/%d bot wins'):format(level+1,row.wins,samples))
end
report.relic_budget={minimum_spare_gold=10*rules.FIRST_GOLD,maximum_spare_gold=10*(rules.FIRST_GOLD+rules.MAX_MOVE_GOLD),
    compass_income=rules.discovery_compasses(10),compass_sinks=20,replay_min=rules.REPLAY_GOLD,replay_max=rules.REPLAY_GOLD+rules.MAX_MOVE_GOLD}
report.nile={start_coins=archive.START_COINS,start_influence=archive.START_INFLUENCE,
    first_clear_min=archive.reward(0,0,1,false).coins,first_clear_max=archive.reward(0,0,3,true).coins,
    mastered_replay_min=archive.reward(1,3,1,false).coins,mastered_replay_max=archive.reward(1,3,3,true).coins,
    minimum_story_path={clears=3,builds=2,construction_cost=archive.buildings[4].coins+archive.buildings[2].coins,
        influence=archive.START_INFLUENCE+archive.buildings[4].influence+archive.buildings[2].influence},shores=archive.shore_costs}
print('ECONOMY_JSON '..encode(report))
return 0
