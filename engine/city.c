/* city.c — the shared city-building meta-game.
 *
 * A city is a large ground texture split into zones that open as wholes, a
 * catalogue of building types (cost, one-off reward, requirements, timed
 * income) and the placed buildings. Games plug in their terrain (`buildable`)
 * and, optionally, their own region map (`zone_at`, `zone_touches`); they
 * decide what the resources mean. The city handles the camera, placement
 * (instant or with a confirmable ghost), moving buildings, depth-sorted
 * drawing, soft fog over closed zones (under the buildings), decorative
 * paths, income and saving. */
#include "render.h"

#include <stdio.h>
#include <string.h>

/* ------------------------------------------------------------------- tiles */

/* Tile coordinates: u runs down-right, v down-left, one unit per tile; tile
 * centres are whole numbers. */
static float tile_w(const city *c) { return c->tile.w > 0 ? c->tile.w : 32; }
static float tile_h(const city *c) { return c->tile.h > 0 ? c->tile.h : 16; }

static vec2 to_tile(const city *c, vec2 p)
{
    float x = p.x / tile_w(c), y = p.y / tile_h(c);
    return v2((x + y) * .5f, (y - x) * .5f);
}

static vec2 from_tile(const city *c, vec2 t) { return v2((t.x - t.y) * tile_w(c), (t.x + t.y) * tile_h(c)); }

/* Footprint in tiles: the base plus the city's clearance; a building without
 * a size counts as one tile. */
static size2 tiles_of(const city *c, int type)
{
    size2 s = type >= 0 && type < c->def_count ? c->defs[type].size : sz2(0, 0);
    return s.w > 0 && s.h > 0 ? size2_add(s, c->clearance) : sz2(1, 1);
}

vec2 city_snap(const city *c, vec2 p, int type)
{
    size2 s = tiles_of(c, type);
    vec2 half = v2((s.w - 1) * .5f, (s.h - 1) * .5f);   /* even sides centre on a tile edge */
    vec2 t = vec2_sub(to_tile(c, p), half);
    return from_tile(c, vec2_add(v2(roundf(t.x), roundf(t.y)), half));
}

void city_init(city *c, const char *ground_path)
{
    if (ground_path) c->ground = tex_load(ground_path);
    if (c->cam.world.w <= 0) c->cam.world = c->ground.size;
    if (c->cam.max_zoom <= 0) c->cam.max_zoom = 2;
    if (c->cam.zoom <= 0) c->cam.zoom = 1;
    if (c->spacing <= 0) c->spacing = 100;
    if (c->fog.a == 0) c->fog = rgba(13, 46, 49, 155);
    c->open |= 1;
    c->selected = c->placing = c->moving = c->pop_index = -1;
    for (int i = 0; i < c->def_count; i++) {
        building_def *d = &c->defs[i];
        if (d->sprite_path && !d->sprite.tex) d->sprite = tex_load(d->sprite_path);
        size2 tex = d->sprite.size;
        if (tex.h <= 0) continue;
        if (d->pivot.x == 0 && d->pivot.y == 0) d->pivot = v2(tex.w * .5f, tex.h);
        /* the footprint's left-to-right corners span size.w + size.h tile half widths */
        if (d->base_width > 0 && d->size.w > 0) d->height = tex.h * (d->size.w + d->size.h) * tile_w(c) / d->base_width;
    }
}

/* ------------------------------------------------------------------ geometry */

/* The sprite is scaled to the drawn height and placed with its pivot on b.pos. */
rect city_sprite_rect(const city *c, building b)
{
    const building_def *d = &c->defs[b.type];
    size2 tex = d->sprite.size.h > 0 ? d->sprite.size : sz2s(1);
    vec2 pivot = d->sprite.size.h > 0 ? d->pivot : v2(.5f, 1);
    float k = d->height / tex.h;
    return rect_make(vec2_sub(b.pos, vec2_scale(pivot, k)), size2_scale(tex, k));
}

int city_zone_at(const city *c, vec2 p)
{
    if (c->zone_at) return c->zone_at(c, p);
    for (int z = 0; z < c->zone_count; z++)
        if (rect_contains(c->zones[z].area, p)) return z;
    return -1;
}

bool city_zone_open(const city *c, int z) { return z >= 0 && z < 32 && (c->open >> z & 1u); }

int city_open_count(const city *c)
{
    int n = 0;
    for (int z = 0; z < c->zone_count; z++) n += city_zone_open(c, z);
    return n;
}

/* Land that is buildable terrain inside an open zone. */
static bool open_land(const city *c, vec2 p)
{
    if (!rect_contains(rect_make(v2(0, 0), c->cam.world), p)) return false;
    if (c->buildable && !c->buildable(c, p)) return false;
    return c->zone_count == 0 || city_zone_open(c, city_zone_at(c, p));
}

bool city_can_place(const city *c, vec2 p, int type, int ignore)
{
    if (type < 0 || type >= c->def_count) return false;
    if (ignore < 0 && c->count >= CITY_MAX) return false;
    bool sized = c->defs[type].size.w > 0;
    size2 f = tiles_of(c, type);
    vec2 t = to_tile(c, p);
    if (!open_land(c, p)) return false;
    if (sized) {
        /* every tile centre and, just inside them, the footprint's corners */
        for (int i = 0; i < (int)f.w; i++)
            for (int j = 0; j < (int)f.h; j++)
                if (!open_land(c, from_tile(c, vec2_add(t, v2(i - (f.w - 1) * .5f, j - (f.h - 1) * .5f))))) return false;
        for (int k = 0; k < 4; k++) {
            vec2 corner = v2((k & 1 ? .5f : -.5f) * f.w * .9f, (k & 2 ? .5f : -.5f) * f.h * .9f);
            if (!open_land(c, from_tile(c, vec2_add(t, corner)))) return false;
        }
    }
    for (int i = 0; i < c->count; i++) {
        if (i == ignore) continue;
        int other = c->items[i].type;
        if (!sized && c->defs[other].size.w <= 0) {
            if (vec2_dist(p, c->items[i].pos) < c->spacing) return false;
            continue;
        }
        /* footprints may share an edge but not overlap */
        size2 g = tiles_of(c, other);
        vec2 d = vec2_sub(t, to_tile(c, c->items[i].pos));
        if (fabsf(d.x) < (f.w + g.w) * .5f - 1e-3f && fabsf(d.y) < (f.h + g.h) * .5f - 1e-3f) return false;
    }
    return true;
}

bool city_find_spot(const city *c, int type, vec2 hint, vec2 *out)
{
    vec2 t = to_tile(c, city_snap(c, hint, type));
    int rings = (int)((c->cam.world.w / tile_w(c) + c->cam.world.h / tile_h(c)) * .5f) + 1;
    for (int ring = 0; ring <= rings; ring++)
        for (int y = -ring; y <= ring; y++)
            for (int x = -ring; x <= ring; x++) {
                if (abs(x) != ring && abs(y) != ring) continue;   /* only the ring's edge */
                vec2 p = from_tile(c, vec2_add(t, v2(x, y)));
                if (city_can_place(c, p, type, -1)) {
                    *out = p;
                    return true;
                }
            }
    return false;
}

int city_add(city *c, vec2 p, int type, double now)
{
    if (c->count >= CITY_MAX || type < 0 || type >= c->def_count) return -1;
    c->items[c->count] = (building){p, type, now};
    return c->count++;
}

int city_building_at(const city *c, vec2 p)
{
    int best = -1;
    for (int i = 0; i < c->count; i++) {
        rect r = city_sprite_rect(c, c->items[i]);
        r.size.h += 10;   /* a little below the sprite still counts */
        if (rect_contains(r, p) && (best < 0 || c->items[i].pos.y > c->items[best].pos.y)) best = i;
    }
    return best;
}

bool city_ready(const city *c, int i, double now)
{
    const building_def *d = &c->defs[c->items[i].type];
    return d->income_period > 0 && now - c->items[i].stamp >= d->income_period;
}

/* --------------------------------------------------------------------- zones */

static bool zone_touches(const city *c, int z)
{
    if (c->zone_touches) return c->zone_touches(c, z, c->open);
    for (int o = 0; o < c->zone_count; o++)
        if (city_zone_open(c, o) && rect_overlaps(rect_inflate(c->zones[z].area, 1), c->zones[o].area)) return true;
    return false;
}

bool city_zone_available(const city *c, int z, purse wallet)
{
    if (z < 0 || z >= c->zone_count || city_zone_open(c, z)) return false;
    return purse_covers(wallet, c->zones[z].needs) && purse_covers(wallet, c->zones[z].cost) && zone_touches(c, z);
}

bool city_unlock(city *c, int z, purse *wallet)
{
    if (!city_zone_available(c, z, *wallet)) return false;
    *wallet = purse_sub(*wallet, c->zones[z].cost);
    c->open |= 1u << z;
    return true;
}

int city_next_zone(const city *c, purse wallet)
{
    int touching = -1;
    for (int z = 0; z < c->zone_count; z++) {
        if (city_zone_available(c, z, wallet)) return z;
        if (touching < 0 && !city_zone_open(c, z) && zone_touches(c, z)) touching = z;
    }
    return touching;
}

/* ----------------------------------------------------------------- placement */

void city_begin_place(city *c, int type, vec2 at)
{
    if (type < 0 || type >= c->def_count) return;
    c->placing = type;
    c->moving = -1;
    c->ghost = city_snap(c, at, type);
}

void city_begin_move(city *c, int index)
{
    if (index < 0 || index >= c->count) return;
    c->placing = c->items[index].type;
    c->moving = index;
    c->ghost = city_snap(c, c->items[index].pos, c->placing);
}

void city_cancel(city *c) { c->placing = c->moving = -1, c->held = false; }

city_event city_confirm(city *c, purse *wallet, double now)
{
    city_event ev = {CITY_NONE, c->moving, -1, {{0}}, camera_to_screen(c->cam, c->ghost)};
    if (c->placing < 0) return ev;
    c->ghost = city_snap(c, c->ghost, c->placing);
    const building_def *d = &c->defs[c->placing];
    if (!city_can_place(c, c->ghost, c->placing, c->moving)) {
        ev.result = CITY_BLOCKED;
        return ev;
    }
    if (c->moving >= 0) {
        c->items[c->moving].pos = c->ghost;
        ev.result = CITY_MOVED;
    } else if (!purse_covers(*wallet, d->needs)) {
        ev.result = CITY_LOCKED_TYPE;
        return ev;
    } else if (!purse_covers(*wallet, d->cost)) {
        ev.result = CITY_CANT_AFFORD;
        return ev;
    } else {
        ev.building = city_add(c, c->ghost, c->placing, now);
        ev.amount = d->cost;
        *wallet = purse_add(purse_sub(*wallet, d->cost), d->reward);
        ev.result = CITY_BUILT;
    }
    c->pop_index = ev.building;
    c->pop_time = 1;
    city_cancel(c);
    return ev;
}

/* -------------------------------------------------------------------- update */

static city_event quick_build(city *c, vec2 p, purse *wallet, double now, vec2 screen)
{
    p = city_snap(c, p, c->selected);
    const building_def *d = &c->defs[c->selected];
    city_event ev = {CITY_NONE, -1, -1, d->cost, screen};
    if (!purse_covers(*wallet, d->needs)) ev.result = CITY_LOCKED_TYPE;
    else if (!purse_covers(*wallet, d->cost)) ev.result = CITY_CANT_AFFORD;
    else if (!city_can_place(c, p, c->selected, -1)) ev.result = CITY_BLOCKED;
    else {
        ev.building = city_add(c, p, c->selected, now);
        *wallet = purse_add(purse_sub(*wallet, d->cost), d->reward);
        c->pop_index = ev.building;
        c->pop_time = 1;
        ev.result = CITY_BUILT;
    }
    return ev;
}

city_event city_update(city *c, input in, purse *wallet, double now, float dt)
{
    city_event ev = {CITY_NONE, -1, -1, {{0}}, in.pos};
    c->pop_time = maxf(0, c->pop_time - dt);
    bool in_view = rect_contains(c->cam.view, in.press_pos);

    if (in.pressed && !in.captured && in_view) {
        vec2 p = camera_to_world(c->cam, in.pos);
        int i = city_building_at(c, p);
        c->press_target = 0;
        if (c->placing >= 0 && rect_contains(city_sprite_rect(c, (building){c->ghost, c->placing, 0}), p)) {
            c->press_target = 1;
            c->grab = vec2_sub(c->ghost, p);
        } else if (c->placing < 0 && c->movable && i >= 0) {
            c->press_target = 2 + i;
            c->grab = vec2_sub(c->items[i].pos, p);
        }
    }
    if (in.dragging && !in.captured && c->press_target >= 2) {   /* dragging a building starts moving it */
        city_begin_move(c, c->press_target - 2);
        c->press_target = 1;
    }
    /* the ghost follows the finger freely and lands on the grid when let go */
    if (in.dragging && !in.captured && c->press_target == 1 && c->placing >= 0) {
        c->ghost = vec2_add(camera_to_world(c->cam, in.pos), c->grab);
        c->held = true;
    }
    if (in.released && c->press_target == 1 && c->placing >= 0) c->ghost = city_snap(c, c->ghost, c->placing), c->held = false;
    c->lift = approachf(c->lift, c->held && c->placing >= 0 ? 1 : 0, 14, dt);

    input cam_in = in;
    if (c->press_target) cam_in.dragging = false, cam_in.drag = v2(0, 0);
    c->cam = camera_clamp(camera_input(c->cam, cam_in));

    if (!in.tap || in.captured || !rect_contains(c->cam.view, in.pos)) {
        if (in.released) c->press_target = 0;
        return ev;
    }
    vec2 p = camera_to_world(c->cam, in.pos);
    int press_target = c->press_target;
    c->press_target = 0;

    if (c->placing >= 0) {
        if (press_target != 1) c->ghost = city_snap(c, p, c->placing);   /* tap the land to put the ghost there */
        return ev;
    }
    if (c->selected >= 0 && c->selected < c->def_count) return quick_build(c, p, wallet, now, in.pos);

    int i = city_building_at(c, p);
    if (i >= 0) {
        const building_def *d = &c->defs[c->items[i].type];
        ev.building = i;
        if (d->income_period <= 0) ev.result = CITY_PICKED;
        else if (!city_ready(c, i, now)) ev.result = CITY_NOT_READY;
        else {
            *wallet = purse_add(*wallet, d->income);
            c->items[i].stamp = now;
            ev.amount = d->income;
            ev.result = CITY_COLLECTED;
        }
        return ev;
    }
    int z = city_zone_at(c, p);
    if (z >= 0 && !city_zone_open(c, z) && (!c->buildable || c->buildable(c, p))) {
        ev.zone = z;
        ev.result = CITY_ZONE;
    }
    return ev;
}

/* ---------------------------------------------------------------------- draw */

static void draw_building(const city *c, building b, color tint, float lift)
{
    const building_def *d = &c->defs[b.type];
    draw_image(d->sprite, rect_offset(camera_rect_to_screen(c->cam, city_sprite_rect(c, b)), v2(0, -lift)), tint);
}

/* Gently curved paths from every building to its nearest older neighbour. */
static void draw_paths(const city *c)
{
    enum { STEPS = 24 };
    color edge = color_alpha(color_shade(c->path, .8f), .85f);
    for (int i = 1; i < c->count; i++) {
        if (i == c->moving && c->placing >= 0) continue;
        int near = 0;
        float best = 1e30f;
        for (int j = 0; j < i; j++) {
            float d = vec2_dist(c->items[i].pos, c->items[j].pos);
            if (d < best) best = d, near = j;
        }
        vec2 a = c->items[i].pos, b = c->items[near].pos;
        if (best < 1) continue;
        vec2 dir = vec2_scale(vec2_sub(b, a), 1 / best), n = v2(-dir.y, dir.x);
        vec2 ctrl = vec2_add(vec2_lerp(a, b, .5f), vec2_scale(n, minf(70, best * .16f) * (i % 2 ? 1 : -1)));
        vec2 pts[STEPS + 1];
        for (int k = 0; k <= STEPS; k++) {
            float t = (float)k / STEPS, u = 1 - t;
            vec2 w = vec2_add(vec2_add(vec2_scale(a, u * u), vec2_scale(ctrl, 2 * u * t)), vec2_scale(b, t * t));
            pts[k] = camera_to_screen(c->cam, w);
        }
        draw_polyline(pts, STEPS + 1, 12 * c->cam.zoom, edge);
        draw_polyline(pts, STEPS + 1, 8 * c->cam.zoom, c->path);
    }
}

/* Fog over closed zones. Region borders are often staircases (Relic Rush's
 * come from a hex grid), and a coarse grid of all-or-nothing vertices turns
 * them into a saw edge. Instead the closed land is sampled once on a fine
 * world grid and blurred into soft cloud banks, and the result is kept until
 * the open zones change; a frame draws only the visible, foggy cells. */
enum { FOG_MAX = 160 };
#define FOG_SOFT 56.f   /* blur reach in world units: rounds off steps up to a hex wide */

static struct {
    const city *c;
    unsigned open;
    int zone_count, nx, ny;
    size2 world;
    bool land_only;
    float step;
    float a[FOG_MAX * FOG_MAX];   /* 0 clear .. 1 fully fogged, per grid point */
} fog;

/* One box-blur pass along rows (dx = 1) or columns (dx = nx), edges clamped. */
static void fog_box(const float *src, float *dst, int nx, int ny, bool rows, int r)
{
    int len = rows ? nx : ny, lines = rows ? ny : nx;
    for (int l = 0; l < lines; l++)
        for (int k = 0; k < len; k++) {
            float sum = 0;
            for (int d = -r; d <= r; d++) {
                int m = clampi(k + d, 0, len - 1);
                sum += src[rows ? l * nx + m : m * nx + l];
            }
            dst[rows ? l * nx + k : k * nx + l] = sum / (2 * r + 1);
        }
}

static void fog_build(const city *c)
{
    static float tmp[FOG_MAX * FOG_MAX];
    size2 world = c->cam.world;
    float step = maxf(20, maxf(world.w, world.h) / (FOG_MAX - 2));
    int nx = clampi((int)ceilf(world.w / step) + 1, 2, FOG_MAX), ny = clampi((int)ceilf(world.h / step) + 1, 2, FOG_MAX);
    for (int y = 0; y < ny; y++)
        for (int x = 0; x < nx; x++) {
            vec2 w = v2(x * step, y * step);
            int z = city_zone_at(c, w);
            bool closed = z >= 0 && !city_zone_open(c, z) && (!c->fog_on_land_only || !c->buildable || c->buildable(c, w));
            fog.a[y * nx + x] = closed ? 1.f : 0.f;
        }
    int r = clampi((int)roundf(FOG_SOFT / step), 1, 8);
    for (int pass = 0; pass < 2; pass++) {   /* two box passes each way: nearly gaussian */
        fog_box(fog.a, tmp, nx, ny, true, r);
        fog_box(tmp, fog.a, nx, ny, false, r);
    }
    fog.c = c, fog.open = c->open, fog.zone_count = c->zone_count, fog.world = world;
    fog.land_only = c->fog_on_land_only, fog.nx = nx, fog.ny = ny, fog.step = step;
}

static void draw_fog(const city *c)
{
    static render_vertex v[FOG_MAX * FOG_MAX];
    static int idx[(FOG_MAX - 1) * (FOG_MAX - 1) * 6];
    if (c->zone_count == 0 || city_open_count(c) == c->zone_count) return;
    if (fog.c != c || fog.open != c->open || fog.zone_count != c->zone_count || fog.land_only != c->fog_on_land_only ||
        fog.world.w != c->cam.world.w || fog.world.h != c->cam.world.h)
        fog_build(c);

    /* the grid points under the view, one cell of margin */
    float step = fog.step;
    vec2 lo = camera_to_world(c->cam, c->cam.view.pos), hi = camera_to_world(c->cam, rect_max(c->cam.view));
    int x0 = clampi((int)floorf(lo.x / step) - 1, 0, fog.nx - 1), x1 = clampi((int)ceilf(hi.x / step) + 1, 0, fog.nx - 1);
    int y0 = clampi((int)floorf(lo.y / step) - 1, 0, fog.ny - 1), y1 = clampi((int)ceilf(hi.y / step) + 1, 0, fog.ny - 1);
    int w = x1 - x0 + 1, n = 0;
    for (int y = y0; y <= y1; y++)
        for (int x = x0; x <= x1; x++) {
            vec2 p = v2(x * step, y * step);
            /* edges ease in and out; the bank itself drifts gently, like cloud */
            float t = smoothstep(.12f, .88f, fog.a[y * fog.nx + x]);
            float cloud = .9f + .1f * sinf(p.x * .006f + 1.7f * sinf(p.y * .004f)) * sinf(p.y * .005f - p.x * .002f);
            vec2 s = camera_to_screen(c->cam, p);
            v[(y - y0) * w + x - x0] = (render_vertex){{s.x, s.y}, {c->fog.r, c->fog.g, c->fog.b, (uint8_t)(c->fog.a * t * cloud)}, {0, 0}};
        }
    for (int y = 0; y < y1 - y0; y++)
        for (int x = 0; x < x1 - x0; x++) {
            int i = y * w + x;
            if (!(v[i].color.a | v[i + 1].color.a | v[i + w].color.a | v[i + w + 1].color.a)) continue;   /* clear land */
            int q[6] = {i, i + 1, i + w, i + 1, i + w + 1, i + w};
            memcpy(idx + n, q, sizeof q);
            n += 6;
        }
    if (n) render_geometry(NULL, v, w * (y1 - y0 + 1), idx, n);
}

static void draw_footprint(const city *c, vec2 at, int type, bool ok)
{
    color fill = ok ? rgba(114, 221, 136, 110) : rgba(245, 100, 84, 145), line = ok ? rgba(217, 255, 189, 255) : rgba(255, 208, 179, 255);
    if (c->defs[type].size.w <= 0) {
        draw_glow(camera_to_screen(c->cam, at), c->spacing * .5f * c->cam.zoom, fill, color_alpha(fill, 0));
        return;
    }
    size2 f = tiles_of(c, type);
    vec2 t = to_tile(c, at);
#define CORNER(u, v) camera_to_screen(c->cam, from_tile(c, vec2_add(t, v2((u) - f.w * .5f, (v) - f.h * .5f))))
    vec2 pts[4] = {CORNER(0, 0), CORNER(f.w, 0), CORNER(f.w, f.h), CORNER(0, f.h)};
    draw_poly(pts, 4, fill);
    for (int i = 1; i < f.w; i++) draw_line(CORNER(i, 0), CORNER(i, f.h), 1, color_alpha(line, .45f));   /* the tiles inside */
    for (int j = 1; j < f.h; j++) draw_line(CORNER(0, j), CORNER(f.w, j), 1, color_alpha(line, .45f));
#undef CORNER
    for (int i = 0; i < 4; i++) draw_line(pts[i], pts[(i + 1) % 4], 1.5f, line);
}

void city_draw(const city *c, input in, double now)
{
    camera cam = c->cam;
    gfx_clip(cam.view);
    camera_draw_texture(cam, c->ground);
    if (c->path.a) draw_paths(c);
    draw_fog(c);   /* over the land, under the buildings: they stand on open ground */

    /* painter's order: buildings further down the map are in front */
    int order[CITY_MAX], n = 0;
    for (int i = 0; i < c->count; i++) {
        if (c->placing >= 0 && i == c->moving) continue;
        int j = n++;
        order[j] = i;
        while (j > 0 && c->items[order[j - 1]].pos.y > c->items[order[j]].pos.y) {
            int t = order[j - 1];
            order[j - 1] = order[j];
            order[j] = t;
            j--;
        }
    }
    for (int k = 0; k < n; k++) {
        int i = order[k];
        float lift = i == c->pop_index && c->pop_time > 0 ? sinf((1 - c->pop_time) * ENGINE_PI) * 8 : 0;
        draw_building(c, c->items[i], WHITE, lift);
    }

    for (int i = 0; i < c->count; i++) {
        const building_def *d = &c->defs[c->items[i].type];
        if (d->income_period <= 0) continue;
        rect top = camera_rect_to_screen(cam, city_sprite_rect(c, c->items[i]));
        vec2 at = vec2_add(rect_point(top, v2(.5f, 0)), v2(0, -6));
        if (city_ready(c, i, now)) {
            float bob = sinf((float)now * 4 + i) * 4;
            rect bubble = rect_centered(vec2_add(at, v2(0, bob)), sz2s(44));
            draw_shadow(rect_offset(bubble, v2(0, 4)), 22, 10, rgba(0, 0, 0, 90));
            draw_circle(rect_center(bubble), 22, rgba(255, 250, 235, 245));
            draw_ring(rect_center(bubble), 22, 2.5f, rgba(214, 170, 92, 255));
            draw_image(c->income_icon, rect_inflate(bubble, -8), WHITE);
        } else {
            float t = (float)((now - c->items[i].stamp) / d->income_period);
            rect bar = rect_centered(at, sz2(56, 8));
            draw_round_rect(bar, 4, rgba(0, 0, 0, 120));
            draw_round_rect(rect_resize(bar, sz2(bar.size.w * saturate(t), bar.size.h), v2(0, .5f)), 4, rgba(242, 210, 140, 230));
        }
    }

    if (c->show_footprints)   /* over the sprites, to check their measured bases */
        for (int i = 0; i < c->count; i++) {
            draw_footprint(c, c->items[i].pos, c->items[i].type, true);
            draw_circle(camera_to_screen(cam, c->items[i].pos), 4, rgba(255, 60, 200, 255));   /* the pivot */
        }
    if (c->draw_over) c->draw_over(c);

    if (c->placing >= 0) {
        vec2 land = city_snap(c, c->ghost, c->placing);   /* mid-drag the footprint shows where it will land */
        bool ok = city_can_place(c, land, c->placing, c->moving);
        draw_footprint(c, land, c->placing, ok);
        float lift = c->lift * 34 * cam.zoom;   /* held up so the footprint shows beneath */
        draw_building(c, (building){c->ghost, c->placing, 0}, ok ? rgba(255, 255, 255, 245) : rgba(255, 90, 80, 160), lift);   /* red: it can't go here */
    } else if (c->selected >= 0 && in.hover && !in.down && rect_contains(cam.view, in.pos) && !ui_blocks(in.pos)) {
        vec2 p = city_snap(c, camera_to_world(cam, in.pos), c->selected);
        bool ok = city_can_place(c, p, c->selected, -1);
        draw_footprint(c, p, c->selected, ok);
        draw_building(c, (building){p, c->selected, 0}, ok ? rgba(255, 255, 255, 170) : rgba(255, 140, 130, 140), 0);
    }
    gfx_unclip();
}

/* ---------------------------------------------------------------------- save */

void city_serialize(city *c, save *s)
{
    int open = (int)c->open, legacy = 0;
    save_int(s, "city.open", &open);
    if (save_is_reading(s)) {
        save_int(s, "city.zones", &legacy);   /* older saves: a count of zones opened in order */
        if (legacy > 0) open = (int)((1u << clampi(legacy, 1, 31)) - 1);
    }
    c->open = (unsigned)open | 1u;
    int n = c->count;
    save_int(s, "city.count", &n);
    if (save_is_reading(s)) c->count = 0;
    for (int i = 0; i < n && i < CITY_MAX; i++) {
        building b = save_is_reading(s) ? (building){{0, 0}, -1, 0} : c->items[i];
        int type = b.type;
        save_vec2(s, fmt("city.%d.pos", i), &b.pos);
        save_int(s, fmt("city.%d.type", i), &type);
        save_double(s, fmt("city.%d.stamp", i), &b.stamp);
        if (save_is_reading(s) && type >= 0 && type < c->def_count) {
            b.type = type;
            c->items[c->count++] = b;
        }
    }
}
