-- skin.lua — Relic Rush's look as data: fonts, text styles and, for every
-- control, what each interaction state draws. The engine (ui.skin) turns this
-- into the paint for forms, dialogs and the game's own buttons and panels;
-- layout, hit testing and focus stay in the engine.
--
-- Colours are "#RRGGBB" or "#RRGGBBAA". Text lengths (outline, shadow) are at
-- the style's `em` and scale with the size a control asks for. Layer boxes take
-- `inset` (number or {left, top, right, bottom}), `offset` {x, y} and
-- `height_ratio` (the top fraction, taken before the inset); a state's
-- `offset` moves every layer that isn't `fixed`.
return ui.skin{
    fonts = {
        -- Lilita One measures ascent to descent: 1.17 of its em.
        lilita = {path = "fonts/LilitaOne-Regular.ttf", scale = 1.171875},
    },

    colors = {
        ink = "#3E311D",
        ink_shadow = "#1F2318B8",
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
        -- Parchment in a dark wooden rim, on a soft jade shadow.
        panel = {
            normal = {layers = {
                {fill = "#091C1A91", radius = 18, offset = {0, 6}},
                {fill = "#664427", radius = 18},
                {fill = "#EFCC87", radius = 16, inset = 2},
                {fill = "#FFEFBC", radius = 13, inset = 5},
            }},
            -- A recessed well that groups related settings inside a dialog.
            variants = {group = {normal = {layers = {
                {fill = "#E8CC8E", fill2 = "#F6E2B0", radius = 14},
                {border = "#C9A464", width = 1.5, radius = 14},
            }}}},
        },

        -- A green jade button with a gloss; pressing sinks it onto its shadow.
        -- Disabled drains the colour from the same layers. Hover and selected
        -- look like normal: touch has no hover, and toggles name their state.
        button = {
            text = "cream", em = 25, text_inset = 8,
            normal = {layers = {
                {name = "shadow", fill = "#0D362B", radius = 15, offset = {0, 6}, fixed = true},
                {name = "body", fill = "#2E7046", radius = 15},
                {name = "face", fill = "#71B953", radius = 12, inset = {3, 3, 3, 4}},
                {name = "gloss", fill = "#9FD56D", radius = 10, height_ratio = .4, inset = {6, 4, 6, -4}},
            }},
            pressed = {offset = {0, 2}},
            disabled = {set = {body = {fill = "#4B5E50"}, face = {fill = "#6E7E6C"}, gloss = {fill = "#82917D"}}},
            variants = {
                flat = {normal = {layers = {}}},   -- a text-only action, such as CLOSE
                -- Secondary actions (Restart, Quit) in carved wood, beside the jade primary.
                secondary = {normal = {set = {shadow = {fill = "#4A2C12"}, body = {fill = "#7A4C22"},
                                              face = {fill = "#B98446"}, gloss = {fill = "#D9A865"}}}},
                link = {text = "gold", normal = {layers = {}}},   -- a text link, such as the guide
            },
        },
        toggle = {extends = "button"},

        -- A wooden-rimmed well that fills with jade and a cream tick when checked.
        -- Pressing sinks box and tick 2 units; disabled greys the rim and fill.
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
                    {name = "face", fill = "#71B953", fill2 = "#4E9A3E", radius = 8, inset = 3},
                    {name = "gloss", fill = "#9FD56D", radius = 6, height_ratio = .42, inset = {6, 5, 6, -5}},
                    {name = "tick_rim", check = "#1F4A2A", width = 7.5, inset = 3},
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
