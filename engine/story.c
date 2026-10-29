/* story.c — characters, dialogue and speech bubbles.
 *
 * A game registers its cast once, then queues lines: either single lines or
 * named beats that play once per save. The dialogue draws over everything:
 * the speaker's portrait at the side, a speech bubble whose tail points at
 * them, a name tag, and text that types itself out. A tap finishes the line,
 * the next tap moves on. Bubbles are also available on their own, for words
 * floating over the world. */
#include "engine.h"

#include <stdio.h>
#include <string.h>

#define QUEUE 48
#define MAX_SEEN 256
#define TYPE_SPEED 45.0f   /* codepoints per second */

static struct {
    character *cast;
    int count;
    story_style style;
    struct { const character *who; char text[512]; } queue[QUEUE];
    int lines;
    float shown, enter, line_time;
    const character *last;
    int seen[MAX_SEEN];
    int seen_count;
} S;

static int hash(const char *s)
{
    uint32_t h = 2166136261u;   /* FNV-1a */
    for (; *s; s++) h = (h ^ (uint8_t)*s) * 16777619u;
    return (int)(h & 0x7fffffff);
}

void story_setup(character *cast, int count, const story_style *style)
{
    S.cast = cast;
    S.count = count;
    S.style = *style;
    if (S.style.portrait_height <= 0) S.style.portrait_height = .5f;
    if (S.style.bubble.a == 0) S.style.bubble = rgba(255, 248, 230, 250);
    if (S.style.edge.a == 0) S.style.edge = rgba(110, 80, 45, 255);
    for (int i = 0; i < count; i++)
        if (cast[i].portrait_path && !cast[i].portrait.tex) cast[i].portrait = tex_load(cast[i].portrait_path);
}

const character *story_character(const char *id)
{
    for (int i = 0; id && i < S.count; i++)
        if (!strcmp(S.cast[i].id, id)) return &S.cast[i];
    return NULL;
}

void story_say(const char *who, const char *text)
{
    if (S.lines >= QUEUE || !text) return;
    S.queue[S.lines].who = story_character(who);
    snprintf(S.queue[S.lines].text, sizeof S.queue[0].text, "%s", text);
    S.lines++;
}

bool story_seen(const char *beat)
{
    int h = hash(beat);
    for (int i = 0; i < S.seen_count; i++)
        if (S.seen[i] == h) return true;
    return false;
}

bool story_play(const char *beat, const story_line *lines, int count)
{
    if (story_seen(beat)) return false;
    if (S.seen_count < MAX_SEEN) S.seen[S.seen_count++] = hash(beat);
    for (int i = 0; i < count; i++) story_say(lines[i].who, lines[i].text);
    return true;
}

bool story_active(void) { return S.lines > 0; }
void story_forget(void) { S.seen_count = 0; }

void story_serialize(save *s)
{
    save_int(s, "story.seen", &S.seen_count);
    S.seen_count = clampi(S.seen_count, 0, MAX_SEEN);
    save_ints(s, "story.beats", S.seen, S.seen_count);
}

static void next_line(void)
{
    memmove(S.queue, S.queue + 1, sizeof S.queue[0] * (size_t)(S.lines - 1));
    S.lines--;
    S.shown = S.line_time = 0;
}

/* ------------------------------------------------------------------ bubbles */

void speech_bubble_shape(rect box, vec2 tip, color fill, color edge)
{
    float radius = minf(18, box.size.h * .3f);
    draw_shadow(rect_offset(box, v2(0, 5)), radius + 4, 14, rgba(0, 0, 0, 70));
    draw_round_rect(box, radius, fill);
    draw_round_rect_line(box, radius, 2.5f, edge);
    if (rect_contains(box, tip)) return;
    /* the tail leaves the edge facing the tip, kept clear of the corners */
    rect inner = rect_inflate(box, -(radius + 14));
    vec2 base = vec2_clamp(tip, inner.pos, rect_max(inner));
    vec2 out = v2(0, 0);
    if (tip.y > rect_max(box).y) base.y = rect_max(box).y, out = v2(1, 0);
    else if (tip.y < box.pos.y) base.y = box.pos.y, out = v2(1, 0);
    else if (tip.x < box.pos.x) base.x = box.pos.x, out = v2(0, 1);
    else base.x = rect_max(box).x, out = v2(0, 1);
    vec2 a = vec2_add(base, vec2_scale(out, 13)), b = vec2_sub(base, vec2_scale(out, 13));
    vec2 tri[3] = {a, tip, b};
    draw_poly(tri, 3, fill);
    draw_line(a, tip, 2.5f, edge);
    draw_line(b, tip, 2.5f, edge);
}

rect speech_bubble(vec2 tip, const char *utf8, text_style s, color fill, color edge, float max_width)
{
    rect screen = app_screen();
    float pad = s.size * .6f;
    size2 text = text_box_size(s, max_width - 2 * pad, utf8);
    size2 size = sz2(text.w + 2 * pad, text.h + 2 * pad);
    rect box = rect_anchor(vec2_sub(tip, v2(0, 18)), size, v2(.5f, 1));
    if (box.pos.y < screen.pos.y + 8) box = rect_anchor(vec2_add(tip, v2(0, 18)), size, v2(.5f, 0));
    box.pos = vec2_clamp(box.pos, v2s(8), vec2_sub(rect_max(screen), vec2_add(size2_vec(size), v2s(8))));
    speech_bubble_shape(box, tip, fill, edge);
    text_box(s, rect_inflate(box, -pad), v2(.5f, .5f), utf8);
    return box;
}

/* ----------------------------------------------------------------- dialogue */

static void draw_portrait(const character *c, rect r, float slide)
{
    r = rect_offset(r, v2((c->right ? 1 : -1) * slide, 0));
    if (!S.style.framed) {
        draw_image(c->portrait, r, WHITE);
        return;
    }
    draw_shadow(rect_offset(r, v2(0, 6)), 22, 16, rgba(0, 0, 0, 110));
    draw_round_rect(rect_inflate(r, 5), 22, S.style.edge);
    draw_round_rect(r, 18, color_shade(c->color, .55f));
    draw_image(c->portrait, rect_inflate(r, -3), WHITE);
    draw_round_rect_line(rect_inflate(r, 1), 19, 4, S.style.edge);
}

void story_frame(float dt)
{
    if (!S.lines) {
        S.enter = 0;
        S.last = NULL;
        return;
    }
    ui_set_enabled(true);
    S.enter += dt;
    S.line_time += dt;
    S.shown += dt * TYPE_SPEED;
    const char *text = S.queue[0].text;
    const character *who = S.queue[0].who;
    int length = text_length(text);
    rect screen = app_screen();
    float m = 16, in = ease_out_cubic(S.enter * 4);
    if (S.style.dim.a) draw_rect(screen, color_alpha(S.style.dim, in));
    ui_block(screen);

    /* portrait */
    bool has_face = who && who->portrait.tex;
    size2 face = sz2(0, 0);
    if (has_face) {
        float h = screen.size.h * S.style.portrait_height;
        face = S.style.framed ? sz2(h * .82f, h) : sz2(h * size2_aspect(who->portrait.size), h);
    }
    bool wide = screen.size.w - face.w - 3 * m >= 520;
    text_style ts = S.style.text;
    float pad = ts.size * .9f, tag = S.style.name.size * 1.6f;

    /* bubble beside the speaker on wide screens, below them on narrow ones */
    float width = wide ? minf(screen.size.w - face.w - 3 * m, 820) : screen.size.w - 2 * m;
    size2 body = text_box_size(ts, width - 2 * pad, text);
    float height = maxf(body.h + 2 * pad + tag * .4f, ts.size * 3.4f);
    rect bubble, portrait = rect_make(v2(0, 0), face);
    if (!has_face) {
        bubble = rect_anchor(v2(rect_center(screen).x, rect_max(screen).y - m), sz2(width, height), v2(.5f, 1));
    } else if (wide) {
        portrait = rect_anchor(v2(who->right ? rect_max(screen).x - m : screen.pos.x + m, rect_max(screen).y - (S.style.framed ? m : 0)), face,
                               v2(who->right ? 1 : 0, 1));
        float x = who->right ? portrait.pos.x - m - width : rect_max(portrait).x + m;
        bubble = rc(x, rect_max(screen).y - m - height, width, height);
    } else {
        bubble = rect_anchor(v2(rect_center(screen).x, rect_max(screen).y - m), sz2(width, height), v2(.5f, 1));
        portrait = rect_anchor(v2(who->right ? rect_max(bubble).x - m : bubble.pos.x + m, bubble.pos.y + (S.style.framed ? -tag : face.h * .08f)),
                               face, v2(who->right ? 1 : 0, 1));
    }
    bool new_speaker = S.last != who;
    float slide = new_speaker ? (1 - ease_out_cubic(S.line_time * 5)) * face.w * .3f : 0;
    if (has_face) draw_portrait(who, portrait, slide * (S.enter < .3f || new_speaker ? 1 : 0));

    /* a short tail towards the speaker: out of the near side, or the top when they stand above */
    vec2 tip = !has_face ? rect_center(bubble)
               : wide ? v2(who->right ? portrait.pos.x + face.w * .14f : rect_max(portrait).x - face.w * .14f, bubble.pos.y + 4)
                      : v2(rect_center(portrait).x, maxf(portrait.pos.y + face.h * .9f, bubble.pos.y - 26));
    if (!wide && has_face && tip.y > bubble.pos.y - 8) tip = rect_center(bubble);   /* portrait overlaps: no tail */
    speech_bubble_shape(rect_offset(bubble, v2(0, (1 - in) * 30)), tip, S.style.bubble, S.style.edge);
    bubble = rect_offset(bubble, v2(0, (1 - in) * 30));

    if (who) {   /* name tag on the bubble's top edge, on the speaker's side */
        text_style ns = S.style.name;
        float w = text_measure(ns, who->name).w + tag;
        rect pill = rect_anchor(v2(who->right ? rect_max(bubble).x - 22 : bubble.pos.x + 22, bubble.pos.y + tag * .15f), sz2(w, tag),
                                v2(who->right ? 1 : 0, .5f));
        draw_round_rect(pill, tag * .5f, who->color);
        draw_round_rect_line(pill, tag * .5f, 2, S.style.edge);
        text_in(ns, rect_inflate(pill, -4), v2(.5f, .5f), who->name);
    }
    rect inner = rect_inflate2(bubble, v2(-pad, -pad));
    inner.pos.y += tag * .3f;
    text_box_reveal(ts, inner, v2(0, 0), text, (int)S.shown);
    if (S.shown >= length) {   /* waiting for a tap */
        vec2 at = vec2_sub(rect_max(bubble), v2(pad, pad * .6f - sinf(S.line_time * 6) * 3));
        vec2 arrow[3] = {vec2_sub(at, v2(9, 6)), vec2_add(at, v2(9, -6)), vec2_add(at, v2(0, 4))};
        draw_poly(arrow, 3, S.style.edge);
    }

    S.last = who;
    if (S.style.skip) {   /* a pill like the name tag, above the bubble away from the speaker */
        text_style ns = S.style.name;
        bool left = who && who->right;
        rect pill = rect_anchor(v2(left ? bubble.pos.x : rect_max(bubble).x, bubble.pos.y - 10),
                                sz2(text_measure(ns, S.style.skip).w + tag * 1.4f, tag * 1.25f), v2(left ? 0 : 1, 1));
        ui_state st = ui_hit(pill, 0);
        draw_round_rect(rect_offset(pill, v2(0, st.held ? 2 : 0)), tag * .6f, color_alpha(S.style.edge, st.hot ? 1 : .85f));
        text_in(ns, rect_inflate(rect_offset(pill, v2(0, st.held ? 2 : 0)), -5), v2(.5f, .5f), S.style.skip);
        if (st.clicked) {
            S.lines = 0;
            S.shown = S.line_time = 0;
            return;
        }
    }
    if (ui_hit(screen, 0).clicked || input_get().key == SDLK_SPACE) {
        if (S.shown < length) S.shown = (float)length;
        else next_line();
    }
}
