/* Headless tests: engine math and layout, camera, purses, saves, city and
 * story rules in C, then every Lua file named on the command line (the games'
 * rules, the tests/lua folder) in the engine's Lua state. Run with `make test`. */
#include "engine.h"
#include "viewport.h"

#include <stdio.h>
#include <string.h>

static int failures, checks;

#define CHECK(cond)                                                                    \
    do {                                                                               \
        checks++;                                                                      \
        if (!(cond)) failures++, fprintf(stderr, "%s:%d: CHECK(%s)\n", __FILE__, __LINE__, #cond); \
    } while (0)
#define NEAR(a, b) CHECK(fabsf((float)(a) - (float)(b)) < 1e-3f)

static void test_math(void)
{
    vec2 a = v2(3, 4);
    NEAR(vec2_len(a), 5);
    NEAR(vec2_dot(vec2_norm(a), vec2_norm(a)), 1);
    vec2 r = vec2_rotate(v2(1, 0), ENGINE_PI / 2);
    NEAR(r.x, 0);
    NEAR(r.y, 1);
    NEAR(vec3_dot(vec3_cross(v3(1, 0, 0), v3(0, 1, 0)), v3(0, 0, 1)), 1);
    NEAR(size2_fit(sz2(200, 100), sz2(100, 100)), .5f);
    NEAR(size2_cover(sz2(200, 100), sz2(100, 100)), 1);
    NEAR(ease_out_cubic(1), 1);
    NEAR(ease_out_back(0), 0);
}

static void test_rect(void)
{
    rect r = rc(0, 0, 100, 50);
    rect c = rect_inflate(rect_offset(r, v2(10, 10)), 5);
    NEAR(c.pos.x, 5);
    NEAR(c.size.w, 110);
    NEAR(rect_center(r).x, 50);
    CHECK(rect_contains(r, v2(99, 49)) && !rect_contains(r, v2(100, 10)));

    rect body = rc(0, 0, 400, 300);
    rect top = rect_cut_top(&body, 60), side = rect_cut_right(&body, 100);
    NEAR(top.size.h, 60);
    NEAR(side.pos.x, 300);
    NEAR(body.pos.y, 60);
    NEAR(body.size.w, 300);
    NEAR(body.size.h, 240);
    rect cell = rect_col(rc(0, 0, 100, 10), 4, 3, 4);
    NEAR(cell.pos.x, 3 * (22 + 4));
    rect a = rect_align(rc(0, 0, 100, 100), sz2(20, 10), v2(1, 1));
    NEAR(a.pos.x, 80);
    NEAR(a.pos.y, 90);
    CHECK(rect_overlaps(rc(0, 0, 10, 10), rc(5, 5, 10, 10)) && !rect_overlaps(rc(0, 0, 10, 10), rc(10, 0, 5, 5)));
    rect i = rect_intersect(rc(0, 0, 10, 10), rc(5, 5, 10, 10));
    NEAR(i.size.w, 5);
    CHECK(rect_ellipse_contains(rc(0, 0, 20, 10), v2(10, 5)) && !rect_ellipse_contains(rc(0, 0, 20, 10), v2(1, 1)));
}

static void test_camera(void)
{
    camera c = {.center = v2(500, 500), .zoom = 1, .view = rc(100, 50, 400, 300), .world = sz2(1000, 800), .max_zoom = 4, .cover = true};
    c = camera_clamp(c);
    vec2 w = camera_to_world(c, v2(300, 200));
    NEAR(w.x, 500);
    vec2 back = camera_to_screen(c, camera_to_world(c, v2(123, 77)));
    NEAR(back.x, 123);
    NEAR(back.y, 77);
    c = camera_pan(c, v2(-100000, 0));          /* clamped to the world edge */
    NEAR(camera_visible(c).pos.x + camera_visible(c).size.w, 1000);
    vec2 anchor = camera_to_world(c, v2(200, 120));
    c = camera_zoom_at(c, 2, v2(200, 120));
    vec2 after = camera_to_world(c, v2(200, 120));
    NEAR(after.x, anchor.x);
    c.zoom = .01f;
    c = camera_clamp(c);                         /* cover: never smaller than the view */
    CHECK(c.zoom >= size2_cover(c.world, c.view.size) - 1e-4f);
    camera small = {.view = rc(0, 0, 1000, 1000), .world = sz2(100, 100), .zoom = .5f};
    small = camera_clamp(small);
    NEAR(small.center.x, 50);                    /* a small world is centred */
}

static void test_purse(void)
{
    purse wallet = {{100, 5}}, cost = {{60, 0}}, need = {{0, 6}};
    CHECK(purse_covers(wallet, cost));
    CHECK(!purse_covers(wallet, need));
    wallet = purse_add(purse_sub(wallet, cost), (purse){{0, 1}});
    CHECK(wallet.v[0] == 40 && wallet.v[1] == 6 && purse_covers(wallet, need));
    CHECK(purse_empty((purse){{0}}) && !purse_empty(cost));
}

static struct { int coins; int list[3]; vec2 spot; double when; } saved, loaded;

static void serialize_saved(save *s, void *user)
{
    (void)user;
    save_int(s, "coins", &saved.coins);
    save_ints(s, "list", saved.list, 3);
    save_vec2(s, "spot", &saved.spot);
    save_double(s, "when", &saved.when);
}

static void serialize_loaded(save *s, void *user)
{
    (void)user;
    save_int(s, "coins", &loaded.coins);
    save_ints(s, "list", loaded.list, 3);
    save_vec2(s, "spot", &loaded.spot);
    save_double(s, "when", &loaded.when);
    int missing = 77;
    save_int(s, "missing", &missing);
    CHECK(missing == 77);   /* absent keys keep defaults */
}

static void test_save(void)
{
    saved.coins = 1234;
    saved.list[0] = 1, saved.list[1] = -2, saved.list[2] = 3;
    saved.spot = v2(12.5f, -4);
    saved.when = 1700000000.25;
    CHECK(save_write("test-slot", serialize_saved, NULL));
    CHECK(save_read("test-slot", serialize_loaded, NULL));
    CHECK(loaded.coins == 1234 && loaded.list[1] == -2 && loaded.list[2] == 3);
    NEAR(loaded.spot.x, 12.5f);
    CHECK(fabs(loaded.when - saved.when) < .01);
    save_inject("injected", "coins=9\n");
    loaded.coins = 0;
    CHECK(save_read("injected", serialize_loaded, NULL) && loaded.coins == 9);
}

static bool flat_land(const city *c, vec2 p) { return p.y > 100; }

static void test_safe_view(void)
{
    rect v = app_fit_view(sz2(480, 900), rc(0, 59, 390, 751));
    NEAR(v.pos.x, 0); NEAR(v.pos.y, 68.875f);
    NEAR(v.size.w, 390); NEAR(v.size.h, 731.25f);
    v = app_fit_view(sz2(1200, 900), rc(59, 0, 759, 369));
    CHECK(v.pos.x >= 59 && v.pos.y >= 0);
    CHECK(rect_max(v).x <= 818 && rect_max(v).y <= 369);
    vec2 p = v2(320, 844);
    float scale = v.size.w / 1200;
    vec2 native = vec2_add(v.pos, vec2_scale(p, scale));
    vec2 logical = vec2_scale(vec2_sub(native, v.pos), 1 / scale);
    NEAR(logical.x, p.x); NEAR(logical.y, p.y);
    v = app_fit_view(sz2(480, 900), rc(0, 0, 480, 900));
    NEAR(v.pos.x, 0); NEAR(v.pos.y, 0); NEAR(v.size.h, 900);
}

static void test_city(void)
{
    static building_def defs[3] = {
        {.name = "hut", .height = 100, .cost = {{50}}, .reward = {{0, 5}}},
        {.name = "mine", .height = 120, .cost = {{80}}, .needs = {{0, 10}}, .income = {{30}}, .income_period = 60},
        {.name = "hall", .height = 100, .footprint = {60, 30}, .cost = {{10}}},
    };
    static city c;
    c = (city){.defs = defs, .def_count = 3, .spacing = 100, .buildable = flat_land, .zone_count = 2};
    c.zones[0] = (city_zone){.area = rc(0, 0, 500, 1000)};
    c.zones[1] = (city_zone){.area = rc(500, 0, 500, 1000), .cost = {{100}}, .needs = {{0, 1}}};
    c.cam = (camera){.world = sz2(1000, 1000), .view = rc(0, 0, 1000, 1000), .zoom = 1};
    city_init(&c, NULL);
    CHECK(c.selected == -1 && c.open == 1 && city_open_count(&c) == 1);
    CHECK(city_can_place(&c, v2(200, 300), 0, -1));
    CHECK(!city_can_place(&c, v2(200, 50), 0, -1));     /* terrain */
    CHECK(!city_can_place(&c, v2(700, 300), 0, -1));    /* closed zone */

    /* quick build: tap to place the selected type */
    purse wallet = {{200, 0}};
    c.selected = 0;
    input tap = {.tap = true, .pos = v2(200, 300), .press_pos = v2(200, 300), .pinch = 1};
    city_event ev = city_update(&c, tap, &wallet, 0, 0);
    CHECK(ev.result == CITY_BUILT && c.count == 1 && wallet.v[0] == 150 && wallet.v[1] == 5);
    tap.pos = tap.press_pos = v2(250, 320);
    CHECK(city_update(&c, tap, &wallet, 0, 0).result == CITY_BLOCKED);   /* too close */
    c.selected = 1;
    tap.pos = tap.press_pos = v2(400, 400);
    CHECK(city_update(&c, tap, &wallet, 0, 0).result == CITY_LOCKED_TYPE);
    wallet.v[1] = 10;
    CHECK(city_update(&c, tap, &wallet, 0, 0).result == CITY_BUILT && wallet.v[0] == 70);
    c.selected = -1;
    tap.pos = tap.press_pos = v2(400, 380);
    CHECK(city_update(&c, tap, &wallet, 30, 0).result == CITY_NOT_READY);
    ev = city_update(&c, tap, &wallet, 61, 0);
    CHECK(ev.result == CITY_COLLECTED && wallet.v[0] == 100);
    tap.pos = tap.press_pos = v2(200, 280);
    CHECK(city_update(&c, tap, &wallet, 61, 0).result == CITY_PICKED);

    /* zones: tapping closed land reports it; opening needs and spends */
    tap.pos = tap.press_pos = v2(700, 300);
    ev = city_update(&c, tap, &wallet, 61, 0);
    CHECK(ev.result == CITY_ZONE && ev.zone == 1);
    CHECK(city_next_zone(&c, wallet) == 1 && city_zone_available(&c, 1, wallet));
    CHECK(city_unlock(&c, 1, &wallet) && city_zone_open(&c, 1) && wallet.v[0] == 0 && wallet.v[1] == 10);
    CHECK(!city_unlock(&c, 1, &wallet) && city_next_zone(&c, wallet) == -1);
    CHECK(city_can_place(&c, v2(700, 300), 0, -1));

    /* confirmable placement and moving; footprints may touch, not overlap */
    wallet.v[0] = 100;
    city_begin_place(&c, 2, v2(702, 601));
    CHECK(c.placing == 2 && c.ghost.x == 704 && c.ghost.y == 608);   /* isometric tile centre */
    ev = city_confirm(&c, &wallet, 0);
    CHECK(ev.result == CITY_BUILT && c.placing == -1 && wallet.v[0] == 90);
    int hall = ev.building;
    NEAR(c.items[hall].pos.x, 704); NEAR(c.items[hall].pos.y, 608);
    city_begin_move(&c, hall);
    vec2 original = c.items[hall].pos;
    c.ghost = v2(703, 607);
    city_cancel(&c);
    NEAR(c.items[hall].pos.x, original.x); NEAR(c.items[hall].pos.y, original.y);
    city_begin_place(&c, 2, v2(760, 620));
    CHECK(city_confirm(&c, &wallet, 0).result == CITY_BLOCKED && c.placing == 2);   /* overlaps */
    c.ghost = v2(828, 600);
    CHECK(city_confirm(&c, &wallet, 0).result == CITY_BUILT);   /* 124 apart: diamonds just touch */
    city_begin_move(&c, hall);
    c.ghost = v2(704, 800);
    CHECK(city_confirm(&c, &wallet, 0).result == CITY_MOVED && c.items[hall].pos.y == 800 && wallet.v[0] == 80);
    city_begin_move(&c, hall);
    c.ghost = v2(704, 50);
    CHECK(city_confirm(&c, &wallet, 0).result == CITY_BLOCKED);
    city_cancel(&c);
    CHECK(c.placing == -1 && c.items[hall].pos.y == 800);
    vec2 spot;
    CHECK(city_find_spot(&c, 2, v2(704, 800), &spot) && city_can_place(&c, spot, 2, -1));
}

static void serialize_story(save *s, void *user)
{
    (void)user;
    story_serialize(s);
}

static void test_story(void)
{
    static character cast[2] = {{.id = "ann", .name = "Ann"}, {.id = "bob", .name = "Bob", .right = true}};
    story_setup(cast, 2, &(story_style){0});
    CHECK(story_character("bob") == &cast[1] && !story_character("eve") && !story_active());
    story_line beat[2] = {{"ann", "Hello."}, {"bob", "Hi, Ann."}};
    CHECK(story_play("hello", beat, 2) && story_active() && story_seen("hello"));
    CHECK(!story_play("hello", beat, 2));       /* a beat plays once */
    story_next();
    story_next();
    CHECK(!story_active());
    story_line_add((story_line){"bob", "Hey!", BUBBLE_SHOUT});
    CHECK(story_active());
    story_next();
    CHECK(!story_active());
    CHECK(save_write("story-slot", serialize_story, NULL));
    story_forget();
    CHECK(!story_seen("hello"));
    CHECK(save_read("story-slot", serialize_story, NULL) && story_seen("hello") && !story_seen("other"));
    CHECK(text_length("Привет") == 6 && text_length("") == 0);
}

int main(int argc, char **argv)
{
    test_math();
    test_rect();
    test_camera();
    test_purse();
    test_save();
    test_city();
    test_safe_view();
    test_story();
    printf("engine: %d checks, %d failures\n", checks, failures);

    /* Lua tests: each file returns its failure count (and prints its own summary). */
    script_open("tests/lua;games/relic-rush/lua;games/nile-archive/lua;games/volcano/lua");
    for (int i = 1; i < argc; i++) {
        int r = script_dofile(argv[i]);
        if (r) fprintf(stderr, "%s: %s\n", argv[i], r < 0 ? "error" : "failed");
        failures += r < 0 ? 1 : r;
    }
    script_close();
    return failures ? 1 : 0;
}
