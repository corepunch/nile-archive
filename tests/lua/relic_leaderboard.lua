-- Relic Rush's Game Center boards: scores go out when a reward is claimed, and
-- Settings and the results card open the shared dialog (engine/match3_game.lua).
local rules = require('rules')
local island = require('island')
local R = require('state')
require('main')

testing.reset()
R.test_mode, R.quiet, R.overlay = true, false, R.OV_NONE
R.island = city.new()
island.island_setup(R.island)
R.wonders = island.wonders
R.prog = {level = 0, seed = 1, wallet = purse(), lives = rules.LIVES, life_at = 0, story_seen = {}}
R.notice = function() end
local config = R.words.leaderboard
check(config and config.board == 'stars' and config.level_board == 'level_%02d', 'game.json names the boards')

-- first clear: lifetime stars and this expedition's score
R.g = rules.game_start(0, 1)
R.g.won, R.g.score = true, 4321
R.claim_reward()
check(R.prog.level == 1 and R.prog.wallet[rules.STARS] > 0, 'the first clear awards discovery stars')
check(gamecenter.best('stars') == R.prog.wallet[rules.STARS], 'the stars board holds the lifetime stars')
check(gamecenter.best('level_01') == 4321, 'the expedition board holds its score')

-- a weaker replay keeps the best; a better one raises it; other levels have their own boards
R.on_island, R.overlay = false, R.OV_NONE
R.g = rules.game_start(0, 2)
R.g.won, R.g.score = true, 100
R.claim_reward()
check(gamecenter.best('level_01') == 4321, 'a worse replay never lowers the board')
R.g = rules.game_start(0, 3)
R.g.won, R.g.score = true, 9000
R.claim_reward()
check(gamecenter.best('level_01') == 9000 and gamecenter.best('level_02') == 0, 'a better replay raises only its own board')

-- Settings has the link, the dialog opens above it and closes back to it
R.on_island, R.overlay = false, R.OV_PAUSE
R.g = rules.game_start(0, 1)
local link = R.pause_form.nodes.leaderboard
check(link and link.visible ~= false and link.text == R.words.pause.leaderboard, 'Settings offers the leaderboard')
check(R.leaderboard_active() == nil, 'closed to begin with')
R.open_leaderboard()
local lb = R.leaderboard_active()
check(lb and lb.board == 'stars' and R.overlay == R.OV_PAUSE, 'the stars board opens over Settings')
check(lb:handle({modal = 'leaderboard', id = 'close', kind = 'click'}) and R.leaderboard_active() == nil and R.overlay == R.OV_PAUSE,
    'Close returns to Settings')
R.open_leaderboard(1)
check(R.leaderboard_active().board == 'level_02', 'an expedition opens its own board (0-based level)')
R.leaderboard_active():close()
