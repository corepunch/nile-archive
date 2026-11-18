-- Game integration selects its rules adapter; assertions live in one engine contract.
local rules, engine = require('rules'), require('match3')
local minimum = testing.game == "relic-rush" and 4 or 3
check(rules.MATCH_MIN == minimum and rules.flags & engine.LINE_MATCHES ~= 0,
    'each game uses its configured straight-line minimum on the hex grid')
return require('contracts/puzzle')(rules, {name=testing.game, extended=testing.extended})
