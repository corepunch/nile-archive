-- The shared leaderboard dialog (engine/leaderboard.lua) over the engine's Game Center rows.
local leaderboard = require("leaderboard")
testing.reset()
gamecenter.submit('stars', 1234567)
local lb = leaderboard.new{skin = {}, board = 'stars', title = 'Top explorers', count = 5}
check(not lb:active(), 'closed until opened')
check(lb:open() and lb:active(), 'opens as a modal layer')
lb:sync()
local rows = lb.form.nodes.rows
check(#rows.children == 1, 'the player\'s own best fills the board without Game Center')
check(lb.form:get('status') == lb.texts.sign_in, 'says how to compare with other players')
check(lb.form.values.show_global_on and not lb.form.values.show_global_off and lb.form.values.show_friends_off, 'Everyone tab is selected')
check(lb.form.values.show_native == false, 'no native button while signed out')
check(lb.format(1234567) == '1,234,567' and lb.format(12) == '12' and lb.format(999) == '999', 'scores get thousands separators')

check(lb:handle({modal = 'leaderboard', id = 'friends', kind = 'click'}), 'tab events belong to the dialog')
check(lb:handle({modal = 'leaderboard', id = 'friends_on', kind = 'click'}) and lb.scope == gamecenter.FRIENDS, 'the chosen tab does nothing')
lb:sync()
check(lb.scope == gamecenter.FRIENDS and lb.form.values.show_friends_on and lb.form.values.show_global_off, 'Friends tab switches scope')
check(lb.form:get('status') == lb.texts.sign_in_friends, 'friends need Game Center')
check(not lb:handle({modal = 'other', id = 'close'}), 'other dialogs\' events pass through')
check(lb:handle({modal = 'leaderboard', id = 'close', kind = 'click'}) and not lb:active(), 'Close removes the layer')

-- rows are plain, ranked and highlight the player; an empty board explains itself
testing.reset()
local empty = leaderboard.new{skin = {}, board = 'nobody'}
empty:open(); empty:sync()
check(#empty.form.nodes.rows.children == 0 and empty.form:get('status') == empty.texts.empty, 'an empty board says so')
check(empty:open(), 'opening twice is harmless')
check(not pcall(leaderboard.new, {}), 'a board name is required')

-- portraits: demo rivals arrive with ids, and rows without a photo get a placeholder
testing.reset()
gamecenter.submit('stars', 5)
gamecenter.load('stars')
local mine = gamecenter.entries('stars')[1]
check(mine.id == '' and mine.photo == nil and mine.photo_rev == 0, 'the local row has no portrait yet')
