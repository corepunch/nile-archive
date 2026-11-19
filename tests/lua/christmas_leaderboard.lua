-- The campaign leaderboard tracks boards cleared and opens from Settings.
local rules = require('rules')
local island = require('island')
local R = require('state')
local app_desc = require('main')

testing.reset()
R.test_mode, R.quiet, R.overlay = true, false, R.OV_NONE
R.island = city.new()
island.island_setup(R.island)
R.wonders = island.wonders
R.prog = {level = 0, seed = 1, wallet = purse(), story_seen = {}}
R.notice = function() end
check(app_desc.gamecenter_board == 'stars', 'the game declares its campaign leaderboard')

-- A first clear counts toward the campaign leaderboard.
R.g = rules.game_start(0, 1)
R.g.won, R.g.score = true, 4321
R.claim_reward()
check(R.prog.level == 1 and R.prog.wallet[rules.CLEARED] == 1, 'the first clear counts one board')
check(gamecenter.best('stars') == R.prog.level, 'the campaign board holds the boards cleared')
check(gamecenter.best('level_01') == 0, 'a clear does not report the individual board score')

-- A higher-scoring replay leaves the board count alone.
R.on_island, R.overlay = false, R.OV_NONE
R.g = rules.game_start(0, 2)
R.g.won, R.g.score = true, 9000
R.claim_reward()
check(gamecenter.best('stars') == 1 and gamecenter.best('level_01') == 0, 'a replay leaves the campaign board at one clear')

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
