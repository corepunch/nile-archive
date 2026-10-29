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
    struct { const character *who; char text[512]; bubble_kind kind; } queue[QUEUE];
    int lines;
    float shown, enter, line_time;
    const character *last, *listener;
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
    for (int i = 0; i < count; i++) {
        if (cast[i].portrait_path && !cast[i].portrait.tex) cast[i].portrait = tex_load(cast[i].portrait_path);
        if (cast[i].mouth.x <= 0 && cast[i].mouth.y <= 0) cast[i].mouth = v2(.5f, .25f);
    }
}

const character *story_character(const char *id)
{
    for (int i = 0; id && i < S.count; i++)
        if (!strcmp(S.cast[i].id, id)) return &S.cast[i];
    return NULL;
}

void story_line_add(story_line line)
{
    if (S.lines >= QUEUE || !line.text) return;
    S.queue[S.lines].who = story_character(line.who);
    S.queue[S.lines].kind = line.kind;
    snprintf(S.queue[S.lines].text, sizeof S.queue[0].text, "%s", line.text);
    S.lines++;
}

void story_say(const char *who, const char *text) { story_line_add((story_line){who, text, BUBBLE_SPEECH}); }

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
    for (int i = 0; i < count; i++) story_line_add(lines[i]);
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
    if (S.lines > 1 && S.queue[1].who != S.queue[0].who) S.listener = S.queue[0].who;   /* stays on stage */
    memmove(S.queue, S.queue + 1, sizeof S.queue[0] * (size_t)(S.lines - 1));
    S.lines--;
    S.shown = S.line_time = 0;
}

void story_next(void)
{
    if (S.lines) next_line();
}

/* ------------------------------------------------------------------ bubbles */

#define OUTLINE 3.0f

/* The edge point of `box` facing `tip`, kept clear of the rounded corners. */
static vec2 tail_base(rect box, vec2 tip, float radius, vec2 *along)
{
    rect inner = rect_inflate(box, -(radius + 12));
    vec2 base = vec2_clamp(tip, inner.pos, rect_max(inner));
    vec2 hi = rect_max(box);
    if (tip.y > hi.y && tip.y - hi.y >= fmaxf(box.pos.x - tip.x, tip.x - hi.x)) base.y = hi.y, *along = v2(1, 0);
    else if (tip.y < box.pos.y && box.pos.y - tip.y >= fmaxf(box.pos.x - tip.x, tip.x - hi.x)) base.y = box.pos.y, *along = v2(1, 0);
    else if (tip.x < box.pos.x) base.x = box.pos.x, *along = v2(0, 1);
    else base.x = hi.x, *along = v2(0, 1);
    return base;
}

/* Speech: a rounded body and a tapered tail drawn as one shape. The outline
 * pass draws both a little larger in the edge colour, the fill pass draws
 * both on top, with the tail's root reaching into the body so no seam shows. */
static void speech_shape(rect box, vec2 tip, color fill, color edge, bool tail)
{
    float r = minf(20, box.size.h * .32f);
    vec2 along, base = tail_base(box, tip, r, &along), dir = vec2_norm(vec2_sub(tip, base));
    float half = clampf(vec2_dist(base, tip) * .22f, 10, 17);
    vec2 a = vec2_sub(vec2_add(base, vec2_scale(along, half)), vec2_scale(dir, 8));   /* root inside the body */
    vec2 b = vec2_sub(vec2_sub(base, vec2_scale(along, half)), vec2_scale(dir, 8));
    vec2 rim_a = vec2_add(a, vec2_scale(along, OUTLINE)), rim_b = vec2_sub(b, vec2_scale(along, OUTLINE));
    vec2 rim_tip = vec2_add(tip, vec2_scale(dir, OUTLINE * 1.4f));
    draw_shadow(rect_offset(box, v2(0, 6)), r + 4, 16, rgba(0, 0, 0, 60));
    draw_round_rect(rect_inflate(box, OUTLINE), r + OUTLINE, edge);
    if (tail) draw_poly((vec2[]){rim_a, rim_tip, rim_b}, 3, edge);
    draw_round_rect(box, r, fill);
    if (tail) draw_poly((vec2[]){a, tip, b}, 3, fill);
}

/* Thought: a cloud of puffs around the body, and shrinking puffs as the tail. */
static void thought_shape(rect box, vec2 tip, color fill, color edge, bool tail)
{
    float puff = clampf(minf(box.size.w, box.size.h) * .22f, 9, 18), step = puff * 1.35f;
    vec2 centers[96];
    int n = 0;
    rect path = rect_inflate(box, -puff * .35f);
    const vec2 corners[4] = {{0, 0}, {1, 0}, {1, 1}, {0, 1}};
    for (int side = 0; side < 4 && n < 96; side++) {
        vec2 p0 = rect_point(path, corners[side]), p1 = rect_point(path, corners[(side + 1) % 4]);
        int k = (int)ceilf(vec2_dist(p0, p1) / step);
        for (int i = 0; i < k && n < 96; i++) centers[n++] = vec2_lerp(p0, p1, (float)i / k);
    }
    vec2 dots[3];
    vec2 along, base = tail_base(box, tip, puff, &along);
    for (int i = 0; i < 3; i++) dots[i] = vec2_lerp(base, tip, .38f + i * .31f);
    draw_shadow(rect_offset(box, v2(0, 6)), puff, 16, rgba(0, 0, 0, 60));
    for (int i = 0; i < n; i++) draw_circle(centers[i], puff + OUTLINE, edge);
    draw_round_rect(rect_inflate(box, OUTLINE), puff, edge);
    for (int i = 0; tail && i < 3; i++) draw_circle(dots[i], puff * (.55f - i * .14f) + OUTLINE, edge);
    for (int i = 0; i < n; i++) draw_circle(centers[i], puff, fill);
    draw_round_rect(box, puff, fill);
    for (int i = 0; tail && i < 3; i++) draw_circle(dots[i], puff * (.55f - i * .14f), fill);
}

/* Shout: spikes of a fixed length all around a rounded box (a superellipse),
 * so wide and narrow bubbles burst alike, plus one long spike to the speaker. */
static void shout_shape(rect box, vec2 tip, color fill, color edge, bool tail)
{
    enum { MAX = 120 };
    vec2 c = rect_center(box), half = vec2_scale(size2_vec(box.size), .5f);
    int n = clampi((int)((box.size.w + box.size.h) * 2 / 30) & ~1, 12, MAX);
    vec2 body[MAX], rim[MAX];
    for (int i = 0; i < n; i++) {
        float a = 2 * ENGINE_PI * (i + .5f) / n, ca = cosf(a), sa = sinf(a);
        vec2 dir = v2(copysignf(sqrtf(fabsf(ca)), ca), copysignf(sqrtf(fabsf(sa)), sa));   /* superellipse, p = 4 */
        float spike = i % 2 ? 4 : 15 + 4 * sinf(i * 2.3f);
        vec2 p = vec2_add(c, vec2_mul(dir, vec2_add(half, v2s(spike))));
        body[i] = p;
        rim[i] = vec2_add(p, vec2_scale(vec2_norm(vec2_sub(p, c)), OUTLINE * 1.5f));
    }
    vec2 along, base = tail_base(box, tip, 10, &along), dir = vec2_norm(vec2_sub(tip, base));
    vec2 a = vec2_sub(vec2_add(base, vec2_scale(along, 12)), vec2_scale(dir, 10));
    vec2 b = vec2_sub(vec2_sub(base, vec2_scale(along, 12)), vec2_scale(dir, 10));
    draw_shadow(rect_offset(box, v2(0, 6)), 18, 18, rgba(0, 0, 0, 60));
    draw_poly(rim, n, edge);
    if (tail) draw_poly((vec2[]){vec2_add(a, vec2_scale(along, OUTLINE)), vec2_add(tip, vec2_scale(dir, OUTLINE * 1.6f)), vec2_sub(b, vec2_scale(along, OUTLINE))}, 3, edge);
    draw_poly(body, n, fill);
    draw_round_rect(rect_inflate(box, 2), 8, fill);
    if (tail) draw_poly((vec2[]){a, tip, b}, 3, fill);
}

void speech_bubble_shape(rect box, vec2 tip, color fill, color edge, bubble_kind kind)
{
    bool tail = !rect_contains(rect_inflate(box, 4), tip);
    if (kind == BUBBLE_THOUGHT) thought_shape(box, tip, fill, edge, tail);
    else if (kind == BUBBLE_SHOUT) shout_shape(box, tip, fill, edge, tail);
    else speech_shape(box, tip, fill, edge, tail);
}

rect speech_bubble(vec2 tip, const char *utf8, text_style s, color fill, color edge, float max_width, bubble_kind kind)
{
    rect screen = app_screen();
    float pad = s.size * .6f, lift = kind == BUBBLE_SPEECH ? 18 : 30;
    size2 text = text_box_size(s, max_width - 2 * pad, utf8);
    size2 size = sz2(text.w + 2 * pad, text.h + 2 * pad);
    rect box = rect_anchor(vec2_sub(tip, v2(0, lift)), size, v2(.5f, 1));
    if (box.pos.y < screen.pos.y + 8) box = rect_anchor(vec2_add(tip, v2(0, lift)), size, v2(.5f, 0));
    box.pos = vec2_clamp(box.pos, v2s(14), vec2_sub(rect_max(screen), vec2_add(size2_vec(size), v2s(14))));
    speech_bubble_shape(box, tip, fill, edge, kind);
    text_box(s, rect_inflate(box, -pad), v2(.5f, .5f), utf8);
    return box;
}

/* ----------------------------------------------------------------- dialogue */

static size2 portrait_size(const character *c, float h)
{
    return S.style.framed ? sz2(h * .82f, h) : sz2(h * size2_aspect(c->portrait.size), h);
}

/* Where a character stands: bottom corner on their side. */
static rect stand(const character *c, float h)
{
    rect screen = app_screen();
    float m = 16;
    vec2 foot = v2(c->right ? rect_max(screen).x - m : screen.pos.x + m, rect_max(screen).y - (S.style.framed ? m : 0));
    return rect_anchor(foot, portrait_size(c, h), v2(c->right ? 1 : 0, 1));
}

static void draw_portrait(const character *c, rect r, color tint)
{
    if (!S.style.framed) {
        draw_image(c->portrait, r, tint);
        return;
    }
    draw_shadow(rect_offset(r, v2(0, 6)), 22, 16, rgba(0, 0, 0, 110));
    draw_round_rect(rect_inflate(r, 5), 22, color_lerp(S.style.edge, BLACK, 1 - tint.r / 255.f));
    draw_round_rect(r, 18, color_lerp(color_shade(c->color, .55f), BLACK, 1 - tint.r / 255.f));
    draw_image(c->portrait, rect_inflate(r, -3), tint);
    draw_round_rect_line(rect_inflate(r, 1), 19, 4, S.style.edge);
}

void story_frame(float dt)
{
    if (!S.lines) {
        S.enter = 0;
        S.last = S.listener = NULL;
        return;
    }
    ui_set_enabled(true);
    S.enter += dt;
    S.line_time += dt;
    S.shown += dt * TYPE_SPEED;
    const char *text = S.queue[0].text;
    const character *who = S.queue[0].who;
    bubble_kind kind = S.queue[0].kind;
    int length = text_length(text);
    rect screen = app_screen();
    float m = 16, in = ease_out_cubic(S.enter * 4), h = screen.size.h * S.style.portrait_height;
    if (S.style.dim.a) draw_rect(screen, color_alpha(S.style.dim, in));
    ui_block(screen);

    bool has_face = who && who->portrait.tex;
    size2 face = has_face ? portrait_size(who, h) : sz2(0, 0);
    text_style ts = S.style.text;
    float pad = ts.size * .9f, tag = S.style.name.size * 1.6f;
    bool beside = has_face && screen.size.w - face.w * .7f - 2 * m >= 420;   /* room for a bubble at face height */

    /* the listener: the previous speaker, dimmed, on the other side */
    const character *listener = S.listener;
    if (listener && listener->portrait.tex && who && listener->right != who->right && listener != who) {
        rect r = stand(listener, h * .92f);
        draw_portrait(listener, rect_offset(r, v2(0, h * .02f)), rgba(120, 124, 132, 235));
    }

    float width = beside ? minf(600, screen.size.w * .5f) : screen.size.w - 2 * m;
    size2 body = text_box_size(ts, width - 2 * pad, text);
    float height = maxf(body.h + 2 * pad + tag * .4f, ts.size * 3.4f);
    rect portrait = rect_make(v2(0, 0), face), bubble;
    vec2 tip;
    if (!has_face) {
        bubble = rect_anchor(v2(rect_center(screen).x, rect_max(screen).y - m), sz2(width, height), v2(.5f, 1));
        tip = rect_center(bubble);
    } else if (beside) {   /* Playrix staging: the bubble at face height, the tail on the mouth */
        portrait = stand(who, h);
        vec2 mouth = rect_point(portrait, who->mouth);
        float x = who->right ? mouth.x - face.w * .2f - width : mouth.x + face.w * .2f;
        float y = mouth.y - height * .8f;
        bubble = rc(clampf(x, m, rect_max(screen).x - m - width), clampf(y, m + 50, rect_max(screen).y - m - height), width, height);
        tip = vec2_add(mouth, v2((who->right ? -1 : 1) * face.w * .07f, 6));
    } else {   /* narrow screens: the bubble along the bottom, the speaker standing on it */
        bubble = rect_anchor(v2(rect_center(screen).x, rect_max(screen).y - m), sz2(width, height), v2(.5f, 1));
        portrait = rect_anchor(v2(who->right ? rect_max(bubble).x - m : bubble.pos.x + m, bubble.pos.y + (S.style.framed ? -tag : face.h * .08f)),
                               face, v2(who->right ? 1 : 0, 1));
        /* a short tail from the bubble's top edge, beside the frame, aimed at the mouth */
        vec2 mouth = rect_point(portrait, who->mouth);
        vec2 root = v2(who->right ? portrait.pos.x - 26 : rect_max(portrait).x + 26, bubble.pos.y);
        tip = vec2_add(root, vec2_scale(vec2_norm(vec2_sub(mouth, root)), 40));
        if (!S.style.framed) tip = rect_center(bubble);   /* a standing figure overlaps the bubble: no tail */
    }
    bool new_speaker = S.last != who;
    float slide = new_speaker ? (1 - ease_out_cubic(S.line_time * 5)) * face.w * .3f : 0;
    if (has_face) draw_portrait(who, rect_offset(portrait, v2((who->right ? 1 : -1) * slide, 0)), WHITE);

    float rise = (1 - in) * 30;
    bubble = rect_offset(bubble, v2(0, rise));
    speech_bubble_shape(bubble, vec2_add(tip, v2(0, rise)), S.style.bubble, S.style.edge, kind);

    if (who) {   /* name tag on the bubble's top edge, on the speaker's side */
        text_style ns = S.style.name;
        float w = text_measure(ns, who->name).w + tag;
        rect pill = rect_anchor(v2(who->right ? rect_max(bubble).x - 22 : bubble.pos.x + 22, bubble.pos.y + tag * .1f), sz2(w, tag),
                                v2(who->right ? 1 : 0, .5f));
        draw_round_rect(rect_inflate(pill, 2), tag * .5f + 2, S.style.edge);
        draw_round_rect(pill, tag * .5f, who->color);
        text_in(ns, rect_inflate(pill, -4), v2(.5f, .5f), who->name);
    }
    rect inner = rect_inflate2(bubble, v2(-pad, -pad));
    inner.pos.y += tag * .3f;
    text_box_reveal(ts, inner, v2(0, 0), text, (int)S.shown);
    if (S.shown >= length) {   /* waiting for a tap */
        vec2 at = vec2_sub(rect_max(bubble), v2(pad, pad * .6f - sinf(S.line_time * 6) * 3));
        draw_poly((vec2[]){vec2_sub(at, v2(9, 6)), vec2_add(at, v2(9, -6)), vec2_add(at, v2(0, 4))}, 3, S.style.edge);
    }
    S.last = who;

    if (S.style.skip) {   /* a pill like the name tag, above the bubble away from the speaker */
        text_style ns = S.style.name;
        bool left = who && who->right;
        rect pill = rect_anchor(v2(left ? bubble.pos.x : rect_max(bubble).x, bubble.pos.y - 12),
                                sz2(text_measure(ns, S.style.skip).w + tag * 1.4f, tag * 1.25f), v2(left ? 0 : 1, 1));
        if (beside)   /* the bottom corner away from the speaker */
            pill = rect_anchor(v2(left ? screen.pos.x + m : rect_max(screen).x - m, rect_max(screen).y - m), pill.size, v2(left ? 0 : 1, 1));
        ui_state st = ui_hit(pill, 0);
        rect drawn = rect_offset(pill, v2(0, st.held ? 2 : 0));
        draw_round_rect(drawn, tag * .6f, color_alpha(S.style.edge, st.hot ? 1 : .85f));
        text_in(ns, rect_inflate(drawn, -5), v2(.5f, .5f), S.style.skip);
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
