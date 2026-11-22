-- Real Relic Rush staging: entrance, waiting, listener, returning speaker, exit.
local desc = require("games/relic-rush/lua/main")
local init, frame = desc.init, desc.frame
local tick = 0
local same_side
function desc.init()
    init()
    same_side = app.arg("same-side") ~= nil
    while story.active() do story.next() end
    story.say(same_side and "oren" or "sela", "Give me the bucket.")
end
function desc.frame(dt)
    tick = tick + 1
    if tick == 25 then story.say(same_side and "tavi" or "oren", same_side and "I can show you the way." or "Try the spring well."); story.next() end
    if tick == 49 then story.say("sela", "Help me lift this stone."); story.next() end
    if tick == 73 then story.next() end
    frame(.05) -- fixed presentation clock; capture does not depend on GPU speed
end
return desc
