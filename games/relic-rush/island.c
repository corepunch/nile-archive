/* island.c — the Lost Valley map: shoreline, six regions and ten wonders.
 *
 * The island is an engine city. This file only knows the map: which world
 * points are lawn (an authored contour), which region owns them (a hidden
 * axial hex grid flood-filled from six region centres, so every region is one
 * connected patch) and which regions touch. Placement, unlocking, moving and
 * drawing are the engine's. */
#include "relic.h"

#include <string.h>

/* Ten restorations in campaign order: footprint and draw width per sprite. */
#define WONDER(title, text, i, w, gold, wood, stone)                                                                \
    {.name = title, .about = text, .sprite_path = "buildings/" #i ".png", .width = w, .max_height = 230,            \
     .footprint = {(float)(int)((w) * .4f), (float)(int)((w) * .19f)}, .cost = {{gold, wood, stone}}}

building_def wonders[WONDERS] = {
    WONDER("Expedition camp", "Every great discovery begins with a little canvas.", 0, 180, 60, 10, 5),
    WONDER("Spring well", "Fresh water brings the lost valley back to life.", 1, 145, 80, 15, 15),
    WONDER("Artisan workshop", "A home for the hands that rebuild the valley.", 2, 180, 100, 25, 15),
    WONDER("Jungle market", "Stories, spices and treasures from far away.", 3, 165, 120, 25, 25),
    WONDER("Sunstone gateway", "A garden arch marks the path into your valley.", 4, 190, 140, 30, 30),
    WONDER("Explorer's lodge", "A warm light after a long day of adventure.", 5, 185, 160, 35, 35),
    WONDER("Lost-world archive", "Protect the knowledge buried beneath the vines.", 6, 190, 180, 35, 45),
    WONDER("Star observatory", "Follow the stars to the next discovery.", 7, 165, 200, 40, 50),
    WONDER("Jade fountain", "Let the ancient spring flow once more.", 8, 165, 220, 45, 55),
    WONDER("Temple of the sun", "The heart of the valley shines again.", 9, 220, 250, 50, 60),
};

static const char *zone_names[ISLAND_ZONES] = {"Harbor glade", "Sunlit coast", "Fern meadow", "Sun garden", "Ancient heights", "Temple ridge"};
static const int zone_stars[ISLAND_ZONES] = {0, 6, 9, 15, 21, 27};
static const int zone_compasses[ISLAND_ZONES] = {0, 2, 3, 4, 5, 6};
static const vec2 zone_centers[ISLAND_ZONES] = {{760, 2080}, {1330, 2100}, {670, 1430}, {1330, 1440}, {850, 770}, {1220, 860}};
static const vec2 suggestions[WONDERS] = {{760, 2030}, {1270, 2120}, {640, 1580}, {1110, 1830}, {1000, 1420},
                                          {1400, 1710}, {1070, 1040}, {1390, 1350}, {690, 1250}, {940, 780}};

/* Authored walkable lawn contour in half-scale map coordinates. */
static const vec2 shore[] = {{440, 220}, {535, 235}, {610, 300}, {700, 350}, {795, 470}, {795, 680}, {770, 820},
                             {805, 965}, {710, 1110}, {580, 1170}, {440, 1160}, {290, 1090}, {210, 980}, {230, 855},
                             {180, 700}, {190, 575}, {255, 465}, {320, 400}, {340, 295}};

static bool on_lawn(vec2 p)
{
    p = vec2_scale(vec2_floor(p), .5f);
    p = vec2_floor(p);
    bool in = false;
    int n = (int)(sizeof shore / sizeof shore[0]);
    for (int i = 0, j = n - 1; i < n; j = i++) {   /* even-odd point in polygon */
        vec2 a = shore[i], b = shore[j];
        if ((a.y > p.y) != (b.y > p.y) && p.x < (b.x - a.x) * (p.y - a.y) / (b.y - a.y) + a.x) in = !in;
    }
    return in;
}

/* ---------------------------------------------------------- hidden region map */

enum { MQ = 29, MR = 52, RMIN = -14 };
#define MAP_HEX_R 45.f

static signed char region[MQ * MR];   /* -2 water, -1 unassigned land, else zone */
static bool region_ready;
static const ivec2 axial_dirs[6] = {{1, 0}, {0, 1}, {-1, 1}, {-1, 0}, {0, -1}, {1, -1}};

static int map_index(ivec2 a) { return a.x >= 0 && a.x < MQ && a.y >= RMIN && a.y < RMIN + MR ? a.x * MR + a.y - RMIN : -1; }
static ivec2 map_axial(int i) { return iv2(i / MR, i % MR + RMIN); }

static vec2 map_position(int i)
{
    ivec2 a = map_axial(i);
    return v2((float)(int)(a.x * 1.5f * MAP_HEX_R), (float)(int)((a.y + a.x * .5f) * 1.732050808f * MAP_HEX_R));
}

static void region_init(void)
{
    if (region_ready) return;
    region_ready = true;
    int queue[MQ * MR], head = 0, tail = 0;
    for (int i = 0; i < MQ * MR; i++) region[i] = on_lawn(map_position(i)) ? -1 : -2;
    for (int z = 0; z < ISLAND_ZONES; z++) {   /* seed each region at the land cell nearest its centre */
        int best = -1;
        float best_d = 1e30f;
        for (int i = 0; i < MQ * MR; i++) {
            if (region[i] != -1) continue;
            vec2 d = vec2_sub(map_position(i), zone_centers[z]);
            if (vec2_dot(d, d) < best_d) best_d = vec2_dot(d, d), best = i;
        }
        if (best >= 0) region[best] = (signed char)z, queue[tail++] = best;
    }
    while (head < tail) {   /* multi-source flood fill: every region grows at the same pace */
        int i = queue[head++];
        for (int d = 0; d < 6; d++) {
            int n = map_index(ivec2_add(map_axial(i), axial_dirs[d]));
            if (n >= 0 && region[n] == -1) region[n] = region[i], queue[tail++] = n;
        }
    }
}

static int map_cell(vec2 p)
{
    float q = p.x / (1.5f * MAP_HEX_R), r = p.y / (1.732050808f * MAP_HEX_R) - q * .5f, s = -q - r;
    int iq = (int)roundf(q), ir = (int)roundf(r), is = (int)roundf(s);
    float dq = fabsf(iq - q), dr = fabsf(ir - r), ds = fabsf(is - s);
    if (dq > dr && dq > ds) iq = -ir - is;
    else if (dr > ds) ir = -iq - is;
    return map_index(iv2(iq, ir));
}

int island_zone(vec2 p)
{
    region_init();
    int i = map_cell(vec2_floor(p));
    return i >= 0 && region[i] >= 0 ? region[i] : -1;
}

bool island_grass(vec2 p) { return on_lawn(p) && island_zone(p) >= 0; }

bool island_zone_touches(int z, unsigned open)
{
    region_init();
    for (int i = 0; i < MQ * MR; i++) {
        if (region[i] != z) continue;
        for (int d = 0; d < 6; d++) {
            int n = map_index(ivec2_add(map_axial(i), axial_dirs[d]));
            if (n >= 0 && region[n] >= 0 && (open >> region[n] & 1u)) return true;
        }
    }
    return false;
}

vec2 island_suggestion(int i) { return suggestions[clampi(i, 0, WONDERS - 1)]; }

void island_setup(city *c)
{
    c->defs = wonders;
    c->def_count = WONDERS;
    c->zone_count = ISLAND_ZONES;
    for (int z = 0; z < ISLAND_ZONES; z++)
        c->zones[z] = (city_zone){.name = zone_names[z], .marker = zone_centers[z], .needs = {{[STARS] = zone_stars[z]}},
                                  .cost = {{[COMPASSES] = zone_compasses[z]}}};
    c->buildable = island_grass;
    c->zone_at = island_zone;
    c->zone_touches = island_zone_touches;
    c->footprint_gap = sz2(14, 12);
    c->fog = rgba(233, 242, 224, 240);
    c->fog_on_land_only = true;
    c->path = rgba(222, 204, 151, 240);
    c->movable = true;
    c->cam = (camera){.center = v2(760, 2010), .zoom = .65f, .min_zoom = .24f, .max_zoom = 1.05f, .world = sz2(ISLAND_W, ISLAND_H)};
    city_init(c, "island.jpg");
}

bool island_place_next(city *c, purse *wallet, int built_limit, double now)
{
    int next = c->count;
    vec2 spot;
    if (next >= WONDERS || next >= built_limit || !city_find_spot(c, next, island_suggestion(next), &spot)) return false;
    city_begin_place(c, next, spot);
    if (city_confirm(c, wallet, now).result == CITY_BUILT) return true;
    city_cancel(c);
    return false;
}
