/* city.c — the shared city-building meta-game.
 *
 * A city is a large ground texture split into unlockable zones, a catalogue of
 * building types (cost, one-off reward, unlock requirement, timed income) and
 * the placed buildings. Games plug in their own terrain test (`buildable`) and
 * decide what the resources mean; the city handles the camera, placement,
 * depth-sorted drawing, income collection and saving. */
#include "engine.h"

#include <stdio.h>
#include <string.h>

void city_init(city *c, const char *ground_path)
{
    if (ground_path) c->ground = tex_load(ground_path);
    if (c->cam.world.w <= 0) c->cam.world = c->ground.size;
    if (c->cam.max_zoom <= 0) c->cam.max_zoom = 2;
    if (c->cam.zoom <= 0) c->cam.zoom = 1;
    c->cam.cover = true;
    if (c->spacing <= 0) c->spacing = 100;
    if (c->locked_tint.a == 0) c->locked_tint = rgba(13, 46, 49, 155);
    if (c->unlocked <= 0) c->unlocked = 1;
    c->selected = -1;
    for (int i = 0; i < c->def_count; i++)
        if (c->defs[i].sprite_path && !c->defs[i].sprite.tex) c->defs[i].sprite = tex_load(c->defs[i].sprite_path);
}

static rect sprite_rect(const city *c, const building *b)
{
    const building_def *d = &c->defs[b->type];
    size2 tex = d->sprite.size.h > 0 ? d->sprite.size : sz2s(1);
    size2 size = sz2(d->height * size2_aspect(tex), d->height);
    return rect_anchor(vec2_add(b->pos, v2(0, d->sink)), size, v2(.5f, 1));
}

static bool in_unlocked_zone(const city *c, vec2 p)
{
    if (c->zone_count == 0) return true;
    for (int z = 0; z < c->unlocked && z < c->zone_count; z++)
        if (rect_contains(c->zones[z].area, p)) return true;
    return false;
}

bool city_can_place(const city *c, vec2 p, int type)
{
    if (type < 0 || type >= c->def_count || c->count >= CITY_MAX) return false;
    if (!rect_contains(rect_make(v2(0, 0), c->cam.world), p) || !in_unlocked_zone(c, p)) return false;
    if (c->buildable && !c->buildable(p)) return false;
    for (int i = 0; i < c->count; i++)
        if (vec2_dist(p, c->items[i].pos) < c->spacing) return false;
    return true;
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
    for (int i = 0; i < c->count; i++)
        if (rect_contains(sprite_rect(c, &c->items[i]), p) && (best < 0 || c->items[i].pos.y > c->items[best].pos.y)) best = i;
    return best;
}

bool city_ready(const city *c, int i, double now)
{
    const building_def *d = &c->defs[c->items[i].type];
    return d->income_period > 0 && now - c->items[i].stamp >= d->income_period;
}

city_event city_update(city *c, input in, purse *wallet, double now)
{
    city_event ev = {CITY_NONE, -1, {{0}}, in.pos};
    c->cam = camera_clamp(camera_input(c->cam, in));
    if (!in.tap || in.captured || !rect_contains(c->cam.view, in.pos)) return ev;
    vec2 p = camera_to_world(c->cam, in.pos);

    if (c->selected >= 0 && c->selected < c->def_count) {
        const building_def *d = &c->defs[c->selected];
        ev.amount = d->cost;
        if (!purse_covers(*wallet, d->needs)) ev.result = CITY_LOCKED_TYPE;
        else if (!purse_covers(*wallet, d->cost)) ev.result = CITY_CANT_AFFORD;
        else if (!city_can_place(c, p, c->selected)) ev.result = CITY_BLOCKED;
        else {
            ev.building = city_add(c, p, c->selected, now);
            *wallet = purse_add(purse_sub(*wallet, d->cost), d->reward);
            ev.result = CITY_BUILT;
        }
        return ev;
    }

    int i = city_building_at(c, p);
    if (i < 0) return ev;
    ev.building = i;
    const building_def *d = &c->defs[c->items[i].type];
    if (d->income_period <= 0) return ev;
    if (!city_ready(c, i, now)) {
        ev.result = CITY_NOT_READY;
        return ev;
    }
    *wallet = purse_add(*wallet, d->income);
    c->items[i].stamp = now;
    ev.amount = d->income;
    ev.result = CITY_COLLECTED;
    return ev;
}

purse city_next_zone_cost(const city *c)
{
    return c->unlocked < c->zone_count ? c->zones[c->unlocked].cost : (purse){{0}};
}

bool city_unlock_next(city *c, purse *wallet)
{
    if (c->unlocked >= c->zone_count) return false;
    purse cost = city_next_zone_cost(c);
    if (!purse_covers(*wallet, cost)) return false;
    *wallet = purse_sub(*wallet, cost);
    c->unlocked++;
    return true;
}

static void draw_building(const city *c, const building *b, color tint)
{
    const building_def *d = &c->defs[b->type];
    draw_image(d->sprite, camera_rect_to_screen(c->cam, sprite_rect(c, b)), tint);
}

void city_draw(const city *c, input in, double now)
{
    camera cam = c->cam;
    gfx_clip(cam.view);
    camera_draw_texture(cam, c->ground);

    for (int z = c->unlocked; z < c->zone_count; z++) {
        rect r = camera_rect_to_screen(cam, c->zones[z].area);
        draw_rect(r, c->locked_tint);
        draw_line(r.pos, rect_point(r, v2(0, 1)), 2, color_alpha(WHITE, .25f));
    }

    /* painter's order: buildings further down the map are in front */
    int order[CITY_MAX];
    for (int i = 0; i < c->count; i++) {
        int j = i;
        order[j] = i;
        while (j > 0 && c->items[order[j - 1]].pos.y > c->items[order[j]].pos.y) {
            int t = order[j - 1];
            order[j - 1] = order[j];
            order[j] = t;
            j--;
        }
    }
    for (int n = 0; n < c->count; n++) draw_building(c, &c->items[order[n]], WHITE);

    for (int i = 0; i < c->count; i++) {
        const building_def *d = &c->defs[c->items[i].type];
        if (d->income_period <= 0) continue;
        rect top = camera_rect_to_screen(cam, sprite_rect(c, &c->items[i]));
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

    if (c->selected >= 0 && in.hover && !in.down && rect_contains(cam.view, in.pos) && !ui_blocks(in.pos)) {
        vec2 p = camera_to_world(cam, in.pos);
        bool ok = city_can_place(c, p, c->selected);
        building ghost = {p, c->selected, 0};
        draw_glow(in.pos, c->spacing * .5f * cam.zoom, ok ? rgba(120, 230, 150, 90) : rgba(240, 90, 80, 90), rgba(0, 0, 0, 0));
        draw_building(c, &ghost, ok ? rgba(255, 255, 255, 170) : rgba(255, 140, 130, 140));
    }
    gfx_unclip();
}

void city_serialize(city *c, save *s)
{
    save_int(s, "city.zones", &c->unlocked);
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
    c->unlocked = clampi(c->unlocked, 1, c->zone_count > 0 ? c->zone_count : 1);
}
