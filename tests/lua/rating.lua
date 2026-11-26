-- The App Store rating sheet: asked for rarely, after a first clear, once the
-- town has stood untouched. Run once in each portrait campaign's suite.
local rules = require('rules')
local island = require('island')
local rating = require('match3.rating')
local R = require('state')
require('main')   -- binds the campaign's screens to R

-- The policy alone.
local C = rating.DEFAULTS
local s = rating.new()
check(not rating.due(C, s, C.level - 1, 0), 'no ask before the first milestone')
check(rating.due(C, s, C.level, 0), 'the first ask comes at the milestone')
s.losses = 1
check(not rating.due(C, s, C.comeback_level - 1, 0), 'a comeback on an early board is too soon')
check(rating.due(C, s, C.comeback_level, 0), 'a win after a loss asks earlier')
rating.asked(s, C.level, 100)
check(s.asks == 1 and s.level == C.level and s.day == 100, 'an ask is remembered')
check(not rating.due(C, s, C.level + C.gap_levels, 100 + C.gap_days - 1), 'the next ask waits for the days')
check(not rating.due(C, s, C.level + C.gap_levels - 1, 100 + C.gap_days), 'and for the boards')
check(rating.due(C, s, C.level + C.gap_levels, 100 + C.gap_days), 'then it is due again')
s.asks = C.asks
check(not rating.due(C, s, 99, 99999), 'the asks run out')
check(rating.url('123') == 'https://apps.apple.com/app/id123?action=write-review', 'Settings links to the review form')

-- In the campaign.
local function setup(level)
    testing.reset()
    R.test_mode, R.quiet, R.overlay, R.on_menu = true, false, R.OV_NONE, false
    R.island = city.new()
    island.island_setup(R.island)
    R.wonders = island.wonders
    R.prog = {level = level, seed = 1, wallet = purse(), story_seen = {}}
    R.notice = function() end
    R.rating, R.rating_due, R.rating_forced = rating.new(), nil, nil
end
local function win(level)
    R.on_island, R.overlay = false, R.OV_NONE
    R.g = rules.game_start(level, 1)
    R.g.won, R.g.score = true, 1000
    R.claim_reward()
end
local function wait(seconds, calm)
    for _ = 1, math.ceil(seconds * 20) do R.rating_tick(.05, calm) end
end

setup(C.level - 2)
testing.review(true)
win(C.level - 2)
check(not R.rating_due, 'an ordinary early win does not ask')
win(C.level - 1)
check(R.prog.level == C.level and R.rating_due, 'the milestone win marks an ask')
wait(C.pause + .5, false)
check(testing.review() == 0, 'nothing shows while the town is busy')
wait(C.pause - .2, true)
check(testing.review() == 0, 'nor at once when it calms')
wait(.4, true)
check(testing.review() == 1 and not R.rating_due, 'the sheet is asked for once the town has stood still')
check(R.rating.asks == 1 and R.rating.level == C.level, 'and the ask is recorded')
wait(5, true)
check(testing.review() == 1, 'one ask, not one a frame')
win(C.level)
check(not R.rating_due, 'the next win is too soon')

-- A replay never asks.
setup(C.level + 5)
testing.review(true)
win(0)
check(not R.rating_due, 'a replay does not ask')

-- Lost, then won: the ask comes earlier, and the loss is spent.
setup(C.comeback_level - 1)
testing.review(true)
R.g = rules.game_start(C.comeback_level - 1, 1)
R.level_lost()
check(R.rating.losses == 1, 'a lost board is counted')
win(C.comeback_level - 1)
check(R.rating_due and R.rating.losses == 0, 'the comeback win marks an ask')
R.on_island = false   -- straight on to the next board
wait(C.pause + 1, true)
check(testing.review() == 0 and not R.rating_due and R.rating.asks == 0, 'leaving for a board drops the ask unspent')

-- No sheet on this platform: nothing is marked or spent.
setup(C.level - 1)
win(C.level - 1)
wait(C.pause + 1, true)
check(not R.rating_due and R.rating.asks == 0 and testing.review() == 0, 'without the sheet there is no ask')
