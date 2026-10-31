/* Real-renderer contracts for the city's depth order. */
#include "render.h"
#include <stdio.h>
#include <stdlib.h>

static int checks, failures;
static city c;
static building_def defs[2];
static unsigned char *pixels;
static int w, h;
#define CHECK(x) do { checks++; if (!(x)) { failures++; fprintf(stderr, "%d: %s\n", __LINE__, #x); } } while (0)

static color at(int x, int y)
{
    int px = x * w / 160, py = y * h / 160;
    unsigned char *p = pixels + (py * w + px) * 4;
    return rgba(p[0], p[1], p[2], p[3]);
}

static void init(void)
{
    color green = rgba(50, 150, 60, 255), white = WHITE, red = rgba(220, 30, 30, 255);
    defs[0] = (building_def){.sprite = tex_from_pixels(&white, 1, 1), .size = {1, 6}, .pivot = {.5, 1}, .base_width = 1};
    defs[1] = (building_def){.sprite = tex_from_pixels(&red, 1, 1), .size = {1, 1}, .pivot = {.5, 1}, .base_width = 1};
    c = (city){.ground = tex_from_pixels(&green, 1, 1), .defs = defs, .def_count = 2, .tile = 14,
        .cam = {.center = {80, 80}, .world = {160, 160}, .zoom = 1, .view = {{0, 0}, {160, 160}}}};
    city_init(&c, NULL);
}

static void frame(float dt)
{
    struct AXsize size; axGetSize(&size);
    w = (int)roundf(size.width * axGetScaling()); h = (int)roundf(size.height * axGetScaling());
    pixels = malloc((size_t)w * h * 4);
    /* a long footprint draws behind the small one past it, whose ground centre is higher up */
    vec2 long_at = v2(80, 100), small_at = vec2_add(long_at, city_tile_to_world(&c, v2(1, -2.5f)));
    CHECK(small_at.y < long_at.y);
    c.count = 2; c.items[0] = (building){long_at, 0, 0}; c.items[1] = (building){small_at, 1, 0};
    city_draw(&c, (input){0}, 0);
    CHECK(render_read_pixels(pixels, w, h));
    CHECK(at(103, 75).r > 200 && at(103, 75).g < 60);
    free(pixels);
    app_quit();
}

static void quit(void) { tex_free(c.ground); tex_free(defs[0].sprite); tex_free(defs[1].sprite); }
int main(void)
{
    char *args[] = {"test-city-render", "--headless", "--mute", "--size", "160x160"};
    app_desc desc = {.design = {160, 160}, .fixed = true, .init = init, .frame = frame, .quit = quit};
    CHECK(app_run(desc, 5, args) == 0);
    printf("city renderer: %d checks, %d failures; depth order\n", checks, failures);
    return failures != 0;
}
