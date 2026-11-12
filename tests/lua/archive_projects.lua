-- Projects spend coins and award Influence only after confirmation, once.
local economy = require('archive_economy')

local state = {wallet = purse(1000, 90), caches = {0, 0, 0}, projects = {}, cache_done = false}
check(economy.project_lock(state, 1) == 'chapter', 'chapter 2 project waits for chapter 1 cache')
check(not economy.claim_project(state, 1), 'locked project cannot be claimed')
check(state.wallet[1] == 1000 and state.wallet[2] == 90, 'locked project does not change wallet')

state.caches[1] = 1
state.wallet[1] = 99
check(economy.project_lock(state, 1) == 'coins', 'insufficient funds are reported')
check(not economy.claim_project(state, 1) and state.wallet[1] == 99 and state.wallet[2] == 90,
    'insufficient funds do not alter the wallet')
state.wallet[1] = 100
check(economy.claim_project(state, 1), 'exact funds complete project')
check(state.wallet[1] == 0 and state.wallet[2] == 105 and state.projects[1] == 1,
    'project debits coins, awards Influence and records ownership')
state.wallet[1] = 1000
check(economy.project_lock(state, 1) == 'done' and not economy.claim_project(state, 1),
    'project cannot be claimed twice')
check(state.wallet[1] == 1000 and state.wallet[2] == 105, 'repeated claim does not change wallet')
check(economy.project_lock(state, 6) == 'chapter', 'chapter 3 project waits for chapter 2 cache')
state.caches[2] = 1
check(economy.claim_project(state, 6) and state.wallet[1] == 700 and state.wallet[2] == 135,
    'chapter 3 project is available after its predecessor')
local old = {wallet = purse(100, 10), cache_done = true}
check(economy.claim_project(old, 1) and old.projects[1] == 1,
    'legacy completed cache unlocks its projects')
local fresh = {wallet = purse(100, 10), cache_done = false, caches = {0, 0, 0}, projects = {0}}
check(economy.project_lock(fresh, 1) == 'chapter', 'zero flags are not treated as completion')
check(economy.project_lock(state, 99) == 'unknown' and not economy.claim_project(state, 99),
    'invalid project cannot be claimed')

local campaign = {
    wallet = purse(0, 1000), wins = {}, stars = {}, clues = {}, restored = {[4] = true, [5] = true},
    caches = {0, 0, 0}, projects = {}, cache_done = false,
}
for i = 1, 15 do campaign.wins[i], campaign.stars[i], campaign.clues[i] = 0, 0, economy.clue_count(i) end
check(economy.lock(campaign, 6) == 'chapter', 'chapter 2 waits for first cache')
check(economy.claim_cache(campaign, 1) and campaign.caches[1] == 1 and campaign.cache_done,
    'first cache sets both new and legacy flags')
check(not economy.lock(campaign, 6), 'first cache opens chapter 2')
check(economy.lock(campaign, 11) == 'chapter', 'chapter 3 waits for second cache')
check(economy.claim_cache(campaign, 2) and campaign.caches[2] == 1,
    'second cache records its chapter flag')
check(not economy.lock(campaign, 11), 'second cache opens chapter 3')
campaign.restored[5] = false
check(economy.lock(campaign, 15) == 'workshop', 'final search requires workshop')
check(not economy.claim_cache(campaign, 3), 'final cache requires workshop')
campaign.restored[5] = true
local coins = campaign.wallet[1]
check(economy.claim_cache(campaign, 3) and campaign.wallet[1] == coins + 200,
    'final cache awards its chapter reward once')
check(not economy.claim_cache(campaign, 3) and campaign.wallet[1] == coins + 200,
    'final cache cannot be claimed twice')
