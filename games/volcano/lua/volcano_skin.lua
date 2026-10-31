-- volcano_skin.lua — Volcano's look as data: the lettering, the native theme
-- (toasts, modal backdrops) and every control's states. The engine (ui.skin)
-- paints panels, buttons and meters from it; main.lua only places them.
--
-- Colours are "#RRGGBB" or "#RRGGBBAA". Text lengths are at `em` and scale
-- with the size asked for. Layer boxes take `height_ratio` (top fraction),
-- then `inset` and `offset`; a state's `inset` shrinks every non-fixed layer.
return ui.skin{
    fonts = {lilita = "fonts/LilitaOne-Regular.ttf"},

    colors = {
        cream = "#FFF2D2", ink = "#193D43", gold = "#F4CB78", amber = "#D6A050", teal = "#234F55",
        rim = "#3E311D", rim_shadow = "#1F2318B8",
        panel = "#19393EF6", panel_low = "#122B30F8", border = "#E2C99687",
        button = "#346068", button_low = "#23474E", button_hot = "#477A7E", button_border = "#EBD3A482",
    },

    -- Relic Rush's Lilita One palettes, with the rim and cast shadow scaled by
    -- size: at 75 px the rim is 4 and the shadow drops 5.
    text = {
        base = {font = "lilita", em = 75, outline = "rim", outline_width = 4, shadow = "rim_shadow", shadow_offset = {0, 5}},
        cream = {extends = "base", fill = "#FFF9E2", fill2 = "#F4DDA6"},
        gold = {extends = "base", fill = "#FFFFDB", fill2 = "#EFA939"},
        green = {extends = "base", fill = "#C7FFC9", fill2 = "#5BC682"},
        white = {extends = "base", fill = "#FFFFFF", fill2 = "#C4E8DC"},
        cream_off = {extends = "cream", fade = .45},
    },

    controls = {
        -- A deep teal card with a soft drop shadow and a fine gold rim.
        panel = {normal = {layers = {
            {shadow = "#00000046", radius = 19, blur = 18, offset = {0, 6}},
            {fill = "panel", fill2 = "panel_low", radius = 13},
            {border = "border", width = 1.5, radius = 13, inset = .75},
        }}},

        -- Teal buttons with a soft top gloss. Hover lifts the top colour,
        -- pressing sinks the body 2 units and drops its shadow, disabled fades
        -- the whole button. Accent buttons are gold.
        button = {
            text = "cream", em = 25, text_inset = {10, 4}, text_fit = true,
            normal = {layers = {
                {name = "shadow", shadow = "#0000003C", radius = 16, blur = 8, offset = {0, 3}},
                {name = "body", fill = "button", fill2 = "button_low", radius = 13},
                {name = "gloss", fill = "#FFFFFF16", fill2 = "#FFFFFF00", radius = 9.1, height_ratio = .5, inset = {3, 2, 3, 2}},
                {name = "rim", border = "button_border", width = 1.5, radius = 13},
            }},
            hover = {set = {body = {fill = "button_hot"}}},
            pressed = {inset = 2, set = {shadow = {hidden = true}}},
            disabled = {alpha = .45, text = "cream_off"},
            variants = {accent = {
                normal = {set = {body = {fill = "gold", fill2 = "amber"}, gloss = {fill = "#FFFFFF46"}, rim = {border = "#957038"}}},
                hover = {set = {body = {fill = "#FFDB81", fill2 = "#E7AC56"}}},
            }},
        },

        -- A teal box in the buttons' rim that shows a gold tick when checked.
        -- Hover lifts it, pressing sinks box and tick 1 unit, disabled fades it.
        checkbox = {
            size = 36, gap = 14, text = "cream", em = 25,
            box = {
                normal = {layers = {
                    {name = "shadow", shadow = "#0000003C", radius = 11, blur = 6, offset = {0, 3}, fixed = true},
                    {name = "body", fill = "button", fill2 = "button_low", radius = 9},
                    {name = "gloss", fill = "#FFFFFF16", fill2 = "#FFFFFF00", radius = 6, height_ratio = .5, inset = {3, 2, 3, 2}},
                    {name = "rim", border = "button_border", width = 1.5, radius = 9},
                }},
                hover = {set = {body = {fill = "button_hot"}}},
                pressed = {offset = {0, 1}},
                disabled = {alpha = .45},
            },
            mark = {
                normal = {layers = {
                    {name = "tick_rim", check = "ink", width = 7, inset = 2},
                    {name = "tick", check = "gold", width = 4, inset = 2},
                }},
                pressed = {offset = {0, 1}},
                disabled = {alpha = .45},
            },
            disabled = {text = "cream_off"},
        },

        -- Progress meters: a dark track, a gold fill and the panel's rim over both.
        progress = {
            track = {normal = {layers = {{fill = "button_low", radius = 13}}}},
            fill = {normal = {layers = {{fill = "gold", fill2 = "amber", radius = 13}}}},
            over = {normal = {layers = {{border = "border", width = 1, radius = 13}}}},
        },
    },

    -- Native widgets: toasts and the modal backdrop.
    theme = {
        text = {"cream", 24}, small = {"cream", 16}, title = {"gold", 36}, button = {"cream", 25}, accent_text = {"cream", 25},
        panel = "panel", panel2 = "panel_low", border = "border",
        button_bg = "button", button_bg2 = "button_low", button_hot = "button_hot", button_border = "button_border",
        accent = "gold", accent2 = "amber", active = "gold", dim = "#09171CC4", toast_bg = "cream", toast_text = "ink", radius = 13,
    },
}
