/* The engine's tests: math and layout, camera, purses, saves, city and story rules.
 * With the real-renderer tests beside it and tests/games/engine.lua, this is
 * build/test/engine, one start for all of them. See docs/TESTING.md. */
#include "test_runner.c"
#include "viewport.h"
#include "script_modules.h"
#include "third_party/lua/lauxlib.h"

#include <stdio.h>
#include <string.h>

TEST(script_module_roots)
{
    /* A long missing root must not truncate the list or the fallback path.
     * Separate states must own both their root strings and their caches. */
    char roots[1200];
    memset(roots, 'x', 1024);
    strcpy(roots + 1024, ";tests/fixtures/modules/first");
    lua_State *first = luaL_newstate(), *second = luaL_newstate();
    script_modules_open(first, roots);
    script_modules_open(second, "tests/fixtures/modules/second");
    memset(roots, 0, sizeof roots);

    lua_getglobal(first, "require");
    lua_pushliteral(first, "loader.precedence");
    int status = lua_pcall(first, 1, 1, 0);
    CHECKF(status == LUA_OK, "%s", lua_tostring(first, -1));
    CHECK(lua_isstring(first, -1) && !strcmp(lua_tostring(first, -1), "first"));
    lua_getglobal(second, "require");
    lua_pushliteral(second, "loader.precedence");
    status = lua_pcall(second, 1, 1, 0);
    CHECKF(status == LUA_OK, "%s", lua_tostring(second, -1));
    CHECK(lua_isstring(second, -1) && !strcmp(lua_tostring(second, -1), "second"));
    lua_close(first);
    lua_close(second);
}


TEST(math)
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

TEST(tween_retarget)
{
    tween t = {0};
    tween_to(&t, 1, .2f);
    tween_step(&t, .08f);
    float moving = tween_value(t);
    CHECK(moving > 0 && moving < 1);
    tween_to(&t, 1, .2f);
    NEAR(tween_value(t), moving); /* an unchanged target must not restart */
    tween_to(&t, 0, .2f);
    NEAR(tween_value(t), moving); /* interruption preserves the visible value */
    tween_step(&t, .2f);
    CHECK(tween_value(t) == 0);
    tween_step(&t, 1000);
    CHECK(tween_value(t) == 0);
    tween_to(&t, 5, 0);
    CHECK(tween_value(t) == 5);
    tween_to(&t, 1, .2f);
    tween_step(&t, -.1f);
    CHECK(tween_value(t) == 5);
    tween whole = t, split = t;
    tween_step(&whole, .1f);
    for (int i = 0; i < 10; i++) tween_step(&split, .01f);
    NEAR(tween_value(whole), tween_value(split));
}

TEST(rect)
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

TEST(camera)
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

TEST(purse)
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

TEST(save)
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

TEST(safe_view)
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

TEST(city)
{
    static building_def defs[4] = {
        {.name = "hut", .height = 100, .cost = {{50}}, .reward = {{0, 5}}},
        {.name = "mine", .height = 120, .cost = {{80}}, .needs = {{0, 10}}, .income = {{30}}, .income_period = 60},
        {.name = "hall", .height = 100, .size = {2, 2}, .cost = {{10}}},
        {.name = "tower", .sprite = {.size = {200, 300}}, .size = {2, 3}, .pivot = {100, 250}, .base_width = 160},
    };
    static city c;
    c = (city){.defs = defs, .def_count = 4, .spacing = 100, .buildable = flat_land, .zone_count = 2};
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

    /* the ground is seen by the city camera: yaw 30, elevation 40 */
#define T(u, v) city_tile_to_world(&c, v2(u, v))
    NEAR(T(1, 0).x, 45 * .8660254f); NEAR(T(1, 0).y, 45 * .5f * .6427876f);
    NEAR(T(0, 1).x, 45 * -.5f); NEAR(T(0, 1).y, 45 * .8660254f * .6427876f);
    vec2 round_trip = city_world_to_tile(&c, T(3.25f, -2));
    NEAR(round_trip.x, 3.25f); NEAR(round_trip.y, -2);

    /* a sprite is scaled so its base spans the footprint's tiles and stands on its pivot */
    float span = city_base_span(&c, defs[3].size), k = span / 160;
    NEAR(span, 45 * (2 * .8660254f + 3 * .5f));
    NEAR(defs[3].height, 300 * k);
    rect tower = city_sprite_rect(&c, (building){v2(500, 500), 3, 0});
    NEAR(tower.pos.x, 500 - 100 * k); NEAR(tower.pos.y, 500 - 250 * k); NEAR(tower.size.w, 200 * k);
    defs[3].height = 300;
    /* A separately cropped shadow shares the sprite's pixel scale, not its
     * dimensions or crop origin. Its empty margins never enlarge the sprite. */
    defs[3].shadow.size = sz2(400, 180);
    defs[3].shadow_pivot = v2(170, 80);
    rect shadow = city_shadow_rect(&c, (building){v2(500, 500), 3, 0});
    NEAR(shadow.pos.x, 330); NEAR(shadow.pos.y, 420);
    NEAR(shadow.size.w, 400); NEAR(shadow.size.h, 180);
    defs[3].height = 150;   /* both layers must scale around the same ground point */
    shadow = city_shadow_rect(&c, (building){v2(500, 500), 3, 0});
    NEAR(shadow.pos.x, 415); NEAR(shadow.pos.y, 460); NEAR(shadow.size.w, 200);
    NEAR(city_sprite_rect(&c, (building){v2(500, 500), 3, 0}).size.w, 100);
    defs[3].height = 300 * k;
    defs[3].shadow_base_width = 40;   /* a low-resolution layer measures its own footprint */
    shadow = city_shadow_rect(&c, (building){v2(500, 500), 3, 0});
    NEAR(shadow.size.w, 400 * span / 40); NEAR(shadow.pos.x, 500 - 170 * span / 40);
    defs[3].shadow_base_width = 0;
    vec2 odd = city_snap(&c, T(.4f, .1f), 3);   /* 2 x 3: centred on a tile edge one way, a tile centre the other */
    NEAR(odd.x, T(.5f, 0).x); NEAR(odd.y, T(.5f, 0).y);

    /* confirmable placement and moving; footprints may share an edge, not overlap */
    wallet.v[0] = 100;
    vec2 near_corner = vec2_add(T(20.5f, 5.5f), v2(1, 1));
    city_begin_place(&c, 2, near_corner);
    vec2 tile_corner = c.ghost;
    city_begin_place(&c, 2, vec2_add(near_corner, v2(1, 1)));
    NEAR(c.ghost.x, tile_corner.x); NEAR(c.ghost.y, tile_corner.y);
    CHECK(c.placing == 2);
    NEAR(c.ghost.x, T(20.5f, 5.5f).x); NEAR(c.ghost.y, T(20.5f, 5.5f).y);   /* 2 x 2 centres on a tile corner */
    ev = city_confirm(&c, &wallet, 0);
    CHECK(ev.result == CITY_BUILT && c.placing == -1 && wallet.v[0] == 90);
    int hall = ev.building;
    NEAR(c.items[hall].pos.x, T(20.5f, 5.5f).x); NEAR(c.items[hall].pos.y, T(20.5f, 5.5f).y);
    city_begin_move(&c, hall);
    vec2 original = c.items[hall].pos;
    c.ghost = vec2_add(original, v2(1, 7));
    city_cancel(&c);
    NEAR(c.items[hall].pos.x, original.x); NEAR(c.items[hall].pos.y, original.y);
    city_begin_place(&c, 2, T(21.5f, 5.5f));
    CHECK(city_confirm(&c, &wallet, 0).result == CITY_BLOCKED && c.placing == 2);   /* one tile over: overlaps */
    c.ghost = T(22.5f, 5.5f);
    CHECK(city_confirm(&c, &wallet, 0).result == CITY_BUILT);   /* two tiles over: they share an edge */
    city_begin_move(&c, hall);
    c.ghost = T(20.5f, 12.5f);
    CHECK(city_confirm(&c, &wallet, 0).result == CITY_MOVED && wallet.v[0] == 80);
    NEAR(c.items[hall].pos.y, T(20.5f, 12.5f).y);
    city_begin_move(&c, hall);
    c.ghost = v2(704, 50);
    CHECK(city_confirm(&c, &wallet, 0).result == CITY_BLOCKED);
    city_cancel(&c);
    CHECK(c.placing == -1);
    NEAR(c.items[hall].pos.y, T(20.5f, 12.5f).y);

    /* dragging the ghost follows the finger; letting go lands it on the grid */
    vec2 start = T(10.5f, 10.5f);
    city_begin_place(&c, 2, start);
    NEAR(c.ghost.x, start.x); NEAR(c.ghost.y, start.y);
    vec2 grab = vec2_add(start, v2(0, -34));
    input drag = {.pressed = true, .down = true, .pos = grab, .press_pos = grab, .pinch = 1};
    city_update(&c, drag, &wallet, 0, 0);
    drag = (input){.down = true, .dragging = true, .pos = vec2_add(grab, v2(40, 10)), .press_pos = grab, .pinch = 1};
    city_update(&c, drag, &wallet, 0, 0);
    NEAR(c.ghost.x, start.x + 40); NEAR(c.ghost.y, start.y + 10);   /* not snapped mid-drag */
    CHECK(c.held);
    vec2 land = city_snap(&c, c.ghost, 2);
    drag.down = false, drag.released = true;
    city_update(&c, drag, &wallet, 0, 0);
    NEAR(c.ghost.x, land.x); NEAR(c.ghost.y, land.y);
    CHECK(!c.held);
    city_cancel(&c);
    /* clearance widens every sized footprint without scaling its sprite */
    CHECK(city_can_place(&c, T(22.5f, 12.5f), 2, -1));   /* two tiles from the moved hall: edges touch */
    c.clearance = sz2(1, 1);
    CHECK(!city_can_place(&c, T(22.5f, 12.5f), 2, -1) && city_can_place(&c, T(23.5f, 12.5f), 2, -1));
    NEAR(city_sprite_rect(&c, (building){v2(500, 500), 3, 0}).size.w, 200 * k);
    c.clearance = sz2(0, 0);
    vec2 spot;
    CHECK(city_find_spot(&c, 2, T(20.5f, 12.5f), &spot) && city_can_place(&c, spot, 2, -1));
#undef T
}

/* Gesture arbitration: a map drag must never turn into a building move. */
static void move_city(city *c)
{
    static building_def defs[]={{.name="income",.height=100,.income={{5}},.income_period=60}};
    *c=(city){.defs=defs,.def_count=1,.movable=true};
    c->cam=(camera){.world={2000,2000},.view={{0,0},{480,900}},.center={1000,1000},.zoom=1,.min_zoom=1,.max_zoom=2};
    city_init(c,NULL);
    city_add(c,city_snap(c,v2(1000,1000),0),0,0);
}

static input building_press(const city *c)
{
    vec2 p=camera_to_screen(c->cam,vec2_sub(c->items[0].pos,v2(0,30)));
    return (input){.pos=p,.press_pos=p,.pressed=true,.down=true,.pinch=1};
}

TEST(city_hold)
{
    static city c;
    purse wallet={{100}};
    move_city(&c);
    vec2 original=c.items[0].pos, cam=c.cam.center;
    input in=building_press(&c);
    city_update(&c,in,&wallet,100,0);
    in.pressed=false;in.dragging=true;in.drag=v2(-40,0);in.pos=vec2_add(in.pos,in.drag);
    city_update(&c,in,&wallet,100,.1f);
    CHECK(c.placing<0 && c.moving<0 && !c.held);
    NEAR(c.cam.center.x,cam.x+40);
    in.dragging=false;in.drag=v2(0,0);
    city_update(&c,in,&wallet,100,1);
    CHECK(c.placing<0); /* no late re-arming after a pan */
    in.down=false;in.released=true;
    CHECK(city_update(&c,in,&wallet,100,0).result==CITY_NONE);
    NEAR(c.items[0].pos.x,original.x);

    move_city(&c);in=building_press(&c);
    city_update(&c,in,&wallet,100,0);in.pressed=false;
    city_update(&c,in,&wallet,100,.49f);
    CHECK(c.placing<0 && !c.held);
    city_update(&c,in,&wallet,100,.02f);
    CHECK(c.moving==0 && c.held && c.lift>0);
    in.pos=vec2_add(in.pos,v2(64,17));in.dragging=true;in.drag=v2(64,17);
    city_update(&c,in,&wallet,100,.1f);
    NEAR(c.ghost.x,original.x+64);NEAR(c.ghost.y,original.y+17);
    in.down=false;in.released=true;in.drag=v2(0,0);
    CHECK(city_update(&c,in,&wallet,100,0).result==CITY_NONE);
    CHECK(!c.held && c.placing==0 && wallet.v[0]==100);
    NEAR(c.items[0].pos.x,original.x);NEAR(c.items[0].pos.y,original.y);
    vec2 snapped=city_snap(&c,vec2_add(original,v2(64,17)),0);
    NEAR(c.ghost.x,snapped.x);NEAR(c.ghost.y,snapped.y);
    input tap={.pressed=true,.down=true,.pos={400,700},.press_pos={400,700},.pinch=1};
    city_update(&c,tap,&wallet,100,0);
    tap.pressed=tap.down=false;tap.released=tap.tap=true;
    city_update(&c,tap,&wallet,100,0);
    NEAR(c.ghost.x,snapped.x);NEAR(c.ghost.y,snapped.y); /* tapping land cannot move the preview */
    CHECK(city_confirm(&c,&wallet,100).result==CITY_MOVED && wallet.v[0]==100);
    CHECK(city_confirm(&c,&wallet,100).result==CITY_NONE);
    NEAR(c.items[0].pos.y,snapped.y);

    move_city(&c);in=building_press(&c);
    city_update(&c,in,&wallet,100,0);in.pressed=false;
    city_update(&c,in,&wallet,100,.51f);city_cancel(&c);
    in.down=false;in.released=in.tap=true;
    CHECK(city_update(&c,in,&wallet,100,0).result==CITY_NONE && wallet.v[0]==100);
    CHECK(c.placing<0 && !c.held);
    NEAR(c.items[0].pos.x,original.x);

    for (int interrupt=0;interrupt<9;interrupt++) {
        move_city(&c);in=building_press(&c);
        city_update(&c,in,&wallet,100,0);in.pressed=false;
        city_update(&c,in,&wallet,100,.2f);
        input changed=in;
        switch (interrupt) {
        case 0: changed.captured=true;break;
        case 1: changed.multi_touch=true;break;
        case 2: changed.pinch=1.1f;break;
        case 3: changed.dragging=true;break;
        case 4: changed.down=false;break; /* focus loss / pointer cancellation */
        case 5: changed.pos=v2(-1,-1);break;
        case 6: changed.wheel=1;break;
        case 7: c.movable=false;break;
        case 8: changed.back=true;break;
        }
        city_update(&c,changed,&wallet,100,1);
        CHECK(c.placing<0 && !c.held);
        city_update(&c,in,&wallet,100,1);
        CHECK(c.placing<0 && !c.held);
        if (interrupt==0 || interrupt==1 || interrupt==2 || interrupt==6 || interrupt==8) {
            in.down=false;in.released=in.tap=true;
            CHECK(city_update(&c,in,&wallet,100,0).result==CITY_NONE && wallet.v[0]==100);
        }
    }
    move_city(&c);in=building_press(&c);in.captured=true;
    city_update(&c,in,&wallet,100,0);in.pressed=false;in.captured=false;
    city_update(&c,in,&wallet,100,1);
    CHECK(c.placing<0); /* a press that began on UI cannot become a world hold */

    move_city(&c);in=building_press(&c);
    city_update(&c,in,&wallet,100,0);in.pressed=false;in.down=false;in.released=in.tap=true;
    CHECK(city_update(&c,in,&wallet,100,.1f).result==CITY_COLLECTED && wallet.v[0]==105);
    move_city(&c);c.selected=0;in=building_press(&c);
    city_update(&c,in,&wallet,100,0);in.pressed=false;
    city_update(&c,in,&wallet,100,1);
    CHECK(c.placing<0); /* quick-build selection takes precedence */

    move_city(&c);in=building_press(&c);
    city_update(&c,in,&wallet,100,0);in.pressed=false;
    city_update(&c,in,&wallet,100,.51f);
    in.multi_touch=true;
    city_update(&c,in,&wallet,100,.1f);
    CHECK(!c.held && c.placing==0 && c.moving==0);
    NEAR(c.items[0].pos.x,original.x); /* interruption never commits a held preview */
    city_cancel(&c);
}

static void serialize_story(save *s, void *user)
{
    (void)user;
    story_serialize(s);
}

TEST(story)
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
    if (argc > 2 && !strcmp(argv[1], "--script")) {   /* a Lua tool with every game's modules, as economy_audit.py uses */
        script_open("tests/lua;games/relic-rush/lua;games/nile-archive/lua;games/emergency/lua");
        script_dofile(argv[2]);
        script_close();
        if (test_failures()) fprintf(stderr, "%s\n", T.notes[0]);
        return test_failures() != 0;
    }
    return test_main("engine", "tests/lua", "games/relic-rush/data", argc, argv);
}
