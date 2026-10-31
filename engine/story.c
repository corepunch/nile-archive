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
#define PORTRAIT_TIME .2f /* entrance, exit, and active/listener transitions */

typedef struct {
    const character *who;
    rect bounds;
    color from_tint, to_tint;
    tween blend, visibility;
    bool wanted, active;
} portrait_track;

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
    portrait_track portraits[QUEUE];
} S;

#ifdef ENGINE_TEST
void story_restart(void) { memset(&S, 0, sizeof S); }
#endif

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

#define TAIL_LEN 20.0f    /* a short comma: it says who speaks, it does not reach them */
#define TAIL_HALF 7.0f

/* The speech tail as one convex polygon: a straight leading edge from the root
 * to the tip and a trailing edge that bows outward, the lettered "comma".
 * One polygon has one smooth rim and no seams. `grow` widens it for the
 * outline pass and pushes its point a little past the tip. */
static int tail_shape(vec2 base, vec2 dir, vec2 along, float len, float half, float grow, vec2 *out)
{
    enum { N = 8 };
    vec2 side = vec2_dot(along, v2(-dir.y, dir.x)) >= 0 ? along : vec2_scale(along, -1);
    vec2 root = vec2_sub(base, vec2_scale(dir, 8));   /* inside the body, under its rim */
    vec2 tip = vec2_add(base, vec2_scale(dir, len + grow * 1.5f));
    vec2 a = vec2_add(root, vec2_scale(side, half + grow)), b = vec2_sub(root, vec2_scale(side, half + grow));
    vec2 ctrl = vec2_add(vec2_lerp(b, tip, .5f), vec2_scale(side, -(half + grow) * .7f));
    int n = 0;
    out[n++] = a;
    out[n++] = tip;
    for (int i = 1; i < N; i++) {   /* tip back to b along the bowed edge */
        float t = (float)i / N, u = 1 - t;
        out[n++] = vec2_add(vec2_add(vec2_scale(tip, u * u), vec2_scale(ctrl, 2 * u * t)), vec2_scale(b, t * t));
    }
    out[n++] = b;
    return n;
}

/* Speech: a rounded body and a short tapered tail drawn as one shape. The
 * outline pass draws both a little larger in the edge colour, the fill pass
 * draws both on top, with the tail's root reaching into the body so no seam
 * shows where they meet. */
static void speech_shape(rect box, vec2 tip, color fill, color edge, bool tail)
{
    float r = minf(24, box.size.h * .42f);
    vec2 along, base = tail_base(box, tip, r, &along), dir = vec2_norm(vec2_sub(tip, base));
    float len = minf(TAIL_LEN, vec2_dist(base, tip));
    vec2 outline[12], body[12];
    int n = tail ? tail_shape(base, dir, along, len, TAIL_HALF, OUTLINE, outline) : 0;
    if (tail) tail_shape(base, dir, along, len, TAIL_HALF, 0, body);
    draw_shadow(rect_offset(box, v2(0, 6)), r + 4, 16, rgba(0, 0, 0, 60));
    draw_round_rect(rect_inflate(box, OUTLINE), r + OUTLINE, edge);
    if (tail) draw_poly(outline, n, edge);
    draw_round_rect(box, r, fill);
    if (tail) draw_poly(body, n, fill);
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
enum { SHOUT_POINTS = 140 };

/* Shared by paint and bounds: layout must use the actual spike tips, including
 * the wider rim, rather than the rounded rectangle underneath them. */
static int shout_outline(rect box, vec2 *body, vec2 *rim)
{
    const float mid = SHOUT_SPIKE * .5f;   /* spikes are spaced along their own middle line */
    float r = minf(box.size.h * .5f, 30);
    rect path = rect_inflate(box, mid);
    float around = 2 * (path.size.w + path.size.h - 4 * (r + mid)) + 2 * ENGINE_PI * (r + mid);
    int n = clampi((int)(around / 22) & ~1, 14, SHOUT_POINTS);
    for (int i = 0; i < n; i++) {
        vec2 normal, p = round_rect_at(path, r + mid, around * (i + .5f) / n, &normal);
        float spike = i % 2 ? 1 - mid : SHOUT_SPIKE - mid + 3 * sinf(i * 1.7f);
        body[i] = vec2_add(p, vec2_scale(normal, spike));
        rim[i] = vec2_add(body[i], vec2_scale(normal, OUTLINE * (i % 2 ? 1 : 1.6f)));
    }
    return n;
}

rect speech_bubble_bounds(rect box, bubble_kind kind)
{
    if (kind != BUBBLE_SHOUT) return rect_inflate(box, bubble_reach(kind, box));
    vec2 body[SHOUT_POINTS], rim[SHOUT_POINTS];
    int n = shout_outline(box, body, rim);
    vec2 lo = rim[0], hi = rim[0];
    for (int i = 1; i < n; i++) {
        lo.x = minf(lo.x, rim[i].x); lo.y = minf(lo.y, rim[i].y);
        hi.x = maxf(hi.x, rim[i].x); hi.y = maxf(hi.y, rim[i].y);
    }
    return rect_make(lo, sz2(hi.x - lo.x, hi.y - lo.y));
}

static void shout_shape(rect box, vec2 tip, color fill, color edge, bool tail)
{
    vec2 body[SHOUT_POINTS], rim[SHOUT_POINTS];
    int n = shout_outline(box, body, rim);
    float r = minf(box.size.h * .5f, 30);
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
    float alpha = tint.a / 255.f;
    draw_shadow(rect_offset(r, v2(0, 6)), 22, 16, color_alpha(rgba(0, 0, 0, 110), alpha));
    draw_round_rect(rect_inflate(r, 5), 22, color_alpha(color_lerp(S.style.edge, BLACK, 1 - tint.r / 255.f), alpha));
    draw_round_rect(r, 18, color_alpha(color_lerp(color_shade(c->color, .55f), BLACK, 1 - tint.r / 255.f), alpha));
    draw_image(c->portrait, rect_inflate(r, -3), tint);
    draw_round_rect_line(rect_inflate(r, 1), 19, 4, color_alpha(S.style.edge, alpha));
}

/* Entrance/exit own the slide. Speaking state owns colour only, so a
 * speaker/listener change cannot restart the slide or resize the portrait. */
static rect portrait_pose(const portrait_track *p)
{
    float slide = (1 - tween_value(p->visibility)) * p->bounds.size.w * .3f;
    return rect_offset(p->bounds, v2(p->who->right ? slide : -slide, 0));
}

static color portrait_tint(const portrait_track *p)
{
    return color_alpha(color_lerp(p->from_tint, p->to_tint, tween_value(p->blend)), tween_value(p->visibility));
}

static void portrait_target(portrait_track *p, color tint)
{
    if (!memcmp(&p->to_tint, &tint, sizeof tint)) return;
    p->from_tint = color_lerp(p->from_tint, p->to_tint, tween_value(p->blend));
    p->to_tint = tint;
    p->blend = (tween){.to=1, .duration=PORTRAIT_TIME};
}

static void portrait_stage(const character *who, rect r, bool active)
{
    color tint = active ? WHITE : rgba(120, 124, 132, 235);
    portrait_track *p = NULL;
    for (int i = 0; i < QUEUE; i++) if (S.portraits[i].who == who) { p = &S.portraits[i]; break; }
    if (!p) {
        for (int i = 0; i < QUEUE; i++) if (!S.portraits[i].who) { p = &S.portraits[i]; break; }
        if (!p) return;
        *p = (portrait_track){.who=who, .from_tint=tint, .to_tint=tint};
    }
    p->bounds = r;
    p->wanted = true;
    p->active = active;
    portrait_target(p, tint);
}

static void portraits_frame(float dt)
{
    for (int pass = 0; pass < 2; pass++) for (int i = 0; i < QUEUE; i++) {
        portrait_track *p = &S.portraits[i];
        if (!p->who || p->active != (pass == 1)) continue;
        tween_to(&p->visibility, p->wanted ? 1 : 0, PORTRAIT_TIME);
        tween_step(&p->visibility, dt);
        tween_step(&p->blend, dt);
        color tint = portrait_tint(p);
        if (tint.a) draw_portrait(p->who, portrait_pose(p), tint);
        if (!p->wanted && p->visibility.elapsed >= p->visibility.duration) *p = (portrait_track){0};
    }
}

#ifdef ENGINE_TEST
bool story_test_portrait(const character *who, rect *r, color *tint)
{
    for (int i = 0; i < QUEUE; i++) if (S.portraits[i].who == who) {
        portrait_track *p = &S.portraits[i];
        *r = portrait_pose(p);
        *tint = portrait_tint(p);
        return true;
    }
    return false;
}
#endif

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
    for (int i = 0; i < QUEUE; i++) S.portraits[i].wanted = false;
    if (!S.lines) {
        portraits_frame(dt);
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
    if (S.style.dim.a) {   /* the whole display dims, safe-area margins too */
        ui_modal_layer(S.style.backdrop_blur * in, color_alpha(S.style.dim, in));
    }
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
    float arrow = ts.size * .8f;   /* room for the "tap to continue" arrow after the last word */
    size2 body = text_box_size(ts, max_w - 2 * pad - arrow, text);
    float width = minf(max_w, maxf(body.w + 2 * pad + arrow, maxf(tag_w + 64, ts.size * 9)));
    float top_gap = vpad + (who ? tag * .35f : 0);
    float top_pad = top_gap, bottom_pad = vpad;
    float height = body.h + top_pad + bottom_pad;
    /* Puffs and spikes already provide padding outside the core rectangle.
     * Reserve only the remaining space inside it. Thought-puff radius depends
     * on height; this contraction converges below a pixel in eight passes. */
    for (int i = 0; i < 8; i++) {
        rect bounds = speech_bubble_bounds(rc(0, 0, width, height), kind);
        top_pad = maxf(4, top_gap + bounds.pos.y);
        bottom_pad = maxf(4, vpad - (rect_max(bounds).y - height));
        float next_height = body.h + top_pad + bottom_pad;
        if (fabsf(next_height - height) < .01f) { height = next_height; break; }
        height = next_height;
    }

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
        float y = mouth.y - height - 14;   /* the bubble's bottom just above the mouth */
        bubble = rc(clampf(x, m + reach, rect_max(screen).x - m - reach - width),
                    clampf(y, m + 50, rect_max(screen).y - m - reach - height), width, height);
        /* the tail leaves the bottom edge near the speaker and leans toward
         * their mouth; thought puffs trail further, a shout's spike a little */
        float drop = kind == BUBBLE_THOUGHT ? 46 : kind == BUBBLE_SHOUT ? 26 : TAIL_LEN;
        float near = who->right ? rect_max(bubble).x - 44 : bubble.pos.x + 44;
        tip = v2(near - side * 12, rect_max(bubble).y + drop);
        grow_from = tip;
    } else if (framed_narrow) {
        /* Build the phone's portrait/box unit first, then centre its complete
         * visible bounds below. The box stays sized to the phrase, with the
         * medallion above the speaker's end and no competing tail. */
        width = clampf(width, minf(face.w + 60, max_w), max_w);
        bubble = rect_anchor(v2(who->right ? rect_max(screen).x - m - reach : screen.pos.x + m + reach, rect_max(screen).y - m - reach),
                             sz2(width, height), v2(who->right ? 1 : 0, 1));
        portrait = rect_anchor(v2(who->right ? rect_max(screen).x - m - 5 : screen.pos.x + m + 5, speech_bubble_bounds(bubble, kind).pos.y - tag * .5f - 2),
                               face, v2(who->right ? 1 : 0, 1));
        tip = rect_center(bubble);
        grow_from = rect_point(bubble, v2(who->right ? 1 : 0, 0));
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
    rect listener_portrait = rc(0, 0, 0, 0), group = screen;
    if (listening) {
        listener_portrait = stand(listener, h);
        if (framed_narrow)   /* on the speaker's baseline, above the box */
            listener_portrait = rect_anchor(v2(listener->right ? rect_max(screen).x - m - 5 : screen.pos.x + m + 5,
                                               rect_max(portrait).y), listener_portrait.size, v2(listener->right ? 1 : 0, 1));
    }
    if (framed_narrow) {
        /* Centre the authored frame plus the actual puff/spike outline, not
         * just the bubble or a fixed-height placeholder. Safe areas are already
         * represented by app_screen(). Keep a listener in the same unit. */
        group = rect_union(rect_inflate(portrait, 5), speech_bubble_bounds(bubble, kind));
        if (listening) group = rect_union(group, rect_inflate(listener_portrait, 5));
        vec2 offset = vec2_sub(rect_center(screen), rect_center(group));
        portrait = rect_offset(portrait, offset);
        bubble = rect_offset(bubble, offset);
        listener_portrait = rect_offset(listener_portrait, offset);
        tip = vec2_add(tip, offset);
        grow_from = vec2_add(grow_from, offset);
        group = rect_offset(group, offset);
    }
    if (listening) portrait_stage(listener, listener_portrait, false);
    if (has_face) portrait_stage(who, portrait, true);
    portraits_frame(dt);

    /* the bubble springs out of its tail when a speaker arrives */
    float pop = lerpf(.55f, 1, ease_out_cubic(S.arrive / POP_TIME));
    rect drawn = scale_about(bubble, grow_from, pop);
    speech_bubble_shape(drawn, tip, S.style.bubble, S.style.edge, kind);

    float settle = saturate((S.arrive - POP_TIME * .5f) / (POP_TIME * .5f));
    if (who && settle > 0) {   /* name tag on the bubble's top edge, on the speaker's side */
        vec2 at = v2(who->right ? rect_max(bubble).x - 22 : bubble.pos.x + 22, speech_bubble_bounds(bubble, kind).pos.y);
        name_tag(who, vec2_add(at, v2(0, (1 - settle) * 6)), v2(who->right ? 1 : 0, .5f), tag);
    }
    rect inner = rc(bubble.pos.x + pad, bubble.pos.y + top_pad, bubble.size.w - 2 * pad - arrow, body.h);
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
        if (beside)   /* the bottom corner away from the speaker */
            pill = rect_anchor(v2(left ? screen.pos.x + m : rect_max(screen).x - m, rect_max(screen).y - m), pill.size, v2(left ? 0 : 1, 1));
        else if (framed_narrow)   /* travel with the unit; sit above it when a listener occupies the far end */
            pill = rect_anchor(v2(left ? group.pos.x : rect_max(group).x,
                                  listening ? group.pos.y - 12 : bubble.pos.y - 12 - reach), pill.size, v2(left ? 0 : 1, 1));
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
