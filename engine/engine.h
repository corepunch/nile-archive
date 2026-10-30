/*
 * engine.h — the one public header of the shared sprite engine.
 *
 * A small platform-based engine for 2D sprite games with a city-building meta-game:
 * value-type math, a letterboxed logical screen, pointer/touch gestures,
 * 2D cameras, shape drawing, styled TrueType text, an immediate-mode UI,
 * save files and a reusable "city" (economy, buildings, zones).
 *
 * Conventions
 *   - Plain C11. Small structs are passed and returned by value, so calls
 *     chain:  rect_inflate(rect_cut_top(&r, 64), -8)
 *   - Functions are prefixed by the type they work on: vec2_add, rect_center,
 *     camera_pan, purse_covers. Constructors are short: v2(), sz2(), rc().
 *   - Prefer vector operations over touching .x/.y by hand.
 *   - Zero-initialised structs are valid defaults wherever possible.
 *   - Engine state lives in the engine; games get read-only snapshots
 *     (input_get(), app_screen()) and mutate their own state.
 */
#ifndef ENGINE_H
#define ENGINE_H

#include "third_party/platform/platform.h"
#include <math.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ===================================================================== */
/* Math: value types                                                      */
/* ===================================================================== */

typedef struct { float x, y; } vec2;
typedef struct { float x, y, z; } vec3;
typedef struct { float w, h; } size2;
typedef struct { vec2 pos; size2 size; } rect;
typedef struct { uint8_t r, g, b, a; } color;

#define ENGINE_PI 3.14159265358979f

static inline float clampf(float v, float lo, float hi) { return v < lo ? lo : v > hi ? hi : v; }
static inline float saturate(float v) { return clampf(v, 0, 1); }
static inline float lerpf(float a, float b, float t) { return a + (b - a) * t; }
static inline float minf(float a, float b) { return a < b ? a : b; }
static inline float maxf(float a, float b) { return a > b ? a : b; }
static inline int clampi(int v, int lo, int hi) { return v < lo ? lo : v > hi ? hi : v; }
static inline float smoothstep(float a, float b, float v) { float t = saturate((v - a) / (b - a)); return t * t * (3 - 2 * t); }
/* Frame-rate independent exponential approach towards target. */
static inline float approachf(float cur, float target, float rate, float dt) { return target + (cur - target) * expf(-rate * dt); }

/* Easing curves, t in [0,1]. */
static inline float ease_out_cubic(float t) { t = 1 - saturate(t); return 1 - t * t * t; }
static inline float ease_in_cubic(float t) { t = saturate(t); return t * t * t; }
static inline float ease_in_out(float t) { t = saturate(t); return t < .5f ? 4 * t * t * t : 1 - powf(-2 * t + 2, 3) / 2; }
static inline float ease_out_back(float t) { const float c1 = 1.70158f, c3 = c1 + 1; t = saturate(t) - 1; return 1 + c3 * t * t * t + c1 * t * t; }
static inline float ease_out_bounce(float t)
{
    t = saturate(t);
    if (t < 1 / 2.75f) return 7.5625f * t * t;
    if (t < 2 / 2.75f) { t -= 1.5f / 2.75f; return 7.5625f * t * t + .75f; }
    if (t < 2.5f / 2.75f) { t -= 2.25f / 2.75f; return 7.5625f * t * t + .9375f; }
    t -= 2.625f / 2.75f;
    return 7.5625f * t * t + .984375f;
}

/* --- vec2 --- */
static inline vec2 v2(float x, float y) { return (vec2){x, y}; }
static inline vec2 v2s(float s) { return (vec2){s, s}; }
static inline vec2 vec2_add(vec2 a, vec2 b) { return v2(a.x + b.x, a.y + b.y); }
static inline vec2 vec2_sub(vec2 a, vec2 b) { return v2(a.x - b.x, a.y - b.y); }
static inline vec2 vec2_mul(vec2 a, vec2 b) { return v2(a.x * b.x, a.y * b.y); }
static inline vec2 vec2_div(vec2 a, vec2 b) { return v2(a.x / b.x, a.y / b.y); }
static inline vec2 vec2_scale(vec2 a, float s) { return v2(a.x * s, a.y * s); }
static inline vec2 vec2_neg(vec2 a) { return v2(-a.x, -a.y); }
static inline float vec2_dot(vec2 a, vec2 b) { return a.x * b.x + a.y * b.y; }
static inline float vec2_len(vec2 a) { return sqrtf(vec2_dot(a, a)); }
static inline float vec2_dist(vec2 a, vec2 b) { return vec2_len(vec2_sub(a, b)); }
static inline vec2 vec2_norm(vec2 a) { float l = vec2_len(a); return l > 0 ? vec2_scale(a, 1 / l) : a; }
static inline vec2 vec2_lerp(vec2 a, vec2 b, float t) { return v2(lerpf(a.x, b.x, t), lerpf(a.y, b.y, t)); }
static inline vec2 vec2_min(vec2 a, vec2 b) { return v2(minf(a.x, b.x), minf(a.y, b.y)); }
static inline vec2 vec2_max(vec2 a, vec2 b) { return v2(maxf(a.x, b.x), maxf(a.y, b.y)); }
static inline vec2 vec2_clamp(vec2 v, vec2 lo, vec2 hi) { return vec2_min(vec2_max(v, lo), hi); }
static inline vec2 vec2_round(vec2 a) { return v2(roundf(a.x), roundf(a.y)); }
static inline vec2 vec2_floor(vec2 a) { return v2(floorf(a.x), floorf(a.y)); }
static inline vec2 vec2_polar(float angle, float len) { return v2(cosf(angle) * len, sinf(angle) * len); }
static inline vec2 vec2_rotate(vec2 a, float angle) { float c = cosf(angle), s = sinf(angle); return v2(a.x * c - a.y * s, a.x * s + a.y * c); }
static inline vec2 vec2_approach(vec2 cur, vec2 target, float rate, float dt) { return vec2_lerp(target, cur, expf(-rate * dt)); }
/* Squared length of a in units of the ellipse radii r: <= 1 means inside. */
static inline float vec2_ellipse(vec2 a, vec2 r) { vec2 q = vec2_div(a, r); return vec2_dot(q, q); }

/* --- vec3 --- */
static inline vec3 v3(float x, float y, float z) { return (vec3){x, y, z}; }
static inline vec3 vec3_add(vec3 a, vec3 b) { return v3(a.x + b.x, a.y + b.y, a.z + b.z); }
static inline vec3 vec3_sub(vec3 a, vec3 b) { return v3(a.x - b.x, a.y - b.y, a.z - b.z); }
static inline vec3 vec3_scale(vec3 a, float s) { return v3(a.x * s, a.y * s, a.z * s); }
static inline float vec3_dot(vec3 a, vec3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
static inline vec3 vec3_cross(vec3 a, vec3 b) { return v3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x); }
static inline float vec3_len(vec3 a) { return sqrtf(vec3_dot(a, a)); }
static inline vec3 vec3_norm(vec3 a) { float l = vec3_len(a); return l > 0 ? vec3_scale(a, 1 / l) : a; }
static inline vec3 vec3_lerp(vec3 a, vec3 b, float t) { return v3(lerpf(a.x, b.x, t), lerpf(a.y, b.y, t), lerpf(a.z, b.z, t)); }
static inline vec2 vec3_xy(vec3 a) { return v2(a.x, a.y); }
/* Isometric projection: world (x, y on the ground, z up) to screen offset. */
static inline vec2 vec3_iso(vec3 a, size2 tile) { return v2((a.x - a.y) * tile.w * .5f, (a.x + a.y) * tile.h * .5f - a.z); }
static inline vec2 iso2(float x, float y, float z, size2 tile) { return vec3_iso(v3(x, y, z), tile); }

/* --- ivec2: integer grid coordinates --- */
typedef struct { int x, y; } ivec2;
static inline ivec2 iv2(int x, int y) { return (ivec2){x, y}; }
static inline ivec2 ivec2_add(ivec2 a, ivec2 b) { return iv2(a.x + b.x, a.y + b.y); }
static inline ivec2 ivec2_sub(ivec2 a, ivec2 b) { return iv2(a.x - b.x, a.y - b.y); }
static inline bool ivec2_eq(ivec2 a, ivec2 b) { return a.x == b.x && a.y == b.y; }
static inline int ivec2_manhattan(ivec2 a, ivec2 b) { return abs(a.x - b.x) + abs(a.y - b.y); }
static inline vec2 ivec2_vec(ivec2 a) { return v2((float)a.x, (float)a.y); }
static inline ivec2 vec2_ivec(vec2 a) { return iv2((int)floorf(a.x), (int)floorf(a.y)); }

/* --- size2 --- */
static inline size2 sz2(float w, float h) { return (size2){w, h}; }
static inline size2 sz2s(float s) { return (size2){s, s}; }
static inline vec2 size2_vec(size2 s) { return v2(s.w, s.h); }
static inline size2 size2_of(vec2 v) { return sz2(v.x, v.y); }
static inline size2 size2_scale(size2 s, float k) { return sz2(s.w * k, s.h * k); }
static inline size2 size2_add(size2 a, size2 b) { return sz2(a.w + b.w, a.h + b.h); }
static inline size2 size2_min(size2 a, size2 b) { return sz2(minf(a.w, b.w), minf(a.h, b.h)); }
static inline size2 size2_max(size2 a, size2 b) { return sz2(maxf(a.w, b.w), maxf(a.h, b.h)); }
static inline float size2_aspect(size2 s) { return s.h > 0 ? s.w / s.h : 1; }
/* Scale factor that fits `inner` entirely inside `outer` ("contain"). */
static inline float size2_fit(size2 inner, size2 outer) { return minf(outer.w / inner.w, outer.h / inner.h); }
/* Scale factor that makes `inner` fill all of `outer` ("cover"). */
static inline float size2_cover(size2 inner, size2 outer) { return maxf(outer.w / inner.w, outer.h / inner.h); }

/* --- rect --- */
static inline rect rc(float x, float y, float w, float h) { return (rect){{x, y}, {w, h}}; }
static inline rect rect_make(vec2 pos, size2 size) { return (rect){pos, size}; }
static inline rect rect_corners(vec2 a, vec2 b) { vec2 lo = vec2_min(a, b), hi = vec2_max(a, b); return rect_make(lo, size2_of(vec2_sub(hi, lo))); }
static inline vec2 rect_pos(rect r) { return r.pos; }
static inline size2 rect_size(rect r) { return r.size; }
static inline vec2 rect_max(rect r) { return vec2_add(r.pos, size2_vec(r.size)); }
/* Point at normalised coordinates inside r: (0,0) top-left, (1,1) bottom-right. */
static inline vec2 rect_point(rect r, vec2 uv) { return vec2_add(r.pos, vec2_mul(size2_vec(r.size), uv)); }
static inline vec2 rect_center(rect r) { return rect_point(r, v2(.5f, .5f)); }
/* Rect of `size` whose pivot (normalised) sits on `point`. */
static inline rect rect_anchor(vec2 point, size2 size, vec2 pivot) { return rect_make(vec2_sub(point, vec2_mul(size2_vec(size), pivot)), size); }
static inline rect rect_centered(vec2 center, size2 size) { return rect_anchor(center, size, v2(.5f, .5f)); }
/* Place `size` inside `outer` with normalised alignment (0.5,0.5 = centre). */
static inline rect rect_align(rect outer, size2 size, vec2 align) { return rect_anchor(rect_point(outer, align), size, align); }
static inline rect rect_offset(rect r, vec2 d) { return rect_make(vec2_add(r.pos, d), r.size); }
static inline rect rect_inflate(rect r, float d) { return rc(r.pos.x - d, r.pos.y - d, r.size.w + 2 * d, r.size.h + 2 * d); }
static inline rect rect_inflate2(rect r, vec2 d) { return rc(r.pos.x - d.x, r.pos.y - d.y, r.size.w + 2 * d.x, r.size.h + 2 * d.y); }
static inline rect rect_scale(rect r, float k) { return rect_centered(rect_center(r), size2_scale(r.size, k)); }
static inline rect rect_resize(rect r, size2 size, vec2 pivot) { return rect_anchor(rect_point(r, pivot), size, pivot); }
static inline rect rect_lerp(rect a, rect b, float t) { return rect_make(vec2_lerp(a.pos, b.pos, t), size2_of(vec2_lerp(size2_vec(a.size), size2_vec(b.size), t))); }
static inline rect rect_fit(rect outer, size2 inner) { return rect_centered(rect_center(outer), size2_scale(inner, size2_fit(inner, outer.size))); }
static inline bool rect_contains(rect r, vec2 p) { vec2 hi = rect_max(r); return p.x >= r.pos.x && p.y >= r.pos.y && p.x < hi.x && p.y < hi.y; }
static inline bool rect_overlaps(rect a, rect b) { vec2 ah = rect_max(a), bh = rect_max(b); return a.pos.x < bh.x && b.pos.x < ah.x && a.pos.y < bh.y && b.pos.y < ah.y; }
static inline rect rect_intersect(rect a, rect b) { vec2 lo = vec2_max(a.pos, b.pos), hi = vec2_max(lo, vec2_min(rect_max(a), rect_max(b))); return rect_corners(lo, hi); }
static inline rect rect_union(rect a, rect b) { return rect_corners(vec2_min(a.pos, b.pos), vec2_max(rect_max(a), rect_max(b))); }
static inline bool rect_ellipse_contains(rect r, vec2 p) { return vec2_ellipse(vec2_sub(p, rect_center(r)), vec2_scale(size2_vec(r.size), .5f)) <= 1; }

/* RectCut layout (https://halt76.notion.site/RectCut-for-dead-simple-UI-layouts):
 * each cut slices `a` units off one side of *r, shrinks *r and returns the slice. */
static inline rect rect_cut_left(rect *r, float a) { a = minf(a, r->size.w); rect s = rc(r->pos.x, r->pos.y, a, r->size.h); r->pos.x += a; r->size.w -= a; return s; }
static inline rect rect_cut_right(rect *r, float a) { a = minf(a, r->size.w); r->size.w -= a; return rc(r->pos.x + r->size.w, r->pos.y, a, r->size.h); }
static inline rect rect_cut_top(rect *r, float a) { a = minf(a, r->size.h); rect s = rc(r->pos.x, r->pos.y, r->size.w, a); r->pos.y += a; r->size.h -= a; return s; }
static inline rect rect_cut_bottom(rect *r, float a) { a = minf(a, r->size.h); r->size.h -= a; return rc(r->pos.x, r->pos.y + r->size.h, r->size.w, a); }
/* Non-destructive versions: the slice of r without changing r. */
static inline rect rect_left(rect r, float a) { return rect_cut_left(&r, a); }
static inline rect rect_right(rect r, float a) { return rect_cut_right(&r, a); }
static inline rect rect_top(rect r, float a) { return rect_cut_top(&r, a); }
static inline rect rect_bottom(rect r, float a) { return rect_cut_bottom(&r, a); }
/* Cell i of n equal columns / rows separated by gap. */
static inline rect rect_col(rect r, int n, int i, float gap) { float w = (r.size.w - gap * (n - 1)) / n; return rc(r.pos.x + i * (w + gap), r.pos.y, w, r.size.h); }
static inline rect rect_row(rect r, int n, int i, float gap) { float h = (r.size.h - gap * (n - 1)) / n; return rc(r.pos.x, r.pos.y + i * (h + gap), r.size.w, h); }

/* --- color --- */
static inline color rgba(int r, int g, int b, int a) { return (color){(uint8_t)r, (uint8_t)g, (uint8_t)b, (uint8_t)a}; }
static inline color hex(uint32_t rgb) { return rgba(rgb >> 16 & 255, rgb >> 8 & 255, rgb & 255, 255); }
static inline color color_alpha(color c, float a) { c.a = (uint8_t)(c.a * saturate(a)); return c; }
static inline color color_lerp(color a, color b, float t) { return rgba((int)lerpf(a.r, b.r, t), (int)lerpf(a.g, b.g, t), (int)lerpf(a.b, b.b, t), (int)lerpf(a.a, b.a, t)); }
static inline color color_shade(color c, float k) { return rgba((int)clampf(c.r * k, 0, 255), (int)clampf(c.g * k, 0, 255), (int)clampf(c.b * k, 0, 255), c.a); }
#define WHITE ((color){255, 255, 255, 255})
#define BLACK ((color){0, 0, 0, 255})
#define CLEAR ((color){0, 0, 0, 0})

/* Small deterministic RNG (xorshift32). */
typedef struct { uint32_t s; } rng;
static inline uint32_t rng_next(rng *r) { uint32_t x = r->s ? r->s : 0x9E3779B9u; x ^= x << 13; x ^= x >> 17; x ^= x << 5; return r->s = x; }
static inline int rng_int(rng *r, int n) { return n > 0 ? (int)(rng_next(r) % (uint32_t)n) : 0; }
static inline float rng_float(rng *r) { return (rng_next(r) >> 8) * (1.0f / 16777216.0f); }
static inline float rng_range(rng *r, float lo, float hi) { return lerpf(lo, hi, rng_float(r)); }

/* ===================================================================== */
/* App: window, logical screen, main loop                                 */
/* ===================================================================== */

typedef struct {
    const char *title;      /* window title */
    const char *id;         /* save namespace, e.g. "nile-archive" */
    size2 design;           /* design resolution; the logical screen keeps its short side */
    float max_aspect;       /* longest/shortest side ratio before letterboxing (0 = design) */
    bool landscape;         /* ask to rotate the device when the screen is portrait */
    bool fixed;             /* keep exactly the design resolution and letterbox the rest */
    const char *rotate_text;/* message for the rotate prompt */
    color clear;            /* clear / letterbox colour */
    const char *data_dir;   /* asset root for relative paths (overridden by --data) */
    void (*init)(void);
    void (*frame)(float dt);
    void (*quit)(void);
} app_desc;

/* Runs the game. Command line options understood by every game:
 *   --size WxH        window size            --fresh   ignore and never write saves
 *   --data DIR        asset root
 *   --shot file.png   render, save a screenshot and quit (after --frames N, default 3)
 * On the web the page's query string supplies them: ?fresh&tiles=jewels */
int app_run(app_desc desc, int argc, char **argv);
void app_quit(void);
rect app_screen(void);          /* logical screen, origin (0,0) */
float app_pixel_scale(void);    /* device pixels per logical unit */
double app_time(void);          /* seconds since start (frame time) */
float app_dt(void);             /* duration of the current frame, seconds */
double app_clock(void);         /* wall clock, seconds since the Unix epoch */
const char *app_arg(const char *name);  /* value after --name, "" for a bare flag, NULL if absent */
const char *app_path(const char *rel);  /* resolve an asset path against the data root */
void app_inject_click(vec2 p);          /* queue a press and release at a logical point (tests) */
const char *app_web_storage(const char *key);   /* localStorage[key] on the web, else NULL */

/* ===================================================================== */
/* Input: one pointer (mouse or first finger) with gestures               */
/* ===================================================================== */

typedef struct {
    vec2 pos;          /* pointer position, logical units */
    vec2 press_pos;    /* where the current/last press started */
    bool down;         /* held */
    bool pressed;      /* went down this frame */
    bool released;     /* went up this frame */
    bool tap;          /* released this frame without dragging */
    bool dragging;     /* moved further than the drag threshold */
    vec2 drag;         /* movement this frame while dragging */
    bool captured;     /* the press started on UI; the world should ignore it */
    bool hover;        /* a real mouse is over the window (desktop) */
    float wheel;       /* wheel steps this frame */
    float pinch;       /* zoom factor from two fingers this frame (1 = none) */
    vec2 pinch_center;
    int key;           /* AX key code pressed this frame, 0 if none */
    bool back;         /* Escape / Android back */
} input;

input input_get(void);
/* Same as input_get(), but with pointer actions cleared when UI owns the press. */
input input_world(void);

/* ===================================================================== */
/* Graphics                                                               */
/* ===================================================================== */

typedef struct { struct render_texture *tex; size2 size; } texture;

texture tex_load(const char *path);         /* PNG/JPG/BMP via stb_image */
texture tex_from_pixels(const void *rgba, int w, int h);
void tex_free(texture t);
rect tex_rect(texture t);                   /* (0,0,w,h) */
static inline size2 tex_size(texture t) { return t.size; }
void tex_additive(texture t, bool on);      /* additive instead of alpha blending when drawn */

void draw_image(texture t, rect dst, color tint);
void draw_image_part(texture t, rect src, rect dst, color tint);
void draw_image_rot(texture t, rect dst, float angle, color tint);
void draw_rect(rect r, color c);
void draw_rect_grad(rect r, color top, color bottom);
void draw_round_rect(rect r, float radius, color c);
void draw_round_rect_grad(rect r, float radius, color top, color bottom);
void draw_round_rect_line(rect r, float radius, float thickness, color c);
void draw_shadow(rect r, float radius, float blur, color c);
void draw_circle(vec2 center, float radius, color c);
void draw_ring(vec2 center, float radius, float thickness, color c);
void draw_glow(vec2 center, float radius, color inner, color outer);
void draw_line(vec2 a, vec2 b, float thickness, color c);
void draw_poly(const vec2 *pts, int n, color c);   /* convex polygon */
void draw_polyline(const vec2 *pts, int n, float thickness, color c);
void draw_ngon(vec2 center, float radius, int sides, float angle, color c);
void draw_star(vec2 center, float radius, float inner, int points, float angle, color c);  /* inner: ratio of radius */
/* Coloured triangles: one colour per vertex, three 0-based indices per triangle. */
void draw_mesh(const vec2 *pts, const color *cols, int n, const int *idx, int m);
void gfx_additive(bool on);   /* additive blending for shapes (glows, sparks) */
void gfx_clip(rect r);
void gfx_unclip(void);

/* --- 2D camera: a view rect on screen looking at a world of `world` size --- */
typedef struct {
    vec2 center;       /* world point at the middle of the view */
    float zoom;        /* screen units per world unit */
    rect view;         /* where the camera draws on screen */
    size2 world;       /* world bounds (0,0)-(w,h) */
    float min_zoom, max_zoom;
    bool cover;        /* never show outside the world (else centre small worlds) */
} camera;

vec2 camera_to_world(camera c, vec2 screen);
vec2 camera_to_screen(camera c, vec2 world);
rect camera_rect_to_screen(camera c, rect world);
rect camera_visible(camera c);                 /* world rect currently visible */
float camera_fit_zoom(camera c);               /* zoom at which the whole world fits */
camera camera_clamp(camera c);
camera camera_pan(camera c, vec2 screen_delta);
camera camera_zoom_at(camera c, float factor, vec2 screen_point);
camera camera_look(camera c, vec2 world_point);
camera camera_input(camera c, input in);       /* drag, wheel and pinch */
void camera_draw_texture(camera c, texture t); /* draw a world-sized backdrop */

/* Atlas animations use authored frames, pivots and timing. No game-specific drawing. */
typedef struct { rect source; vec2 pivot; } sprite_frame;
rect sprite_bounds(sprite_frame frame, vec2 anchor, float scale);
void sprite_draw(texture atlas, sprite_frame frame, vec2 anchor, float scale, color tint);
sprite_frame sprite_sample(const sprite_frame *frames, int count, float fps, double seconds);

/* Small dynamic route graphs. Blocker indices and ignored target are 0-based. */
#define NAV_NODES 768
#define NAV_BLOCKERS 128
#define NAV_PATH (NAV_NODES + 2)
typedef struct { vec2 pos; float radius; } nav_blocker;
typedef struct {
    vec2 nodes[NAV_NODES], path[NAV_PATH];
    nav_blocker blockers[NAV_BLOCKERS];
    int node_count, blocker_count, path_count;
    float link_distance, length;
} nav;
bool nav_find(nav *g, vec2 start, vec2 finish, int ignore, vec2 footprint);

/* --- particles and floating text, drawn in screen space --- */
void fx_burst(vec2 pos, int count, color c, float speed, float size);
struct text_style;
void fx_text(vec2 pos, const struct text_style *s, const char *utf8);  /* rises and fades */
void fx_text_at(vec2 pos, struct text_style s, const char *utf8);      /* the same, style by value */
void fx_sparkle(vec2 pos, float radius, color c);
void fx_update(float dt);
void fx_draw(void);
void fx_clear(void);

/* ===================================================================== */
/* Text: TrueType fonts with outline, gradient and shadow                 */
/* ===================================================================== */

typedef struct font font;

font *font_load(const char *path);
void font_set_fallback(font *f, font *fallback);

/* All fields optional except font and size; zero means "off" (fill defaults to white). */
typedef struct text_style {
    font *font;
    float size;          /* line height in logical units */
    color fill;          /* top colour */
    color fill2;         /* bottom colour for a vertical gradient (alpha 0 = flat fill) */
    color outline;
    float outline_width;
    color shadow;
    vec2 shadow_offset;
    float shadow_blur;
    float tracking;      /* extra letter spacing */
    float fade;          /* 0 = opaque .. 1 = invisible */
} text_style;

static inline text_style ts_size(text_style s, float size) { s.size = size; return s; }
static inline text_style ts_fill(text_style s, color c) { s.fill = c; s.fill2 = CLEAR; return s; }
static inline text_style ts_grad(text_style s, color top, color bottom) { s.fill = top; s.fill2 = bottom; return s; }
static inline text_style ts_outline(text_style s, float w, color c) { s.outline_width = w; s.outline = c; return s; }
static inline text_style ts_shadow(text_style s, vec2 off, float blur, color c) { s.shadow_offset = off; s.shadow_blur = blur; s.shadow = c; return s; }
static inline text_style ts_fade(text_style s, float fade) { s.fade = fade; return s; }

size2 text_measure(text_style s, const char *utf8);
/* Draw one line with its pivot (0,0 top-left .. 1,1 bottom-right) at pos; returns its rect. */
rect text_draw(text_style s, vec2 pos, vec2 pivot, const char *utf8);
/* Word-wrapped text aligned inside box, lines balanced in length; shrinks the
 * font (down to 60%) if it would not fit. */
rect text_box(text_style s, rect box, vec2 align, const char *utf8);
/* text_box showing only the first `visible` codepoints, every line already in
 * its final place: a typewriter that never re-wraps. */
rect text_box_reveal(text_style s, rect box, vec2 align, const char *utf8, int visible);
size2 text_box_size(text_style s, float width, const char *utf8);   /* wrapped size at that width */
int text_length(const char *utf8);                                   /* in codepoints */
/* Visible ink of one line, relative to where text_draw with pivot (0,0) puts its box. */
rect text_ink(text_style s, const char *utf8);
/* One line placed by its visible ink: aligned inside box and shrunk to fit it.
 * Optical centring for buttons, counters and badges. Returns the ink rect. */
rect text_in(text_style s, rect box, vec2 align, const char *utf8);
/* Single line that shrinks to fit the box width. */
rect text_fit(text_style s, rect box, vec2 align, const char *utf8);
/* Format into a rotating scratch buffer, handy for one-off labels. */
const char *fmt(const char *f, ...);

/* ===================================================================== */
/* Audio: a tiny synthesiser for UI and game sounds                       */
/* ===================================================================== */

void sfx_tone(float hz, float seconds);   /* a soft bell-like note */
void sfx_enable(bool on);
bool sfx_enabled(void);

/* ===================================================================== */
/* UI: immediate mode widgets                                             */
/* ===================================================================== */

typedef struct {
    text_style text, small, title, button, accent_text;
    color panel, panel2, border;           /* panel gradient + border */
    color button_bg, button_bg2, button_hot, button_border;
    color accent, accent2;                 /* "gold" primary buttons */
    color active;                          /* selection outline */
    color dim;                             /* modal backdrop */
    color toast_bg, toast_text;
    float radius;
} ui_theme;

enum {
    UI_ACCENT = 1 << 0,    /* primary call to action */
    UI_DISABLED = 1 << 1,
    UI_ACTIVE = 1 << 2,    /* selected / toggled on */
    UI_FLAT = 1 << 3,      /* no background */
};

typedef struct { bool hot, held, clicked; } ui_state;

void ui_set_theme(const ui_theme *t);
const ui_theme *ui_theme_get(void);
void ui_block(rect r);                     /* mark r as UI so world input ignores presses on it */
ui_state ui_hit(rect r, int flags);        /* raw interaction of an area */
void ui_panel(rect r);
void ui_panel_ex(rect r, color top, color bottom, color border, float radius);
ui_state ui_button_frame(rect r, int flags);  /* background only; draw your own content */
bool ui_button(rect r, const char *label, int flags);
void ui_label(rect r, text_style s, vec2 align, const char *utf8);
void ui_progress(rect r, float fraction, const char *label);
void ui_toast(const char *utf8);
/* Dim everything drawn so far and block input outside dialogs. Call before drawing a modal. */
void ui_modal_backdrop(float t);
/* While false, widgets draw but ignore input (e.g. under a modal). */
void ui_set_enabled(bool enabled);

/* ===================================================================== */
/* Save: one function both reads and writes ("serialize" visitor)         */
/* ===================================================================== */

typedef struct save save;
typedef void (*save_fn)(save *s, void *user);

bool save_read(const char *slot, save_fn fn, void *user);   /* false if no save exists */
bool save_write(const char *slot, save_fn fn, void *user);
bool save_is_reading(const save *s);
void save_int(save *s, const char *key, int *v);
void save_float(save *s, const char *key, float *v);
void save_double(save *s, const char *key, double *v);
void save_ints(save *s, const char *key, int *v, int n);
void save_vec2(save *s, const char *key, vec2 *v);
/* Use text produced elsewhere as the source of the next save_read (e.g. a migration). */
void save_inject(const char *slot, const char *text);

/* ===================================================================== */
/* Story: characters, dialogue and speech bubbles                         */
/* ===================================================================== */

typedef struct {
    const char *id;              /* how scripts refer to the character */
    const char *name, *role;
    const char *portrait_path;
    texture portrait;            /* loaded by story_setup */
    color color;                 /* name tag */
    bool right;                  /* stands on the right of the dialogue */
    vec2 mouth;                  /* where they speak from, 0..1 inside the portrait (default .5, .25) */
} character;

/* Speech bubbles come in the shapes comics use. */
typedef enum { BUBBLE_SPEECH, BUBBLE_THOUGHT, BUBBLE_SHOUT } bubble_kind;

typedef struct { const char *who, *text; bubble_kind kind; } story_line;   /* who: character id, NULL = narrator */

typedef struct {
    text_style text, name;       /* bubble text and name tag */
    color bubble, edge, dim;     /* bubble fill and rim, backdrop behind the dialogue */
    float portrait_height;       /* fraction of the screen height (default .5) */
    bool framed;                 /* portraits are busts: show them in a medallion */
    const char *skip;            /* label of a skip button, NULL for none */
} story_style;

/* The game's cast and how its dialogue looks; call once after loading fonts. */
void story_setup(character *cast, int count, const story_style *style);
const character *story_character(const char *id);
/* Queue a beat once per save: false (and nothing queued) if it was seen before. */
bool story_play(const char *beat, const story_line *lines, int count);
void story_say(const char *who, const char *text);        /* queue one spoken line, every time */
void story_line_add(story_line line);                      /* queue one line of any kind */
bool story_active(void);
void story_next(void);                                     /* move on, as a tap would after the line */
bool story_seen(const char *beat);
/* Draws the dialogue over everything and takes all input while it runs. Call
 * after the game's own UI (drawn with ui_set_enabled(!story_active())).
 * Staging follows Playrix and Wooga story screens: the speaker stands at the
 * screen edge with the bubble at face height and the tail on their mouth; the
 * previous speaker stays on the other side, dimmed, as the listener. */
void story_frame(float dt);
void story_serialize(save *s);
void story_forget(void);                                   /* new game: nothing seen */

/* A bubble around `box` pointing at `tip`: one outline around body and tail. */
void speech_bubble_shape(rect box, vec2 tip, color fill, color edge, bubble_kind kind);
/* A bubble with text, placed above `tip` (or below when there is no room), kept on screen. */
rect speech_bubble(vec2 tip, const char *utf8, text_style s, color fill, color edge, float max_width, bubble_kind kind);

/* ===================================================================== */
/* City: the shared building meta-game                                    */
/* ===================================================================== */

#define PURSE_MAX 6
#define CITY_MAX 160
#define CITY_ZONES 16

/* An amount of each resource; the game names the slots (coins, stars, ...). */
typedef struct { int v[PURSE_MAX]; } purse;

static inline purse purse_add(purse a, purse b) { for (int i = 0; i < PURSE_MAX; i++) a.v[i] += b.v[i]; return a; }
static inline purse purse_sub(purse a, purse b) { for (int i = 0; i < PURSE_MAX; i++) a.v[i] -= b.v[i]; return a; }
static inline purse purse_scale(purse a, int k) { for (int i = 0; i < PURSE_MAX; i++) a.v[i] *= k; return a; }
static inline bool purse_covers(purse have, purse need) { for (int i = 0; i < PURSE_MAX; i++) if (have.v[i] < need.v[i]) return false; return true; }
static inline bool purse_empty(purse a) { for (int i = 0; i < PURSE_MAX; i++) if (a.v[i]) return false; return true; }

typedef struct {
    const char *name;
    const char *about;
    const char *sprite_path;
    texture sprite;      /* loaded by city_init from sprite_path */
    float height;        /* drawn height in world units (width keeps the aspect)... */
    float width;         /* ...or, with height 0, the drawn width */
    float max_height;    /* cap for a height derived from width (0 = none) */
    float sink;          /* how far the sprite bottom sits below the anchor point */
    size2 footprint;     /* half extents of the ground diamond; zero = a circle of city.spacing */
    purse cost;          /* paid when placed */
    purse reward;        /* granted once when placed */
    purse needs;         /* must be owned (not spent) to build */
    purse income;        /* collected by tapping when ready */
    float income_period; /* seconds; 0 = no income */
} building_def;

typedef struct { vec2 pos; int type; double stamp; } building;

/* A region of the map that opens as a whole. `area` is used when the city has
 * no zone_at callback; `marker` is where games put its label. */
typedef struct { const char *name; rect area; vec2 marker; purse cost, needs; } city_zone;

typedef enum {
    CITY_NONE,
    CITY_BUILT,        /* a new building was placed and paid for */
    CITY_MOVED,        /* a building got a new place */
    CITY_BLOCKED,      /* the spot is not free, not land or not open */
    CITY_CANT_AFFORD,
    CITY_LOCKED_TYPE,  /* the building's `needs` are not met */
    CITY_COLLECTED,    /* income collected */
    CITY_NOT_READY,    /* tapped a building whose income is still growing */
    CITY_PICKED,       /* tapped a building without income */
    CITY_ZONE,         /* tapped land in a closed zone (event.zone) */
} city_result;

typedef struct {
    city_result result;
    int building;        /* index of the building involved, or -1 */
    int zone;            /* zone involved, or -1 */
    purse amount;        /* paid or collected */
    vec2 screen;         /* where it happened */
} city_event;

typedef struct city {
    texture ground;
    building_def *defs;
    int def_count;
    building items[CITY_MAX];
    int count;
    city_zone zones[CITY_ZONES];
    int zone_count;
    unsigned open;                          /* bit per opened zone; zone 0 starts open */
    float spacing;                          /* minimum distance between buildings without footprints */
    size2 footprint_gap;                    /* extra clearance between footprints */
    bool (*buildable)(const struct city *c, vec2 world);   /* terrain test supplied by the game */
    int (*zone_at)(const struct city *c, vec2 world);      /* region lookup (default: zone rects); -1 = none */
    bool (*zone_touches)(const struct city *c, int zone, unsigned open);  /* adjacency (default: rects touching) */
    void (*draw_over)(const struct city *c);        /* game drawing above the fog, below the ghost */
    camera cam;
    color fog;                              /* locked zones; default dark teal */
    bool fog_on_land_only;                  /* fog only where buildable() */
    color path;                             /* paths linking buildings; alpha 0 = none */
    bool movable;                           /* drag a building to move it */
    texture income_icon;                    /* bubble shown over buildings with income ready */
    int selected;                           /* quick build: tap places this type at once (-1 = off) */

    /* placement session, driven by city_begin_place/move, city_confirm and city_cancel */
    int placing;                            /* building type being placed, -1 = none */
    int moving;                             /* index being moved, -1 = a new building */
    vec2 ghost;                             /* where it would go */

    /* engine bookkeeping */
    int press_target;                       /* 0 nothing, 1 ghost, 2 + index of a building */
    vec2 grab;
    int pop_index;
    float pop_time;
} city;

void city_init(city *c, const char *ground_path);
bool city_can_place(const city *c, vec2 world, int type, int ignore);   /* ignore: index to skip, or -1 */
bool city_find_spot(const city *c, int type, vec2 hint, vec2 *out);     /* nearest free spot to hint */
int city_add(city *c, vec2 world, int type, double now);                /* no checks; returns index or -1 */
int city_building_at(const city *c, vec2 world);
bool city_ready(const city *c, int index, double now);
rect city_sprite_rect(const city *c, building b);                       /* world rect of a building's sprite */

int city_zone_at(const city *c, vec2 world);
bool city_zone_open(const city *c, int zone);
int city_open_count(const city *c);
bool city_zone_available(const city *c, int zone, purse wallet);        /* closed, touching, affordable */
bool city_unlock(city *c, int zone, purse *wallet);
int city_next_zone(const city *c, purse wallet);   /* first available zone, else first closed touching one, else -1 */

void city_begin_place(city *c, int type, vec2 at);
void city_begin_move(city *c, int index);
void city_cancel(city *c);
city_event city_confirm(city *c, purse *wallet, double now);

/* Camera, gestures, quick build and collecting. `wallet` pays and receives. */
city_event city_update(city *c, input in, purse *wallet, double now, float dt);
void city_draw(const city *c, input in, double now);
void city_serialize(city *c, save *s);

/* ===================================================================== */
/* Script: games written in Lua (see docs/SCRIPTING.md)                   */
/* ===================================================================== */

/* Create the game's Lua state: the engine API (engine/api.xml), a sandboxed
 * standard library and `require` resolving against lua_dir (several roots
 * separated by ';' are searched in order). */
void script_open(const char *lua_dir);
/* Run lua_dir/main.lua, which returns the app descriptor; its init, frame and
 * quit become Lua calls. data_dir and id are filled in when the script
 * leaves them out. Errors are printed and end the process with status 3. */
app_desc script_boot(const char *lua_dir, const char *data_dir);
/* Run one file in the open state; the integer it returns, 0 if none, -1 on error. */
int script_dofile(const char *path);
void script_close(void);

/* ===================================================================== */
/* Engine internals shared by the engine sources (not for games)          */
/* ===================================================================== */

const char *app_id(void);
void ui_begin_frame(void);
void ui_end_frame(float dt);
bool ui_blocks(vec2 p);

#ifdef __cplusplus
}
#endif
#endif
