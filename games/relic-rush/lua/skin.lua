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
local buttons = require("match3.buttons")
local resource_fill = color(13, 47, 41, 0xD7)

local rgb = color.hex
local close_faces = {
    normal   = {top=rgb(0xE65843), bottom=rgb(0xA52D24)},
    hover    = {top=rgb(0xF67856), bottom=rgb(0xC43B2C)},
    selected = {top=rgb(0xF36B49), bottom=rgb(0xB13224)},
    pressed  = {top=rgb(0x982D25), bottom=rgb(0xC54936)},
}


return ui.skin{
    fonts = {
        -- Lilita One measures ascent to descent: 1.17 of its em.
        lilita = {path = "common/fonts/LilitaOne-Regular.ttf", scale = 1.171875},
    },

    colors = {
        ink = "#3E311D",
        ink_shadow = "#1F2318B8",
        moves_face = "#0C3E34",
        moves_glow = "#247C60",
        moves_low = "#702218",
        moves_low_glow = "#B24028",
        board_face = "#C3A87D",
        bubble_face = "#102D26F0",
        bubble_edge = "#D7BB76AA",
    },

    -- Every palette shares a dark rim and a drop shadow cast by the rimmed silhouette.
    text = {
        base = {font = "lilita", em = 64, outline = "ink", outline_width = 4, shadow = "ink_shadow", shadow_offset = {0, 5}},
        gold = {extends = "base", fill = "#FFFFDB", fill2 = "#EFA939"},
        cream = {extends = "base", fill = "#FFF9E2", fill2 = "#F4DDA6"},
        menu_title = {extends = "gold", outline = "#362716", outline_width = 4, shadow = "#06231DDD", shadow_offset = {0, 7}},
        menu_subtitle = {extends = "cream", tracking = 8, shadow = "#06231DDD"},
        green = {extends = "base", fill = "#C7FFC9", fill2 = "#5BC682"},
        white = {extends = "base", fill = "#FFFFFF", fill2 = "#C4E8DC"},
        price_short = {font = "lilita", em = 64, fill = "#B42A21"},   -- a shop price the wallet cannot cover
        short = {extends = "base", fill = "#FFD9CC", fill2 = "#F0705A"},   -- a price the wallet cannot cover
        -- Running copy on parchment is flat ink. The rim, gradient and shadow
        -- above are for titles, buttons and figures.
        body = {font = "lilita", em = 64, fill = "#5A4226"},
        caption = {font = "lilita", em = 64, fill = "#9A7A48", tracking = 2},
        -- A popup's title is written on its parchment, not on a plate.
        popup_title = {extends = "body"},
        popup_subtitle = {extends = "caption"},
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
            variants = {
                epoch_medal = buttons.epoch_medal(),
                -- The rule under a popup's title: a thin line threaded through a diamond.
                popup_rule = {normal = {layers = {
                    {fill = "#C9A464", radius = 1, inset = {0, 6, 0, 6}},
                    {paint = function(_, _, _, _, out, alpha)
                        gfx.ngon(out:center(), out.h * .5, 4, 0, color.alpha(color.hex(0xC9A464), alpha))
                    end},
                }}},
                -- A gathered amount: the met-goal tick (Skin:paint_tick).
                -- A quest row's number: a gold coin in a dark rim.
                quest_number = {normal = {layers = {
                    {fill = "#00000055", radius = 13, offset = {0, 2}},
                    {fill = "#5A3A16", radius = 13},
                    {fill = "#FFE08A", fill2 = "#D9962A", radius = 11, inset = 2},
                }}},
                done_tick = {normal = {layers = {
                    {paint = function(box, _, _, skin) skin:paint_tick(box) end},
                }}},
                -- A recessed well that groups related settings inside a dialog.
                group = {normal = {layers = {
                {fill = "#E8CC8E", fill2 = "#F6E2B0", radius = 14},
                {border = "#C9A464", width = 1.5, radius = 14},
            }}}},
        },

        -- A pale inset card: one banked resource on the results dialog.
        border = {variants = {
            -- The town's quest tracker: a soft dark glass behind its rows.
            quest_tracker = {normal = {layers = {
                {fill = "#0B1E2AB4", fill2 = "#0B1E2A60", radius = 14},
            }}},
            resource_indicator = {normal = {layers = {
            {fill = "#F1DA9D", radius = 12},
            {fill = "#FFF2C9", radius = 10, inset = 2},
        }}}}},

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
                popup_close = buttons.navigation("close", nil, close_faces),
                navigation_build=buttons.navigation("build"),
                navigation_play = buttons.project_play(),
                navigation_pause = buttons.navigation("pause"),
                flat = {normal = {layers = {}}},   -- a text-only action, such as CLOSE
                -- Secondary actions (Restart, Quit) in carved wood, beside the jade primary.
                secondary = {normal = {set = {shadow = {fill = "#4A2C12"}, body = {fill = "#7A4C22"},
                                              face = {fill = "#B98446"}, gloss = {fill = "#D9A865"}}}},
                link = {text = "gold", normal = {layers = {}}},   -- a text link, such as the guide
                placement_confirm = {normal = {layers = {
                    {fill="#0D362B",radius=28,offset={0,4},fixed=true},
                    {fill="#2E7046",radius=28},
                    {fill="#71B953",radius=25,inset=3},
                    {check="#FFF9E2",width=5,inset=10},
                }}, disabled={alpha=.45}},
                placement_cancel = {normal = {layers = {
                    {fill="#4A2C12",radius=28,offset={0,4},fixed=true},
                    {fill="#8B352C",radius=28},
                    {fill="#CC6250",radius=25,inset=3},
                    {inset=18,paint=function(box, _, _, _skin)
                        gfx.line(box:point(vec2(0,0)),box:point(vec2(1,1)),5,color(255,249,226))
                        gfx.line(box:point(vec2(1,0)),box:point(vec2(0,1)),5,color(255,249,226))
                    end},
                }}},
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

        -- A slim pill holding one figure; the icon overhangs its left end.
        resource = {
            text = "cream", em = 16,
            normal = {layers = {
                {shadow = "#00000050", radius_scale = 1, blur = 5, offset = {0, 2}, fixed = true},
                {fill = resource_fill, radius_scale = 1},
                {border = "#E9C77BAA", width = 1.4, radius_scale = 1},
            }},
            pressed = {offset = {0, 1}},
            variants = {
                goal = {icon_overhang = .24},
                signboard_goal = {em = 19, icon_overhang = .12, normal = {layers = {}}},
                wallet = {normal = buttons.wallet(resource_fill),
                          em = 16, icon_ratio = 1.71, icon_overhang = .375},
            },
        },

        label = {text = "gold", em = 26, wrap_text = "cream", wrap_em = 22},

        focus = {normal = {layers = {{border = "#FFDF81", width = 2, radius = 15, inset = -3}}}},
    },
}
