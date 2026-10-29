/* Relic Rush · The Lost Valley — hex match-4 expeditions that restore an island.
 *
 * main.c owns the flow between the two screens, progress and saving, sound,
 * and the debug entry points used for screenshots and the smoke test. */
#include "relic.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef GAME_DATA_DIR
#define GAME_DATA_DIR "games/relic-rush/data"
#endif

relic_state R;

/* The expedition (see docs/art-direction-v2.md). Busts come from the cast lineup. */
static character cast[] = {
    {.id = "elena", .name = "Elena Voss", .role = "Archaeologist, expedition lead", .portrait_path = "characters/elena.png",
     .color = {44, 108, 84, 255}, .mouth = {.46f, .51f}},
    {.id = "mara", .name = "Mara Bell", .role = "Pilot and expedition partner", .portrait_path = "characters/mara.png",
     .color = {150, 74, 40, 255}, .right = true, .mouth = {.60f, .49f}},
    {.id = "tomas", .name = "Tomas Reed", .role = "Island archivist", .portrait_path = "characters/tomas.png",
     .color = {92, 112, 58, 255}, .right = true, .mouth = {.44f, .52f}},
    {.id = "adrian", .name = "Adrian Vale", .role = "Expedition financier", .portrait_path = "characters/adrian.png",
     .color = {104, 48, 92, 255}, .right = true, .mouth = {.46f, .52f}},
};

static const story_line intro[] = {
    {"elena", "The Lost Valley at last. Broken sunstones, silent terraces... someone lived here once.", BUBBLE_THOUGHT},
    {"mara", "And now we do. I'll keep the plane ready. You find out who they were."},
    {"elena", "Every puzzle is an excavation. Let's start digging."},
};

const story_line finale[2] = {
    {"adrian", "The Heart of the Sun... remarkable. My sponsors will be delighted."},
    {"elena", "It stays in the valley, Adrian. That was always the deal."},
};

/* Dialogue text: Lilita One in dark ink on the cream bubble. */
text_style speech_style(float size) { return (text_style){.font = R.font, .size = size, .fill = rgba(74, 50, 28, 255)}; }

void notice(const char *text)
{
    R.toast = text;
    R.toast_time = 3.6f;
}

void tone(float hz)
{
    if (R.sound) sfx_tone(hz, .17f);
}

/* ------------------------------------------------------------------ progress */

static void serialize(save *s, void *user)
{
    (void)user;
    int version = 1, seed = (int)R.prog.seed;
    save_int(s, "version", &version);
    save_int(s, "level", &R.prog.level);
    save_int(s, "seed", &seed);
    save_ints(s, "wallet", R.prog.wallet.v, PURSE_MAX);
    city_serialize(&R.island, s);
    story_serialize(s);
    if (save_is_reading(s)) {
        R.prog.seed = (uint32_t)seed;
        R.prog.level = clampi(R.prog.level, 0, LEVELS);
        if (R.island.count > R.prog.level) R.island.count = R.prog.level;   /* never more wonders than wins */
    }
}

void save_progress(void)
{
    if (!R.test_mode) save_write("progress", serialize, NULL);
}

void start_level(void)
{
    game_start(&R.g, clampi(R.prog.level, 0, LEVELS - 1), R.prog.seed + (uint32_t)R.prog.level * 7919u);
    R.on_island = false;
    R.overlay = OV_NONE;
    R.phase = PH_IDLE;
    R.selected = R.tool = R.hint_a = R.hint_b = -1;
    R.idle_time = 0;
    vfx_reset();
    /* Elena explains a level's twist the first time; later it is a reminder */
    story_line lesson = {"elena", levels[R.g.level].lesson};
    if (R.quiet || !story_play(fmt("level-%d", R.g.level), &lesson, 1)) notice(levels[R.g.level].lesson);
}

/* After the results dialog closes: bank the reward and go build. */
void claim_reward(void)
{
    progress_reward(&R.prog, &R.g);
    save_progress();
    R.on_island = true;
    R.overlay = OV_NONE;
    notice("Your next wonder is ready to restore.");
}

/* ---------------------------------------------------------------- smoke test */

/* --smoke: plays level one through real (injected) mouse clicks, claims the
 * reward, builds the first wonder and enters level two. */
static void click(vec2 p)
{
    SDL_Event e = {0};
    int x, y;
    SDL_RenderLogicalToWindow(app_renderer(), p.x, p.y, &x, &y);
    e.type = SDL_MOUSEBUTTONDOWN;
    e.button.button = SDL_BUTTON_LEFT;
    e.button.windowID = SDL_GetWindowID(SDL_RenderGetWindow(app_renderer()));   /* SDL maps it to logical units */
    e.button.x = x, e.button.y = y;
    SDL_PushEvent(&e);   /* SDL rewrites the coordinates in place to logical units... */
    e.type = SDL_MOUSEBUTTONUP;
    e.button.x = x, e.button.y = y;   /* ...so the release needs window units again */
    SDL_PushEvent(&e);
}

static void smoke(void)
{
    static int stage, frames, wait, partner = -1;
    if (++frames > 8000 || R.g.lost) {
        fprintf(stderr, "smoke test failed at stage %d\n", stage);
        exit(4);
    }
    if (wait > 0) {   /* one click per few frames, so each press and release is its own frame */
        wait--;
        return;
    }
    wait = 3;
    if (story_active()) {   /* tap through the dialogue */
        click(v2(240, 300));
        return;
    }
    if (stage == 0) {
        if (R.overlay == OV_RESULT) {
            if (R.modal_clock > 1.4f) click(rect_center(rc(76, 660, 328, 56))), stage = 1;
            return;
        }
        if (R.phase == PH_IDLE && !R.overlay && R.selected < 0) {
            int best = -1, a = -1, b = -1;
            for (int i = 0; i < CELLS; i++)
                for (int z = 0; z < 3; z++) {
                    int j = hex_neighbor(i, z), v = game_evaluate_move(&R.g, i, j);
                    if (v > best) best = v, a = i, b = j;
                }
            if (a >= 0) click(cell_pos(a)), partner = b;
        } else if (R.selected >= 0 && R.phase == PH_IDLE && partner >= 0) {
            click(cell_pos(partner));
            partner = -1;
        }
    } else if (stage == 1 && R.on_island && !R.overlay) {
        if (R.prog.level != 1) exit(5);
        click(v2(240, 844)), stage = 2;   /* CHOOSE A LOCATION */
    } else if (stage == 2 && R.overlay == OV_WONDER) {
        click(rect_center(rc(76, 632, 328, 56))), stage = 3;
    } else if (stage == 3 && R.island.placing >= 0) {
        click(v2(320, 844)), stage = 4;   /* PLACE & BUILD */
    } else if (stage == 4 && R.island.placing < 0 && !R.overlay) {
        if (R.island.count != 1) exit(6);
        click(v2(240, 844)), stage = 5;   /* PLAY HEX LEVEL 2 */
    } else if (stage == 5 && !R.on_island && !R.overlay) {
        if (R.g.level != 1) exit(7);
        puts("smoke test passed: swaps -> cascades -> win -> claim -> island -> build -> level 2");
        app_quit();
    }
}

/* -------------------------------------------------------------------- frame */

static void frame(float dt)
{
    input in = input_get();
    bool talking = story_active();
    input world = R.overlay || talking ? (input){.pos = in.pos, .pinch = 1} : input_world();
    if (app_arg("smoke")) smoke();
    R.now += dt;
    R.toast_time -= dt;
    if (in.back && !talking) R.overlay = R.overlay ? OV_NONE : OV_PAUSE;

    board_update(dt);
    vfx_update(dt);
    ui_set_enabled(R.overlay == OV_NONE && !talking);
    if (R.on_island) island_screen(world, dt);
    else board_screen(world, dt);
    if (!R.on_island) {
        vfx_draw();
        vfx_particles();
    }
    draw_toast();
    ui_set_enabled(true);
    if (!talking) overlays(dt);   /* a dialogue comes first; dialogs wait for it */
    story_frame(dt);
}

/* ---------------------------------------------------------------- debug setup */

/* An island after n expeditions: n wonders at their suggested spots and the
 * regions a player would have opened by then, stars and compasses to match. */
static void island_with(int n)
{
    static const int opened_at[ISLAND_ZONES] = {0, 2, 3, 5, 7, 9};
    R.prog = (progress){.level = n, .seed = 782341, .wallet = {{340, 115, 92, n * 3, n * 3}}};
    R.island.count = 0;
    R.island.open = 1;
    for (int z = 1; z < ISLAND_ZONES; z++)
        if (n >= opened_at[z]) R.island.open |= 1u << z, R.prog.wallet.v[COMPASSES] -= R.island.zones[z].cost.v[COMPASSES];
    purse spend = {{100000, 100000, 100000}};
    for (int i = 0; i < n; i++) island_place_next(&R.island, &spend, n, 0);
}

static void debug_screens(void)
{
    const char *a;
    if ((a = app_arg("level"))) game_start(&R.g, atoi(a) - 1, 123478), R.on_island = false, R.toast_time = 0;
    if ((a = app_arg("city"))) island_with(clampi(atoi(a), 0, WONDERS)), R.on_island = true, R.toast_time = 0;
    if (app_arg("showcase")) {
        static const vec2 spots[WONDERS] = {{690, 2050}, {930, 2180}, {580, 1870}, {1050, 2000}, {820, 1900},
                                            {1180, 1800}, {760, 1700}, {1040, 1620}, {620, 1550}, {920, 1400}};
        R.prog = (progress){.level = LEVELS, .seed = 782341, .wallet = {{340, 115, 92, 30, 10}}};
        R.island.count = 0;
        R.island.open = 63;
        for (int i = 0; i < WONDERS; i++) {
            vec2 p = spots[i];
            if (!city_can_place(&R.island, p, i, -1)) city_find_spot(&R.island, i, p, &p);
            city_add(&R.island, p, i, 0);
        }
        island_focus(v2(850, 1650), .52f);
        R.on_island = true;
        R.toast_time = 0;
    }
    if (app_arg("overview")) island_focus(v2(ISLAND_W / 2.f, ISLAND_H / 2.f), .25f);
    if (app_arg("placing") && R.island.count < WONDERS) {
        R.prog.level = R.island.count + 1;
        island_begin(R.island.count, true);
        R.toast_time = 0;
    }
    if ((a = app_arg("zone"))) R.zone_card = clampi(atoi(a), 1, ISLAND_ZONES - 1), R.overlay = OV_ZONE, R.on_island = true;
    if (app_arg("victory")) {
        R.prog = (progress){.level = 1, .seed = 782341, .wallet = {{142, 37, 45, 3, 3}}};
        game_start(&R.g, 1, 123478);
        R.g.score = 5860, R.g.relics = 13, R.g.wood = 9, R.g.stone = 14, R.g.won = true;
        vfx_reset();
        R.on_island = false;
        R.overlay = OV_RESULT;
        R.toast_time = 0;
    }
    if ((a = app_arg("card"))) {
        int i = clampi(atoi(a), 0, WONDERS - 1);
        island_with(i);
        R.prog.level = i + 1 > 2 ? i + 1 : 2;
        R.prog.wallet = (purse){{142, 37, 45, R.prog.level * 3, R.prog.level * 3}};
        R.inspect = i;
        R.overlay = OV_WONDER;
        R.on_island = true;
        R.toast_time = 0;
    }
    if ((a = app_arg("fx"))) {   /* fire one special in the middle of level nine */
        int mode = !strcmp(a, "ray") ? 0 : !strcmp(a, "bomb") ? 1 : 2, c = hex_center();
        game_start(&R.g, 8, 123478);
        R.on_island = false;
        vfx_reset();
        R.g.obstacles -= R.g.chain[c] + R.g.ice[c];
        R.g.chain[c] = R.g.ice[c] = 0;
        R.g.tiles[c] = (tile){mode == 2 ? 0 : 3, mode == 0 ? ROW : mode == 1 ? BOMB : PRISM};
        memset(&R.pending, 0, sizeof R.pending);
        R.pending.mask[c] = 1;
        R.pending.hits = 1;
        finish_wave();
        R.toast_time = 0;
    }
    if ((a = app_arg("dialog"))) {   /* guide, pause, failed, finale, a dialogue (intro, mara, tomas, adrian) or a bubble */
        R.toast_time = 0;
        if (!strcmp(a, "intro")) story_play("intro", intro, 3);
        else if (!strcmp(a, "adrian")) island_with(WONDERS), R.on_island = true, story_play("finale", finale, 2);
        else if (!strcmp(a, "mara")) island_with(3), R.on_island = true, story_line_add((story_line){"mara", "New land is yours. Make it your own!", BUBBLE_SHOUT});
        else if (!strcmp(a, "tomas")) island_with(2), R.on_island = true, story_say("tomas", wonders[1].about);
        else if (!strcmp(a, "bubble")) {
            island_with(2), R.on_island = true;
            R.bubble_wonder = 1, R.bubble_text = "A new wonder, exactly where you wanted it.", R.bubble_time = 3.5f;
            island_focus(R.island.items[1].pos, .8f);
        }
        else {
            R.overlay = !strcmp(a, "guide") ? OV_GUIDE : !strcmp(a, "pause") ? OV_PAUSE : !strcmp(a, "failed") ? OV_FAILED : OV_FINALE;
            if (R.overlay == OV_FINALE) island_with(WONDERS), R.on_island = true;
        }
    }
    if (R.overlay && !app_arg("reel")) R.modal_for = R.overlay, R.modal_clock = 1.6f;   /* stills show dialogs settled */
}

static void init(void)
{
    R.font = font_load("fonts/LilitaOne-Regular.ttf");
    story_setup(cast, (int)(sizeof cast / sizeof cast[0]),
                &(story_style){.text = speech_style(21), .name = pal(PAL_CREAM, 15), .bubble = {255, 246, 222, 252},
                               .edge = {102, 68, 39, 255}, .dim = {5, 22, 22, 110}, .portrait_height = .27f, .framed = true,
                               .skip = "SKIP"});
    R.backdrop = tex_load("jungle.jpg");
    R.scenes[0] = tex_load("scene-lagoon.jpg");
    R.scenes[1] = tex_load("scene-temple.jpg");
    R.title = tex_load("title.png");
    for (int i = 0; i < COLORS; i++) R.relics[i] = tex_load(fmt("relics/%d.png", i));
    vfx_init();
    island_setup(&R.island);

    R.sound = true;
    R.inspect = R.zone_card = -1;
    R.test_mode = app_arg("smoke") || app_arg("shot") || app_arg("fresh");
    R.quiet = app_arg("shot") != NULL;   /* stills skip the story unless asked for (--dialog) */
    R.bubble_wonder = -1;
    R.prog = (progress){.seed = 782341};
    if (!app_arg("smoke")) save_read("progress", serialize, NULL);
    if (!R.quiet) story_play("intro", intro, 3);
    start_level();
    if (R.prog.level > R.island.count || R.prog.level >= LEVELS) R.on_island = true;
    debug_screens();
}

int main(int argc, char **argv)
{
    return app_run((app_desc){
                       .title = "Relic Rush - The Lost Valley",
                       .id = "relic-rush",
                       .design = {SCREEN_W, SCREEN_H},
                       .fixed = true,
                       .clear = {9, 33, 31, 255},
                       .data_dir = GAME_DATA_DIR,
                       .init = init,
                       .frame = frame,
                   },
                   argc, argv);
}
