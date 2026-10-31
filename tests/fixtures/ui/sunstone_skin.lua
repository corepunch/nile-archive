-- A warm stone skin: rounded parchment, sandstone buttons, a ticked checkbox.
return ui.skin{
    fonts = {display = "fonts/LilitaOne-Regular.ttf"},
    colors = {
        ink = "#47341E", parchment = "#FFF0C0", sand = "#EBCB84", sand_low = "#DDB66A",
        sand_hot = "#FFE3A1", rim = "#BB9555", amber = "#D6AC62", rust = "#AC713A",
    },
    text = {
        body = {font = "display", em = 23, fill = "ink"},
        muted = {extends = "body", fill = "#47341E80"},
        title = {font = "display", em = 31, fill = "#8B572C"},
        button = {font = "display", em = 24, fill = "ink"},
    },
    roles = {title = {text = "title"}},
    controls = {
        panel = {normal = {layers = {
            {shadow = "#00000060", radius = 22, blur = 18, offset = {0, 8}},
            {fill = "parchment", radius = 20},
            {border = "rim", width = 1.5, radius = 20, inset = 1},
        }}},
        button = {
            text = "button",
            normal = {layers = {
                {shadow = "#00000040", radius = 20, blur = 8, offset = {0, 3}, fixed = true},
                {name = "body", fill = "sand", fill2 = "sand_low", radius = 20},
                {name = "rim", border = "rim", width = 1.5, radius = 20},
            }},
            hover = {set = {body = {fill = "sand_hot"}}},
            pressed = {offset = {0, 2}, set = {body = {fill = "sand_low", fill2 = "sand_low"}}},
            selected = {set = {rim = {border = "rust", width = 3}}},
            disabled = {text = "muted", set = {body = {fill = "#EBCB8480", fill2 = "#DDB66A80"}, rim = {border = "#BB955580"}}},
            variants = {accent = {normal = {set = {body = {fill = "amber", fill2 = "#C38F45"}}}}},
        },
        toggle = {extends = "button"},
        checkbox = {
            size = 30, gap = 12, text = "body",
            box = {
                normal = {layers = {
                    {name = "face", fill = "#FFF8DE", radius = 8},
                    {name = "edge", border = "rim", width = 2, radius = 8},
                }},
                hover = {set = {edge = {border = "rust"}}},
                pressed = {set = {face = {fill = "sand"}}},
                disabled = {set = {face = {fill = "#FFF8DE80"}, edge = {border = "#BB955580"}}},
            },
            mark = {
                normal = {layers = {{name = "tick", check = "rust", width = 3.5}}},
                disabled = {set = {tick = {check = "#AC713A80"}}},
            },
            disabled = {text = "muted"},
        },
        progress = {
            track = {normal = {layers = {{fill = "#E3D2A4", radius = 12}}}},
            fill = {normal = {layers = {{fill = "amber", fill2 = "rust", radius = 12}}}},
        },
        label = {text = "body"},
        focus = {normal = {layers = {{border = "rust", width = 2, radius = 22, inset = -3}}}},
    },
    theme = {dim = "#040F1996", backdrop_blur = 7, radius = 20},
}
