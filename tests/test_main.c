/* Headless tests: engine math and layout, camera, purses, saves, city rules
 * and the Relic Rush match-3 board.  Run with `make test`. */
#include "engine.h"
#include "relic.h"

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

static bool flat_land(vec2 p) { return p.y > 100; }

static void test_city(void)
{
    static building_def defs[2] = {
        {.name = "hut", .height = 100, .cost = {{50}}, .reward = {{0, 5}}},
        {.name = "mine", .height = 120, .cost = {{80}}, .needs = {{0, 10}}, .income = {{30}}, .income_period = 60},
    };
    static city c;
    c = (city){.defs = defs, .def_count = 2, .spacing = 100, .buildable = flat_land, .zone_count = 2};
    c.zones[0] = (city_zone){rc(0, 0, 500, 1000), {{0}}};
    c.zones[1] = (city_zone){rc(500, 0, 500, 1000), {{100}}};
    c.cam = (camera){.world = sz2(1000, 1000), .view = rc(0, 0, 1000, 1000), .zoom = 1};
    city_init(&c, NULL);
    CHECK(c.selected == -1 && c.unlocked == 1);
    CHECK(city_can_place(&c, v2(200, 300), 0));
    CHECK(!city_can_place(&c, v2(200, 50), 0));     /* terrain */
    CHECK(!city_can_place(&c, v2(700, 300), 0));    /* locked zone */

    purse wallet = {{200, 0}};
    c.selected = 0;
    input tap = {.tap = true, .pos = v2(200, 300), .pinch = 1};
    city_event ev = city_update(&c, tap, &wallet, 0);
    CHECK(ev.result == CITY_BUILT && c.count == 1 && wallet.v[0] == 150 && wallet.v[1] == 5);
    tap.pos = v2(250, 320);
    CHECK(city_update(&c, tap, &wallet, 0).result == CITY_BLOCKED);   /* too close */
    c.selected = 1;
    tap.pos = v2(400, 400);
    CHECK(city_update(&c, tap, &wallet, 0).result == CITY_LOCKED_TYPE);
    wallet.v[1] = 10;
    CHECK(city_update(&c, tap, &wallet, 0).result == CITY_BUILT && wallet.v[0] == 70);
    c.selected = -1;
    tap.pos = v2(400, 380);
    CHECK(city_update(&c, tap, &wallet, 30).result == CITY_NOT_READY);
    ev = city_update(&c, tap, &wallet, 61);
    CHECK(ev.result == CITY_COLLECTED && wallet.v[0] == 100);
    CHECK(city_unlock_next(&c, &wallet) && c.unlocked == 2 && wallet.v[0] == 0);
    CHECK(city_can_place(&c, v2(700, 300), 0));
}

/* ------------------------------------------------------------------ board */

static board fixed(const char *rows[BOARD_H])
{
    board b;
    board_init(&b, 1, KINDS);
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++) b.cell[y][x] = (piece){(int8_t)(rows[y][x] - '0'), SP_NONE};
    return b;
}

static bool no_matches_and_full(const board *b)
{
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++) {
            piece p = b->cell[y][x];
            if (p.kind == EMPTY) return false;
            if (p.kind < KINDS && x >= 2 && b->cell[y][x - 1].kind == p.kind && b->cell[y][x - 2].kind == p.kind) return false;
            if (p.kind < KINDS && y >= 2 && b->cell[y - 1][x].kind == p.kind && b->cell[y - 2][x].kind == p.kind) return false;
        }
    return true;
}

static void test_board(void)
{
    static const char *base[BOARD_H] = {"01234501", "12345012", "23450123", "34501234",
                                        "45012345", "50123450", "01234501", "12345012"};
    for (uint32_t seed = 1; seed < 40; seed++) {
        board b;
        board_init(&b, seed, 5 + seed % 2);
        CHECK(no_matches_and_full(&b));
        CHECK(board_find_move(&b, NULL, NULL));
    }

    step st;
    /* four in a row -> row blaster at the swapped cell */
    const char *four[BOARD_H] = {"00102345", "12045012", "23450123", "34501234", "45012345", "50123450", "01234501", "12345012"};
    board b = fixed(four);
    CHECK(!board_swap_works(&b, iv2(6, 6), iv2(7, 7)));     /* not adjacent */
    CHECK(board_swap_works(&b, iv2(2, 0), iv2(2, 1)));
    ivec2 sw[2] = {{2, 0}, {2, 1}};
    board_swap(&b, sw[0], sw[1]);
    CHECK(board_resolve(&b, sw, &st));
    CHECK(st.count == 4 && st.created == 1 && st.by_kind[0] == 4);
    CHECK(b.cell[0][2].special == SP_ROW && b.cell[0][2].kind == 0);
    CHECK(b.cell[0][0].kind == EMPTY && b.cell[0][1].kind == EMPTY && b.cell[0][3].kind == EMPTY);

    /* L shape -> bomb at the corner */
    const char *ell[BOARD_H] = {"00012345", "02345012", "03450123", "34501234", "45012345", "50123450", "01234501", "12345012"};
    b = fixed(ell);
    CHECK(board_resolve(&b, NULL, &st));
    CHECK(st.count == 5 && b.cell[0][0].special == SP_BOMB);

    /* five in a row -> orb */
    const char *five[BOARD_H] = {"00000123", "12345012", "23450123", "34501234", "45012345", "50123450", "01234501", "12345012"};
    b = fixed(five);
    CHECK(board_resolve(&b, NULL, &st));
    CHECK(st.count == 5 && b.cell[0][2].special == SP_ORB && b.cell[0][2].kind == ORB_KIND);

    /* orb swapped with a gem clears every gem of that kind */
    b = fixed(base);
    b.cell[3][3] = (piece){ORB_KIND, SP_ORB};
    int ones = 0;
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++) ones += b.cell[y][x].kind == 1;
    CHECK(board_swap_works(&b, iv2(3, 3), iv2(4, 3)));
    ivec2 orb_swap[2] = {{3, 3}, {4, 3}};
    int target = b.cell[3][4].kind;
    board_swap(&b, orb_swap[0], orb_swap[1]);
    CHECK(board_resolve(&b, orb_swap, &st));
    int target_count = 0;
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++) target_count += st.before[y][x].kind == target;
    CHECK(st.by_kind[target] == target_count && target_count > 0);
    (void)ones;

    /* a row blaster hit by a match clears its whole row */
    b = fixed(base);
    b.cell[4][0] = (piece){2, SP_ROW};
    b.cell[4][1] = (piece){2, SP_NONE};
    b.cell[4][2] = (piece){2, SP_NONE};
    CHECK(board_resolve(&b, NULL, &st));
    for (int x = 0; x < BOARD_W; x++) CHECK(st.cleared[4][x]);
    CHECK(st.fired_count >= 1 && st.fired[0].type == SP_ROW);

    /* gravity keeps order and refills */
    int fall[BOARD_H][BOARD_W];
    piece above = b.cell[3][5];
    board_collapse(&b, fall);
    CHECK(b.cell[4][5].kind == above.kind && fall[4][5] == 1);
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++) CHECK(b.cell[y][x].kind != EMPTY);

    /* long random play: invariants hold through cascades and shuffles */
    board_init(&b, 2024, 6);
    rng r = {99};
    int cascades = 0, specials = 0;
    for (int turn = 0; turn < 600; turn++) {
        ivec2 a, c;
        if (!board_find_move(&b, &a, &c)) {
            board_shuffle(&b);
            continue;
        }
        if (rng_int(&r, 3) == 0) {   /* sometimes pick a random valid move instead of the first */
            for (int k = 0; k < 30; k++) {
                ivec2 p = iv2(rng_int(&r, BOARD_W), rng_int(&r, BOARD_H)), q = ivec2_add(p, rng_int(&r, 2) ? iv2(1, 0) : iv2(0, 1));
                if (board_swap_works(&b, p, q)) {
                    a = p, c = q;
                    break;
                }
            }
        }
        ivec2 pair[2] = {a, c};
        board_swap(&b, a, c);
        bool any = board_resolve(&b, pair, &st);
        CHECK(any);
        while (any) {
            specials += st.created;
            board_collapse(&b, fall);
            any = board_resolve(&b, NULL, &st);
            cascades += any;
        }
        CHECK(no_matches_and_full(&b));
    }
    CHECK(cascades > 0 && specials > 0);
}

int main(int argc, char **argv)
{
    (void)argc, (void)argv;
    test_math();
    test_rect();
    test_camera();
    test_purse();
    test_save();
    test_city();
    test_board();
    printf("%d checks, %d failures\n", checks, failures);
    return failures ? 1 : 0;
}
