local state = require("loader.state")
state.attempts = state.attempts + 1
if state.attempts == 1 then error("loader runtime failure") end
return state
