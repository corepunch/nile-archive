-- skin.lua — Christmas Market's look as data: fonts, text styles and, for every
-- control, what each interaction state draws. The engine (ui.skin) turns this
-- into the paint for forms, dialogs and the game's own buttons and panels;
-- layout, hit testing and focus stay in the engine.
--
-- Colours are "#RRGGBB" or "#RRGGBBAA". Text lengths (outline, shadow) are at
-- the style's `em` and scale with the size a control asks for. Layer boxes take
-- `height_ratio` (the top fraction, taken before the inset), then `inset`
-- (number or {left, top, right, bottom}) and `offset` {x, y}; a state's
-- `offset` moves every layer that isn't `fixed`.
-- Market navigation badges: a gold-rimmed evergreen (Build) or ribbon-red
-- (Play) tile, drawn as layers until an authored festive atlas replaces them
-- (see docs/asset-catalogue.md#market-navigation). Pressing sinks the badge;
-- disabled drains its colour.
local function badge(face, face2, icon)
    return {
        normal = {layers = {
            {name = "shadow", fill = "#0A1E1B99", radius = 30, inset = {8, 12, 8, 2}, offset = {0, 6}, fixed = true},
            {name = "rim", fill = "#8A5A24", radius = 30, inset = {8, 10, 8, 4}},
            {name = "gold", fill = "#FFE7A3", fill2 = "#C98A33", radius = 28, inset = {10, 12, 10, 6}},
            {name = "face", fill = face, fill2 = face2, radius = 23, inset = {16, 18, 16, 12}},
            {name = "gloss", fill = "#FFFFFF30", radius = 20, height_ratio = .42, inset = {20, 21, 20, -2}},
            {inset = {16, 18, 16, 12}, paint = icon},
        }},
        hover = {},
        selected = {},
        pressed = {offset = {0, 3}},
        disabled = {set = {gold = {fill = "#D8D2C2", fill2 = "#8F8A7E"}, face = {fill = "#7C847C", fill2 = "#5B625B"}}},
    }
end
local function build_icon(box, _, st)
    local R = require("state")
    local w = R.buildings and R.buildings[3]
    if w and w.sprite then
        gfx.image(w.sprite, box:inflate(-4):fit(texture.size(w.sprite)), color(255, 255, 255, st and st.disabled and 140 or 255))
    end
end
local function play_icon(box, _, st)
    local c, r = box:center() + vec2(4, 0), box.h * .3
    local pts = {c + vec2(-r * .75, -r), c + vec2(r, 0), c + vec2(-r * .75, r)}
    local shade, cream = color(74, 18, 24, 150), st and st.disabled and color(220, 216, 206) or color(255, 249, 226)
    gfx.poly({pts[1] + vec2(0, 3), pts[2] + vec2(0, 3), pts[3] + vec2(0, 3)}, shade)
    gfx.poly(pts, cream)
end

return ui.skin{
    fonts = {
        -- Lilita One measures ascent to descent: 1.17 of its em.
        lilita = {path = "fonts/LilitaOne-Regular.ttf", scale = 1.171875},
    },

    colors = {
        ink = "#3E311D",
        ink_shadow = "#1F2318B8",
        moves_face = "#164630",
        moves_glow = "#2C7850",
        moves_low = "#80181E",
        moves_low_glow = "#C43434",
    },

    -- Every palette shares a dark rim and a drop shadow cast by the rimmed silhouette.
    text = {
        base = {font = "lilita", em = 64, outline = "ink", outline_width = 4, shadow = "ink_shadow", shadow_offset = {0, 5}},
        gold = {extends = "base", fill = "#FFFFDB", fill2 = "#EFA939"},
        cream = {extends = "base", fill = "#FFF9E2", fill2 = "#F4DDA6"},
        green = {extends = "base", fill = "#C7FFC9", fill2 = "#5BC682"},
        white = {extends = "base", fill = "#FFFFFF", fill2 = "#C4E8DC"},
    },

    controls = {
        -- Warm parchment in a wooden rim, on a soft evergreen shadow.
        panel = {normal = {layers = {
            {fill = "#091C1A91", radius = 18, offset = {0, 6}},
            {fill = "#664427", radius = 18},
            {fill = "#EFCC87", radius = 16, inset = 2},
            {fill = "#FFEFBC", radius = 13, inset = 5},
        }}, variants = {group = {normal = {layers = {
            {fill = "#E8CC8E", fill2 = "#F6E2B0", radius = 14},
            {border = "#C9A464", width = 1.5, radius = 14},
        }}}}},

        -- A slim pill holding one figure; the icon overhangs its left end.
        resource = {
            text = "cream", em = 18,
            normal = {layers = {
                {shadow = "#00000050", radius_scale = 1, blur = 5, offset = {0, 2}, fixed = true},
                {fill = "#0D2F29E1", radius_scale = 1},
                {border = "#E9C77BBE", width = 1.4, radius_scale = 1},
            }},
            pressed = {offset = {0, 1}},
            variants = {
                goal = {icon_overhang = .24},
                wallet = {em = 18, icon_ratio = 60 / 36, icon_overhang = .5},
            },
        },

        -- A festive red button with a gloss on an evergreen shadow; pressing
        -- sinks it onto the shadow, disabled drains the colour from the same
        -- layers. Hover and selected look like normal: touch has no hover.
        button = {
            text = "cream", em = 25, text_inset = 8,
            normal = {layers = {
                {name = "shadow", fill = "#0D362B", radius = 15, offset = {0, 6}, fixed = true},
                {name = "body", fill = "#85232E", radius = 15},
                {name = "face", fill = "#B84041", radius = 12, inset = {3, 3, 3, 4}},
                {name = "gloss", fill = "#D3665B", radius = 10, height_ratio = .4, inset = {6, 4, 6, -4}},
            }},
            pressed = {offset = {0, 2}},
            disabled = {set = {body = {fill = "#4B5E50"}, face = {fill = "#6E7E6C"}, gloss = {fill = "#82917D"}}},
            variants = {
                flat = {normal = {layers = {}}},
                link = {text = "gold", normal = {layers = {}}},
                navigation_build = badge("#2C7850", "#164630", build_icon),
                navigation_play = badge("#D3584E", "#85232E", play_icon),
                -- Confirm and cancel a placement beside the lifted building.
                placement_confirm = {normal = {layers = {
                    {fill = "#0D362B", radius = 28, offset = {0, 4}, fixed = true},
                    {fill = "#1E5A3C", radius = 28},
                    {fill = "#3F9A5C", radius = 25, inset = 3},
                    {check = "#FFF9E2", width = 5, inset = 10},
                }}, disabled = {alpha = .45}},
                placement_cancel = {normal = {layers = {
                    {fill = "#4A2C12", radius = 28, offset = {0, 4}, fixed = true},
                    {fill = "#85232E", radius = 28},
                    {fill = "#B84041", radius = 25, inset = 3},
                    {inset = 18, paint = function(box)
                        gfx.line(box:point(vec2(0, 0)), box:point(vec2(1, 1)), 5, color(255, 249, 226))
                        gfx.line(box:point(vec2(1, 0)), box:point(vec2(0, 1)), 5, color(255, 249, 226))
                    end},
                }}},
            },
        },
        toggle = {extends = "button"},

        checkbox = {
            size = 40, gap = 16, text = "cream", em = 25,
            box = {
                normal = {layers = {
                    {name = "shadow", fill = "#0D362B", radius = 11, offset = {0, 5}, fixed = true},
                    {name = "rim", fill = "#664427", radius = 11},
                    {name = "well", fill = "#E6CB8C", fill2 = "#FFF3CC", radius = 8, inset = 3},
                }},
                pressed = {offset = {0, 2}},
                disabled = {set = {rim = {fill = "#6E655A"}, well = {fill = "#C9C2B2", fill2 = "#DDD8CC"}}},
            },
            mark = {
                normal = {layers = {
                    {name = "face", fill = "#B84041", fill2 = "#85232E", radius = 8, inset = 3},
                    {name = "gloss", fill = "#D3665B", radius = 6, height_ratio = .42, inset = {6, 5, 6, -5}},
                    {name = "tick_rim", check = "#641D29", width = 7.5, inset = 3},
                    {name = "tick", check = "#FFF9E2", width = 4.5, inset = 3},
                }},
                pressed = {offset = {0, 2}},
                disabled = {set = {face = {fill = "#8E9A88", fill2 = "#76806F"}, gloss = {fill = "#A9B3A2"}}},
            },
        },

        label = {text = "gold", em = 26, wrap_text = "cream", wrap_em = 22},

        focus = {normal = {layers = {{border = "#FFDF81", width = 2, radius = 15, inset = -3}}}},
    },
}
