-- Game integration selects its rules adapter; assertions live in one engine contract.
return require('contracts/puzzle')(require('rules'), {name=testing.game, extended=testing.extended})
