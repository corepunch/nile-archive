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
        panel = {normal = {layers = {
            {fill = "#091C1A91", radius = 18, offset = {0, 6}},
            {fill = "#664427", radius = 18},
            {fill = "#EFCC87", radius = 16, inset = 2},
            {fill = "#FFEFBC", radius = 13, inset = 5},
        }}},

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
            variants = {flat = {normal = {layers = {}}}},   -- a text-only action, such as CLOSE
        },
        toggle = {extends = "button"},

        label = {text = "gold", em = 26, wrap_text = "cream", wrap_em = 22},

        focus = {normal = {layers = {{border = "#FFDF81", width = 2, radius = 15, inset = -3}}}},
    },
}
