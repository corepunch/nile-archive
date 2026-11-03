-- Game integration selects its rules adapter; assertions live in one engine contract.
local rules, engine = require('rules'), require('match3')
check(rules.MATCH_MIN == 3 and rules.flags & engine.LINE_MATCHES ~= 0,
    'both portrait games use swap-based straight-line triples on the hex grid')
return require('contracts/puzzle')(rules, {name=testing.game, extended=testing.extended})
