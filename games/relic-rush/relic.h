/* relic.h — Relic Rush: hex match-4 rules, campaign, island map and the
 * state shared by the game's source files. The rules part has no SDL or
 * engine state and is exercised by tests/test_relic.c. */
#ifndef RELIC_H
#define RELIC_H

#include "engine.h"

/* ------------------------------------------------------------------ hex grid */

/* 61 cells of a radius-4 hexagon in axial coordinates (q, r); neighbours are
 * numbered 0..5 and opposite directions differ by 3. */
enum { HEX_RADIUS = 4, CELLS = 61 };

int hex_index(int q, int r);    /* -1 outside the board */
int hex_q(int cell);
int hex_r(int cell);
int hex_neighbor(int cell, int direction);
int hex_distance(int a, int b);
int hex_center(void);

/* --------------------------------------------------------------------- rules */

enum { LEVELS = 10, COLORS = 6, MATCH_MIN = 4 };

/* Relic kinds with a meaning: idols are counted, flames thaw ice, leaves and
 * crystals are wood and stone for building. */
enum { RELIC_IDOL = 0, RELIC_FLAME = 1, RELIC_LEAF = 2, RELIC_SCARAB = 3, RELIC_CRYSTAL = 4, RELIC_AMPHORA = 5 };

typedef enum { NORMAL, ROW, COLUMN, DIAGONAL, BOMB, PRISM } special;

typedef struct { int kind, special; } tile;     /* kind -1 = empty */

typedef struct {
    const char *name, *lesson;
    int moves, score, relics, soil, chains, ice;
} level;

/* What a swap or wave clears (mask) and which specials it leaves behind (make). */
typedef struct { int mask[CELLS], make[CELLS], hits; } match;

typedef struct {
    tile tiles[CELLS];
    unsigned char active[CELLS];         /* the level's board shape */
    int soil[CELLS], chain[CELLS], ice[CELLS];
    int level, moves, score, relics, dug, obstacles, initial_obstacles, initial_soil;
    int combo, cleared, last_gold, last_wood, last_stone, wood, stone;
    uint32_t rng;
    bool won, lost;
    int tools[3];                        /* pickaxe, dynamite, sunburst charges */
} game;

extern const level levels[LEVELS];
extern const char *level_shapes[LEVELS];

bool game_cell_active(const game *g, int cell);
void game_start(game *g, int level, uint32_t seed);
void game_matches(const game *g, match *m, int preferred);
bool game_can_swap(const game *g, int a, int b);
bool game_swap(game *g, int a, int b, match *m);   /* false (and unchanged) if nothing would clear */
int game_apply(game *g, match *m);                  /* clear one wave, fire specials; returns cleared relics */
void game_collapse(game *g, int from[CELLS]);       /* gravity per column segment; from[] = source cell, or -n spawned */
void game_check_end(game *g);
bool game_hint(const game *g, int *a, int *b);
void game_shuffle(game *g);
bool game_tool(game *g, int tool, int cell, match *m);
int game_evaluate_move(const game *g, int a, int b);

/* ------------------------------------------------------------------- economy */

enum { GOLD, WOOD, STONE, STARS, COMPASSES };

typedef struct {
    int level;          /* expeditions won = buildings unlocked */
    uint32_t seed;
    purse wallet;       /* gold, wood, stone, stars (never spent), compasses */
} progress;

/* Reward for winning the current expedition, once per level. */
purse level_reward(const game *g);
void progress_reward(progress *p, const game *g);

/* -------------------------------------------------------------------- island */

enum { ISLAND_W = 1920, ISLAND_H = 2880, ISLAND_ZONES = 6, WONDERS = 10 };

extern building_def wonders[WONDERS];      /* the ten restorations, in campaign order */

bool island_grass(vec2 world);
int island_zone(vec2 world);
bool island_zone_touches(int zone, unsigned open);
vec2 island_suggestion(int wonder);         /* a good first spot for each wonder */
void island_setup(city *c);                 /* map, zones, wonders and rules for an engine city */
bool island_place_next(city *c, purse *wallet, int built_limit, double now);   /* build the next wonder at a free spot */

/* -------------------------------------------------------------- presentation */

/* The game is laid out for a 480 x 900 portrait screen, letterboxed elsewhere. */
enum { SCREEN_W = 480, SCREEN_H = 900 };
#define HEX_R 26.5f
#define BOARD_CLIP rc(24, 276, 432, 432)
#define MAP_VIEW rc(0, 164, 480, 576)

typedef enum { OV_NONE, OV_GUIDE, OV_PAUSE, OV_RESULT, OV_FAILED, OV_WONDER, OV_FINALE, OV_ZONE } overlay_id;
typedef enum { PH_IDLE, PH_SWAP, PH_REJECT, PH_CLEAR, PH_FALL } phase_id;
enum { PAL_GOLD, PAL_CREAM, PAL_GREEN, PAL_WHITE };

typedef struct {
    texture backdrop, scenes[2], title, relics[COLORS], glow;
    font *font;
    progress prog;
    city island;

    /* the expedition in progress */
    game g;
    match pending;
    tile old_tiles[CELLS];               /* the board before the current animation step */
    int fall_from[CELLS], wave_ice[CELLS], wave_chain[CELLS];
    phase_id phase;
    float phase_time, idle_time, shake;
    int selected, swap_a, swap_b, tool, hint_a, hint_b;

    /* screens */
    bool on_island;
    overlay_id overlay, modal_for;      /* modal_for: the dialog whose entrance is playing */
    float modal_clock, modal_exit;
    bool modal_closing;
    int inspect, zone_card;
    bool reduced_motion, sound, test_mode;
    const char *toast;
    float toast_time, now;
    bool quiet;                          /* no story (stills for the docs) */
    int bubble_wonder;                   /* a word bubble over a wonder just placed */
    const char *bubble_text;
    float bubble_time;

    /* animated readouts */
    float score_display, score_pulse, goal_display, goal_pulse, word_time;
    int word_combo, fx_combo, fx_origin;
} relic_state;

extern relic_state R;

/* main.c */
extern const story_line finale[2];
text_style speech_style(float size);
void notice(const char *text);
void tone(float hz);
void save_progress(void);
void start_level(void);
void claim_reward(void);

/* screens.c: painting helpers honour a modal transform (scale, offset, opacity) */
typedef struct { float scale; vec2 offset; float alpha; } paint;
extern paint P;
rect pr(rect r);
vec2 pp(vec2 p);
void fill(rect r, color c);
void rrect(rect r, float radius, color c);
void disc(vec2 center, float radius, color c);
void seg(vec2 a, vec2 b, float width, color c);
void picture(texture t, rect r, float alpha);
void picture_fit(texture t, rect box, float alpha);
text_style pal(int palette, float em);
rect say(const char *s, rect box, float em, int palette);
rect say_left(const char *s, rect box, float em, int palette);
rect say_at(const char *s, vec2 center, float em, int palette, float max_width);
void paragraph(const char *s, rect box, float em, int palette);
void panel(rect r);
bool button(rect r, const char *label, bool enabled);
bool tapped(rect r);
void star_icon(vec2 center, float radius);
void compass_icon(vec2 center, float radius);
void draw_header(bool island);
void draw_toast(void);
void overlays(float dt);

/* board.c */
vec2 cell_pos(int cell);
void draw_relic(tile t, vec2 at, float scale, float alpha, float aspect);
void board_screen(input in, float dt);
void board_update(float dt);
void finish_wave(void);
void attempt_swap(int a, int b);

/* vfx.c */
void vfx_init(void);
void vfx_reset(void);
void vfx_wave(int old_score);
void vfx_emit(vec2 at, int kind, bool flying);
void vfx_update(float dt);
void vfx_draw(void);
void vfx_particles(void);
void vfx_halo(vec2 at, float radius, color c);
void vfx_torch(vec2 at, float t);
color vfx_color(int kind, float alpha);

/* island_view.c */
void island_screen(input in, float dt);
void island_begin(int wonder, bool focus);
void island_focus(vec2 world, float zoom);

#endif
