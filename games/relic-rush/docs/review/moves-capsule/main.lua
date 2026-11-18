-- Optional screen mockup loaded with --lua for art review.
local game = require("games/relic-rush/lua/main")
local R = require("state")
local init = game.init

local function draw_variants(header)
    local atlas = texture.load("../docs/review/moves-capsule/variants-atlas.png")
    assert(atlas.w > 0)
    local cell_width, cell_height = atlas.w // 4, atlas.h // 2
    local caption_style = R.skin:text("cream", 14)
    local rows = {}
    for row = 0, 1 do
        local caps = {}
        for col = 0, 3 do
            local label = tostring(row * 4 + col + 1)
            local icon = texture.region(atlas, rect(col * cell_width, row * cell_height, cell_width, cell_height))
            caps[col + 1] = {icon = icon, value = "32", decorate = function(box)
                local caption = rect(box.x - header.overhang, box:max().y + 4, box.w + header.overhang, 16)
                text.inside(caption_style, caption, vec2(.5, .5), label)
            end}
        end
        local layout = {}
        for key, value in pairs(header) do layout[key] = value end
        layout.y = header.y + row * 72
        rows[row + 1] = {caps = caps, layout = layout}
    end
    return function()
        for _, row in ipairs(rows) do R.town:header(row.caps, row.layout) end
    end
end

function game.init()
    init()
    local header = {
        role = "wallet", align = "center", interactive = false, x = 12, y = -2,
        height = 32, band_height = 72, gap = 18, overhang = 16, width = 90,
    }
    if app.arg("moves-variants") then
        R.draw_board_hud = draw_variants(header)
        return
    end
    local icon = texture.load("../docs/review/moves-capsule/moves.png")
    assert(icon.w > 0)
    function R.draw_board_hud()
        local caps = R.header_capsules(true)
        table.insert(caps, 1, {icon = icon, value = tostring(R.g.moves)})
        R.town:header(caps, header)
    end
end

return game
