local rules=require("rules")
-- Lives regenerate offline, stop at five, and charge a failed attempt once.
do
    local p={lives=5,life_at=0}
    local g={lost=true}
    check(rules.lose_life(p,g,1000) and p.lives==4 and p.life_at==2800,'first failed attempt costs one life')
    check(not rules.lose_life(p,g,1001) and p.lives==4,'failed board charges once')
    check(rules.lose_life(p,{lost=true},1010) and p.lives==3 and p.life_at==2800,'timer does not restart when another life is spent')
    rules.refill_lives(p,2799);check(p.lives==3,'refill waits for the full interval')
    rules.refill_lives(p,2800);check(p.lives==4 and p.life_at==4600,'one interval restores one life')
    rules.refill_lives(p,10000);check(p.lives==5 and p.life_at==0,'offline refill caps at five')
    check(not rules.lose_life(p,{lost=false},10000),'winning boards cost no life')
end
