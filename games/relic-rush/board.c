/* board.c — the expedition screen: HUD, hex board, relic animation phases,
 * tools and swipe / tap input.
 *
 * Phases: SWAP (relics trade places, then the wave clears), REJECT (they
 * slide back), CLEAR (matched relics pop) and FALL (gravity per column
 * segment); after a fall the board is checked again, so cascades chain. */
#include "relic.h"

#include <string.h>

#define CELL_SIZE 46.f
#define HEX_DY (1.732050808f * HEX_R)

static const vec2 board_origin = {240, 492};

vec2 cell_pos(int i) { return vec2_add(board_origin, v2(hex_q(i) * 1.5f * HEX_R, (hex_r(i) + hex_q(i) * .5f) * HEX_DY)); }

/* Screen point to the active cell under it, by rounding cube coordinates. */
static int cell_at(vec2 p)
{
    vec2 d = vec2_sub(p, board_origin);
    float q = d.x * 2 / (3 * HEX_R), r = -d.x / (3 * HEX_R) + d.y / HEX_DY, s = -q - r;
    int iq = (int)roundf(q), ir = (int)roundf(r), is = (int)roundf(s);
    float dq = fabsf(iq - q), dr = fabsf(ir - r), ds = fabsf(is - s);
    if (dq > dr && dq > ds) iq = -ir - is;
    else if (dr > ds) ir = -iq - is;
    int cell = hex_index(iq, ir);
    return game_cell_active(&R.g, cell) ? cell : -1;
}

/* ------------------------------------------------------------------ drawing */

void draw_relic(tile t, vec2 at, float scale, float alpha, float aspect)
{
    if (t.kind < 0) return;
    float s = CELL_SIZE * .95f * scale;
    draw_image(R.relics[t.kind], rect_centered(at, sz2(s * aspect, s / aspect)), rgba(255, 255, 255, (int)alpha));
    if (!t.special) return;
    float r = 18 * scale;
    color cream = rgba(255, 251, 194, (int)alpha);
    if (t.special == ROW || t.special == COLUMN || t.special == DIAGONAL) {
        float a = (t.special == ROW ? 30 : t.special == COLUMN ? 90 : 150) * ENGINE_PI / 180;
        vec2 dir = vec2_polar(a, r), n = vec2_polar(a + ENGINE_PI / 2, 7 * scale);
        for (int k = -1; k <= 1; k++) {
            vec2 c = vec2_add(at, vec2_scale(n, (float)k));
            draw_line(vec2_sub(c, dir), vec2_add(c, dir), 1.6f * scale, cream);
        }
    } else if (t.special == BOMB) {
        draw_circle(at, 12 * scale, rgba(74, 47, 50, (int)alpha));
        draw_circle(vec2_add(at, v2s(-3 * scale)), 3 * scale, cream);
        draw_line(vec2_add(at, vec2_scale(v2(6, -9), scale)), vec2_add(at, vec2_scale(v2(13, -18), scale)), 1.6f * scale, cream);
        draw_circle(vec2_add(at, vec2_scale(v2(13, -18), scale)), 3 * scale, rgba(255, 185, 65, (int)alpha));
    } else {   /* prism */
        draw_circle(at, 12 * scale, cream);
        for (int k = 0; k < 6; k++)
            draw_circle(vec2_add(at, vec2_polar(k * ENGINE_PI / 3, 8 * scale)), 3 * scale, rgba(100 + k * 20, 220 - k * 20, 180, (int)alpha));
    }
}

static float wrapf(float v, float m) { return v - m * floorf(v / m); }

static void draw_backdrop(void)
{
    texture scene = R.scenes[R.g.level >= 5];
    draw_image(scene.tex ? scene : R.backdrop, rc(0, 0, SCREEN_W, SCREEN_H), WHITE);
    draw_rect(rc(0, 0, SCREEN_W, SCREEN_H), rgba(5, 30, 29, 35));
    for (int i = 0; i < 12; i++) {   /* drifting motes of sunlight */
        vec2 p = v2(20 + wrapf(i * 93 + R.now * (i % 2 ? 3 : -4) + 480, 440), 170 + wrapf(i * 139 + R.now * 5, 620));
        draw_circle(p, 1.5f + sinf(R.now + i) * .5f, rgba(255, 228, 139, (int)(70 + 50 * sinf(R.now + i))));
    }
}

static void draw_hud(void)
{
    const level *l = &levels[R.g.level];
    panel(rc(24, 106, 432, 112));
    say_at("SCORE", v2(90, 126), 14, PAL_WHITE, 0);
    say_at(fmt("%d", (int)R.score_display), v2(90, 153), 30 + (R.reduced_motion ? 0 : 5 * sinf(R.score_pulse / .25f * ENGINE_PI)), PAL_GOLD, 0);
    say_at(fmt("LEVEL %d", R.g.level + 1), v2(239, 126), 17, PAL_GOLD, 0);
    say_at(l->name, v2(239, 155), 18, PAL_CREAM, 184);
    draw_circle(v2(399, 151), 38, rgba(122, 78, 36, 255));
    draw_circle(v2(399, 148), 34, rgba(237, 184, 77, 255));
    draw_circle(v2(399, 146), 30, rgba(255, 223, 129, 255));
    say(fmt("%d", R.g.moves), rc(369, 119, 60, 37), 33, PAL_CREAM);
    say("MOVES", rc(365, 156, 68, 17), 11, PAL_CREAM);
    draw_round_rect(rc(47, 190, 386, 11), 5, rgba(163, 132, 78, 255));
    if (R.goal_display > 0) draw_round_rect(rc(48, 191, maxf(6, 384 * R.goal_display), 8), 4, rgba(88, 169, 92, 255));

    /* two primary goals, then sand and lock goals when the level has them */
    int goals = 2 + (l->soil > 0) + (R.g.initial_obstacles > 0);
    float gw = 432.f / goals;
    for (int k = 0; k < goals; k++) draw_round_rect(rc(24 + k * gw + 2, 230, gw - 4, 36), 10, rgba(13, 47, 41, 230));
    say_at(fmt("%d / %d", R.g.score < l->score ? R.g.score : l->score, l->score), v2(24 + gw * .5f, 246), 17, PAL_CREAM, gw - 10);
    float pop = R.reduced_motion ? 0 : 5 * sinf(R.goal_pulse / .22f * ENGINE_PI);
    draw_image(R.relics[RELIC_IDOL], rc(24 + gw + 5 - pop / 2, 234 - pop / 2, 29 + pop, 29 + pop), WHITE);
    say_at(fmt("%d / %d", R.g.relics < l->relics ? R.g.relics : l->relics, l->relics), v2(24 + gw * 1.58f, 246), 19, PAL_GOLD, gw - 33);
    int slot = 2;
    if (l->soil) say_at(fmt("SAND %d", l->soil - R.g.dug), v2(24 + gw * (slot++ + .5f), 246), 17, PAL_CREAM, gw - 8);
    if (R.g.initial_obstacles) say_at(fmt("LOCK %d", R.g.obstacles), v2(24 + gw * (slot + .5f), 246), 17, PAL_WHITE, gw - 8);
}

static void draw_cells(float sx)
{
    for (int i = 0; i < CELLS; i++) {
        if (!game_cell_active(&R.g, i)) continue;
        vec2 at = vec2_add(cell_pos(i), v2(sx, 0));
        draw_ngon(vec2_add(at, v2(0, 2)), HEX_R + .7f, 6, 0, rgba(7, 37, 34, 255));
        for (int d = 0; d < 6; d++)   /* a gold rim where the board ends */
            if (!game_cell_active(&R.g, hex_neighbor(i, d))) {
                float a = d * ENGINE_PI / 3, b = (d + 1) * ENGINE_PI / 3;
                draw_line(vec2_add(at, vec2_polar(a, HEX_R - .5f)), vec2_add(at, vec2_polar(b, HEX_R - .5f)), 2, rgba(212, 175, 95, 255));
            }
        draw_ngon(at, HEX_R - .8f, 6, 0, rgba(75, 120, 91, 255));
        draw_ngon(at, HEX_R - 2, 6, 0, (hex_q(i) - hex_r(i)) % 2 ? rgba(29, 82, 67, 255) : rgba(35, 94, 73, 255));
        if (R.g.soil[i]) {
            draw_ngon(at, HEX_R - 1.5f, 6, 0, rgba(209, 166, 85, 255));
            draw_ngon(at, HEX_R - 4, 6, 0, rgba(164, 121, 57, 255));
            draw_circle(vec2_add(at, v2(-13, -12)), 2, rgba(247, 211, 141, 220));
        }
        if (i == R.selected || ((i == R.hint_a || i == R.hint_b) && R.phase == PH_IDLE)) {
            int a = i == R.selected ? 255 : (int)(110 + 70 * sinf(R.now * 5));
            draw_ngon(at, HEX_R - 1, 6, 0, rgba(255, 234, 138, a));
            draw_ngon(at, HEX_R - 4, 6, 0, rgba(65, 123, 82, 255));
        }
    }
}

static bool movable(int i) { return game_cell_active(&R.g, i) && !R.g.ice[i] && !R.g.chain[i]; }

static void draw_relics(float sx)
{
    gfx_clip(BOARD_CLIP);
    for (int i = 0; i < CELLS; i++) {
        if (!game_cell_active(&R.g, i)) continue;
        vec2 at = vec2_add(cell_pos(i), v2(sx, 0));
        float scale = 1, alpha = 255, aspect = 1;
        tile t = R.g.tiles[i];
        bool clipped = false;
        if (R.phase == PH_SWAP || R.phase == PH_REJECT) {
            t = R.old_tiles[i];
            if (i == R.swap_a || i == R.swap_b) {
                int other = i == R.swap_a ? R.swap_b : R.swap_a;
                float f = R.phase_time / (R.phase == PH_SWAP ? .17f : .16f);
                if (R.phase == PH_REJECT && f > 1) f = 2 - f;
                at = vec2_lerp(at, vec2_add(cell_pos(other), v2(sx, 0)), ease_out_cubic(f));
            }
        } else if (R.phase == PH_CLEAR && R.pending.mask[i]) {
            t = R.old_tiles[i];
            if (!R.wave_chain[i] && !R.wave_ice[i] && !R.pending.make[i]) {   /* a small pop, then shrink away */
                float f = saturate(R.phase_time / .24f);
                scale = f < .22f ? 1 + .18f * sinf(f / .22f * ENGINE_PI) : 1 - .92f * ease_out_cubic((f - .22f) / .78f);
                alpha = 255 * (1 - f * f);
            }
        } else if (R.phase == PH_FALL) {
            int q = hex_q(i), lo = hex_r(i), hi = lo;
            if (movable(i)) {   /* the column segment this relic falls within */
                while (movable(hex_index(q, lo - 1))) lo--;
                while (movable(hex_index(q, hi + 1))) hi++;
            }
            float f = ease_out_cubic((R.phase_time - (q + 4) * .006f) / .29f);
            float source = R.fall_from[i] >= 0 ? cell_pos(R.fall_from[i]).y : cell_pos(hex_index(q, lo)).y + R.fall_from[i] * HEX_DY;
            at.y = lerpf(source, cell_pos(i).y, f);
            if (!R.reduced_motion) {
                at.y += sinf(f * ENGINE_PI * 2) * 3 * (1 - f);
                if (f > .72f) aspect = 1 + .11f * sinf((f - .72f) / .28f * ENGINE_PI);   /* landing squash */
            }
            vec2 top = cell_pos(hex_index(q, lo));
            gfx_clip(rc(cell_pos(i).x - CELL_SIZE / 2 - 1, top.y - HEX_DY / 2, CELL_SIZE + 2, (hi - lo + 1) * HEX_DY));
            clipped = true;
        }
        draw_relic(t, at, scale, alpha, aspect);
        if (clipped) gfx_clip(BOARD_CLIP);
    }
    gfx_unclip();
}

static void draw_blockers(float sx)
{
    color ice = rgba(225, 253, 255, 235);
    for (int i = 0; i < CELLS; i++) {
        if (!game_cell_active(&R.g, i)) continue;
        vec2 at = vec2_add(cell_pos(i), v2(sx, 0));
        if (R.g.ice[i]) {
            draw_ngon(at, HEX_R - 2, 6, 0, rgba(170, 230, 249, 110));
            vec2 cracks[][2] = {{{-11, -18}, {11, -18}}, {{-20, 0}, {-11, -18}}, {{-7, -19}, {4, -4}}, {{4, -4}, {-4, 11}}, {{18, -10}, {-10, 17}}};
            for (int k = 0; k < (R.g.ice[i] > 1 ? 5 : 4); k++) draw_line(vec2_add(at, cracks[k][0]), vec2_add(at, cracks[k][1]), 1.5f, ice);
        }
        if (R.g.chain[i]) {
            for (int a = -1; a <= 1; a += 2)
                for (int k = -2; k <= 2; k++) {
                    vec2 link = vec2_add(at, v2(k * 7.f, a * k * 6.f));
                    draw_round_rect(rect_centered(link, sz2(10, 6)), 2, rgba(42, 45, 42, 255));
                    draw_round_rect(rect_centered(link, sz2(6, 2)), 1, rgba(194, 186, 151, 255));
                }
            draw_round_rect(rc(at.x - 7, at.y - 5, 14, 13), 3, rgba(224, 183, 76, 255));
            draw_circle(at, 2, rgba(72, 68, 48, 255));
        }
    }
}

static void draw_tool_icon(int k, float x)
{
    if (k == 0) {   /* pickaxe */
        draw_line(v2(x - 12, 812), v2(x + 9, 782), 7, rgba(109, 66, 38, 255));
        draw_line(v2(x - 16, 783), v2(x + 20, 792), 9, rgba(234, 237, 196, 255));
    } else if (k == 1) {   /* dynamite */
        for (int z = -1; z <= 1; z++) draw_round_rect(rc(x + z * 10 - 5, 783, 10, 30), 4, rgba(190 + z * 15, 66, 42, 255));
        draw_rect(rc(x - 16, 795, 32, 5), rgba(244, 202, 129, 255));
        draw_circle(v2(x + 9, 780), 4, rgba(255, 235, 141, 255));
    } else {   /* sunburst */
        draw_circle(v2(x, 798), 14, rgba(255, 234, 147, 255));
        for (int z = 0; z < 8; z++) {
            vec2 d = vec2_polar(z * ENGINE_PI / 4, 1);
            draw_line(vec2_add(v2(x, 798), vec2_scale(d, 17)), vec2_add(v2(x, 798), vec2_scale(d, 23)), 2, rgba(255, 232, 154, 255));
        }
    }
}

static void draw_tools(void)
{
    static const char *names[3] = {"Pickaxe", "Dynamite", "Sunburst"};
    if (R.word_time <= 0 || R.reduced_motion)
        say_at(R.tool >= 0 ? "TAP A RELIC TO USE YOUR TOOL" : "CONNECT 4+ MATCHING NEIGHBORS.", v2(240, 739), 13, PAL_WHITE, 0);
    for (int k = 0; k < 3; k++) {
        float x = 63 + k * 112;
        rect r = rc(x - 38, 766, 76, 65);
        draw_round_rect(r, 14, rgba(50, 45, 31, 240));
        draw_round_rect(rc(x - 35, 768, 70, 58), 12, R.tool == k ? rgba(168, 191, 92, 255) : rgba(220, 178, 99, 255));
        draw_tool_icon(k, x);
        draw_circle(v2(x + 29, 772), 13, rgba(44, 88, 61, 255));
        say(fmt("%d", R.g.tools[k]), rc(x + 16, 759, 26, 26), 16, PAL_CREAM);
        say_at(names[k], v2(x, 846), 15, PAL_CREAM, 0);
        if (tapped(r) && R.phase == PH_IDLE) {
            if (R.g.tools[k] > 0) {
                R.tool = R.tool == k ? -1 : k;
                R.selected = -1;
                notice(R.tool < 0 ? "Tool put away." : "Tap a relic to use your tool.");
            } else {
                notice("No charges left. More tools next expedition.");
            }
        }
    }
    rect guide = rc(387, 774, 63, 55);
    draw_round_rect(guide, 14, rgba(28, 77, 61, 240));
    say("?", rect_inflate(guide, -3), 33, PAL_GOLD);
    say_at("GUIDE", v2(419, 845), 12, PAL_WHITE, 0);
    if (tapped(guide)) R.overlay = OV_GUIDE;
    say_at("THE LOST VALLEY", v2(240, 881), 11, PAL_WHITE, 0);
}

/* ------------------------------------------------------------------- input */

static void tap_cell(vec2 at)
{
    int cell = cell_at(at);
    if (cell < 0) {
        R.selected = R.tool = -1;
        return;
    }
    R.idle_time = 0;
    R.hint_a = R.hint_b = -1;
    if (R.tool >= 0) {
        if (game_tool(&R.g, R.tool, cell, &R.pending)) {
            R.tool = -1;
            finish_wave();
        }
        return;
    }
    if (R.selected == cell) R.selected = -1;
    else if (R.selected >= 0 && hex_distance(R.selected, cell) == 1) attempt_swap(R.selected, cell);
    else R.selected = cell, tone(270);
}

/* A swipe trades with the neighbour best aligned with the gesture. */
static void swipe(vec2 from, vec2 to)
{
    int a = cell_at(from), b = -1;
    vec2 d = vec2_sub(to, from);
    float best = -1;
    if (a < 0) return;
    for (int k = 0; k < 6; k++) {
        int n = hex_neighbor(a, k);
        if (n < 0) continue;
        float alignment = vec2_dot(vec2_norm(d), vec2_norm(vec2_sub(cell_pos(n), cell_pos(a))));
        if (alignment > best) best = alignment, b = n;
    }
    if (best > .75f) attempt_swap(a, b);
}

static void board_input(input in)
{
    if (!in.released || R.overlay) return;
    vec2 d = vec2_sub(in.pos, in.press_pos);
    if (R.phase == PH_IDLE && cell_at(in.press_pos) >= 0 && (fabsf(d.x) > 16 || fabsf(d.y) > 16)) swipe(in.press_pos, in.pos);
    else if (R.phase == PH_IDLE && rect_contains(BOARD_CLIP, in.pos)) tap_cell(in.pos);
}

/* ------------------------------------------------------------------- rules */

void finish_wave(void)
{
    memcpy(R.old_tiles, R.g.tiles, sizeof R.old_tiles);
    memcpy(R.wave_ice, R.g.ice, sizeof R.wave_ice);
    memcpy(R.wave_chain, R.g.chain, sizeof R.wave_chain);
    int old_score = R.g.score;
    game_apply(&R.g, &R.pending);
    R.phase = PH_CLEAR;
    R.phase_time = 0;
    R.shake = R.reduced_motion ? 0 : R.g.combo > 1 ? .13f : .06f;
    vfx_wave(old_score);
    static const float notes[5] = {523.25f, 659.25f, 783.99f, 1046.5f, 1318.5f};
    tone(notes[clampi(R.g.combo - 1, 0, 4)]);
}

void attempt_swap(int a, int b)
{
    if (R.phase || R.overlay || R.on_island) return;
    R.selected = R.tool = R.hint_a = R.hint_b = -1;
    R.idle_time = 0;
    R.swap_a = a;
    R.swap_b = b;
    memcpy(R.old_tiles, R.g.tiles, sizeof R.old_tiles);
    if (game_swap(&R.g, a, b, &R.pending)) {
        int sa = R.old_tiles[a].special, sb = R.old_tiles[b].special;
        R.fx_origin = sa == PRISM ? b : sb == PRISM ? a : b;
        R.fx_combo = sa == PRISM || sb == PRISM ? 3 : sa && sb ? (sa == BOMB || sb == BOMB ? 2 : 1) : 0;
        R.phase = PH_SWAP;
        R.phase_time = 0;
        tone(320);
    } else if (game_can_swap(&R.g, a, b)) {
        R.phase = PH_REJECT;
        R.phase_time = 0;
        tone(170);
    } else {
        notice("Ice and chains must be broken first.");
    }
}

static void settle(void)
{
    game_matches(&R.g, &R.pending, -1);
    if (R.pending.hits) {
        finish_wave();
        return;
    }
    R.phase = PH_IDLE;
    game_check_end(&R.g);
    if (R.g.won) R.overlay = OV_RESULT, tone(880);
    else if (R.g.lost) R.overlay = OV_FAILED, tone(165);
    R.idle_time = 0;
}

void board_update(float dt)
{
    R.shake = maxf(0, R.shake - dt);
    if (R.overlay || R.on_island) return;
    R.idle_time += dt;
    if (R.phase == PH_IDLE && !R.g.won && !R.g.lost) {   /* ready groups resolve before any input */
        game_matches(&R.g, &R.pending, -1);
        if (R.pending.hits) {
            R.selected = R.tool = R.hint_a = R.hint_b = -1;
            finish_wave();
        }
    }
    if (R.idle_time > 5 && R.hint_a < 0 && R.phase == PH_IDLE) game_hint(&R.g, &R.hint_a, &R.hint_b);
    if (R.phase == PH_IDLE) return;
    R.phase_time += dt;
    float speed = R.reduced_motion ? .35f : 1;
    if (R.phase == PH_SWAP && R.phase_time > .17f * speed) finish_wave();
    else if (R.phase == PH_REJECT && R.phase_time > .32f * speed) R.phase = PH_IDLE;
    else if (R.phase == PH_CLEAR && R.phase_time > .24f * speed) {
        game_collapse(&R.g, R.fall_from);
        R.phase = PH_FALL;
        R.phase_time = 0;
    } else if (R.phase == PH_FALL && R.phase_time > .35f * speed) {
        settle();
    }
}

void board_screen(input in, float dt)
{
    draw_backdrop();
    draw_header(false);
    draw_hud();
    float sx = !R.reduced_motion && R.shake > 0 ? sinf(R.now * 110) * R.shake * 15 : 0;
    draw_cells(sx);
    draw_relics(sx);
    draw_blockers(sx);
    draw_tools();
    board_input(in);
    (void)dt;
}
