-- Optional screen mockup loaded with --lua for art review.
local game = require("games/relic-rush/lua/main")
local R = require("state")
local init = game.init

function game.init()
    init()
    local icon = texture.load("../docs/review/moves-capsule/moves.png")
    assert(icon.w > 0)
    local header = {
        role = "wallet", align = "center", interactive = false, x = 12, y = -2,
        height = 32, band_height = 72, gap = 18, overhang = 16, width = 90,
    }
    function R.draw_board_hud()
        local caps = R.header_capsules(true)
        table.insert(caps, 1, {icon = icon, value = tostring(R.g.moves)})
        R.town:header(caps, header)
    end
end

return game
