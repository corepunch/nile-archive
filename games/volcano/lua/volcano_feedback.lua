-- Presentation for completed simulation events; planning, queues and worker
-- travel never request feedback. Keep the deterministic simulation silent.
local M = {}
function M.event(ev)
    if ev.kind == 'rescue' then haptic.play(haptic.SUCCESS)
    elseif ev.kind == 'income' then haptic.play(haptic.COLLECT, .4)
    elseif ev.kind == 'complete' then haptic.play(ev.building and haptic.PLACE or haptic.MATCH, .8) end
end
function M.win() haptic.play(haptic.SUCCESS) end
return M
