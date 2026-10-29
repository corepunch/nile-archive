/* vfx.c — presentation-only effects with their own random stream and fixed
 * pools: impacts, travelling sun rays, blast shockwaves, prism links, special
 * births, score pop-ups, sparks, relics flying to the HUD and torch flames.
 * Gameplay never reads anything from here. */
#include "relic.h"

#include <string.h>

enum { FX_CAP = 256, PARTICLES = 650 };
typedef enum { FX_NONE, FX_IMPACT, FX_RAY, FX_BLAST, FX_LINK, FX_BIRTH, FX_SCORE } fx_type;

typedef struct { fx_type type; int kind, value; vec2 at, to; float age, life, delay; } effect;
typedef struct { vec2 at, vel, to; float age, life; int kind; bool flying; } particle;

static effect pool[FX_CAP];
static particle parts[PARTICLES];
static int pool_next, part_next;
static rng fx_rng = {0x4a17b83u};

color vfx_color(int kind, float alpha)
{
    static const color palette[8] = {{255, 201, 73, 255},  {255, 107, 48, 255},  {113, 232, 115, 255}, {71, 222, 255, 255},
                                     {196, 116, 255, 255}, {255, 173, 70, 255},  {188, 244, 255, 255}, {249, 223, 161, 255}};
    color c = palette[clampi(kind, 0, 7)];
    c.a = (uint8_t)clampf(alpha, 0, 255);
    return c;
}

/* A soft radial glow texture (cubic falloff), drawn additively. */
void vfx_init(void)
{
    static uint8_t px[64 * 64 * 4];
    for (int y = 0; y < 64; y++)
        for (int x = 0; x < 64; x++) {
            float t = maxf(0, 1 - vec2_len(v2(x - 31.5f, y - 31.5f)) / 32);
            uint8_t *p = &px[(y * 64 + x) * 4];
            p[0] = p[1] = p[2] = 255;
            p[3] = (uint8_t)(255 * t * t * t);
        }
    R.glow = tex_from_pixels(px, 64, 64);
    if (R.glow.tex) SDL_SetTextureBlendMode(R.glow.tex, SDL_BLENDMODE_ADD);
}

void vfx_reset(void)
{
    memset(pool, 0, sizeof pool);
    memset(parts, 0, sizeof parts);
    pool_next = part_next = 0;
    R.fx_combo = 0;
    R.fx_origin = -1;
    R.score_display = (float)R.g.score;
    R.goal_display = R.word_time = R.score_pulse = R.goal_pulse = 0;
}

static void add(fx_type type, vec2 at, vec2 to, int kind, float life, float delay, int value)
{
    if (R.reduced_motion) return;
    pool[pool_next++ % FX_CAP] = (effect){type, kind, value, at, to, 0, life, delay};
}

void vfx_halo(vec2 at, float radius, color c) { draw_image(R.glow, rect_centered(at, sz2s(radius * 2)), c); }
static void ring(vec2 at, float radius, float width, color c)
{
    if (radius >= 1) draw_ring(at, radius - width * .5f, width, c);
}
static void spark(vec2 at, float radius, float angle, color c) { draw_star(at, radius, .24f, 4, angle, c); }

/* ------------------------------------------------------------------ particles */

static int goal_count(void) { return 2 + (levels[R.g.level].soil > 0) + (R.g.initial_obstacles > 0); }

void vfx_emit(vec2 at, int kind, bool flying)
{
    if (R.reduced_motion) return;
    for (int k = 0; k < (flying ? 1 : 7); k++) {
        particle *p = &parts[part_next++ % PARTICLES];
        float a = rng_float(&fx_rng) * 2 * ENGINE_PI, speed = 55 + rng_float(&fx_rng) * 125;
        vec2 to = kind == RELIC_IDOL ? v2(24 + 432.f / goal_count() + 19, 248) : v2(90, 153);   /* idol goal or score */
        *p = (particle){at, vec2_add(vec2_polar(a, speed), v2(0, -35)), to, flying ? -rng_float(&fx_rng) * .14f : 0,
                        flying ? .75f + rng_float(&fx_rng) * .2f : .35f + rng_float(&fx_rng) * .32f, kind, flying};
    }
}

static vec2 flight(const particle *p, float t)
{
    float f = t < .5f ? 2 * t * t : 1 - powf(-2 * t + 2, 2) / 2, arc = sinf(f * ENGINE_PI);
    return vec2_add(vec2_lerp(p->at, p->to, f), v2(arc * (p->at.x < 240 ? -34 : 34), -arc * 64));
}

static void land(const particle *p)
{
    add(FX_IMPACT, p->to, v2(0, 0), p->kind, .25f, 0, 0);
    if (p->kind == RELIC_IDOL) R.goal_pulse = .22f;
    else R.score_pulse = .22f;
}

void vfx_particles(void)
{
    if (R.reduced_motion) return;
    for (int i = 0; i < PARTICLES; i++) {
        particle *p = &parts[i];
        if (p->life <= 0 || p->age < 0) continue;
        float t = p->age / p->life, fade = 1 - t;
        if (p->flying) {
            vec2 at = flight(p, t);
            for (int k = 4; k > 0; k--) vfx_halo(flight(p, maxf(0, t - k * .025f)), 9 - k, vfx_color(p->kind, 70 * (1 - k / 5.f)));
            vfx_halo(at, 19, vfx_color(p->kind, 125));
            float size = 18 + 7 * sinf(t * ENGINE_PI);
            draw_image(R.relics[p->kind], rect_centered(at, sz2s(size)), WHITE);
            continue;
        }
        color c = vfx_color(p->kind, 255 * fade);
        vfx_halo(p->at, 8 * fade + 2, vfx_color(p->kind, 130 * fade));
        if (i % 3 == 0) {
            spark(p->at, 5 * fade + 1, t * 4, c);
        } else {
            draw_line(p->at, vec2_sub(p->at, vec2_scale(p->vel, .025f)), 2.5f * fade, c);
            draw_circle(p->at, 1.4f + 1.6f * fade, rgba(255, 252, 216, (int)(230 * fade)));
        }
    }
}

/* -------------------------------------------------------------------- waves */

static void axis_rays(int cell, int axis, int kind)
{
    for (int sign = 0; sign < 2; sign++) {
        int end = cell;
        for (int n = hex_neighbor(cell, axis + sign * 3); n >= 0; n = hex_neighbor(n, axis + sign * 3)) end = n;
        add(FX_RAY, cell_pos(cell), cell_pos(end), kind, .6f, .025f, 0);
    }
}

static void prism_links(int cell)
{
    int links = 0;
    for (int i = 0; i < CELLS && links < 18; i++)
        if (R.pending.mask[i] && i != cell) {
            add(FX_LINK, cell_pos(cell), cell_pos(i), R.old_tiles[i].kind, .48f, (links % 6) * .018f, 0);
            links++;
        }
    add(FX_BLAST, cell_pos(cell), v2(0, 0), 4, .6f, 0, 90);
}

/* Effects for one clearing wave, read from R.pending and the board before it. */
void vfx_wave(int old_score)
{
    vec2 sum = v2(0, 0);
    int hits = 0;
    for (int i = 0; i < CELLS; i++) {
        if (!R.pending.mask[i] || !game_cell_active(&R.g, i)) continue;
        vec2 at = cell_pos(i);
        tile was = R.old_tiles[i];
        sum = vec2_add(sum, at);
        hits++;
        int kind = R.wave_ice[i] ? 6 : R.wave_chain[i] ? 7 : was.kind;
        add(FX_IMPACT, at, v2(0, 0), kind, .3f, 0, 0);
        vfx_emit(at, kind, false);
        if (!R.wave_ice[i] && !R.wave_chain[i]) {
            if (was.kind == RELIC_IDOL || was.kind == RELIC_LEAF || was.kind == RELIC_CRYSTAL) vfx_emit(at, was.kind, true);
            if (!R.pending.make[i]) {
                if (was.special == ROW || was.special == COLUMN || was.special == DIAGONAL)
                    axis_rays(i, was.special == ROW ? 0 : was.special == COLUMN ? 1 : 2, was.kind);
                else if (was.special == BOMB) add(FX_BLAST, at, v2(0, 0), 0, .58f, 0, 95);
                else if (was.special == PRISM) prism_links(i);
            }
        }
        if (R.pending.make[i]) add(FX_BIRTH, at, v2(0, 0), was.kind, .65f, .2f, 0);
    }
    if (R.fx_origin >= 0) {   /* the cell a combo swap fired from */
        if (R.fx_combo == 3) prism_links(R.fx_origin);
        else if (R.fx_combo == 2) add(FX_BLAST, cell_pos(R.fx_origin), v2(0, 0), 0, .65f, 0, 150);
        else if (R.fx_combo == 1)
            for (int a = 0; a < 3; a++) axis_rays(R.fx_origin, a, 0);
    }
    R.fx_origin = -1;
    R.fx_combo = 0;
    if (hits) {
        add(FX_SCORE, vec2_sub(vec2_scale(sum, 1.0f / hits), v2(0, 22)), v2(0, 0), 0, .65f, .08f, R.g.score - old_score);
        R.score_pulse = .25f;
    }
    if (R.g.combo > 1) R.word_time = .75f, R.word_combo = R.g.combo;
}

void vfx_update(float dt)
{
    for (int i = 0; i < FX_CAP; i++)
        if (pool[i].life > 0 && (pool[i].age += dt) >= pool[i].life + pool[i].delay) pool[i].life = 0;
    for (int i = 0; i < PARTICLES; i++) {
        particle *p = &parts[i];
        if (p->life <= 0) continue;
        p->age += dt;
        if (p->age >= p->life) {
            if (p->flying) land(p);
            p->life = 0;
            continue;
        }
        if (p->age < 0 || p->flying) continue;
        p->at = vec2_add(p->at, vec2_scale(p->vel, dt));
        p->vel.y += 210 * dt;
    }
    R.score_display = approachf(R.score_display, (float)R.g.score, 15, dt);
    if (fabsf(R.g.score - R.score_display) < 1) R.score_display = (float)R.g.score;
    R.goal_display = approachf(R.goal_display, saturate(R.g.score / (float)levels[R.g.level].score), 12, dt);
    R.score_pulse = maxf(0, R.score_pulse - dt);
    R.goal_pulse = maxf(0, R.goal_pulse - dt);
    R.word_time = maxf(0, R.word_time - dt);
}

void vfx_draw(void)
{
    if (R.on_island || R.reduced_motion) return;
    for (int i = 0; i < FX_CAP; i++) {
        effect *e = &pool[i];
        if (e->life <= 0 || e->age < e->delay || e->type == FX_SCORE) continue;
        float t = (e->age - e->delay) / e->life, fade = 1 - t;
        color c = vfx_color(e->kind, 220 * fade);
        color cream = rgba(255, 249, 207, (int)(220 * fade));
        gfx_additive(true);
        switch (e->type) {
        case FX_IMPACT:
            vfx_halo(e->at, 20 + 35 * t, vfx_color(e->kind, 150 * fade));
            ring(e->at, 7 + 28 * t, 2.5f * fade, c);
            if (t < .65f) spark(e->at, 16 * fade, ENGINE_PI / 4, cream);
            break;
        case FX_BLAST: {
            float r = e->value * ease_out_cubic(t);
            vfx_halo(e->at, 48 + 60 * t, vfx_color(e->kind, 190 * fade * fade));
            ring(e->at, r + 7, 18 * fade, vfx_color(e->kind, 45 * fade));
            ring(e->at, r, 4 + 7 * fade, c);
            ring(e->at, r * .85f, 2.5f, rgba(255, 245, 202, (int)(220 * fade)));
            if (t < .5f) spark(e->at, 40 * fade, ENGINE_PI / 4, rgba(255, 242, 183, (int)(220 * fade)));
            for (int k = 0; k < 8; k++) spark(vec2_add(e->at, vec2_polar(k * ENGINE_PI / 4, r * .8f)), 7 * fade, k * ENGINE_PI / 4, c);
            break;
        }
        case FX_RAY: {
            vec2 tip = vec2_lerp(e->at, e->to, ease_out_cubic(minf(1, t * 1.8f)));
            draw_line(e->at, tip, 36 * fade, vfx_color(e->kind, 80 * fade));
            draw_line(e->at, tip, 2 + 13 * fade, c);
            draw_line(e->at, tip, 1.5f + 3 * fade, rgba(255, 255, 227, (int)(255 * fade)));
            vfx_halo(tip, 29, vfx_color(e->kind, 255 * fade));
            spark(tip, 13 * fade, ENGINE_PI / 4, rgba(255, 251, 220, (int)(255 * fade)));
            break;
        }
        case FX_LINK: {
            vec2 prev = e->at;
            float f = ease_out_cubic(minf(1, t * 3));
            for (int k = 1; k <= 8; k++) {
                float u = k / 8.f * f, bend = sinf(u * ENGINE_PI) * sinf(k * 2.7f + i) * 7;
                vec2 next = vec2_add(vec2_lerp(e->at, e->to, u), v2(bend, -bend));
                draw_line(prev, next, 8 * fade, vfx_color(e->kind, 65 * fade));
                draw_line(prev, next, 2, rgba(255, 250, 220, (int)(220 * fade)));
                prev = next;
            }
            vfx_halo(e->to, 24, vfx_color(e->kind, 150 * fade));
            break;
        }
        case FX_BIRTH:
            vfx_halo(e->at, 48 * fade + 20, c);
            ring(e->at, HEX_R * (1 + .4f * t), 3 * fade, c);
            for (int k = 0; k < 4; k++) {
                float a = t * 3 + k * ENGINE_PI / 2;
                spark(vec2_add(e->at, vec2_polar(a, 24)), 8 * fade, a, rgba(255, 250, 219, (int)(220 * fade)));
            }
            break;
        default: break;
        }
        gfx_additive(false);
    }
    for (int i = 0; i < FX_CAP; i++) {
        effect *e = &pool[i];
        if (e->type != FX_SCORE || e->life <= 0 || e->age < e->delay) continue;
        float t = (e->age - e->delay) / e->life;
        paint keep = P;
        P.alpha = 1 - t;
        say_at(fmt("+%d", e->value), vec2_sub(e->at, v2(0, ease_out_cubic(t) * 30)), 21 + 5 * sinf(t * ENGINE_PI), PAL_GOLD, 0);
        P = keep;
    }
    if (R.word_time > 0) {
        float t = 1 - R.word_time / .75f;
        const char *word = R.word_combo >= 5 ? "SUNSTORM!" : R.word_combo >= 3 ? "MAGNIFICENT!" : "BRILLIANT!";
        say_at(word, v2(240, 732 - sinf(t * ENGINE_PI) * 8), 28 + 8 * sinf(minf(1, t * 4) * ENGINE_PI), PAL_GOLD, 420);
    }
}

/* A quiet torch: buoyant flame parcels, a warm core and translucent wisps. */
void vfx_torch(vec2 at, float t)
{
    vfx_halo(vec2_add(at, v2(0, -20)), 53, rgba(255, 122, 26, 90));
    draw_round_rect(rc(at.x - 12, at.y - 42, 24, 49), 11, rgba(78, 87, 57, 255));
    SDL_SetTextureBlendMode(R.glow.tex, SDL_BLENDMODE_BLEND);
    float clock = R.reduced_motion ? 1.2f : t;
    for (int k = 0; k < 34; k++) {
        float seed = sinf(k * 127.1f + 311.7f) * .5f + .5f, life = .65f + .5f * seed;
        float a = fmodf(clock + seed * life * 5, life) / life, fade = powf(1 - a, 1.2f);
        vec2 p = v2(at.x + sinf(a * 6 + k * .8f) * (2 + a * 4) + sinf(clock * 3 + seed * 4) * 1.3f, at.y - 4 - 40 * a - 8 * a * a);
        float r = (5 + seed * 4) * fade;
        draw_image(R.glow, rc(p.x - r, p.y - r * 2, r * 2, r * 4), rgba(255, (int)(72 + seed * 64), 8, (int)(105 * fade)));
        draw_image(R.glow, rc(p.x - r * .55f, p.y - r * 1.3f, r * 1.1f, r * 2.6f), rgba(255, (int)(179 + seed * 55), 62, (int)(150 * fade)));
    }
    SDL_SetTextureBlendMode(R.glow.tex, SDL_BLENDMODE_ADD);
    vfx_halo(vec2_add(at, v2(0, -4)), 18, rgba(255, 234, 150, 160));
    draw_round_rect(rc(at.x - 3, at.y + 8, 6, 22), 2, rgba(93, 60, 33, 255));
    draw_round_rect(rc(at.x - 11, at.y + 5, 22, 7), 3, rgba(147, 98, 45, 255));
    draw_round_rect(rc(at.x - 9, at.y + 1, 18, 6), 2, rgba(211, 160, 78, 255));
    draw_rect(rc(at.x - 7, at.y + 2, 14, 2), rgba(255, 219, 131, 255));
}
