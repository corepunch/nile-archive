/* Relic Rush — match-3 digs that fund an archaeologist's camp.
 *
 * Levels pay coins and stars; the camp (an engine `city`) spends coins on
 * buildings that unlock with stars and produce coins over time. Works in
 * landscape and portrait: layouts are cut from whatever screen rect we get. */
#include "relic.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef GAME_DATA_DIR
#define GAME_DATA_DIR "games/relic-rush/data"
#endif

enum { COINS, STARS };
enum { MAX_LEVELS = 30, MAX_GHOSTS = BOARD_W * BOARD_H, MAX_BEAMS = 24 };

/* ------------------------------------------------------------------ content */

typedef struct {
    int moves, target, kinds, goals;
    struct { int kind, count; } goal[2];
} level_def;

static level_def level_get(int n)
{
    level_def d = {.kinds = n < 6 ? 5 : 6};
    d.moves = 22 - n / 8 + (n % 3 == 2 ? 3 : 0);
    d.target = n < 6 ? 1100 + n * 220 : 900 + n * 150;   /* six gem kinds cascade less: lower the bar */
    if (n >= 1) {
        d.goal[0].kind = (n * 2) % d.kinds;
        d.goal[0].count = 12 + n * 3 / 2;
        d.goals = 1;
    }
    if (n >= 5 && n % 2 == 1) {
        d.goal[1].kind = (n * 2 + 3) % d.kinds;
        d.goal[1].count = 10 + n;
        d.goals = 2;
    }
    return d;
}

static const color gem_colors[KINDS] = {{255, 80, 100, 255}, {80, 230, 140, 255}, {90, 150, 255, 255},
                                        {255, 210, 80, 255}, {190, 120, 255, 255}, {220, 240, 255, 255}};

#define CAMP(name, about, path, height, cost, stars, income, period) \
    {name, about, path, {0}, height, (height) * .1f, {{cost}}, {{0}}, {{0, stars}}, {{income}}, period}

static building_def camp_defs[] = {
    CAMP("Tent", "Diggers' shelter", "buildings/0.png", 140, 120, 0, 30, 60),
    CAMP("Dig Site", "Turns sand into coins", "buildings/1.png", 165, 300, 3, 70, 150),
    CAMP("Workshop", "Restores the finds", "buildings/2.png", 160, 500, 6, 90, 180),
    CAMP("Market", "Trades with the caravans", "buildings/3.png", 165, 800, 10, 160, 300),
    CAMP("Museum", "Shows off the relics", "buildings/4.png", 185, 1300, 16, 300, 600),
    CAMP("Obelisk", "A monument to the expedition", "buildings/5.png", 230, 2000, 24, 0, 0),
};
enum { CAMP_TYPES = sizeof camp_defs / sizeof camp_defs[0] };

/* Must match tools/make_art.py: river centre x = 250 + 90 sin(y / 260), width 170; oasis ellipse. */
static bool camp_buildable(vec2 p)
{
    if (p.y < 140 || p.y > 1540) return false;
    if (p.x < 250 + 90 * sinf(p.y / 260) + 85 + 70) return false;
    return vec2_ellipse(vec2_sub(p, v2(1650, 1180)), v2(190 * 1.35f, 110 * 1.5f)) > 1;
}

/* -------------------------------------------------------------------- state */

typedef enum { PHASE_IDLE, PHASE_SWAP, PHASE_SWAP_BACK, PHASE_CLEAR, PHASE_FALL, PHASE_OVER } phase;
typedef enum { MODAL_NONE, MODAL_WIN, MODAL_FAIL, MODAL_LEVELS } modal;

static struct {
    /* progress */
    purse wallet;
    int stars[MAX_LEVELS];
    int next_level;
    city camp;

    /* current level */
    bool playing;
    int level;
    level_def def;
    board b;
    int moves, score, combo, goal_left[2];
    phase phase;
    float t;
    ivec2 swap_a, swap_b;
    bool swap_ok;
    ivec2 sel;
    bool has_sel, drag_armed;
    vec2 offset[BOARD_H][BOARD_W];
    float vel[BOARD_H][BOARD_W], pop[BOARD_H][BOARD_W];
    struct { ivec2 cell; piece p; } ghosts[MAX_GHOSTS];
    int ghost_count;
    struct { vec2 a, b; float t; color c; } beams[MAX_BEAMS];
    float idle;
    ivec2 hint_a, hint_b;
    rect board_rect;
    float cell;

    modal modal;
    float modal_time;
    int result_stars, result_coins;
    bool first_clear;

    texture gems[KINDS], orb, coin, star, hourglass, backdrop;
    font *display, *body;
    ui_theme theme;
    text_style big, heading, text, small, number, popup;
} G;

static int total_stars(void)
{
    int n = 0;
    for (int i = 0; i < MAX_LEVELS; i++) n += G.stars[i];
    return n;
}

static void serialize(save *s, void *user)
{
    int version = 1;
    save_int(s, "version", &version);
    save_int(s, "coins", &G.wallet.v[COINS]);
    save_ints(s, "stars", G.stars, MAX_LEVELS);
    save_int(s, "next_level", &G.next_level);
    city_serialize(&G.camp, s);
    if (save_is_reading(s)) G.wallet.v[STARS] = total_stars();
}

static void save_progress(void) { save_write("progress", serialize, NULL); }

/* ------------------------------------------------------------ board view */

static vec2 cell_center(ivec2 p) { return rect_point(rect_make(G.board_rect.pos, sz2s(G.cell)), v2(p.x + .5f, p.y + .5f)); }
static vec2 piece_center(ivec2 p) { return vec2_add(cell_center(p), vec2_scale(G.offset[p.y][p.x], G.cell)); }
static ivec2 cell_at(vec2 screen) { return vec2_ivec(vec2_scale(vec2_sub(screen, G.board_rect.pos), 1 / G.cell)); }

static void start_level(int n)
{
    G.playing = true;
    G.level = clampi(n, 0, MAX_LEVELS - 1);
    G.def = level_get(G.level);
    board_init(&G.b, 7919u * (G.level + 1) + (uint32_t)app_clock(), G.def.kinds);
    G.moves = G.def.moves;
    G.score = 0;
    G.combo = 1;
    for (int i = 0; i < 2; i++) G.goal_left[i] = G.def.goal[i].count;
    G.phase = PHASE_IDLE;
    G.has_sel = false;
    G.idle = 0;
    G.ghost_count = 0;
    memset(G.offset, 0, sizeof G.offset);
    memset(G.vel, 0, sizeof G.vel);
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++) G.offset[y][x] = v2(0, -BOARD_H - (BOARD_H - y) * .4f), G.pop[y][x] = 1;
    G.phase = PHASE_FALL;    /* the first board drops in */
    G.modal = MODAL_NONE;
    fx_clear();
}

static void back_to_camp(void)
{
    G.playing = false;
    G.modal = MODAL_NONE;
    fx_clear();
}

static bool goals_done(void)
{
    for (int i = 0; i < G.def.goals; i++)
        if (G.goal_left[i] > 0) return false;
    return true;
}

static void add_beam(vec2 a, vec2 b, color c)
{
    for (int i = 0; i < MAX_BEAMS; i++)
        if (G.beams[i].t <= 0) {
            G.beams[i].a = a, G.beams[i].b = b, G.beams[i].t = 1, G.beams[i].c = c;
            return;
        }
}

static void begin_clear(const step *st)
{
    G.ghost_count = 0;
    vec2 sum = v2(0, 0);
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++) {
            if (!st->cleared[y][x]) continue;
            piece was = st->before[y][x];
            ivec2 p = iv2(x, y);
            G.ghosts[G.ghost_count].cell = p;
            G.ghosts[G.ghost_count++].p = was;
            sum = vec2_add(sum, cell_center(p));
            if (was.kind >= 0 && was.kind < KINDS) fx_burst(cell_center(p), 6, gem_colors[was.kind], G.cell * 3, G.cell * .14f);
            if (G.b.cell[y][x].kind != EMPTY) G.pop[y][x] = 0;   /* a new special appears here */
        }
    for (int i = 0; i < st->fired_count; i++) {
        vec2 c = cell_center(st->fired[i].at);
        rect br = G.board_rect;
        color gold = rgba(255, 230, 150, 255);
        if (st->fired[i].type == SP_ROW) add_beam(v2(br.pos.x, c.y), v2(rect_max(br).x, c.y), gold);
        if (st->fired[i].type == SP_COL) add_beam(v2(c.x, br.pos.y), v2(c.x, rect_max(br).y), gold);
        if (st->fired[i].type == SP_BOMB) fx_sparkle(c, G.cell * 1.6f, rgba(255, 170, 80, 255));
        if (st->fired[i].type == SP_ORB) fx_sparkle(c, G.cell * 2.2f, rgba(200, 160, 255, 255));
    }
    int gained = (st->count * 10 + st->created * 50 + st->fired_count * 30) * G.combo;
    G.score += gained;
    for (int i = 0; i < G.def.goals; i++) G.goal_left[i] = clampi(G.goal_left[i] - st->by_kind[G.def.goal[i].kind], 0, 999);
    if (G.ghost_count) fx_text(vec2_scale(sum, 1.0f / G.ghost_count), &G.popup, fmt("+%d", gained));
    static const char *cheers[] = {"Nice!", "Great!", "Amazing!", "Legendary!"};
    if (G.combo >= 2) fx_text(vec2_sub(rect_center(G.board_rect), v2(0, G.cell)), &G.big, cheers[clampi(G.combo - 2, 0, 3)]);
    G.phase = PHASE_CLEAR;
    G.t = 0;
}

static void finish_level(bool won)
{
    G.phase = PHASE_OVER;
    G.modal_time = 0;
    if (!won) {
        G.modal = MODAL_FAIL;
        return;
    }
    int bonus = G.moves * 100;
    G.score += bonus;
    if (bonus) fx_text(rect_center(G.board_rect), &G.big, fmt("Bonus +%d", bonus));
    G.result_stars = 1 + (G.score >= G.def.target * 3 / 2) + (G.score >= G.def.target * 2);
    G.first_clear = G.stars[G.level] == 0;
    G.result_coins = (60 + 15 * G.level + 30 * G.result_stars) / (G.first_clear ? 1 : 2);
    if (G.result_stars > G.stars[G.level]) G.stars[G.level] = G.result_stars;
    if (G.level == G.next_level && G.next_level < MAX_LEVELS - 1) G.next_level++;
    G.wallet.v[COINS] += G.result_coins;
    G.wallet.v[STARS] = total_stars();
    save_progress();
    G.modal = MODAL_WIN;
}

static void settle(void)
{
    G.combo = 1;
    if ((goals_done() && G.score >= G.def.target) || G.moves <= 0) {
        finish_level(goals_done() && G.score >= G.def.target);
        return;
    }
    if (!board_find_move(&G.b, &G.hint_a, &G.hint_b)) {
        board_shuffle(&G.b);
        ui_toast("No moves left — shuffling the relics");
        for (int y = 0; y < BOARD_H; y++)
            for (int x = 0; x < BOARD_W; x++) G.pop[y][x] = 0;
    }
    G.phase = PHASE_IDLE;
    G.idle = 0;
}

static void try_swap(ivec2 a, ivec2 c)
{
    G.has_sel = G.drag_armed = false;
    if (!board_inside(c) || ivec2_manhattan(a, c) != 1) return;
    G.swap_a = a;
    G.swap_b = c;
    G.swap_ok = board_swap_works(&G.b, a, c);
    G.phase = PHASE_SWAP;
    G.t = 0;
}

static void board_update(input world, float dt)
{
    G.t += dt;
    for (int i = 0; i < MAX_BEAMS; i++) G.beams[i].t -= dt * 2.5f;
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++) G.pop[y][x] = minf(1, G.pop[y][x] + dt * 4);

    switch (G.phase) {
    case PHASE_IDLE: {
        G.idle += dt;
        if (G.modal != MODAL_NONE) break;
        ivec2 c = cell_at(world.pos);
        if (world.pressed && rect_contains(G.board_rect, world.pos)) {
            G.idle = 0;
            if (G.has_sel && ivec2_manhattan(G.sel, c) == 1) {
                try_swap(G.sel, c);
            } else if (G.has_sel && ivec2_eq(G.sel, c)) {
                G.has_sel = false;
            } else {
                G.sel = c;
                G.has_sel = G.drag_armed = true;
            }
        }
        if (G.drag_armed && world.down) {
            vec2 d = vec2_sub(world.pos, world.press_pos);
            if (vec2_len(d) > G.cell * .35f)
                try_swap(G.sel, ivec2_add(G.sel, fabsf(d.x) > fabsf(d.y) ? iv2(d.x > 0 ? 1 : -1, 0) : iv2(0, d.y > 0 ? 1 : -1)));
        }
        if (world.released) G.drag_armed = false;
        break;
    }
    case PHASE_SWAP:
        if (G.t < .16f) break;
        if (!G.swap_ok) {
            board_swap(&G.b, G.swap_a, G.swap_b);   /* show it swapped, then swap back */
            G.phase = PHASE_SWAP_BACK;
            G.t = 0;
            break;
        }
        board_swap(&G.b, G.swap_a, G.swap_b);
        G.moves--;
        step st;
        ivec2 pair[2] = {G.swap_a, G.swap_b};
        if (board_resolve(&G.b, pair, &st)) begin_clear(&st);
        else settle();
        break;
    case PHASE_SWAP_BACK:
        if (G.t >= .2f) {
            board_swap(&G.b, G.swap_a, G.swap_b);
            G.phase = PHASE_IDLE;
        }
        break;
    case PHASE_CLEAR:
        if (G.t < .24f) break;
        G.ghost_count = 0;
        int fall[BOARD_H][BOARD_W];
        board_collapse(&G.b, fall);
        for (int y = 0; y < BOARD_H; y++)
            for (int x = 0; x < BOARD_W; x++) {
                G.offset[y][x] = vec2_add(G.offset[y][x], v2(0, (float)-fall[y][x]));
                G.vel[y][x] = 0;
            }
        G.phase = PHASE_FALL;
        break;
    case PHASE_FALL: {
        bool moving = false;
        for (int y = 0; y < BOARD_H; y++)
            for (int x = 0; x < BOARD_W; x++) {
                if (G.offset[y][x].y >= 0) continue;
                G.vel[y][x] += 55 * dt;
                G.offset[y][x].y = minf(0, G.offset[y][x].y + G.vel[y][x] * dt);
                moving = true;
            }
        if (moving) break;
        step st;
        if (board_resolve(&G.b, NULL, &st)) {
            G.combo++;
            begin_clear(&st);
        } else {
            settle();
        }
        break;
    }
    case PHASE_OVER: break;
    }
}

/* ------------------------------------------------------------ board draw */

static void draw_piece(piece p, vec2 center, float scale, float alpha)
{
    if (p.kind == EMPTY) return;
    float size = G.cell * .9f * scale;
    rect r = rect_centered(center, sz2s(size));
    color tint = color_alpha(WHITE, alpha);
    float now = (float)app_time();
    if (p.special == SP_ORB) {
        draw_glow(center, size * .75f, rgba(255, 220, 255, (int)(110 * alpha)), rgba(255, 200, 255, 0));
        draw_image_rot(G.orb, r, now * 1.5f, tint);
        return;
    }
    if (p.special == SP_BOMB) draw_glow(center, size * (.7f + .06f * sinf(now * 6)), rgba(255, 160, 60, (int)(150 * alpha)), rgba(255, 120, 40, 0));
    draw_image(G.gems[p.kind], r, tint);
    color line = rgba(255, 255, 255, (int)(220 * alpha));
    float h = size * .42f, w = size * .07f;
    if (p.special == SP_ROW || p.special == SP_COL) {
        vec2 d = p.special == SP_ROW ? v2(1, 0) : v2(0, 1), n = v2(d.y, d.x);
        for (int s = -1; s <= 1; s += 2) {
            vec2 o = vec2_scale(n, s * size * .12f);
            draw_line(vec2_add(center, vec2_add(o, vec2_scale(d, -h))), vec2_add(center, vec2_add(o, vec2_scale(d, h))), w, line);
        }
        for (int s = -1; s <= 1; s += 2) {
            vec2 tip = vec2_add(center, vec2_scale(d, s * (h + size * .1f)));
            vec2 base = vec2_add(center, vec2_scale(d, s * h * .7f));
            vec2 pts[3] = {tip, vec2_add(base, vec2_scale(n, size * .16f)), vec2_sub(base, vec2_scale(n, size * .16f))};
            if (s < 0) pts[1] = vec2_sub(base, vec2_scale(n, size * .16f)), pts[2] = vec2_add(base, vec2_scale(n, size * .16f));
            draw_poly(pts, 3, line);
        }
    }
    if (p.special == SP_BOMB) draw_ring(center, size * .44f, size * .05f, rgba(255, 240, 200, (int)(200 * alpha)));
}

static void draw_board(void)
{
    rect br = G.board_rect;
    draw_shadow(rect_offset(rect_inflate(br, 14), v2(0, 10)), 26, 30, rgba(0, 0, 0, 120));
    draw_round_rect_grad(rect_inflate(br, 14), 24, hex(0x4A3322), hex(0x2E1F15));
    draw_round_rect_line(rect_inflate(br, 14), 24, 3, hex(0xE2B469));
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++) {
            rect c = rect_inflate(rect_centered(cell_center(iv2(x, y)), sz2s(G.cell)), -2);
            draw_round_rect(c, 8, (x + y) % 2 ? rgba(255, 236, 200, 26) : rgba(255, 236, 200, 12));
        }
    if (G.has_sel) draw_round_rect_line(rect_inflate(rect_centered(cell_center(G.sel), sz2s(G.cell)), -3), 10, 3, hex(0xFFE08A));

    gfx_clip(rect_inflate(br, 4));
    float now = (float)app_time();
    bool hinting = G.phase == PHASE_IDLE && G.idle > 5 && G.modal == MODAL_NONE;
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++) {
            ivec2 p = iv2(x, y);
            vec2 at = piece_center(p);
            if (G.phase == PHASE_SWAP || G.phase == PHASE_SWAP_BACK) {
                float t = ease_in_out(G.t / (G.phase == PHASE_SWAP ? .16f : .2f));
                ivec2 from = ivec2_eq(p, G.swap_a) ? G.swap_a : G.swap_b, to = ivec2_eq(p, G.swap_a) ? G.swap_b : G.swap_a;
                bool moving = ivec2_eq(p, G.swap_a) || ivec2_eq(p, G.swap_b);
                /* SWAP moves each piece across; on SWAP_BACK the cells already hold the swapped pieces, so the same path returns them */
                if (moving) at = vec2_lerp(cell_center(from), cell_center(to), t);
            }
            float scale = ease_out_back(G.pop[y][x]);
            if (hinting && (ivec2_eq(p, G.hint_a) || ivec2_eq(p, G.hint_b))) scale *= 1 + .08f * sinf(now * 8);
            if (G.has_sel && ivec2_eq(p, G.sel)) scale *= 1.06f;
            draw_piece(G.b.cell[y][x], at, scale, 1);
        }
    float t = saturate(G.t / .24f);
    for (int i = 0; i < G.ghost_count; i++) {
        vec2 at = cell_center(G.ghosts[i].cell);
        draw_glow(at, G.cell * .6f, rgba(255, 245, 210, (int)(150 * (1 - t))), rgba(255, 245, 210, 0));
        draw_piece(G.ghosts[i].p, at, 1 + t * .3f - t * t * 1.1f, 1 - t);
    }
    gfx_unclip();
    SDL_SetRenderDrawBlendMode(app_renderer(), SDL_BLENDMODE_ADD);
    for (int i = 0; i < MAX_BEAMS; i++)
        if (G.beams[i].t > 0) {
            float k = G.beams[i].t;
            draw_line(G.beams[i].a, G.beams[i].b, G.cell * .5f * k, color_alpha(G.beams[i].c, k * .5f));
            draw_line(G.beams[i].a, G.beams[i].b, G.cell * .14f * k, color_alpha(WHITE, k));
        }
    SDL_SetRenderDrawBlendMode(app_renderer(), SDL_BLENDMODE_BLEND);
}

/* --------------------------------------------------------------- widgets */

static rect amount(vec2 pos, vec2 pivot, texture icon, const char *text, text_style s)
{
    float icon_size = s.size * 1.3f, w = icon_size + 6 + text_measure(s, text).w;
    rect box = rect_anchor(pos, sz2(w, icon_size), pivot);
    draw_image(icon, rect_left(box, icon_size), WHITE);
    text_draw(s, rect_point(rect_offset(box, v2(icon_size + 6, 0)), v2(0, .5f)), v2(0, .5f), text);
    return box;
}

static void star_row(rect r, int filled, float appear)
{
    for (int i = 0; i < 3; i++) {
        rect cell = rect_col(r, 3, i, 8);
        float k = ease_out_back(saturate(appear * 3 - i * .7f));
        rect s = rect_scale(rect_fit(cell, sz2s(1)), (i == 1 ? 1.15f : .95f) * maxf(k, .001f));
        s = rect_offset(s, v2(0, i == 1 ? -8 : 0));
        if (i < filled) {
            draw_glow(rect_center(s), s.size.w * .7f, rgba(255, 220, 120, 90), rgba(255, 220, 120, 0));
            draw_image(G.star, s, WHITE);
        } else {
            draw_image(G.star, s, rgba(40, 30, 20, 150));
        }
    }
}

static void header(rect bar, const char *title)
{
    draw_rect_grad(bar, hex(0x4A2F1C), hex(0x33200F));
    draw_rect(rect_bottom(bar, 2), hex(0xE2B469));
    rect r = rect_inflate2(bar, v2(-18, -8));
    text_draw(G.big, rect_point(r, v2(0, .5f)), v2(0, .5f), title);
    rect right = rect_cut_right(&r, 130);
    amount(rect_point(right, v2(1, .5f)), v2(1, .5f), G.star, fmt("%d", G.wallet.v[STARS]), G.number);
    right = rect_cut_right(&r, 150);
    amount(rect_point(right, v2(1, .5f)), v2(1, .5f), G.coin, fmt("%d", G.wallet.v[COINS]), G.number);
}

/* ---------------------------------------------------------------- screens */

static void camp_frame(rect screen, input world)
{
    bool portrait = screen.size.h > screen.size.w;
    rect top = rect_cut_top(&screen, 76);
    rect body = rect_inflate(screen, -12);
    rect shop = rect_cut_bottom(&body, portrait ? 300 : 140);
    rect_cut_bottom(&body, 10);
    rect footer = rect_cut_bottom(&body, 54);
    rect_cut_bottom(&body, 8);
    rect view = body;

    G.camp.cam.view = view;
    if (G.modal == MODAL_NONE) {
        city_event ev = city_update(&G.camp, world, &G.wallet, app_clock());
        switch (ev.result) {
        case CITY_BUILT:
            save_progress();
            fx_burst(ev.screen, 30, hex(0xFFD36B), 280, 10);
            ui_toast(fmt("%s built!", camp_defs[G.camp.items[ev.building].type].name));
            break;
        case CITY_COLLECTED:
            save_progress();
            fx_burst(ev.screen, 18, hex(0xFFD36B), 200, 8);
            fx_text(vec2_sub(ev.screen, v2(0, 40)), &G.popup, fmt("+%d coins", ev.amount.v[COINS]));
            break;
        case CITY_NOT_READY: {
            const building_def *d = &camp_defs[G.camp.items[ev.building].type];
            double left = d->income_period - (app_clock() - G.camp.items[ev.building].stamp);
            ui_toast(fmt("%s: %d coins in %d:%02d", d->name, d->income.v[COINS], (int)left / 60, (int)left % 60));
            break;
        }
        case CITY_CANT_AFFORD: ui_toast("Not enough coins — dig for more relics!"); break;
        case CITY_LOCKED_TYPE: ui_toast(fmt("Needs %d stars", camp_defs[G.camp.selected].needs.v[STARS])); break;
        case CITY_BLOCKED: ui_toast("Pick open sand inside the camp"); break;
        default: break;
        }
    }

    draw_shadow(rect_offset(view, v2(0, 8)), 18, 26, rgba(0, 0, 0, 90));
    city_draw(&G.camp, world, app_clock());
    draw_round_rect_line(rect_inflate(view, 2), 18, 5, hex(0x3A2414));
    fx_draw();

    rect play = rect_align(rect_inflate(view, -16), sz2(portrait ? 300 : 280, 84), portrait ? v2(.5f, 1) : v2(1, 1));
    float pulse = 1 + .03f * sinf((float)app_time() * 4);
    ui_state st = ui_button_frame(rect_scale(play, pulse), UI_ACCENT);
    text_draw(ts_size(G.big, 34), vec2_sub(rect_center(play), v2(0, 10)), v2(.5f, .5f), "DIG!");
    text_draw(ts_fill(ts_size(G.heading, 18), hex(0x5A3410)), vec2_add(rect_center(play), v2(0, 24)), v2(.5f, .5f), fmt("Level %d", G.next_level + 1));
    if (st.clicked && G.modal == MODAL_NONE) start_level(G.next_level);

    rect levels = rect_align(rect_inflate(view, -16), sz2(150, 52), v2(0, 0));
    if (ui_button(levels, "Levels", 0)) G.modal = MODAL_LEVELS, G.modal_time = 0;

    rect expand = rect_cut_right(&footer, portrait ? 330 : 300);
    text_box(G.small, rect_inflate2(footer, v2(-6, 0)), v2(0, .5f),
             G.camp.selected < 0 ? "Tap a building with a coin bubble to collect. Pick a card to build."
                                 : fmt("Placing %s — tap open sand. Tap the card again to stop.", camp_defs[G.camp.selected].name));
    if (G.camp.unlocked >= G.camp.zone_count) {
        ui_button(expand, "Camp fully explored", UI_DISABLED);
    } else if (ui_button(expand, fmt("Explore east · %d coins", city_next_zone_cost(&G.camp).v[COINS]), 0)) {
        if (city_unlock_next(&G.camp, &G.wallet)) save_progress(), ui_toast("New ground surveyed! Drag the map east.");
        else ui_toast("Not enough coins yet");
    }

    for (int i = 0; i < CAMP_TYPES; i++) {
        building_def *d = &camp_defs[i];
        rect card = portrait ? rect_col(rect_row(shop, 2, i / 3, 10), 3, i % 3, 10) : rect_col(shop, CAMP_TYPES, i, 10);
        bool locked = G.wallet.v[STARS] < d->needs.v[STARS];
        ui_state cs = ui_button_frame(card, G.camp.selected == i ? UI_ACTIVE : 0);
        if (cs.clicked) G.camp.selected = G.camp.selected == i ? -1 : i;
        rect c = rect_inflate(card, -8);
        rect label = rect_cut_bottom(&c, 48);
        draw_image(d->sprite, rect_fit(c, d->sprite.size), locked ? rgba(120, 100, 90, 200) : WHITE);
        text_fit(ts_size(G.heading, 17), rect_top(label, 22), v2(.5f, .5f), d->name);
        rect line = rect_bottom(label, 24);
        if (locked) amount(rect_center(line), v2(.5f, .5f), G.star, fmt("%d needed", d->needs.v[STARS]), ts_size(G.number, 15));
        else amount(rect_center(line), v2(.5f, .5f), G.coin, fmt("%d", d->cost.v[COINS]), ts_size(G.number, 15));
    }
    header(top, "Relic Rush");
}

static void goal_list(rect r, bool row)
{
    for (int i = 0; i < G.def.goals; i++) {
        rect g = row ? rect_col(r, G.def.goals, i, 8) : rect_cut_top(&r, 64);
        rect icon = rect_left(g, g.size.h);
        draw_image(G.gems[G.def.goal[i].kind], rect_inflate(icon, -4), WHITE);
        rect txt = rect_inflate2(rect_offset(g, v2(g.size.h + 6, 0)), v2(0, -6));
        if (G.goal_left[i] <= 0) text_draw(ts_fill(G.number, hex(0x8CF0A0)), rect_point(txt, v2(0, .5f)), v2(0, .5f), "Done!");
        else text_draw(G.number, rect_point(txt, v2(0, .5f)), v2(0, .5f), fmt("%d left", G.goal_left[i]));
    }
    if (G.def.goals == 0) text_box(G.small, r, v2(0, 0), "Reach the target score.");
}

static void score_bar(rect r)
{
    float top = G.def.target * 2.0f;
    draw_round_rect(r, r.size.h / 2, rgba(0, 0, 0, 120));
    rect fill = rect_resize(r, sz2(maxf(r.size.h, r.size.w * saturate(G.score / top)), r.size.h), v2(0, .5f));
    draw_round_rect_grad(fill, r.size.h / 2, hex(0xFFE08A), hex(0xE59A2A));
    float marks[3] = {G.def.target / top, 1.5f * G.def.target / top, 1};
    for (int i = 0; i < 3; i++) {
        vec2 at = v2(lerpf(r.pos.x, rect_max(r).x, marks[i]) - (i == 2 ? 10 : 0), rect_center(r).y);
        draw_image(G.star, rect_centered(at, sz2s(26)), G.score >= marks[i] * top ? WHITE : rgba(60, 40, 30, 200));
    }
}

static void level_frame(rect screen, input world, float dt)
{
    bool portrait = screen.size.h > screen.size.w;
    draw_image(G.backdrop, rect_centered(rect_center(screen), size2_scale(G.backdrop.size, size2_cover(G.backdrop.size, screen.size))), WHITE);
    rect body = rect_inflate(screen, -18);
    rect hud = portrait ? rect_cut_top(&body, 300) : rect_cut_left(&body, 320);
    if (portrait) rect_cut_top(&body, 16);
    else rect_cut_left(&body, 24);

    float side = minf(body.size.w, body.size.h) - 28;
    G.board_rect = rect_align(body, sz2s(side), portrait ? v2(.5f, .25f) : v2(.5f, .5f));
    G.cell = side / BOARD_W;
    if (G.modal == MODAL_NONE) board_update(world, dt);
    else board_update((input){.pos = world.pos, .pinch = 1}, dt);

    draw_board();
    fx_draw();

    ui_panel(hud);
    rect h = rect_inflate(hud, -18);
    rect title = rect_cut_top(&h, 44);
    text_draw(ts_size(G.big, 32), rect_point(title, v2(0, .5f)), v2(0, .5f), fmt("Level %d", G.level + 1));
    if (ui_button(rect_align(title, sz2(110, 44), v2(1, .5f)), "Camp", 0)) back_to_camp();
    rect_cut_top(&h, 10);
    rect moves, score, goals;
    if (portrait) {
        moves = rect_col(h, 3, 0, 14), score = rect_col(h, 3, 1, 14), goals = rect_col(h, 3, 2, 14);
    } else {
        moves = rect_cut_top(&h, 110), rect_cut_top(&h, 12), score = rect_cut_top(&h, 120), rect_cut_top(&h, 12), goals = h;
    }
    ui_panel_ex(moves, rgba(0, 0, 0, 70), rgba(0, 0, 0, 40), CLEAR, 14);
    text_draw(G.small, vec2_add(moves.pos, v2(14, 10)), v2(0, 0), "MOVES");
    amount(vec2_add(rect_center(moves), v2(0, 12)), v2(.5f, .5f), G.hourglass, fmt("%d", G.moves),
           ts_size(G.big, 46));
    ui_panel_ex(score, rgba(0, 0, 0, 70), rgba(0, 0, 0, 40), CLEAR, 14);
    text_draw(G.small, vec2_add(score.pos, v2(14, 10)), v2(0, 0), fmt("SCORE · TARGET %d", G.def.target));
    text_draw(ts_size(G.big, 36), vec2_add(score.pos, v2(14, 30)), v2(0, 0), fmt("%d", G.score));
    score_bar(rc(score.pos.x + 14, rect_max(score).y - 30, score.size.w - 28, 16));
    ui_panel_ex(goals, rgba(0, 0, 0, 70), rgba(0, 0, 0, 40), CLEAR, 14);
    text_draw(G.small, vec2_add(goals.pos, v2(14, 10)), v2(0, 0), "COLLECT");
    goal_list(rect_inflate2(rect_offset(goals, v2(0, 18)), v2(-14, -14)), false);
}

/* ---------------------------------------------------------------- dialogs */

static rect dialog_box(size2 size)
{
    rect s = app_screen();
    rect box = rect_centered(rect_center(s), size2_min(size, size2_add(s.size, sz2(-40, -40))));
    box = rect_offset(box, v2(0, (1 - ease_out_cubic(G.modal_time * 3)) * 50));
    ui_panel_ex(box, hex(0x5A3A22), hex(0x3A2414), hex(0xE2B469), 24);
    return rect_inflate(box, -26);
}

static void win_dialog(void)
{
    rect r = dialog_box(sz2(560, 470));
    text_draw(G.big, rect_point(r, v2(.5f, 0)), v2(.5f, 0), fmt("Level %d cleared!", G.level + 1));
    rect_cut_top(&r, 60);
    star_row(rect_cut_top(&r, 110), G.result_stars, G.modal_time);
    rect_cut_top(&r, 10);
    text_draw(G.heading, rect_point(rect_cut_top(&r, 36), v2(.5f, .5f)), v2(.5f, .5f), fmt("Score %d", G.score));
    rect reward = rect_cut_top(&r, 50);
    amount(rect_center(reward), v2(.5f, .5f), G.coin, fmt("+%d coins%s", G.result_coins, G.first_clear ? "" : " (replay)"), G.number);
    rect buttons = rect_bottom(r, 60);
    if (ui_button(rect_col(buttons, 2, 0, 14), "Camp", 0)) back_to_camp();
    if (ui_button(rect_col(buttons, 2, 1, 14), "Next level", UI_ACCENT)) start_level(G.next_level);
}

static void fail_dialog(void)
{
    rect r = dialog_box(sz2(540, 380));
    text_draw(G.big, rect_point(r, v2(.5f, 0)), v2(.5f, 0), "Out of moves");
    rect_cut_top(&r, 64);
    text_box(G.text, rect_cut_top(&r, 90), v2(.5f, 0),
             G.score < G.def.target ? fmt("You needed %d more points. The sand shifts — try another dig!", G.def.target - G.score)
                                    : "So close! Some relics are still buried.");
    goal_list(rect_inflate2(rect_cut_top(&r, 60), v2(-40, 0)), true);
    rect buttons = rect_bottom(r, 60);
    if (ui_button(rect_col(buttons, 2, 0, 14), "Camp", 0)) back_to_camp();
    if (ui_button(rect_col(buttons, 2, 1, 14), "Retry", UI_ACCENT)) start_level(G.level);
}

static void levels_dialog(void)
{
    rect r = dialog_box(sz2(760, 640));
    rect head = rect_cut_top(&r, 56);
    text_draw(G.big, rect_point(head, v2(0, .5f)), v2(0, .5f), "Expedition log");
    ui_state close = ui_button_frame(rect_align(head, sz2(52, 48), v2(1, .5f)), 0);
    vec2 c = rect_center(rect_align(head, sz2(52, 48), v2(1, .5f)));
    draw_line(vec2_sub(c, v2s(10)), vec2_add(c, v2s(10)), 4, hex(0xFFF3DC));
    draw_line(vec2_add(c, v2(10, -10)), vec2_add(c, v2(-10, 10)), 4, hex(0xFFF3DC));
    if (close.clicked) G.modal = MODAL_NONE;
    rect_cut_top(&r, 12);
    int cols = r.size.w > 600 ? 6 : 4, rows = (MAX_LEVELS + cols - 1) / cols;
    for (int i = 0; i < MAX_LEVELS; i++) {
        rect cell = rect_inflate(rect_col(rect_row(r, rows, i / cols, 8), cols, i % cols, 8), -2);
        bool open = i <= G.next_level;
        ui_state st = ui_button_frame(cell, (open ? 0 : UI_DISABLED) | (i == G.next_level ? UI_ACCENT : 0));
        text_draw(ts_fade(ts_size(G.number, 22), open ? 0 : .55f), rect_point(cell, v2(.5f, .38f)), v2(.5f, .5f), fmt("%d", i + 1));
        rect stars = rect_inflate2(rect_bottom(cell, cell.size.h * .38f), v2(-cell.size.w * .18f, -2));
        for (int s = 0; s < 3 && open; s++)
            draw_image(G.star, rect_fit(rect_col(stars, 3, s, 2), sz2s(1)), s < G.stars[i] ? WHITE : rgba(40, 30, 20, 140));
        if (st.clicked && open) start_level(i);
    }
}

/* ---------------------------------------------------------------- autoplay */

/* --autoplay N: a bot plays N levels through the real input-free state machine
 * and prints each result; used to catch stuck states and to tune targets. */
static void autoplay(void)
{
    static int levels_left = -1;
    if (levels_left < 0) levels_left = atoi(app_arg("autoplay"));
    if (!G.playing) {
        if (levels_left-- <= 0) app_quit();
        else start_level(G.next_level);
        return;
    }
    if (G.modal == MODAL_WIN || G.modal == MODAL_FAIL) {
        printf("level %2d: %s score %5d / %5d, moves left %2d, stars %d\n", G.level + 1, G.modal == MODAL_WIN ? "won " : "lost",
               G.score, G.def.target, G.moves, G.modal == MODAL_WIN ? G.result_stars : 0);
        back_to_camp();
        return;
    }
    ivec2 a, c;
    if (G.phase == PHASE_IDLE && G.modal == MODAL_NONE && board_find_move(&G.b, &a, &c)) {
        /* prefer moves that touch a goal gem or a special */
        for (int y = 0; y < BOARD_H; y++)
            for (int x = 0; x < BOARD_W; x++)
                for (int d = 0; d < 2; d++) {
                    ivec2 p = iv2(x, y), q = ivec2_add(p, d ? iv2(0, 1) : iv2(1, 0));
                    if (!board_swap_works(&G.b, p, q)) continue;
                    piece pp = board_at(&G.b, p), pq = board_at(&G.b, q);
                    bool goal = G.def.goals && (pp.kind == G.def.goal[0].kind || pq.kind == G.def.goal[0].kind) && G.goal_left[0] > 0;
                    if (pp.special || pq.special || goal) a = p, c = q;
                }
        try_swap(a, c);
    }
}

/* ------------------------------------------------------------------ frame */

static void frame(float dt)
{
    input in = input_get();
    input world = G.modal == MODAL_NONE ? input_world() : (input){.pos = in.pos, .pinch = 1};
    if (in.back) {
        if (G.modal == MODAL_LEVELS) G.modal = MODAL_NONE;
        else if (G.playing) back_to_camp();
        else if (G.camp.selected >= 0) G.camp.selected = -1;
    }
    fx_update(dt);
    if (app_arg("autoplay")) autoplay();
    rect screen = app_screen();
    draw_rect_grad(screen, hex(0x3A2414), hex(0x1E120A));

    ui_set_enabled(G.modal == MODAL_NONE);
    if (G.playing) level_frame(screen, world, dt);
    else camp_frame(screen, world);
    ui_set_enabled(true);

    if (G.modal != MODAL_NONE) {
        G.modal_time += dt;
        ui_modal_backdrop(G.modal_time * 4);
        if (G.modal == MODAL_WIN) win_dialog();
        else if (G.modal == MODAL_FAIL) fail_dialog();
        else levels_dialog();
    }
}

/* ------------------------------------------------------------------ setup */

static void setup_theme(void)
{
    G.display = font_load("fonts/LilitaOne-Regular.ttf");
    G.body = font_load("fonts/Nunito.ttf");
    font_set_fallback(G.display, G.body);
    color cream = hex(0xFFF3DC), brown = hex(0x3A1F0B);
    G.big = ts_shadow(ts_outline(ts_grad((text_style){.font = G.display, .size = 40}, hex(0xFFF6C8), hex(0xFFB532)), 2.5f, brown),
                      v2(0, 4), 3, rgba(0, 0, 0, 150));
    G.heading = ts_shadow(ts_outline((text_style){.font = G.display, .size = 24, .fill = cream}, 1.5f, brown), v2(0, 2), 1, rgba(0, 0, 0, 120));
    G.text = (text_style){.font = G.body, .size = 19, .fill = cream};
    G.small = (text_style){.font = G.body, .size = 15, .fill = hex(0xE8D2B0), .tracking = .5f};
    G.number = ts_outline((text_style){.font = G.display, .size = 24, .fill = cream}, 1.5f, brown);
    G.popup = ts_shadow(ts_outline(ts_grad((text_style){.font = G.display, .size = 34}, WHITE, hex(0xFFD36B)), 2.5f, brown), v2(0, 3), 2,
                        rgba(0, 0, 0, 140));
    G.theme = (ui_theme){
        .text = G.text,
        .small = G.small,
        .title = G.big,
        .button = ts_outline((text_style){.font = G.display, .size = 21, .fill = cream}, 1.2f, brown),
        .accent_text = (text_style){.font = G.display, .size = 22, .fill = hex(0x4A2A0C)},
        .panel = rgba(78, 52, 32, 240), .panel2 = rgba(52, 33, 20, 240), .border = rgba(226, 180, 105, 160),
        .button_bg = hex(0x8A5A33), .button_bg2 = hex(0x5E3A1F), .button_hot = hex(0x9D6A3F),
        .button_border = rgba(255, 220, 160, 120),
        .accent = hex(0xFFD86E), .accent2 = hex(0xF09A2A), .active = hex(0xFFE08A),
        .dim = rgba(20, 10, 4, 200), .toast_bg = hex(0xFFE7B0), .toast_text = hex(0x4A2A0C), .radius = 14,
    };
    ui_set_theme(&G.theme);
}

static void camp_setup(void)
{
    city *c = &G.camp;
    c->defs = camp_defs;
    c->def_count = CAMP_TYPES;
    c->spacing = 135;
    c->buildable = camp_buildable;
    c->zone_count = 4;
    c->zones[0] = (city_zone){rc(400, 100, 700, 1480), {{0}}};
    c->zones[1] = (city_zone){rc(1100, 100, 450, 1480), {{400}}};
    c->zones[2] = (city_zone){rc(1550, 100, 450, 1480), {{900}}};
    c->zones[3] = (city_zone){rc(2000, 100, 400, 1480), {{1600}}};
    c->cam = (camera){.center = v2(800, 760), .zoom = .8f, .max_zoom = 2};
    city_init(c, "camp.jpg");
    c->income_icon = G.coin;
}

static void new_game(void)
{
    G.wallet = (purse){{250, 0}};
    memset(G.stars, 0, sizeof G.stars);
    G.next_level = 0;
    G.camp.count = 0;
    G.camp.unlocked = 1;
    city_add(&G.camp, v2(720, 640), 0, app_clock() - 45);
}

/* QA entry points for screenshots: --screen camp|board|win|fail|levels */
static void apply_screen_arg(void)
{
    const char *screen = app_arg("screen");
    if (!screen) return;
    G.wallet = (purse){{1450, 0}};
    for (int i = 0; i < 7; i++) G.stars[i] = 1 + i % 3;
    G.next_level = 7;
    G.wallet.v[STARS] = total_stars();
    if (!strcmp(screen, "camp")) {
        int types[] = {1, 2, 3, 0, 4};
        vec2 spots[] = {{960, 520}, {760, 980}, {1000, 1180}, {600, 1240}, {1250, 760}};
        G.camp.unlocked = 2;
        for (int i = 0; i < 5; i++) city_add(&G.camp, spots[i], types[i], app_clock() - (i % 2 ? 1000 : 10));
        G.camp.cam.center = v2(900, 820);
        G.camp.cam.zoom = .62f;
        return;
    }
    start_level(screen[0] == 'b' ? 5 : 7);
    memset(G.offset, 0, sizeof G.offset);
    G.phase = PHASE_IDLE;
    G.b.cell[2][3].special = SP_ROW;
    G.b.cell[5][6].special = SP_BOMB;
    G.b.cell[6][1] = (piece){ORB_KIND, SP_ORB};
    G.b.cell[4][4].special = SP_COL;
    G.moves = 9;
    G.score = G.def.target - 340;
    G.goal_left[0] = 4;
    G.sel = iv2(3, 4);
    G.has_sel = true;
    if (!strcmp(screen, "win")) {
        G.goal_left[0] = G.goal_left[1] = 0;
        G.score = G.def.target * 7 / 4;
        G.moves = 0;
        finish_level(true);
        G.modal_time = 2;
    } else if (!strcmp(screen, "fail")) {
        G.moves = 0;
        finish_level(false);
        G.modal_time = 2;
    } else if (!strcmp(screen, "levels")) {
        back_to_camp();
        G.modal = MODAL_LEVELS;
        G.modal_time = 2;
    }
}

static void init(void)
{
    setup_theme();
    for (int i = 0; i < KINDS; i++) G.gems[i] = tex_load(fmt("pieces/%d.png", i));
    G.orb = tex_load("pieces/orb.png");
    G.coin = tex_load("icons/coin.png");
    G.star = tex_load("icons/star.png");
    G.hourglass = tex_load("icons/moves.png");
    G.backdrop = tex_load("backdrop.jpg");
    camp_setup();
    new_game();
    save_read("progress", serialize, NULL);
    apply_screen_arg();
}

int main(int argc, char **argv)
{
    return app_run((app_desc){
                       .title = "Relic Rush",
                       .id = "relic-rush",
                       .design = {1200, 900},
                       .max_aspect = 2.2f,
                       .clear = {30, 18, 10, 255},
                       .data_dir = GAME_DATA_DIR,
                       .init = init,
                       .frame = frame,
                   },
                   argc, argv);
}
