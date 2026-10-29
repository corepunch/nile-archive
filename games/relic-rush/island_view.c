/* island_view.c — the restored island: an engine city with the expedition's
 * HUD, region markers in the fog, placement and the next-step panel. */
#include "relic.h"

#include <stdio.h>

void island_focus(vec2 world, float zoom)
{
    camera *cam = &R.island.cam;
    cam->zoom = zoom;
    *cam = camera_clamp(camera_look(*cam, world));
}

/* Start placing the next wonder (or moving a built one) and look at it. */
void island_begin(int i, bool focus)
{
    city *c = &R.island;
    R.overlay = OV_NONE;
    R.inspect = -1;
    if (i == c->count) {
        vec2 spot;
        if (!city_find_spot(c, i, island_suggestion(i), &spot)) {
            notice("Open more land before placing this wonder.");
            return;
        }
        city_begin_place(c, i, spot);
    } else if (i >= 0 && i < c->count) {
        city_begin_move(c, i);
    } else {
        return;
    }
    if (focus) island_focus(vec2_sub(c->ghost, v2(0, 90)), maxf(.65f, c->cam.zoom));
    notice("Tap to choose a spot. Drag the building or scroll the land.");
}

static void confirm_place(void)
{
    city *c = &R.island;
    bool fresh = c->moving < 0;
    city_event ev = city_confirm(c, &R.prog.wallet, app_clock());
    if (ev.result != CITY_BUILT && ev.result != CITY_MOVED) {
        notice("Choose open grass clear of other buildings.");
        return;
    }
    for (int k = 0; k < 24; k++) vfx_emit(vec2_sub(ev.screen, v2(0, 30)), k % 6, false);
    R.bubble_wonder = ev.building;   /* the island answers in a word bubble over the building */
    R.bubble_text = fresh ? "A new wonder, exactly where you wanted it." : "A fresh place for your island wonder.";
    R.bubble_time = 3.5f;
    tone(740);
    if (fresh) {   /* Tomas tells each wonder's story once; the last one brings Adrian */
        const building_def *w = &wonders[c->items[ev.building].type];
        story_play(fmt("wonder-%d", c->items[ev.building].type), &(story_line){"tomas", w->about}, 1);
        if (c->count == WONDERS) {
            story_play("finale", finale, 2);
            R.overlay = OV_FINALE;
        }
    }
    save_progress();
}

static void expand(void)
{
    int z = city_next_zone(&R.island, R.prog.wallet);
    if (z < 0) notice("Your whole island is open to explore.");
    else R.zone_card = z, R.overlay = OV_ZONE;
}

/* Region markers float over the fog: "+" when the region can open now. */
static void draw_markers(const city *c)
{
    for (int z = 1; z < c->zone_count; z++) {
        if (city_zone_open(c, z)) continue;
        vec2 p = camera_to_screen(c->cam, c->zones[z].marker);
        if (p.x < -90 || p.x > SCREEN_W + 90 || p.y < c->cam.view.pos.y - 50 || p.y > rect_max(c->cam.view).y + 40) continue;
        bool ready = city_zone_available(c, z, R.prog.wallet);
        draw_circle(p, 25, rgba(102, 135, 101, 220));
        draw_circle(vec2_add(p, v2(0, -2)), 22, ready ? rgba(249, 211, 104, 255) : rgba(231, 224, 185, 255));
        say_at(ready ? "+" : "?", vec2_add(p, v2(0, -5)), 30, PAL_CREAM, 0);
        draw_round_rect(rc(p.x - 76, p.y + 29, 152, 26), 10, rgba(30, 68, 53, 220));
        say_at(c->zones[z].name, vec2_add(p, v2(0, 40)), 15, PAL_CREAM, 142);
    }
}

static bool map_button(rect r, const char *label, float em, color bg)
{
    draw_round_rect(r, 12, bg);
    say(label, r, em, PAL_CREAM);
    return tapped(r);
}

static void bottom_panel(void)
{
    city *c = &R.island;
    panel(rc(16, 745, 448, 138));
    if (c->placing >= 0) {
        bool ok = city_can_place(c, c->ghost, c->placing, c->moving);
        say_at(wonders[c->placing].name, v2(240, 767), 25, PAL_GOLD, 410);
        say_at("DRAG BUILDING TO MOVE  -  DRAG LAND TO SCROLL", v2(240, 797), 11, PAL_WHITE, 0);
        if (button(rc(32, 824, 140, 40), "CANCEL", true)) city_cancel(c), notice("Your island is unchanged.");
        if (button(rc(191, 824, 257, 40), c->moving < 0 ? "PLACE & BUILD" : "CONFIRM MOVE", ok)) confirm_place();
    } else if (c->count < R.prog.level) {
        say_at(wonders[c->count].name, v2(240, 767), 25, PAL_GOLD, 410);
        say_at("CHOOSE ITS PLACE ON YOUR ISLAND", v2(240, 797), 12, PAL_WHITE, 0);
        if (button(rc(58, 824, 364, 40), "CHOOSE A LOCATION", true)) R.inspect = c->count, R.overlay = OV_WONDER;
    } else if (R.prog.level >= LEVELS) {
        say_at("Your island, your story", v2(240, 767), 27, PAL_GOLD, 0);
        say_at("DRAG TO EXPLORE. MOVE ANY BUILDING.", v2(240, 797), 12, PAL_WHITE, 0);
        if (button(rc(58, 824, 364, 40), "EXPLORE MY ISLAND", true)) notice("Drag the land to explore. Tap a wonder to move it.");
    } else {
        say_at(fmt("%d WONDERS  -  NEW LAND AWAITS", c->count), v2(240, 768), 15, PAL_WHITE, 0);
        say_at("SCROLL THE ISLAND. TAP A BUILDING TO MOVE IT.", v2(240, 797), 11, PAL_WHITE, 0);
        if (button(rc(58, 824, 364, 40), fmt("PLAY HEX LEVEL %d", R.prog.level + 1), true)) {
            if (R.g.level == R.prog.level && !R.g.won && !R.g.lost) R.on_island = false;
            else start_level();
        }
    }
}

void island_screen(input in, float dt)
{
    city *c = &R.island;
    c->cam.view = MAP_VIEW;
    c->draw_over = draw_markers;
    if (!R.overlay) {
        city_event ev = city_update(c, in, &R.prog.wallet, app_clock(), dt);
        if (ev.result == CITY_PICKED) R.inspect = ev.building, R.overlay = OV_WONDER;
        else if (ev.result == CITY_ZONE) R.zone_card = ev.zone, R.overlay = OV_ZONE;
    }

    draw_rect(rc(0, 0, SCREEN_W, SCREEN_H), rgba(22, 110, 119, 255));
    city_draw(c, in, app_clock());
    if (c->placing >= 0) {
        bool ok = city_can_place(c, c->ghost, c->placing, c->moving);
        vec2 p = camera_to_screen(c->cam, c->ghost);
        gfx_clip(MAP_VIEW);
        draw_round_rect(rc(p.x - 60, p.y + 15, 120, 26), 9, rgba(23, 64, 48, 235));
        say_at(ok ? "LOOKS GOOD" : "CAN'T PLACE", vec2_add(p, v2(0, 26)), 13, ok ? PAL_GREEN : PAL_CREAM, 0);
        gfx_unclip();
    }
    vfx_particles();
    R.bubble_time -= dt;
    if (R.bubble_time > 0 && R.bubble_wonder >= 0 && R.bubble_wonder < c->count) {
        rect sprite = camera_rect_to_screen(c->cam, city_sprite_rect(c, c->items[R.bubble_wonder]));
        gfx_clip(MAP_VIEW);
        speech_bubble(rect_point(sprite, v2(.5f, .08f)), R.bubble_text, speech_style(15), rgba(255, 246, 222, 245), rgba(102, 68, 39, 255), 220, BUBBLE_SPEECH);
        gfx_unclip();
    }

    /* the HUD is drawn after the map, so tall buildings never cover buttons */
    draw_rect(rc(0, 0, SCREEN_W, 92), rgba(13, 62, 58, 225));
    draw_header(true);
    rect stats = rc(15, 170, 290, 30);
    draw_round_rect(stats, 10, rgba(22, 68, 52, 220));
    ui_block(stats);
    say_at(fmt("STARS %d   COMPASSES %d", R.prog.wallet.v[STARS], R.prog.wallet.v[COMPASSES]), v2(160, 182), 16, PAL_GOLD, 275);
    if (map_button(rc(318, 170, 146, 30), "EXPAND  +", 16, rgba(47, 105, 67, 245))) expand();
    color dark = rgba(24, 70, 55, 235);
    if (map_button(rc(15, 675, 48, 45), "-", 31, dark)) c->cam = camera_zoom_at(c->cam, 1 / 1.2f, rect_center(MAP_VIEW));
    if (map_button(rc(72, 675, 48, 45), "+", 31, dark)) c->cam = camera_zoom_at(c->cam, 1.2f, rect_center(MAP_VIEW));
    if (map_button(rc(355, 675, 110, 45), "MAP", 20, dark)) {
        if (c->cam.zoom > .35f) island_focus(v2(ISLAND_W / 2.f, ISLAND_H / 2.f), .25f);
        else island_focus(v2(760, 2010), .65f);
    }
    bottom_panel();
}
