local feedback = require('volcano_feedback')
for _, pair in ipairs({
    {{kind='complete',building=true},haptic.PLACE},
    {{kind='complete',building=false},haptic.MATCH},
    {{kind='income'},haptic.COLLECT}, {{kind='rescue'},haptic.SUCCESS}
}) do
    testing.reset()
    feedback.event(pair[1])
    local count, effect = testing.haptics()
    check(count == 1 and effect == pair[2], 'completed '..pair[1].kind..' feedback')
end
testing.reset()
feedback.event{kind='outbound'}
feedback.event{kind='queued'}
feedback.event{kind='returning'}
check(testing.haptics() == 0, 'worker movement and planning stay silent')
feedback.event{kind='income'}
feedback.win()
local count, effect = testing.haptics()
check(count == 1 and effect == haptic.SUCCESS, 'victory overrides same-frame income')
testing.reset()
