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
