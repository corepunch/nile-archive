/* Real-renderer contracts for the city's depth order and animated fog. */
#include "render.h"
#include "test.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static city c;
static building_def defs[2];
static unsigned char *pixels, *first;
static int w, h;
static bool sampling_fog;
static double fog_start;

static color at(int x, int y)
{
    int px = x * w / 160, py = y * h / 160;
    unsigned char *p = pixels + (py * w + px) * 4;
    return rgba(p[0], p[1], p[2], p[3]);
}

static void init(void)
{
    sampling_fog = false;
    color green = rgba(50, 150, 60, 255), white = WHITE, red = rgba(220, 30, 30, 255);
    defs[0] = (building_def){.sprite = tex_from_pixels(&white, 1, 1), .size = {1, 6}, .pivot = {.5, 1}, .base_width = 1};
    defs[1] = (building_def){.sprite = tex_from_pixels(&red, 1, 1), .size = {1, 1}, .pivot = {.5, 1}, .base_width = 1};
    c = (city){.ground = tex_from_pixels(&green, 1, 1), .defs = defs, .def_count = 2, .tile = 14,
        .cam = {.center = {80, 80}, .world = {160, 160}, .zoom = 1, .view = {{0, 0}, {160, 160}}}};
    city_init(&c, NULL);
}

static void frame(float dt)
{
    if (sampling_fog) {
        if (app_time() - fog_start < 4) return;
        goto compare_fog;
    }
    struct AXsize size; axGetSize(&size);
    w = (int)roundf(size.width * axGetScaling()); h = (int)roundf(size.height * axGetScaling());
    size_t bytes = (size_t)w * h * 4;
    pixels = malloc(bytes); first = malloc(bytes);
    /* a long footprint draws behind the small one past it, whose ground centre is higher up */
    vec2 long_at = v2(80, 100), small_at = vec2_add(long_at, city_tile_to_world(&c, v2(1, -2.5f)));
    CHECK(small_at.y < long_at.y);
    c.count = 2; c.items[0] = (building){long_at, 0, 0}; c.items[1] = (building){small_at, 1, 0};
    city_draw(&c, (input){0}, 0);
    CHECK(render_read_pixels(pixels, w, h));
    CHECK(at(103, 75).r > 200 && at(103, 75).g < 60);
    /* cloud fog moves on frame time alone, and unlocking clears it at once */
    c.count = 0;
    c.zone_count = 2; c.zones[0].area = rc(0, 0, 160, 40); c.zones[1].area = rc(0, 40, 160, 120);
    c.fog = rgba(233, 242, 224, 240); c.fog_clouds = true;
    city_draw(&c, (input){0}, 0);
    CHECK(render_read_pixels(pixels, w, h));
    memcpy(first, pixels, bytes);
    sampling_fog = true; fog_start = app_time();
    return;
compare_fog:
    city_draw(&c, (input){0}, 8);
    CHECK(render_read_pixels(pixels, w, h));
    bytes = (size_t)w * h * 4;
    int changed = 0;
    for (size_t i = 0; i < bytes; i += 4) if (abs(pixels[i] - first[i]) > 3) changed++;
    CHECK(changed > w * h / 10);   /* visible motion without camera or input changes */
    c.open = 3;
    city_draw(&c, (input){0}, 8);
    CHECK(render_read_pixels(pixels, w, h));
    CHECK(at(80, 140).g == 150 && at(80, 140).r == 50);
    free(first); free(pixels);
    app_quit();
}

static void quit(void) { tex_free(c.ground); tex_free(defs[0].sprite); tex_free(defs[1].sprite); }
TEST(city_render)
{
    char *args[] = {"test-city-render", "--headless", "--mute", "--size", "160x160"};
    app_desc desc = {.design = {160, 160}, .fixed = true, .init = init, .frame = frame, .quit = quit};
    CHECK(app_run(desc, 5, args) == 0);
}
