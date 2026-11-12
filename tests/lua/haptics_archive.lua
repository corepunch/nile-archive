local G = require('archive_state')
local scene = require('archive_scene')
local content = require('archive_content')
testing.reset()
G.island = city.new()
scene.open(1)
G.reduced_motion = true
G.cam = camera{center=vec2(600,400),zoom=1,view=rect(0,0,1200,800),world=size2(1200,800)}
local function pulse(expected, message)
    local count, effect = testing.haptics()
    check(count == 1 and effect == expected, message)
end
check(testing.haptics() == 0, 'opening a hidden-object scene stays silent')
scene.tap(content.scenes[1].at[1])
pulse(haptic.MATCH, 'finding an object pulses even with reduced motion')
testing.reset()
scene.tap(content.scenes[1].at[2])
pulse(haptic.COMBO, 'consecutive finds escalate feedback')
testing.reset()
local unlisted = 4
local score = G.score
scene.tap(content.scenes[1].at[unlisted])
pulse(haptic.ERROR, 'an object outside the visible list is a miss')
check(not G.found[unlisted] and G.score == math.max(0, score - G.MISS_POINTS),
    'unlisted objects cannot be collected')
testing.reset()
scene.tap(vec2(600,10))
pulse(haptic.ERROR, 'miss breaks the chain with error feedback')
testing.reset()
scene.show_hint()
pulse(haptic.TICK, 'hint acknowledges the target')
testing.reset()
G.found[3] = app.time()
local hints = G.hints
scene.show_hint()
check(G.hints == hints and testing.haptics() == 0, 'hint waits until a visible slot refills')
for i=1,G.ITEMS-1 do G.found[i] = 0 end
G.slots = {G.ITEMS}
G.wallet = purse()
G.wins, G.stars, G.clues = {0,0,0,0,0}, {0,0,0,0,0}, {0,0,0,0,0}
scene.tap(content.scenes[1].at[G.ITEMS])
pulse(haptic.SUCCESS, 'last find coalesces to scene completion')
check(G.result and G.result.claimed, 'completion pays once')
testing.reset()
