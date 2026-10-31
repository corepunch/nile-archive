-- archive_skin.lua — Nile Archive's look as data: June's Journey's UI in the
-- archive's colours. Fonts, every text style, the native theme, the bevelled
-- gold frame (teal or parchment) and the glossy pill buttons. The engine
-- (ui.skin) paints them; archive_kit.lua keeps the drawn icons and ornaments.
--
-- Colours are "#RRGGBB" or "#RRGGBBAA". Frame and pill layers follow the radius
-- the caller asks for (`radius_delta`, `radius_scale`); `radius` is the default.
local hex = color.hex
local GOLD_HI, GOLD, GOLD_SEAM = hex(0xF8E3A3), hex(0xDDB362), hex(0x5E3F14)

-- Four gold studs at the corners of a frame's filigree line, on large frames only.
local function studs(line)
    if line.w <= 96 or line.h <= 66 then return end
    for _, a in ipairs({vec2(0, 0), vec2(1, 0), vec2(0, 1), vec2(1, 1)}) do
        local p, r = line:point(a), 5
        gfx.ngon(p, r + 1.5, 4, 0, GOLD_SEAM)
        gfx.ngon(p, r, 4, 0, GOLD)
        gfx.ngon(p - vec2(0, r * .25), r * .45, 4, 0, GOLD_HI)
    end
end

-- A glossy pill: shadow, a darker lip below, the gradient body and a gloss.
-- Pressing sinks it 3 units onto its lip and drops the shadow.
local function pill(hi, lo, lip, hot, text)
    return {
        normal = {set = {lip = {fill = lip}, rim = {fill = lip}, body = {fill = hi, fill2 = lo}}},
        hover = {set = {body = {fill = hot}}},
        text = text,
    }
end

return ui.skin{
    fonts = {
        serif = {path = "fonts/Philosopher-Bold.ttf", fallback = "sans_bold"},
        sans = "fonts/PT_Sans-Web-Regular.ttf",
        sans_bold = "fonts/PT_Sans-Web-Bold.ttf",
    },

    colors = {
        white = "#FFFFFF", cream = "#F4E8CA", ink = "#0B2426", ink_brown = "#3A2914", ink_soft = "#6B5435",
        gold_hi = "#F8E3A3", gold = "#DDB362", gold_lo = "#93682A", gold_seam = "#5E3F14",
        teal_hi = "#22545C", teal_lo = "#0F2E36", parch_hi = "#FCF3DD", parch_lo = "#EBD6A8",
    },

    -- Sizes are pixels. Styles that the build tray resizes keep their shadow
    -- lengths (`scale_lengths = false`), as the art was tuned.
    text = {
        body = {font = "sans", em = 17, fill = "cream", shadow = "#0000005A", shadow_offset = {0, 1}, shadow_blur = 1, scale_lengths = false},
        eyebrow = {font = "sans_bold", em = 12, fill = "#E9D7A8", tracking = 1.6, shadow = "#00000078", shadow_offset = {0, 1}, shadow_blur = 1},
        number = {font = "sans_bold", em = 20, fill = "cream", outline = "ink", outline_width = 1},
        tiny = {font = "sans_bold", em = 11, fill = "white", outline = "#0A2832DC", outline_width = 1},
        name = {font = "serif", em = 20, fill = "cream", outline = "ink", outline_width = 1.2},
        badge = {font = "sans_bold", em = 16, fill = "white", outline = "#6B4410", outline_width = 1.6},
        caption = {font = "sans_bold", em = 13, fill = "cream"},
        button = {font = "sans_bold", em = 21, fill = "white", shadow = "#00000050", shadow_offset = {0, 2}, shadow_blur = 1, scale_lengths = false},
        ribbon = {font = "serif", em = 26, fill = "#FFF6DC", fill2 = "#F5D58E", outline = "#5A150F", outline_width = 1.6,
                  shadow = "#00000078", shadow_offset = {0, 2}, shadow_blur = 2},
        score = {font = "serif", em = 30, fill = "#FFF3D1", fill2 = "#E2B46A", outline = "ink", outline_width = 1.4,
                 shadow = "#0000008C", shadow_offset = {0, 2}, shadow_blur = 3},
        card_title = {font = "serif", em = 18, fill = "ink_brown"},
        reward = {font = "serif", em = 28, fill = "ink_brown"},
        ink_body = {font = "sans", em = 17, fill = "ink_brown"},
        ink_small = {font = "sans", em = 14, fill = "ink_soft"},
        goal_eyebrow = {font = "sans_bold", em = 11, fill = "#8A5A22", tracking = 1.4},
        goal_title = {font = "serif", em = 20, fill = "ink_brown"},
        pill_text = {font = "sans_bold", em = 30, fill = "white", outline = "#28180AE6", outline_width = 2,
                     shadow = "#00000078", shadow_offset = {0, 2}, shadow_blur = 2},
        bonus = {font = "sans_bold", em = 22, fill = "white", outline = "#0A3246DC", outline_width = 1.6},
        multiplier = {font = "serif", em = 24, fill = "#F6C24A", fill2 = "#B8761C", outline = "#5A3608", outline_width = 1.2},
        float = {font = "serif", em = 26, fill = "#FFF6DC", fill2 = "#F5C860", outline = "#4A2A08", outline_width = 1.6},
        float_miss = {font = "serif", em = 22, fill = "#FF8A70", outline = "#3A0E08", outline_width = 1.4},
        -- Pill captions take the pill's lip colour as a 2-pixel rim.
        pill_green = {extends = "button", outline = "#2A6A1E", outline_width = 2},
        pill_blue = {extends = "button", outline = "#184A5B", outline_width = 2},
        pill_red = {extends = "button", outline = "#6E2017", outline_width = 2},
        pill_off = {extends = "button", outline = "#3B4443", outline_width = 2},
        -- The native theme's typography (move strip, toasts).
        theme_title = {font = "serif", em = 30, fill = "#FFF3D1", fill2 = "#E2B46A", outline = "ink", outline_width = 1.4,
                       shadow = "#0000008C", shadow_offset = {0, 3}, shadow_blur = 4},
        theme_button = {font = "sans_bold", em = 21, fill = "#FFF6DC", fill2 = "#F5D58E", outline = "ink", outline_width = 1,
                        shadow = "#00000078", shadow_offset = {0, 1}, shadow_blur = 1},
        theme_accent = {font = "sans_bold", em = 21, fill = "#203C36", fill2 = "ink", shadow = "#FFF6DC96", shadow_offset = {0, 1}, shadow_blur = 0},
    },

    -- Build-tray typography: the budget line, the category name, card titles.
    roles = {budget = {text = "body", em = 17}, category = {text = "button", em = 17}},

    controls = {
        -- A teal (or parchment) panel inside a bevelled gold rim, with a
        -- filigree line and corner studs. Callers pass the corner radius.
        panel = {
            normal = {layers = {
                {shadow = "#00000082", radius = 22, radius_delta = 2, blur = 28, offset = {0, 10}},
                {fill = "gold_hi", fill2 = "gold_lo", radius = 20, radius_delta = 0},
                {fill = "gold_seam", radius = 17, radius_delta = -3, inset = 3},
                {name = "inner", fill = "teal_hi", fill2 = "teal_lo", radius = 15, radius_delta = -5, inset = 5},
                {name = "line", border = "#E9C77B69", width = 1.2, radius = 10, radius_delta = -10, radius_min = 4, inset = 12},
                {paint = studs, inset = 12},
            }},
            variants = {parchment = {normal = {set = {inner = {fill = "parch_hi", fill2 = "parch_lo"}, line = {border = "#B0843C96"}}}}},
        },

        -- Glossy pills in green (default), blue and red; a disabled pill turns grey.
        pill = {
            text = "pill_green", text_inset = {14, 4}, text_fit = true, text_align = {.5, .52},
            normal = {layers = {
                {name = "shadow", shadow = "#00000064", radius = 18, radius_delta = 2, blur = 10, offset = {0, 6}, fixed = true},
                {name = "lip", fill = "#2A6A1E", radius = 18, radius_delta = 2, inset = -2, offset = {0, 4}, fixed = true},
                {name = "rim", fill = "#2A6A1E", radius = 18, radius_delta = 2, inset = -2},
                {name = "body", fill = "#A8E46C", fill2 = "#4AA536", radius = 16, radius_delta = 0},
                {name = "gloss", fill = "#FFFFFF3C", radius = 11.2, radius_scale = .7, height_ratio = .4, inset = {7, 3, 7, -3}},
            }},
            hover = {set = {body = {fill = "#B2F172"}}},
            pressed = {offset = {0, 3}, set = {shadow = {hidden = true}}},
            disabled = {text = "pill_off", set = {lip = {fill = "#3B4443"}, rim = {fill = "#3B4443"}, body = {fill = "#9AA3A0", fill2 = "#66706E"}}},
            variants = {
                blue = pill("#67C0D6", "#2D7E97", "#184A5B", "#6DCBE2", "pill_blue"),
                red = pill("#E57A5E", "#B13F2C", "#6E2017", "#F28163", "pill_red"),
            },
        },

        -- A gold-rimmed teal well that shows a cream tick when checked, like a
        -- small frame. Hover brightens the rim, pressing sinks it, disabled greys it.
        checkbox = {
            size = 34, gap = 14, text = "body", em = 19,
            box = {
                normal = {layers = {
                    {name = "shadow", shadow = "#00000064", radius = 10, blur = 8, offset = {0, 3}, fixed = true},
                    {name = "rim", fill = "gold_hi", fill2 = "gold_lo", radius = 9},
                    {name = "seam", fill = "gold_seam", radius = 7, inset = 2},
                    {name = "well", fill = "teal_lo", fill2 = "teal_hi", radius = 6, inset = 3},
                }},
                hover = {set = {rim = {fill = "#FFF1C4"}}},
                pressed = {offset = {0, 2}},
                disabled = {set = {rim = {fill = "#9AA3A0", fill2 = "#66706E"}, well = {fill = "#2B3A3A", fill2 = "#3B4443"}}},
            },
            mark = {
                normal = {layers = {
                    {name = "tick_rim", check = "ink", width = 6.5, inset = 3},
                    {name = "tick", check = "#FFF6DC", width = 3.8, inset = 3},
                }},
                pressed = {offset = {0, 2}},
                disabled = {set = {tick = {check = "#C9C2B2"}}},
            },
        },

        -- Form text: the build tray's cards and buttons (native button paint).
        label = {text = "card_title", em = 17},
        button = {text = "button", em = 17},
    },

    theme = {
        text = "body", small = "eyebrow", title = "theme_title", button = "theme_button", accent_text = "theme_accent",
        panel = "#1D4442", panel2 = "#183A39", border = "#A7AD755A",
        button_bg = "#2A524F", button_bg2 = "#1F4442", button_hot = "#38615B", button_border = "#BFA66B6E",
        accent = "#F0CF8E", accent2 = "#D8AE66", active = "#E4C080",
        dim = "#06161AC8", toast_bg = "#F6E7C1", toast_text = "ink_brown", radius = 10,
    },
}
