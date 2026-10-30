/* story.c — characters, dialogue and speech bubbles.
 *
 * A game registers its cast once, then queues lines: either single lines or
 * named beats that play once per save. The dialogue draws over everything:
 * the speaker's portrait at the side, a speech bubble whose tail points at
 * them, a name tag, and text that types itself out, pausing on punctuation.
 * A tap finishes the line, the next tap moves on. Bubbles are also available
 * on their own, for words floating over the world.
 *
 * The bubbles follow comic lettering: the balloon hugs its words (no empty
 * balloon), the tail is curved and tapered, aims at the mouth and stops short
 * of the face, thought balloons trail detached puffs to the head, and shouts
 * burst with regular spikes that never leave the screen. */
#include "engine.h"

#include <stdio.h>
#include <string.h>

#define QUEUE 48
#define MAX_SEEN 256
#define TYPE_SPEED 40.0f   /* codepoints per second (25 ms each, the usual 20-50 ms) */
#define POP_TIME .22f      /* a new speaker's bubble springs out of its tail */

static struct {
    character *cast;
    int count;
    story_style style;
    struct { const character *who; char text[512]; bubble_kind kind; } queue[QUEUE];
    int lines;
    float shown, enter, line_time, arrive, hold;
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
    S.shown = S.line_time = S.hold = 0;
}

void story_next(void)
{
    if (S.lines) next_line();
}

/* ------------------------------------------------------------------ bubbles */

#define OUTLINE 3.0f
#define SHOUT_SPIKE 16.0f

/* How far a bubble's outline reaches past its box, so layouts keep it on screen. */
static float bubble_reach(bubble_kind kind, rect box)
{
    if (kind == BUBBLE_THOUGHT) return clampf(minf(box.size.w, box.size.h) * .22f, 9, 18) * .65f + OUTLINE;
    if (kind == BUBBLE_SHOUT) return SHOUT_SPIKE + 3 + OUTLINE * 1.6f;
    return OUTLINE;
}

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

/* A tapered tail along a quadratic curve from `root` (inside the body) to
 * `tip`: the comic-book "comma". It is drawn as a strip of convex quads in one
 * colour, so their soft edges overlap without seams. `grow` widens the strip
 * for the outline pass and pushes its point a little past the tip. */
static void curved_tail(vec2 root, vec2 ctrl, vec2 tip, float half, float grow, color c)
{
    enum { N = 12 };
    vec2 left[N + 1], right[N + 1];
    for (int i = 0; i <= N; i++) {
        float t = (float)i / N, u = 1 - t;
        vec2 p = vec2_add(vec2_add(vec2_scale(root, u * u), vec2_scale(ctrl, 2 * u * t)), vec2_scale(tip, t * t));
        vec2 d = vec2_norm(vec2_add(vec2_scale(vec2_sub(ctrl, root), 2 * u), vec2_scale(vec2_sub(tip, ctrl), 2 * t)));
        if (i == N) p = vec2_add(p, vec2_scale(d, grow * 1.3f));
        float w = half * powf(u, .85f) + grow;
        vec2 n = v2(-d.y * w, d.x * w);
        left[i] = vec2_add(p, n);
        right[i] = vec2_sub(p, n);
    }
    for (int i = 0; i < N; i++) draw_poly((vec2[]){left[i], left[i + 1], right[i + 1], right[i]}, 4, c);
}

/* Speech: a rounded body and a curved, tapered tail drawn as one shape. The
 * outline pass draws both a little larger in the edge colour, the fill pass
 * draws both on top, with the tail's root reaching into the body so no seam
 * shows. The tail bows gently away from the body's centre line, as lettered
 * tails do, so it reads as drawn rather than as a ruler-straight wedge. */
static void speech_shape(rect box, vec2 tip, color fill, color edge, bool tail)
{
    float r = minf(24, box.size.h * .42f);
    vec2 along, base = tail_base(box, tip, r, &along);
    vec2 dir = vec2_norm(vec2_sub(tip, base)), side = v2(-dir.y, dir.x);
    float len = vec2_dist(base, tip), half = clampf(len * .3f, 9, 16);
    vec2 root = vec2_sub(base, vec2_scale(dir, 10));   /* inside the body */
    float bow = vec2_dot(side, vec2_sub(base, rect_center(box))) >= 0 ? 1 : -1;
    vec2 ctrl = vec2_add(vec2_lerp(base, tip, .45f), vec2_scale(side, bow * len * .22f));
    draw_shadow(rect_offset(box, v2(0, 6)), r + 4, 16, rgba(0, 0, 0, 60));
    draw_round_rect(rect_inflate(box, OUTLINE), r + OUTLINE, edge);
    if (tail) curved_tail(root, ctrl, tip, half, OUTLINE, edge);
    draw_round_rect(box, r, fill);
    if (tail) curved_tail(root, ctrl, tip, half, 0, fill);
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

/* A point and outward normal at distance `d` along the outline of a rounded
 * rect (radius `r`), clockwise from the top edge's left end. */
static vec2 round_rect_at(rect box, float r, float d, vec2 *normal)
{
    float w = box.size.w - 2 * r, h = box.size.h - 2 * r, arc = ENGINE_PI * r * .5f;
    float seg[8] = {w, arc, h, arc, w, arc, h, arc};
    vec2 lo = vec2_add(box.pos, v2s(r)), hi = vec2_sub(rect_max(box), v2s(r));
    vec2 corner[4] = {{hi.x, lo.y}, {hi.x, hi.y}, {lo.x, hi.y}, {lo.x, lo.y}};
    const vec2 start[4] = {{0, -1}, {1, 0}, {0, 1}, {-1, 0}};
    for (int i = 0; i < 8; i++) {
        if (d > seg[i] && i < 7) { d -= seg[i]; continue; }
        int k = i / 2;
        if (i % 2 == 0) {   /* a straight edge: top, right, bottom, left */
            vec2 from = vec2_add(corner[(k + 3) % 4], vec2_scale(start[k], r));
            vec2 step = v2(-start[k].y, start[k].x);
            *normal = start[k];
            return vec2_add(from, vec2_scale(step, d));
        }
        float a = atan2f(start[k].y, start[k].x) + (d / maxf(arc, 1e-3f)) * ENGINE_PI * .5f;
        *normal = v2(cosf(a), sinf(a));
        return vec2_add(corner[k], vec2_scale(*normal, r));
    }
    *normal = v2(0, -1);
    return box.pos;
}

/* Shout: spikes at an even spacing all along a rounded box, so a wide line
 * bursts as evenly as a short one and reads as a shout, not torn paper; plus
 * one long straight spike to the speaker. */
static void shout_shape(rect box, vec2 tip, color fill, color edge, bool tail)
{
    enum { MAX = 140 };
    const float mid = SHOUT_SPIKE * .5f;   /* spikes are spaced along their own middle line */
    float r = minf(box.size.h * .5f, 30);
    rect path = rect_inflate(box, mid);
    float around = 2 * (path.size.w + path.size.h - 4 * (r + mid)) + 2 * ENGINE_PI * (r + mid);
    int n = clampi((int)(around / 22) & ~1, 14, MAX);
    vec2 body[MAX], rim[MAX];
    for (int i = 0; i < n; i++) {
        vec2 normal, p = round_rect_at(path, r + mid, around * (i + .5f) / n, &normal);
        float spike = i % 2 ? 1 - mid : SHOUT_SPIKE - mid + 3 * sinf(i * 1.7f);
        body[i] = vec2_add(p, vec2_scale(normal, spike));
        rim[i] = vec2_add(body[i], vec2_scale(normal, OUTLINE * (i % 2 ? 1 : 1.6f)));
    }
    vec2 along, base = tail_base(box, tip, 10, &along), dir = vec2_norm(vec2_sub(tip, base));
    vec2 a = vec2_sub(vec2_add(base, vec2_scale(along, 13)), vec2_scale(dir, 10));
    vec2 b = vec2_sub(vec2_sub(base, vec2_scale(along, 13)), vec2_scale(dir, 10));
    draw_shadow(rect_offset(box, v2(0, 6)), r, 18, rgba(0, 0, 0, 60));
    draw_poly(rim, n, edge);
    if (tail) draw_poly((vec2[]){vec2_add(a, vec2_scale(along, OUTLINE)), vec2_add(tip, vec2_scale(dir, OUTLINE * 1.6f)), vec2_sub(b, vec2_scale(along, OUTLINE))}, 3, edge);
    draw_poly(body, n, fill);
    draw_round_rect(box, r, fill);   /* the same rounded base the spikes stand on */
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
    float pad = s.size * .7f, vpad = s.size * .55f, lift = kind == BUBBLE_SPEECH ? 22 : 30;
    size2 text = text_box_size(s, max_width - 2 * pad, utf8);
    size2 size = sz2(text.w + 2 * pad, text.h + 2 * vpad);
    float reach = bubble_reach(kind, rect_make(v2(0, 0), size)) + 6;
    rect box = rect_anchor(vec2_sub(tip, v2(0, lift)), size, v2(.5f, 1));
    if (box.pos.y < screen.pos.y + reach) box = rect_anchor(vec2_add(tip, v2(0, lift)), size, v2(.5f, 0));
    box.pos = vec2_clamp(box.pos, vec2_add(screen.pos, v2s(reach)), vec2_sub(rect_max(screen), vec2_add(size2_vec(size), v2s(reach))));
    speech_bubble_shape(box, tip, fill, edge, kind);
    text_box(s, rect_inflate2(box, v2(-pad, -vpad)), v2(.5f, .5f), utf8);
    return box;
}

/* ----------------------------------------------------------------- dialogue */

/* The codepoint at index `at` (0 when past the end). */
static uint32_t codepoint_at(const char *s, int at)
{
    const unsigned char *p = (const unsigned char *)s;
    for (int i = 0; *p; i++) {
        int len = *p < 0x80 ? 1 : *p < 0xE0 ? 2 : *p < 0xF0 ? 3 : 4;
        if (i == at) {
            uint32_t c = len == 1 ? *p : *p & (0xFF >> (len + 1));
            for (int k = 1; k < len && p[k]; k++) c = (c << 6) | (p[k] & 0x3F);
            return c;
        }
        for (int k = 0; k < len && *p; k++) p++;
    }
    return 0;
}

/* Typing breathes like speech: a beat after a sentence, a shorter one after a
 * comma or dash. Only when a space follows, so "..." pauses once, at its end. */
static float pause_after(uint32_t c, uint32_t next)
{
    if (next != ' ' && next != '\n') return 0;
    if (c == '.' || c == '!' || c == '?' || c == 0x2026) return .26f;
    if (c == ',' || c == ';' || c == ':' || c == 0x2014 || c == 0x2013) return .1f;
    return 0;
}

static void type_text(const char *text, int length, float dt)
{
    if (S.hold > 0) {
        S.hold -= dt;
        return;
    }
    int before = (int)S.shown;
    S.shown = minf(S.shown + dt * TYPE_SPEED, (float)length);
    for (int i = before; i < (int)S.shown; i++) {
        float p = pause_after(codepoint_at(text, i), codepoint_at(text, i + 1));
        if (p > 0) {
            S.shown = (float)(i + 1);
            S.hold = p;
            break;
        }
    }
}

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

/* A name tag: a pill in the speaker's colour with the edge colour as its rim. */
static void name_tag(const character *who, vec2 at, vec2 pivot, float tag)
{
    text_style ns = S.style.name;
    float w = text_measure(ns, who->name).w + tag;
    rect pill = rect_anchor(at, sz2(w, tag), pivot);
    draw_shadow(rect_offset(pill, v2(0, 2)), tag * .5f, 6, rgba(0, 0, 0, 50));
    draw_round_rect(rect_inflate(pill, 2), tag * .5f + 2, S.style.edge);
    draw_round_rect(pill, tag * .5f, who->color);
    text_in(ns, rect_inflate(pill, -4), v2(.5f, .5f), who->name);
}

/* Scale a rect about a point (the bubble springs out of its tail). */
static rect scale_about(rect r, vec2 at, float k)
{
    return rect_make(vec2_add(at, vec2_scale(vec2_sub(r.pos, at), k)), size2_scale(r.size, k));
}

void story_frame(float dt)
{
    if (!S.lines) {
        S.enter = 0;
        S.last = S.listener = NULL;
        return;
    }
    ui_set_enabled(true);
    const char *text = S.queue[0].text;
    const character *who = S.queue[0].who;
    bubble_kind kind = S.queue[0].kind;
    if (S.enter == 0 || who != S.last) S.arrive = 0;   /* a new speaker steps in */
    S.enter += dt;
    S.line_time += dt;
    S.arrive += dt;
    int length = text_length(text);
    if (S.arrive > POP_TIME * .6f) type_text(text, length, dt);

    rect screen = app_screen();
    float m = 16, in = ease_out_cubic(S.enter * 4), h = screen.size.h * S.style.portrait_height;
    if (S.style.dim.a) draw_rect(screen, color_alpha(S.style.dim, in));
    ui_block(screen);

    bool has_face = who && who->portrait.tex;
    size2 face = has_face ? portrait_size(who, h) : sz2(0, 0);
    text_style ts = S.style.text;
    float pad = ts.size * .9f, vpad = ts.size * .7f, tag = S.style.name.size * 1.6f;
    float tag_w = who ? text_measure(S.style.name, who->name).w + tag : 0;
    bool beside = has_face && screen.size.w - face.w * .7f - 2 * m >= 420;   /* room for a bubble at face height */
    bool framed_narrow = has_face && !beside && S.style.framed;
    float reach = bubble_reach(kind, rc(0, 0, 400, 100));

    /* the bubble hugs its text: balanced lines no wider than a comfortable measure */
    float max_w = beside ? minf(560, screen.size.w * .45f)
                : has_face ? screen.size.w - 2 * (m + reach)
                : minf(screen.size.w - 2 * (m + reach), maxf(560, screen.size.w * .62f));
    size2 body = text_box_size(ts, max_w - 2 * pad, text);
    float width = minf(max_w, maxf(body.w + 2 * pad, maxf(tag_w + 64, ts.size * 9)));
    float top = who ? tag * .35f : 0;   /* room under the name tag */
    float height = maxf(body.h + 2 * vpad + top, ts.size * 2.6f);

    rect portrait = rect_make(v2(0, 0), face), bubble;
    vec2 tip, grow_from;
    if (!has_face) {   /* narration or an unseen speaker: a caption along the bottom */
        bubble = rect_anchor(v2(rect_center(screen).x, rect_max(screen).y - m - reach), sz2(width, height), v2(.5f, 1));
        tip = rect_center(bubble);
        grow_from = rect_point(bubble, v2(.5f, 1));
    } else if (beside) {   /* Playrix staging: the bubble at face height, the tail on the mouth */
        portrait = stand(who, h);
        vec2 mouth = rect_point(portrait, who->mouth);
        float side = who->right ? -1 : 1;
        float x = who->right ? mouth.x - face.w * .22f - width : mouth.x + face.w * .22f;
        float y = mouth.y - height * .85f - 10;
        bubble = rc(clampf(x, m + reach, rect_max(screen).x - m - reach - width),
                    clampf(y, m + 50, rect_max(screen).y - m - reach - height), width, height);
        /* the tail aims at the mouth and stops short of the face */
        tip = vec2_add(mouth, v2(side * face.w * .12f, -2));
        grow_from = tip;
    } else if (framed_narrow) {   /* phones: the medallion in its corner, the bubble above it, tail down */
        portrait = stand(who, h);
        float x = who->right ? rect_max(portrait).x - width : portrait.pos.x;
        float y = portrait.pos.y - 26 - reach - height;
        bubble = rc(clampf(x, m + reach, rect_max(screen).x - m - reach - width), maxf(y, m + reach), width, height);
        /* the tail drops toward the face and stops just above the frame */
        tip = v2(rect_point(portrait, who->mouth).x, portrait.pos.y - 8);
        grow_from = tip;
    } else {   /* narrow screens, standing figures: a panel along the bottom, the speaker standing on it */
        bubble = rect_anchor(v2(rect_center(screen).x, rect_max(screen).y - m - reach), sz2(width, height), v2(.5f, 1));
        portrait = rect_anchor(v2(who->right ? rect_max(bubble).x - m : bubble.pos.x + m, bubble.pos.y + face.h * .08f),
                               face, v2(who->right ? 1 : 0, 1));
        tip = rect_center(bubble);   /* the figure overlaps the bubble: no tail */
        grow_from = rect_point(bubble, v2(who->right ? .85f : .15f, 0));
    }

    /* the listener: the previous speaker, dimmed, on the other side */
    const character *listener = S.listener;
    bool listening = listener && listener->portrait.tex && who && listener->right != who->right && listener != who;
    if (listening) {
        rect r = stand(listener, h * (framed_narrow ? .8f : .92f));
        draw_portrait(listener, rect_offset(r, v2(0, framed_narrow ? 0 : h * .02f)), rgba(120, 124, 132, 235));
    }

    float slide = (1 - ease_out_cubic(S.arrive * 5)) * face.w * .3f;
    rect shown_portrait = rect_offset(portrait, v2((who && who->right ? 1 : -1) * slide, 0));
    if (has_face) draw_portrait(who, shown_portrait, WHITE);

    /* the bubble springs out of its tail when a speaker arrives */
    float pop = lerpf(.55f, 1, ease_out_back(S.arrive / POP_TIME));
    rect drawn = scale_about(bubble, grow_from, pop);
    speech_bubble_shape(drawn, tip, S.style.bubble, S.style.edge, kind);

    float settle = saturate((S.arrive - POP_TIME * .5f) / (POP_TIME * .5f));
    if (who && settle > 0) {   /* name tag on the bubble's top edge, on the speaker's side */
        vec2 at = v2(who->right ? rect_max(bubble).x - 22 : bubble.pos.x + 22, bubble.pos.y + tag * .05f);
        name_tag(who, vec2_add(at, v2(0, (1 - settle) * 6)), v2(who->right ? 1 : 0, .5f), tag);
    }
    rect inner = rect_inflate2(bubble, v2(-pad, -vpad));
    inner.pos.y += top;
    inner.size.h -= top;
    text_box_reveal(ts, inner, v2(who ? 0 : .5f, .5f), text, (int)S.shown);
    if (S.shown >= length) {   /* waiting for a tap: a bobbing arrow in the corner */
        vec2 at = vec2_sub(rect_max(bubble), v2(pad * .75f, vpad * .7f - sinf(S.line_time * 6) * 3));
        draw_poly((vec2[]){vec2_sub(at, v2(8, 6)), vec2_add(at, v2(8, -6)), vec2_add(at, v2(0, 4))}, 3, S.style.edge);
    }
    S.last = who;

    if (S.style.skip) {   /* a quiet pill with a fast-forward mark, away from the speaker */
        text_style ns = S.style.name;
        bool left = who && who->right;
        float icon = tag * .55f;
        size2 size = sz2(text_measure(ns, S.style.skip).w + tag * 1.2f + icon + 6, tag * 1.25f);
        rect pill = rect_anchor(v2(left ? bubble.pos.x : rect_max(bubble).x, bubble.pos.y - 12 - reach), size, v2(left ? 0 : 1, 1));
        if (beside || (framed_narrow && !listening))   /* the free bottom corner away from the speaker */
            pill = rect_anchor(v2(left ? screen.pos.x + m : rect_max(screen).x - m, rect_max(screen).y - m), pill.size, v2(left ? 0 : 1, 1));
        ui_state st = ui_hit(pill, 0);
        rect r = rect_offset(pill, v2(0, st.held ? 2 : 0));
        draw_shadow(rect_offset(r, v2(0, 3)), r.size.h * .5f, 8, rgba(0, 0, 0, 70));
        draw_round_rect(r, r.size.h * .5f, color_alpha(S.style.edge, st.hot ? 1 : .88f));
        rect label = rect_inflate2(r, v2(-tag * .6f, -4));
        rect mark = rect_cut_right(&label, icon);
        text_in(ns, label, v2(.5f, .5f), S.style.skip);
        vec2 c = rect_center(mark);
        float s = icon * .42f;
        for (int k = 0; k < 2; k++) {   /* ▸▸ */
            vec2 o = v2(c.x - s * .55f + k * s * 1.1f, c.y);
            draw_poly((vec2[]){v2(o.x - s * .5f, o.y - s * .62f), v2(o.x + s * .55f, o.y), v2(o.x - s * .5f, o.y + s * .62f)}, 3, ns.fill);
        }
        if (st.clicked) {
            S.lines = 0;
            S.shown = S.line_time = S.hold = 0;
            return;
        }
    }
    if (ui_hit(screen, 0).clicked || input_get().key == AX_KEY_SPACE) {
        if (S.shown < length) S.shown = (float)length, S.hold = 0;
        else next_line();
    }
}
