/* screens.c — Relic Rush's look: text palettes, panels, buttons, the header,
 * toasts and every dialog (guide, pause, results, failure, wonder card, region
 * card, finale).
 *
 * Dialogs animate through a paint transform (scale, offset, opacity) applied
 * by the helpers below; hit testing always uses the untransformed layout, so
 * a dialog is clickable where it will come to rest. */
#include "relic.h"

#include <stdio.h>
#include <string.h>

paint P = {1, {0, 0}, 1};

vec2 pp(vec2 p) { return vec2_add(P.offset, vec2_scale(p, P.scale)); }
rect pr(rect r) { return rect_make(pp(r.pos), size2_scale(r.size, P.scale)); }
static color pc(color c) { return color_alpha(c, P.alpha); }

void fill(rect r, color c) { draw_rect(pr(r), pc(c)); }
void rrect(rect r, float radius, color c) { draw_round_rect(pr(r), radius * P.scale, pc(c)); }
void disc(vec2 center, float radius, color c) { draw_circle(pp(center), radius * P.scale, pc(c)); }
void seg(vec2 a, vec2 b, float width, color c) { draw_line(pp(a), pp(b), width * P.scale, pc(c)); }
void picture(texture t, rect r, float alpha) { draw_image(t, pr(r), rgba(255, 255, 255, (int)(alpha * P.alpha))); }
void picture_fit(texture t, rect box, float alpha)
{
    if (t.size.w > 0) picture(t, rect_fit(box, t.size), alpha);
}

/* ---------------------------------------------------------------------- text */

/* Lilita One sizes are given in em like the original pipeline; the engine
 * measures ascent to descent, 1.17 em for this font. Every palette shares a
 * dark rim and a drop shadow cast by the rimmed silhouette. */
text_style pal(int palette, float em)
{
    static const color tops[4] = {{255, 255, 219, 255}, {255, 249, 226, 255}, {199, 255, 201, 255}, {255, 255, 255, 255}};
    static const color bottoms[4] = {{239, 169, 57, 255}, {244, 221, 166, 255}, {91, 198, 130, 255}, {196, 232, 220, 255}};
    palette = clampi(palette, 0, 3);
    em *= P.scale;
    return (text_style){.font = R.font, .size = em * 1.171875f, .fill = tops[palette], .fill2 = bottoms[palette],
                        .outline = rgba(62, 49, 29, 255), .outline_width = em * 4 / 64, .shadow = rgba(31, 35, 24, 184),
                        .shadow_offset = {0, em * 5 / 64}, .fade = 1 - P.alpha};
}

rect say(const char *s, rect box, float em, int palette) { return text_in(pal(palette, em), pr(box), v2(.5f, .5f), s); }
rect say_left(const char *s, rect box, float em, int palette) { return text_in(pal(palette, em), pr(box), v2(0, .5f), s); }

rect say_at(const char *s, vec2 center, float em, int palette, float max_width)
{
    float w = max_width > 0 ? max_width : 2000;
    return say(s, rect_centered(center, sz2(w, em * 2)), em, palette);
}

void paragraph(const char *s, rect box, float em, int palette)
{
    text_style st = pal(palette, em);
    text_box(st, pr(box), v2(.5f, .5f), s);
}

/* -------------------------------------------------------------------- widgets */

void panel(rect r)
{
    rrect(rect_offset(r, v2(0, 6)), 18, rgba(9, 28, 26, 145));
    rrect(r, 18, rgba(102, 68, 39, 255));
    rrect(rect_inflate(r, -2), 16, rgba(239, 204, 135, 255));
    rrect(rect_inflate(r, -5), 13, rgba(255, 239, 188, 255));
}

bool tapped(rect r) { return ui_hit(r, 0).clicked; }

/* Buttons respond even when drawn disabled, so the game can explain why not. */
bool button(rect r, const char *label, bool enabled)
{
    ui_state st = ui_hit(r, 0);
    rect b = st.held ? rect_offset(r, v2(0, 2)) : r;
    rrect(rect_offset(r, v2(0, 6)), 15, rgba(13, 54, 43, 255));
    rrect(b, 15, enabled ? rgba(46, 112, 70, 255) : rgba(75, 94, 80, 255));
    rrect(rc(b.pos.x + 3, b.pos.y + 3, b.size.w - 6, b.size.h - 7), 12, enabled ? rgba(113, 185, 83, 255) : rgba(110, 126, 108, 255));
    rrect(rc(b.pos.x + 6, b.pos.y + 4, b.size.w - 12, b.size.h * .4f), 10, enabled ? rgba(159, 213, 109, 255) : rgba(130, 145, 125, 255));
    say(label, rect_inflate(b, -12), 25, PAL_CREAM);
    return st.clicked;
}

static void geometry(const SDL_Vertex *v, int n, const int *idx, int m) { SDL_RenderGeometry(app_renderer(), NULL, v, n, idx, m); }

static SDL_Vertex vtx(vec2 p, color c)
{
    c = pc(c);
    return (SDL_Vertex){{p.x, p.y}, {c.r, c.g, c.b, c.a}, {0, 0}};
}

/* Two-tone gold star on a darker rim, lit from above. */
void star_icon(vec2 center, float radius)
{
    SDL_Vertex v[11];
    int idx[30];
    for (int layer = 0; layer < 2; layer++) {
        float r = (radius - (layer ? 2 : 0)) * P.scale;
        vec2 c = vec2_add(pp(center), v2(0, layer ? 0 : 2 * P.scale));
        color rim = rgba(129, 78, 27, 255);
        v[0] = vtx(c, layer ? rgba(255, 224, 100, 255) : rim);
        for (int k = 0; k < 10; k++) {
            float a = -ENGINE_PI / 2 + k * ENGINE_PI / 5, rr = r * (k % 2 ? .46f : 1);
            v[k + 1] = vtx(vec2_add(c, vec2_polar(a, rr)), layer ? (k < 5 ? rgba(255, 242, 163, 255) : rgba(225, 158, 41, 255)) : rim);
            idx[k * 3] = 0, idx[k * 3 + 1] = k + 1, idx[k * 3 + 2] = (k + 1) % 10 + 1;
        }
        geometry(v, 11, idx, 30);
    }
}

void compass_icon(vec2 center, float radius)
{
    disc(center, radius, rgba(112, 81, 40, 255));
    disc(center, radius - 2, rgba(255, 232, 162, 255));
    vec2 pts[4] = {vec2_add(center, v2(0, -radius + 4)), vec2_add(center, v2(4, 3)), vec2_add(center, v2(0, radius - 4)), vec2_add(center, v2(-4, -3))};
    SDL_Vertex v[4];
    for (int i = 0; i < 4; i++) v[i] = vtx(pp(pts[i]), i < 2 ? rgba(33, 114, 102, 255) : rgba(185, 92, 47, 255));
    int idx[6] = {0, 1, 3, 1, 2, 3};
    geometry(v, 4, idx, 6);
}

/* --------------------------------------------------------------------- header */

static bool header_button(rect r, const char *label, float em)
{
    rrect(r, 13, rgba(22, 60, 50, 220));
    say(label, rect_inflate(r, -4), em, PAL_CREAM);
    return tapped(r);
}

void draw_header(bool island)
{
    picture(R.title, rc(137, 12, 206, 206 * R.title.size.h / maxf(R.title.size.w, 1)), 255);
    if (header_button(rc(21, 26, 53, 48), island ? "<" : "Isle", 19)) {
        if (!island) {
            R.on_island = true;
        } else if (R.island.placing >= 0) {
            city_cancel(&R.island);
            notice("Your island is unchanged.");
        } else if (R.prog.level == R.island.count && R.prog.level < LEVELS) {
            if (R.g.won || R.g.lost || R.g.level != R.prog.level) start_level();
            else R.on_island = false;
        } else {
            notice("Restore your new wonder to continue.");
        }
    }
    if (header_button(rc(407, 26, 53, 48), "II", 26)) R.overlay = OV_PAUSE;
    if (!island) return;
    panel(rc(22, 92, 436, 67));
    const int kinds[3] = {RELIC_IDOL, RELIC_LEAF, RELIC_CRYSTAL};
    const float icon_x[3] = {35, 171, 304}, text_x[3] = {104, 240, 379};
    for (int k = 0; k < 3; k++) {
        picture(R.relics[kinds[k]], rc(icon_x[k], 104, 40, 40), 255);
        say_at(fmt("%d", R.prog.wallet.v[GOLD + k]), v2(text_x[k], 121), 24, k ? PAL_CREAM : PAL_GOLD, 0);
    }
}

void draw_toast(void)
{
    if (R.toast_time <= 0 || R.overlay) return;
    float y = R.on_island ? 716 : 93;
    rrect(rc(18, y - 15, 444, 30), 11, rgba(10, 37, 31, 235));
    say_at(R.toast, v2(240, y - 1), 14, PAL_CREAM, 424);
}

/* ---------------------------------------------------------------- dialogs */

typedef struct { rect card, header, stars, score_label, score, treasure_label, rewards, progress, next, claim; } result_layout;
typedef struct { rect card, title, art, description, costs, action, close; } wonder_layout;

static result_layout result_rects(void)
{
    float w = minf(408, SCREEN_W - 48), s = minf(1, (SCREEN_H - 100) / 556.f), x = (SCREEN_W - w) / 2, y = (SCREEN_H - 556 * s) / 2 + 8;
    return (result_layout){rc(x, y, w, 556 * s), rc(x + 22, y - 26 * s, w - 44, 74 * s), rc(x + 70, y + 70 * s, w - 140, 64 * s),
                           rc(x + 66, y + 140 * s, w - 132, 20 * s), rc(x + 60, y + 163 * s, w - 120, 53 * s),
                           rc(x + 30, y + 217 * s, w - 60, 20 * s), rc(x + 22, y + 243 * s, w - 44, 91 * s),
                           rc(x + 44, y + 349 * s, w - 88, 36 * s), rc(x + 28, y + 397 * s, w - 56, 65 * s),
                           rc(x + 40, y + 480 * s, w - 80, 56 * s)};
}

static wonder_layout wonder_rects(void)
{
    float w = minf(420, SCREEN_W - 48), s = minf(1, (SCREEN_H - 100) / 592.f), x = (SCREEN_W - w) / 2, y = (SCREEN_H - 592 * s) / 2;
    return (wonder_layout){rc(x, y, w, 592 * s), rc(x + 24, y + 20 * s, w - 48, 44 * s), rc(x + 76, y + 83 * s, w - 152, 205 * s),
                           rc(x + 24, y + 306 * s, w - 48, 62 * s), rc(x + 40, y + 382 * s, w - 80, 78 * s),
                           rc(x + 46, y + 478 * s, w - 92, 56 * s), rc(x + 96, y + 551 * s, w - 192, 28 * s)};
}

/* Fade and lift a part of a dialog in after `delay`; returns the paint to restore. */
static paint section(float delay, float duration, float rise)
{
    paint old = P;
    float f = R.reduced_motion ? 1 : ease_out_cubic((R.modal_clock - delay) / duration);
    P.alpha *= f;
    P.offset.y += rise * (1 - f) * P.scale;
    return old;
}

static void result_screen(void)
{
    result_layout l = result_rects();
    const building_def *w = &wonders[R.g.level];
    paint s;
    panel(l.card);
    rrect(rect_offset(l.header, v2(0, 5)), 18, rgba(77, 58, 31, 255));
    rrect(l.header, 18, rgba(31, 83, 69, 255));
    rrect(rect_inflate(l.header, -3), 15, rgba(44, 108, 84, 255));
    say("Expedition complete", rc(l.header.pos.x + 14, l.header.pos.y + 9, l.header.size.w - 28, 34), 31, PAL_GOLD);
    say(fmt("LEVEL %d  -  WELL EXPLORED", R.g.level + 1), rc(l.header.pos.x + 12, l.header.pos.y + 48, l.header.size.w - 24, 15), 14, PAL_GOLD);
    for (int k = 0; k < 3; k++) {
        rect slot = rect_col(l.stars, 3, k, 8);
        s = section(.24f + k * .13f, .32f, 13);
        float t = R.reduced_motion ? 1 : saturate((R.modal_clock - .24f - k * .13f) / .32f), pop = 1 + sinf(t * ENGINE_PI) * .14f;
        vfx_halo(pp(rect_center(slot)), 45 * P.scale, rgba(255, 201, 77, (int)(65 * P.alpha)));
        star_icon(rect_center(slot), (k == 1 ? 29 : 24) * pop);
        P = s;
    }
    vfx_torch(pp(v2(l.card.pos.x + 35, l.score.pos.y + 20)), R.now);
    vfx_torch(pp(v2(rect_max(l.card).x - 35, l.score.pos.y + 20)), R.now + .3f);
    s = section(.43f, .3f, 9);
    say("EXPEDITION SCORE", l.score_label, 12, PAL_CREAM);
    float count = R.reduced_motion ? 1 : ease_out_cubic((R.modal_clock - .43f) / .65f);
    say(fmt("%d", (int)roundf(R.g.score * count)), l.score, 46, PAL_GOLD);
    P = s;
    s = section(.62f, .25f, 8);
    say("TREASURES FOUND", l.treasure_label, 12, PAL_CREAM);
    P = s;
    purse reward = level_reward(&R.g);
    const int kinds[3] = {RELIC_IDOL, RELIC_LEAF, RELIC_CRYSTAL};
    for (int k = 0; k < 3; k++) {
        rect r = rect_col(l.rewards, 3, k, 10);
        s = section(.66f + k * .1f, .28f, 10);
        rrect(r, 12, rgba(241, 218, 157, 255));
        rrect(rect_inflate(r, -2), 10, rgba(255, 242, 201, 255));
        picture_fit(R.relics[kinds[k]], rc(r.pos.x + (r.size.w - 40) / 2, r.pos.y + 8, 40, 40), 255);
        say(fmt("+%d", reward.v[GOLD + k]), rc(r.pos.x + 6, r.pos.y + 56, r.size.w - 12, 26), 26, PAL_GOLD);
        P = s;
    }
    s = section(.93f, .24f, 8);
    for (int k = 0; k < 2; k++) {
        rect r = rect_col(l.progress, 2, k, 12);
        rrect(r, 16, rgba(221, 228, 182, 255));
        vec2 icon = v2(r.pos.x + 20, rect_center(r).y);
        if (k) compass_icon(icon, 12);
        else star_icon(icon, 11);
        say(k ? "+3 Compasses" : "+3 Stars", rc(r.pos.x + 38, r.pos.y, r.size.w - 44, r.size.h), 16, PAL_CREAM);
    }
    P = s;
    s = section(1.01f, .26f, 8);
    rrect(l.next, 12, rgba(240, 225, 180, 255));
    picture_fit(w->sprite, rc(l.next.pos.x + 8, l.next.pos.y + 5, 60, l.next.size.h - 10), 255);
    say_left("READY TO RESTORE", rc(l.next.pos.x + 78, l.next.pos.y + 9, l.next.size.w - 88, 18), 11, PAL_CREAM);
    say_left(w->name, rc(l.next.pos.x + 78, l.next.pos.y + 32, l.next.size.w - 88, 24), 22, PAL_GOLD);
    P = s;
    s = section(1.12f, .22f, 8);
    if (button(l.claim, "COLLECT & RETURN", !R.modal_closing) && !R.modal_closing) {
        if (!R.reduced_motion && R.modal_clock < 1.25f) R.modal_clock = 1.5f;   /* first tap fast-forwards */
        else R.modal_closing = true, R.modal_exit = 0;
    }
    P = s;
}

static void wonder_screen(void)
{
    int i = R.inspect >= 0 ? R.inspect : R.island.count;
    if (i < 0 || i >= WONDERS) return;
    const building_def *w = &wonders[i];
    bool can_build = i == R.island.count && i < R.prog.level, built = i < R.island.count;
    wonder_layout l = wonder_rects();
    panel(l.card);
    say(w->name, l.title, 34, PAL_GOLD);
    picture_fit(w->sprite, l.art, 255);
    paragraph(w->about, l.description, 22, PAL_CREAM);
    if (can_build) {
        const int kinds[3] = {RELIC_IDOL, RELIC_LEAF, RELIC_CRYSTAL};
        for (int k = 0; k < 3; k++) {
            rect r = rect_col(l.costs, 3, k, 10);
            picture_fit(R.relics[kinds[k]], rc(r.pos.x + (r.size.w - 34) / 2, r.pos.y, 34, 34), 255);
            say(fmt("%d", w->cost.v[GOLD + k]), rc(r.pos.x, r.pos.y + 43, r.size.w, 28), 26, PAL_GOLD);
        }
    } else {
        paragraph(built ? "RESTORED WITH YOUR EXPEDITION TREASURES" : "COMPLETE MORE LEVELS TO RESTORE THIS WONDER", l.costs, 15, PAL_CREAM);
    }
    if (button(l.action, can_build ? "CHOOSE A LOCATION" : built ? "MOVE THIS BUILDING" : "BACK TO ISLAND", true)) {
        if (can_build || built) island_begin(i, true);
        else R.overlay = OV_NONE;
    }
    say("CLOSE", l.close, 16, PAL_CREAM);
    if (tapped(l.close)) R.overlay = OV_NONE;
}

static void guide_screen(void)
{
    static const char *titles[5] = {"Connect 4+ neighbors", "Group 5: lightning", "Group 6+: bomb or prism", "Chains & ancient sand", "Ice & fire"};
    static const char *lines[5] = {"Bends and diamonds count. Three do not.", "A sun ray follows the longest axis.",
                                   "Six in a line: prism. Other shapes: bomb.", "Match on them to break or excavate.",
                                   "Match on ice; nearby flames also thaw it."};
    panel(rc(24, 144, 432, 632));
    say_at("Explorer's guide", v2(240, 182), 34, PAL_GOLD, 0);
    say_at("SWIPE OR TAP TWO NEIGHBORING RELICS", v2(240, 221), 13, PAL_WHITE, 0);
    for (int k = 0; k < 5; k++) {
        float y = 278 + k * 79;
        draw_relic((tile){k, k == 1 ? ROW : k == 2 ? BOMB : NORMAL}, pp(v2(66, y)), P.scale, 255 * P.alpha, 1);
        say_at(titles[k], v2(273, y - 12), 23, PAL_GOLD, 318);
        say_at(lines[k], v2(273, y + 15), 16, PAL_CREAM, 318);
    }
    say_at("TOOLS DO NOT COST MOVES. TAP ONE, THEN A TILE.", v2(240, 679), 12, PAL_WHITE, 0);
    bool done = button(rc(78, 709, 324, 45), "LET'S EXPLORE", true);
    if (done || tapped(rc(0, 700, SCREEN_W, SCREEN_H - 700))) R.overlay = OV_NONE;
}

static void pause_screen(void)
{
    panel(rc(42, 252, 396, 382));
    say_at("Take a breath", v2(240, 291), 34, PAL_GOLD, 0);
    if (button(rc(88, 337, 304, 49), "RESUME", true)) R.overlay = OV_NONE;
    if (button(rc(88, 406, 304, 49), R.sound ? "SOUND ON" : "SOUND OFF", true)) R.sound = !R.sound, sfx_enable(R.sound);
    if (button(rc(88, 475, 304, 49), R.reduced_motion ? "MOTION REDUCED" : "FULL ANIMATION", true)) R.reduced_motion = !R.reduced_motion;
    if (button(rc(88, 544, 304, 49), "EXPLORER'S GUIDE", true)) R.overlay = OV_GUIDE;
}

static void failed_screen(void)
{
    panel(rc(38, 272, 404, 333));
    say_at("One more adventure?", v2(240, 317), 32, PAL_GOLD, 0);
    say_at("THE RUINS WILL WAIT FOR YOU.", v2(240, 366), 16, PAL_WHITE, 0);
    say_at("Try a special combo or use a tool.", v2(240, 404), 17, PAL_CREAM, 0);
    if (button(rc(83, 448, 314, 50), "TRY AGAIN", true)) start_level();
    if (button(rc(115, 520, 250, 42), "VISIT ISLAND", true)) R.on_island = true, R.overlay = OV_NONE;
}

static void zone_screen(void)
{
    int z = R.zone_card;
    const city_zone *zone = &R.island.zones[z];
    bool ready = city_zone_available(&R.island, z, R.prog.wallet);
    panel(rc(30, 263, 420, 365));
    say_at(zone->name, v2(240, 304), 34, PAL_GOLD, 380);
    say_at("A NEW PLACE TO DISCOVER", v2(240, 349), 16, PAL_CREAM, 0);
    say_at(fmt("STARS  %d / %d", R.prog.wallet.v[STARS], zone->needs.v[STARS]), v2(240, 397), 24, PAL_GOLD, 0);
    say_at(fmt("COMPASSES  %d / %d", R.prog.wallet.v[COMPASSES], zone->cost.v[COMPASSES]), v2(240, 441), 23, PAL_CREAM, 0);
    if (button(rc(72, 487, 336, 47), ready ? "OPEN THIS AREA" : "KEEP EXPLORING", true)) {
        if (city_unlock(&R.island, z, &R.prog.wallet)) {
            island_focus(zone->marker, R.island.cam.zoom);
            save_progress();
            story_say("mara", "New land is yours. Make it your own.");
            tone(820);
        }
        R.overlay = OV_NONE;
    }
    say_at("COMPASSES ARE SPENT. STARS STAY WITH YOU.", v2(240, 559), 12, PAL_WHITE, 0);
    say_at("CLOSE", v2(240, 592), 15, PAL_WHITE, 0);
    if (tapped(rc(0, 575, SCREEN_W, SCREEN_H - 575))) R.overlay = OV_NONE;
}

static void finale_screen(void)
{
    panel(rc(32, 285, 416, 305));
    say_at("The valley lives again", v2(240, 330), 31, PAL_GOLD, 0);
    say_at("YOU RESTORED ALL TEN WONDERS.", v2(240, 386), 16, PAL_WHITE, 0);
    say_at("THANK YOU FOR EXPLORING.", v2(240, 422), 16, PAL_WHITE, 0);
    if (button(rc(82, 489, 316, 50), "BACK TO MY ISLAND", true)) R.overlay = OV_NONE;
}

/* Draws the open dialog over everything; it alone receives input. */
void overlays(float dt)
{
    if (R.overlay != R.modal_for) {   /* a new dialog starts its entrance */
        R.modal_for = R.overlay;
        R.modal_clock = R.modal_exit = 0;
        R.modal_closing = false;
    }
    if (!R.overlay) return;
    R.modal_clock += dt;
    if (R.modal_closing) {
        R.modal_exit += dt;
        if (R.modal_exit >= .2f || R.reduced_motion) {
            R.modal_closing = false;
            claim_reward();
            R.modal_for = R.overlay;
            return;
        }
    }
    float entry = R.reduced_motion ? 1 : ease_out_cubic(R.modal_clock / .28f);
    float exit = R.modal_closing ? ease_out_cubic(R.modal_exit / .2f) : 0;
    draw_rect(rc(0, 0, SCREEN_W, SCREEN_H), rgba(5, 22, 22, (int)(185 * entry * (1 - exit))));
    ui_block(rc(0, 0, SCREEN_W, SCREEN_H));
    float scale = .96f + .04f * entry;
    P = (paint){scale, v2(240 * (1 - scale), 450 * (1 - scale) + 22 * (1 - entry) + 18 * exit), entry * (1 - exit)};
    switch (R.overlay) {
    case OV_GUIDE: guide_screen(); break;
    case OV_PAUSE: pause_screen(); break;
    case OV_RESULT: result_screen(); break;
    case OV_FAILED: failed_screen(); break;
    case OV_WONDER: wonder_screen(); break;
    case OV_ZONE: zone_screen(); break;
    case OV_FINALE: finale_screen(); break;
    default: break;
    }
    P = (paint){1, {0, 0}, 1};
}
