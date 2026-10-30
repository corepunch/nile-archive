/* gfx.c — textures, anti-aliased shapes, 2D camera, particles. */
#include "render.h"

#include <stdio.h>
#include <string.h>

#define STB_IMAGE_IMPLEMENTATION
#define STBI_ONLY_PNG
#define STBI_ONLY_JPEG
#define STBI_ONLY_BMP
#include "third_party/stb_image.h"

/* ---------------------------------------------------------------- textures */

texture tex_from_pixels(const void *rgba, int w, int h)
{
    texture t = {0};
    t.tex = render_texture_create(w, h, rgba);
    if (!t.tex) return t;
    t.size = sz2((float)w, (float)h);
    return t;
}

texture tex_load(const char *path)
{
    int w, h, n;
    if (!render_ready()) return (texture){0};   /* headless (tests): nothing to draw with */
    const char *full = app_path(path);
    unsigned char *px = stbi_load(full, &w, &h, &n, 4);
    if (!px) {
        fprintf(stderr, "tex_load: %s: %s\n", full, stbi_failure_reason());
        return (texture){0};
    }
    texture t = tex_from_pixels(px, w, h);
    stbi_image_free(px);
    return t;
}

void tex_free(texture t)
{
    render_texture_free(t.tex);
}

rect tex_rect(texture t) { return rect_make(v2(0, 0), t.size); }

void draw_image_part(texture t, rect src, rect dst, color c)
{
    render_image(t, src, dst, 0, c);
}

void draw_image(texture t, rect dst, color c)
{
    render_image(t, tex_rect(t), dst, 0, c);
}

void draw_image_rot(texture t, rect dst, float angle, color c)
{
    render_image(t, tex_rect(t), dst, angle, c);
}

/* ------------------------------------------------------------------ shapes */

/* Shapes are triangle meshes drawn with render_geometry. Every outline gets
 * a one-device-pixel "feather" ring that fades to transparent: cheap AA. */

#define MAX_PATH 160
#define MAX_VERTS 4096

static render_vertex verts[MAX_VERTS];
static int vert_count;


static void flush(void)
{
    if (vert_count) render_geometry(NULL, verts, vert_count, NULL, 0);
    vert_count = 0;
}

static void vert(vec2 p, color c)
{
    if (vert_count >= MAX_VERTS) return;
    verts[vert_count++] = (render_vertex){{p.x, p.y}, c, {0, 0}};
}

static void tri(vec2 a, color ca, vec2 b, color cb, vec2 c, color cc)
{
    if (vert_count + 3 > MAX_VERTS) flush();
    vert(a, ca);
    vert(b, cb);
    vert(c, cc);
}

static void quad(vec2 a, color ca, vec2 b, color cb, vec2 c, color cc, vec2 d, color cd)
{
    tri(a, ca, b, cb, c, cc);
    tri(a, ca, c, cc, d, cd);
}

static float feather(void) { return 1.0f / maxf(app_pixel_scale(), .25f); }

static int arc_segments(float radius)
{
    return clampi((int)(radius * app_pixel_scale() / 3), 2, 24);
}

/* Perimeter of a rounded rect, clockwise from the top-left corner. */
static int round_rect_path(rect r, float radius, vec2 *out)
{
    radius = clampf(radius, 0, minf(r.size.w, r.size.h) * .5f);
    if (radius <= 0) {
        out[0] = r.pos;
        out[1] = rect_point(r, v2(1, 0));
        out[2] = rect_max(r);
        out[3] = rect_point(r, v2(0, 1));
        return 4;
    }
    int seg = arc_segments(radius), n = 0;
    rect inner = rect_inflate(r, -radius);
    const vec2 corners[4] = {{0, 0}, {1, 0}, {1, 1}, {0, 1}};
    for (int c = 0; c < 4; c++) {
        vec2 center = rect_point(inner, corners[c]);
        float a0 = ENGINE_PI * (1 + c * .5f);
        for (int i = 0; i <= seg; i++) {
            vec2 q = vec2_add(center, vec2_polar(a0 + ENGINE_PI * .5f * i / seg, radius));
            if (n == 0 || vec2_dist(q, out[n - 1]) > .01f) out[n++] = q;   /* skip duplicates on pill shapes */
        }
    }
    if (n > 1 && vec2_dist(out[0], out[n - 1]) <= .01f) n--;
    return n;
}

static int circle_path(vec2 center, float radius, vec2 *out)
{
    int n = clampi((int)(radius * app_pixel_scale() * .8f), 12, MAX_PATH - 1);
    for (int i = 0; i < n; i++) out[i] = vec2_add(center, vec2_polar(2 * ENGINE_PI * i / n, radius));
    return n;
}

static vec2 path_normal(const vec2 *p, int n, int i)
{
    vec2 a = p[(i + n - 1) % n], b = p[i], c = p[(i + 1) % n];
    vec2 e0 = vec2_norm(vec2_sub(b, a)), e1 = vec2_norm(vec2_sub(c, b));
    vec2 nrm = vec2_norm(vec2_add(v2(e0.y, -e0.x), v2(e1.y, -e1.x)));
    float d = vec2_dot(nrm, v2(e1.y, -e1.x));
    return vec2_scale(nrm, 1 / maxf(d, .3f));
}

typedef struct { color top, bottom; float y0, y1; } grad;

static color grad_at(grad g, vec2 p) { return color_lerp(g.top, g.bottom, g.y1 > g.y0 ? saturate((p.y - g.y0) / (g.y1 - g.y0)) : 0); }

/* Fill a convex path; `soft` is the width of the outer fade (feather or blur). */
static void fill_path(const vec2 *p, int n, grad g, float soft)
{
    vec2 center = v2(0, 0);
    for (int i = 0; i < n; i++) center = vec2_add(center, p[i]);
    center = vec2_scale(center, 1.0f / n);
    color cc = grad_at(g, center);
    for (int i = 0; i < n; i++) {
        int j = (i + 1) % n;
        tri(center, cc, p[i], grad_at(g, p[i]), p[j], grad_at(g, p[j]));
        vec2 oi = vec2_add(p[i], vec2_scale(path_normal(p, n, i), soft));
        vec2 oj = vec2_add(p[j], vec2_scale(path_normal(p, n, j), soft));
        quad(p[i], grad_at(g, p[i]), oi, color_alpha(grad_at(g, oi), 0), oj, color_alpha(grad_at(g, oj), 0), p[j], grad_at(g, p[j]));
    }
    flush();
}

/* Stroke a closed convex path centred on its outline. */
static void stroke_path(const vec2 *p, int n, float thickness, color c)
{
    float f = feather(), h = thickness * .5f;
    color t = color_alpha(c, 0);
    for (int i = 0; i < n; i++) {
        int j = (i + 1) % n;
        vec2 ni = path_normal(p, n, i), nj = path_normal(p, n, j);
        vec2 ai = vec2_add(p[i], vec2_scale(ni, -h - f)), bi = vec2_add(p[i], vec2_scale(ni, -h));
        vec2 ci = vec2_add(p[i], vec2_scale(ni, h)), di = vec2_add(p[i], vec2_scale(ni, h + f));
        vec2 aj = vec2_add(p[j], vec2_scale(nj, -h - f)), bj = vec2_add(p[j], vec2_scale(nj, -h));
        vec2 cj = vec2_add(p[j], vec2_scale(nj, h)), dj = vec2_add(p[j], vec2_scale(nj, h + f));
        quad(ai, t, bi, c, bj, c, aj, t);
        quad(bi, c, ci, c, cj, c, bj, c);
        quad(ci, c, di, t, dj, t, cj, c);
    }
    flush();
}

void draw_rect(rect r, color c)
{
    quad(r.pos, c, rect_point(r, v2(1, 0)), c, rect_max(r), c, rect_point(r, v2(0, 1)), c);
    flush();
}

void draw_rect_grad(rect r, color top, color bottom)
{
    vec2 a = r.pos, b = rect_point(r, v2(1, 0)), c = rect_max(r), d = rect_point(r, v2(0, 1));
    quad(a, top, b, top, c, bottom, d, bottom);
    flush();
}

void draw_round_rect_grad(rect r, float radius, color top, color bottom)
{
    vec2 p[MAX_PATH];
    int n = round_rect_path(r, radius, p);
    fill_path(p, n, (grad){top, bottom, r.pos.y, rect_max(r).y}, feather());
}

void draw_round_rect(rect r, float radius, color c) { draw_round_rect_grad(r, radius, c, c); }

void draw_round_rect_line(rect r, float radius, float thickness, color c)
{
    vec2 p[MAX_PATH];
    stroke_path(p, round_rect_path(r, radius, p), thickness, c);
}

void draw_shadow(rect r, float radius, float blur, color c)
{
    vec2 p[MAX_PATH];
    rect inner = rect_inflate(r, -blur * .5f);
    int n = round_rect_path(inner, maxf(0, radius - blur * .5f), p);
    fill_path(p, n, (grad){c, c, 0, 0}, blur);
}

void draw_circle(vec2 center, float radius, color c)
{
    vec2 p[MAX_PATH];
    fill_path(p, circle_path(center, radius, p), (grad){c, c, 0, 0}, feather());
}

void draw_ring(vec2 center, float radius, float thickness, color c)
{
    vec2 p[MAX_PATH];
    stroke_path(p, circle_path(center, radius, p), thickness, c);
}

void draw_glow(vec2 center, float radius, color inner, color outer)
{
    vec2 p[MAX_PATH];
    int n = circle_path(center, radius, p);
    for (int i = 0; i < n; i++) tri(center, inner, p[i], outer, p[(i + 1) % n], outer);
    flush();
}

void draw_line(vec2 a, vec2 b, float thickness, color c)
{
    vec2 d = vec2_norm(vec2_sub(b, a)), n = v2(-d.y, d.x);
    float f = feather(), h = thickness * .5f;
    color t = color_alpha(c, 0);
    vec2 o1 = vec2_scale(n, h), o2 = vec2_scale(n, h + f);
    quad(vec2_sub(a, o2), t, vec2_sub(a, o1), c, vec2_sub(b, o1), c, vec2_sub(b, o2), t);
    quad(vec2_sub(a, o1), c, vec2_add(a, o1), c, vec2_add(b, o1), c, vec2_sub(b, o1), c);
    quad(vec2_add(a, o1), c, vec2_add(a, o2), t, vec2_add(b, o2), t, vec2_add(b, o1), c);
    flush();
}

void draw_poly(const vec2 *pts, int n, color c)
{
    if (n < 3 || n > MAX_PATH) return;
    fill_path(pts, n, (grad){c, c, 0, 0}, feather());
}

void draw_polyline(const vec2 *pts, int n, float thickness, color c)
{
    float h = thickness * .5f;
    for (int i = 0; i + 1 < n; i++) {
        vec2 d = vec2_norm(vec2_sub(pts[i + 1], pts[i])), o = vec2_scale(v2(-d.y, d.x), h);
        quad(vec2_add(pts[i], o), c, vec2_add(pts[i + 1], o), c, vec2_sub(pts[i + 1], o), c, vec2_sub(pts[i], o), c);
        if (i + 2 < n) {   /* round the joint with a small fan so bends stay solid */
            vec2 d2 = vec2_norm(vec2_sub(pts[i + 2], pts[i + 1])), o2 = vec2_scale(v2(-d2.y, d2.x), h);
            tri(pts[i + 1], c, vec2_add(pts[i + 1], o), c, vec2_add(pts[i + 1], o2), c);
            tri(pts[i + 1], c, vec2_sub(pts[i + 1], o), c, vec2_sub(pts[i + 1], o2), c);
        }
    }
    flush();
}

void draw_ngon(vec2 center, float radius, int sides, float angle, color c)
{
    vec2 p[MAX_PATH];
    sides = clampi(sides, 3, MAX_PATH - 1);
    for (int i = 0; i < sides; i++) p[i] = vec2_add(center, vec2_polar(angle + 2 * ENGINE_PI * i / sides, radius));
    fill_path(p, sides, (grad){c, c, 0, 0}, feather());
}

void draw_star(vec2 center, float radius, float inner, int points, float angle, color c)
{
    points = clampi(points, 2, 32);
    for (int i = 0; i < points * 2; i++) {
        float a0 = angle + ENGINE_PI * i / points, a1 = angle + ENGINE_PI * (i + 1) / points;
        float r0 = i % 2 ? radius * inner : radius, r1 = i % 2 ? radius : radius * inner;
        tri(center, c, vec2_add(center, vec2_polar(a0, r0)), c, vec2_add(center, vec2_polar(a1, r1)), c);
    }
    flush();
}

void tex_additive(texture t, bool on)
{
    render_texture_additive(t.tex, on);
}

void draw_mesh(const vec2 *pts, const color *cols, int n, const int *idx, int m)
{
    render_vertex v[256];
    if (n <= 0 || n > 256) return;
    for (int i = 0; i < n; i++) v[i] = (render_vertex){{pts[i].x, pts[i].y}, {cols[i].r, cols[i].g, cols[i].b, cols[i].a}, {0, 0}};
    for (int i = 0; i < m; i++)
        if (idx[i] < 0 || idx[i] >= n) return;
    render_geometry(NULL, v, n, idx, m);
}

void gfx_additive(bool on) { render_additive(on); }

void gfx_clip(rect r)
{
    render_clip(&r);
}

void gfx_unclip(void) { render_clip(NULL); }
void gfx_bleed(bool on) { render_bleed(on); }

/* ------------------------------------------------------------------ camera */

vec2 camera_to_world(camera c, vec2 s) { return vec2_add(c.center, vec2_scale(vec2_sub(s, rect_center(c.view)), 1 / c.zoom)); }
vec2 camera_to_screen(camera c, vec2 w) { return vec2_add(rect_center(c.view), vec2_scale(vec2_sub(w, c.center), c.zoom)); }
rect camera_rect_to_screen(camera c, rect w) { return rect_make(camera_to_screen(c, w.pos), size2_scale(w.size, c.zoom)); }
rect camera_visible(camera c) { return rect_centered(c.center, size2_scale(c.view.size, 1 / c.zoom)); }
float camera_fit_zoom(camera c) { return size2_fit(c.world, c.view.size); }

static float clamp_axis(float center, float half, float world)
{
    return 2 * half >= world ? world * .5f : clampf(center, half, world - half);
}

camera camera_clamp(camera c)
{
    if (c.world.w <= 0 || c.world.h <= 0 || c.view.size.w <= 0) return c;
    float lo = maxf(c.min_zoom, c.cover ? size2_cover(c.world, c.view.size) : 0);
    float hi = maxf(c.max_zoom, lo);
    c.zoom = clampf(c.zoom > 0 ? c.zoom : lo, lo, hi);
    size2 half = size2_scale(c.view.size, .5f / c.zoom);
    c.center = v2(clamp_axis(c.center.x, half.w, c.world.w), clamp_axis(c.center.y, half.h, c.world.h));
    return c;
}

camera camera_pan(camera c, vec2 screen_delta)
{
    c.center = vec2_sub(c.center, vec2_scale(screen_delta, 1 / c.zoom));
    return camera_clamp(c);
}

camera camera_zoom_at(camera c, float factor, vec2 p)
{
    vec2 anchor = camera_to_world(c, p);
    c.zoom *= factor;
    c = camera_clamp(c);
    c.center = vec2_sub(anchor, vec2_scale(vec2_sub(p, rect_center(c.view)), 1 / c.zoom));
    return camera_clamp(c);
}

camera camera_look(camera c, vec2 world_point)
{
    c.center = world_point;
    return camera_clamp(c);
}

camera camera_input(camera c, input in)
{
    if (in.captured) return c;
    if (in.dragging && rect_contains(c.view, in.press_pos)) c = camera_pan(c, in.drag);
    if (in.wheel != 0 && rect_contains(c.view, in.pos)) c = camera_zoom_at(c, powf(1.15f, in.wheel), in.pos);
    if (in.pinch != 1 && rect_contains(c.view, in.pinch_center)) c = camera_zoom_at(c, in.pinch, in.pinch_center);
    return c;
}

void camera_draw_texture(camera c, texture t)
{
    if (!t.tex) return;
    rect src = rect_intersect(camera_visible(c), rect_make(v2(0, 0), c.world));
    vec2 k = vec2_div(size2_vec(t.size), size2_vec(c.world));   /* texture may differ from world size */
    rect tex_src = rect_make(vec2_mul(src.pos, k), size2_of(vec2_mul(size2_vec(src.size), k)));
    draw_image_part(t, tex_src, camera_rect_to_screen(c, src), WHITE);
}

/* --------------------------------------------------------------- particles */

#define MAX_PARTICLES 768
#define MAX_FLOATERS 24

typedef struct { vec2 pos, vel; float life, max_life, size; color c; bool star; } particle;
typedef struct { vec2 pos; float life; text_style style; char text[64]; } floater;

static particle parts[MAX_PARTICLES];
static floater floaters[MAX_FLOATERS];
static rng fx_rng = {0x51ED1u};

static particle *spawn(void)
{
    particle *best = &parts[0];
    for (int i = 0; i < MAX_PARTICLES; i++) {
        if (parts[i].life <= 0) return &parts[i];
        if (parts[i].life < best->life) best = &parts[i];
    }
    return best;
}

void fx_burst(vec2 pos, int count, color c, float speed, float size)
{
    for (int i = 0; i < count; i++) {
        particle *p = spawn();
        float a = rng_range(&fx_rng, 0, 2 * ENGINE_PI);
        *p = (particle){pos, vec2_polar(a, speed * rng_range(&fx_rng, .3f, 1)), 0, 0, size * rng_range(&fx_rng, .5f, 1.2f), c, false};
        p->life = p->max_life = rng_range(&fx_rng, .45f, .9f);
    }
}

void fx_sparkle(vec2 pos, float radius, color c)
{
    for (int i = 0; i < 10; i++) {
        particle *p = spawn();
        float a = 2 * ENGINE_PI * i / 10 + rng_range(&fx_rng, -.2f, .2f);
        *p = (particle){vec2_add(pos, vec2_polar(a, radius * .6f)), vec2_polar(a, radius * 1.2f), 0, 0,
                        radius * rng_range(&fx_rng, .12f, .22f), c, true};
        p->life = p->max_life = rng_range(&fx_rng, .5f, .8f);
    }
}

void fx_text(vec2 pos, const text_style *s, const char *utf8)
{
    floater *f = &floaters[0];
    for (int i = 0; i < MAX_FLOATERS; i++)
        if (floaters[i].life < f->life) f = &floaters[i];
    f->pos = pos;
    f->life = 1;
    f->style = *s;
    snprintf(f->text, sizeof f->text, "%s", utf8);
}

void fx_update(float dt)
{
    for (int i = 0; i < MAX_PARTICLES; i++) {
        particle *p = &parts[i];
        if (p->life <= 0) continue;
        p->life -= dt;
        p->pos = vec2_add(p->pos, vec2_scale(p->vel, dt));
        p->vel = vec2_add(vec2_scale(p->vel, expf(-2.5f * dt)), v2(0, p->star ? 0 : 220 * dt));
    }
    for (int i = 0; i < MAX_FLOATERS; i++)
        if (floaters[i].life > 0) {
            floaters[i].life -= dt * .8f;
            floaters[i].pos = vec2_add(floaters[i].pos, v2(0, -60 * dt));
        }
}

void fx_draw(void)
{
    render_additive(true);
    for (int i = 0; i < MAX_PARTICLES; i++) {
        particle *p = &parts[i];
        if (p->life <= 0) continue;
        float t = p->life / p->max_life, s = p->size * (p->star ? sinf(t * ENGINE_PI) : .4f + .6f * t);
        color c = color_alpha(p->c, t);
        if (p->star) {
            draw_line(vec2_sub(p->pos, v2(s, 0)), vec2_add(p->pos, v2(s, 0)), s * .25f, c);
            draw_line(vec2_sub(p->pos, v2(0, s)), vec2_add(p->pos, v2(0, s)), s * .25f, c);
        }
        draw_glow(p->pos, s, c, color_alpha(c, 0));
    }
    render_additive(false);
    for (int i = 0; i < MAX_FLOATERS; i++) {
        floater *f = &floaters[i];
        if (f->life <= 0) continue;
        float pop = ease_out_back(saturate((1 - f->life) * 5));
        text_draw(ts_fade(ts_size(f->style, f->style.size * pop), 1 - saturate(f->life * 3)), f->pos, v2(.5f, .5f), f->text);
    }
}

void fx_text_at(vec2 pos, text_style s, const char *utf8) { fx_text(pos, &s, utf8); }

void fx_clear(void)
{
    memset(parts, 0, sizeof parts);
    memset(floaters, 0, sizeof floaters);
}
