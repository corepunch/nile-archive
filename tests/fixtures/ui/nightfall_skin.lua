-- A night skin: square navy panels, teal buttons, a filled-square checkbox.
return ui.skin{
    fonts = {display = "fonts/LilitaOne-Regular.ttf"},
    colors = {
        ink = "#E6F6F6", navy = "#142D42", edge = "#398B9B", deep = "#234A60",
        hot = "#38738B", teal = "#40BDB6", glow = "#77E2DC",
    },
    text = {
        body = {font = "display", em = 23, fill = "ink"},
        muted = {extends = "body", fill = "#E6F6F670"},
        title = {font = "display", em = 31, fill = "#5DE1DD"},
        button = {font = "display", em = 24, fill = "ink", shadow = "#00000080", shadow_offset = {0, 2}},
    },
    roles = {title = {text = "title"}},
    controls = {
        panel = {normal = {layers = {
            {shadow = "#00000080", radius = 6, blur = 16, offset = {0, 6}},
            {fill = "navy", radius = 4},
            {border = "edge", width = 1.5, radius = 4, inset = 1},
        }}},
        button = {
            text = "button",
            normal = {layers = {
                {name = "body", fill = "deep", radius = 4},
                {name = "rim", border = "edge", width = 1.5, radius = 4},
            }},
            hover = {set = {body = {fill = "hot"}}},
            pressed = {set = {body = {fill = "#1A3848"}}, offset = {0, 1}},
            selected = {set = {rim = {border = "glow", width = 3}}},
            disabled = {text = "muted", set = {body = {fill = "#234A6080"}, rim = {border = "#398B9B60"}}},
            variants = {accent = {normal = {set = {body = {fill = "teal"}}}}},
        },
        toggle = {extends = "button"},
        checkbox = {
            size = 28, gap = 12, text = "body",
            box = {
                normal = {layers = {
                    {name = "face", fill = "deep", radius = 3},
                    {name = "edge", border = "edge", width = 2, radius = 3},
                }},
                hover = {set = {edge = {border = "glow"}}},
                pressed = {set = {face = {fill = "#1A3848"}}},
                disabled = {set = {face = {fill = "#234A6080"}, edge = {border = "#398B9B60"}}},
            },
            mark = {
                normal = {layers = {{name = "dot", fill = "glow", radius = 2, inset = 7}}},
                disabled = {set = {dot = {fill = "#77E2DC60"}}},
            },
            disabled = {text = "muted"},
        },
        progress = {
            track = {normal = {layers = {{fill = "#0E2233", radius = 2}, {border = "edge", width = 1, radius = 2}}}},
            fill = {normal = {layers = {{fill = "teal", fill2 = "#2A8F8A", radius = 2}}}},
        },
        label = {text = "body"},
        focus = {normal = {layers = {{border = "glow", width = 2, radius = 6, inset = -3}}}},
    },
    theme = {dim = "#040F1996", backdrop_blur = 7, radius = 4},
}
