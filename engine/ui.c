/* ui.c — immediate-mode widgets, input blocking, toasts and modal backdrops.
 *
 * Widgets are plain function calls made while drawing: `if (ui_button(r, "Play", 0))`.
 * Every widget registers its rect; presses that start on last frame's UI rects
 * are marked `captured` so the world (camera, board, city) ignores them. */
#include "engine.h"

#include <stdio.h>
#include <string.h>

#define MAX_BLOCKS 256

static struct {
    const ui_theme *theme;
    rect blocks[2][MAX_BLOCKS];   /* double buffered so a frame can read while the next one writes */
    int block_count[2];
    int cur;
    bool disabled;
    char toast[160];
    float toast_time;
} U;

static const ui_theme fallback_theme = {
    .panel = {28, 65, 64, 245}, .panel2 = {22, 52, 52, 245}, .border = {191, 166, 107, 110},
    .button_bg = {44, 86, 82, 255}, .button_bg2 = {33, 68, 66, 255}, .button_hot = {60, 104, 96, 255},
    .button_border = {191, 166, 107, 120}, .accent = {242, 210, 140, 255}, .accent2 = {214, 170, 92, 255},
    .active = {228, 192, 128, 255}, .dim = {6, 28, 33, 200}, .toast_bg = {240, 212, 157, 250},
    .toast_text = {32, 60, 54, 255}, .radius = 12,
};

void ui_set_theme(const ui_theme *t) { U.theme = t; }
const ui_theme *ui_theme_get(void) { return U.theme ? U.theme : &fallback_theme; }
void ui_set_enabled(bool enabled) { U.disabled = !enabled; }

void ui_block(rect r)
{
    int n = U.block_count[U.cur];
    if (n < MAX_BLOCKS) U.blocks[U.cur][n] = r, U.block_count[U.cur] = n + 1;
}

/* True if p is on UI registered this frame so far or in the previous frame.
 * Presses are checked while polling events, before the next frame begins. */
bool ui_blocks(vec2 p)
{
    for (int b = 0; b < 2; b++)
        for (int i = 0; i < U.block_count[b]; i++)
            if (rect_contains(U.blocks[b][i], p)) return true;
    return false;
}

void ui_begin_frame(void)
{
    U.cur ^= 1;
    U.block_count[U.cur] = 0;
    U.disabled = false;
}

ui_state ui_hit(rect r, int flags)
{
    ui_block(r);
    ui_state st = {0};
    if (U.disabled || (flags & UI_DISABLED)) return st;
    input in = input_get();
    bool over = rect_contains(r, in.pos), began = rect_contains(r, in.press_pos);
    st.hot = over && (in.hover || in.down);
    st.held = in.down && over && began && !in.dragging;
    st.clicked = in.released && over && began && !in.dragging;
    return st;
}

void ui_panel_ex(rect r, color top, color bottom, color border, float radius)
{
    ui_block(r);
    draw_shadow(rect_offset(r, v2(0, 6)), radius + 6, 18, rgba(0, 0, 0, 70));
    draw_round_rect_grad(r, radius, top, bottom);
    if (border.a) draw_round_rect_line(rect_inflate(r, -.75f), radius, 1.5f, border);
}

void ui_panel(rect r)
{
    const ui_theme *t = ui_theme_get();
    ui_panel_ex(r, t->panel, t->panel2, t->border, t->radius);
}

ui_state ui_button_frame(rect r, int flags)
{
    const ui_theme *t = ui_theme_get();
    ui_state st = ui_hit(r, flags);
    if (flags & UI_FLAT) return st;
    bool accent = flags & UI_ACCENT;
    float a = (flags & UI_DISABLED) ? .45f : 1;
    rect body = st.held ? rect_inflate(r, -2) : r;
    color top = accent ? t->accent : (st.hot ? t->button_hot : t->button_bg);
    color bottom = accent ? t->accent2 : t->button_bg2;
    if (accent && st.hot) top = color_shade(top, 1.08f), bottom = color_shade(bottom, 1.08f);
    if (!st.held) draw_shadow(rect_offset(body, v2(0, 3)), t->radius + 3, 8, rgba(0, 0, 0, (int)(60 * a)));
    draw_round_rect_grad(body, t->radius, color_alpha(top, a), color_alpha(bottom, a));
    /* a soft highlight across the top half gives the button some volume */
    draw_round_rect_grad(rect_inflate2(rect_top(body, body.size.h * .5f), v2(-3, -2)), t->radius * .7f,
                         rgba(255, 255, 255, (int)(accent ? 70 * a : 22 * a)), rgba(255, 255, 255, 0));
    draw_round_rect_line(body, t->radius, 1.5f, color_alpha(accent ? color_shade(t->accent2, .7f) : t->button_border, a));
    if (flags & UI_ACTIVE) draw_round_rect_line(rect_inflate(body, 2.5f), t->radius + 2, 3, t->active);
    return st;
}

bool ui_button(rect r, const char *label, int flags)
{
    const ui_theme *t = ui_theme_get();
    ui_state st = ui_button_frame(r, flags);
    text_style s = (flags & UI_ACCENT) ? t->accent_text : t->button;
    if (flags & UI_DISABLED) s.fade = maxf(s.fade, .45f);
    rect inner = rect_inflate2(st.held ? rect_inflate(r, -2) : r, v2(-10, -4));
    text_fit(s, inner, v2(.5f, .5f), label);
    return st.clicked;
}

void ui_label(rect r, text_style s, vec2 align, const char *utf8) { text_box(s, r, align, utf8); }

void ui_toast(const char *utf8)
{
    snprintf(U.toast, sizeof U.toast, "%s", utf8);
    U.toast_time = 2.8f;
}

void ui_modal_backdrop(float t)
{
    const ui_theme *th = ui_theme_get();
    rect s = app_screen();
    draw_rect(s, color_alpha(th->dim, saturate(t)));
    ui_block(s);
}

void ui_end_frame(float dt)
{
    if (U.toast_time > 0) {
        const ui_theme *t = ui_theme_get();
        U.toast_time -= dt;
        float a = saturate(U.toast_time * 3) * saturate((2.8f - U.toast_time) * 6);
        text_style s = ts_fill(t->text, t->toast_text);
        s.shadow = CLEAR;
        s.outline = CLEAR;
        rect screen = app_screen();
        size2 m = text_measure(s, U.toast);
        float w = minf(m.w + 48, screen.size.w * .85f);
        rect box = rect_anchor(v2(rect_center(screen).x, rect_max(screen).y - 28 + (1 - a) * 20), sz2(w, s.size + 30), v2(.5f, 1));
        draw_shadow(rect_offset(box, v2(0, 8)), 16, 24, color_alpha(rgba(0, 0, 0, 110), a));
        draw_round_rect(box, 14, color_alpha(t->toast_bg, a));
        text_fit(ts_fade(s, 1 - a), rect_inflate(box, -16), v2(.5f, .5f), U.toast);
    }
    U.disabled = false;
}
