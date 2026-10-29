/* rules.c — hex match-4 rules and the ten-level campaign.
 *
 * A connected group of four or more identical relics (sharing hex edges)
 * clears. Five leave a directional sun ray along the group's longest axis;
 * six or more leave a hex bomb, or a sun prism when six lie in a straight
 * line. Sand is excavated by clearing above it, chains and ice lock relics
 * until hit, and matched flames thaw the ice around them. */
#include "relic.h"

#include <string.h>

/* ------------------------------------------------------------------ hex grid */

static const signed char qs[CELLS] = {-4, -4, -4, -4, -4, -3, -3, -3, -3, -3, -3, -2, -2, -2, -2, -2, -2, -2, -1, -1, -1,
                                      -1, -1, -1, -1, -1, 0,  0,  0,  0,  0,  0,  0,  0,  0,  1,  1,  1,  1,  1,  1,  1,
                                      1,  2,  2,  2,  2,  2,  2,  2,  3,  3,  3,  3,  3,  3,  4,  4,  4,  4,  4};
static const signed char rs[CELLS] = {0,  1,  2,  3,  4, -1, 0,  1,  2,  3,  4,  -2, -1, 0,  1,  2,  3,  4,  -3, -2, -1,
                                      0,  1,  2,  3,  4, -4, -3, -2, -1, 0,  1,  2,  3,  4,  -4, -3, -2, -1, 0,  1,  2,
                                      3,  -4, -3, -2, -1, 0, 1,  2,  -4, -3, -2, -1, 0,  1,  -4, -3, -2, -1, 0};
/* direction d: 0 = (+1, 0), 1 = (0, +1), 2 = (-1, +1), 3..5 the opposites */
static const signed char neighbors[CELLS][6] = {
    {6, 1, -1, -1, -1, 5},     {7, 2, -1, -1, 0, 6},      {8, 3, -1, -1, 1, 7},      {9, 4, -1, -1, 2, 8},
    {10, -1, -1, -1, 3, 9},    {12, 6, 0, -1, -1, 11},    {13, 7, 1, 0, 5, 12},      {14, 8, 2, 1, 6, 13},
    {15, 9, 3, 2, 7, 14},      {16, 10, 4, 3, 8, 15},     {17, -1, -1, 4, 9, 16},    {19, 12, 5, -1, -1, 18},
    {20, 13, 6, 5, 11, 19},    {21, 14, 7, 6, 12, 20},    {22, 15, 8, 7, 13, 21},    {23, 16, 9, 8, 14, 22},
    {24, 17, 10, 9, 15, 23},   {25, -1, -1, 10, 16, 24},  {27, 19, 11, -1, -1, 26},  {28, 20, 12, 11, 18, 27},
    {29, 21, 13, 12, 19, 28},  {30, 22, 14, 13, 20, 29},  {31, 23, 15, 14, 21, 30},  {32, 24, 16, 15, 22, 31},
    {33, 25, 17, 16, 23, 32},  {34, -1, -1, 17, 24, 33},  {35, 27, 18, -1, -1, -1},  {36, 28, 19, 18, 26, 35},
    {37, 29, 20, 19, 27, 36},  {38, 30, 21, 20, 28, 37},  {39, 31, 22, 21, 29, 38},  {40, 32, 23, 22, 30, 39},
    {41, 33, 24, 23, 31, 40},  {42, 34, 25, 24, 32, 41},  {-1, -1, -1, 25, 33, 42},  {43, 36, 27, 26, -1, -1},
    {44, 37, 28, 27, 35, 43},  {45, 38, 29, 28, 36, 44},  {46, 39, 30, 29, 37, 45},  {47, 40, 31, 30, 38, 46},
    {48, 41, 32, 31, 39, 47},  {49, 42, 33, 32, 40, 48},  {-1, -1, 34, 33, 41, 49},  {50, 44, 36, 35, -1, -1},
    {51, 45, 37, 36, 43, 50},  {52, 46, 38, 37, 44, 51},  {53, 47, 39, 38, 45, 52},  {54, 48, 40, 39, 46, 53},
    {55, 49, 41, 40, 47, 54},  {-1, -1, 42, 41, 48, 55},  {56, 51, 44, 43, -1, -1},  {57, 52, 45, 44, 50, 56},
    {58, 53, 46, 45, 51, 57},  {59, 54, 47, 46, 52, 58},  {60, 55, 48, 47, 53, 59},  {-1, -1, 49, 48, 54, 60},
    {-1, 57, 51, 50, -1, -1},  {-1, 58, 52, 51, 56, -1},  {-1, 59, 53, 52, 57, -1},  {-1, 60, 54, 53, 58, -1},
    {-1, -1, 55, 54, 59, -1}};

int hex_index(int q, int r)
{
    for (int i = 0; i < CELLS; i++)
        if (qs[i] == q && rs[i] == r) return i;
    return -1;
}

int hex_q(int cell) { return cell >= 0 && cell < CELLS ? qs[cell] : 0; }
int hex_r(int cell) { return cell >= 0 && cell < CELLS ? rs[cell] : 0; }
int hex_neighbor(int cell, int d) { return cell >= 0 && cell < CELLS && d >= 0 && d < 6 ? neighbors[cell][d] : -1; }
int hex_center(void) { return 30; }

int hex_distance(int a, int b)
{
    if (a < 0 || a >= CELLS || b < 0 || b >= CELLS) return 10000;
    int q = qs[a] - qs[b], r = rs[a] - rs[b];
    return (abs(q) + abs(r) + abs(q + r)) / 2;
}

/* ------------------------------------------------------------------ campaign */

const level levels[LEVELS] = {
    {"First Light", "Join 4+ neighbors. Bends and diamonds count!", 24, 1100, 8, 0, 0, 0},
    {"The Jade Crescent", "Groups of five create a sun ray.", 28, 1800, 10, 7, 0, 0},
    {"Sunstone Spiral", "Excavate the spiral beneath the relics.", 32, 2300, 12, 12, 0, 0},
    {"The Vine Constellation", "Match locked relics to break their chains.", 34, 2700, 12, 10, 4, 0},
    {"Three Paths Meet", "Groups of six or more make a hex blast.", 36, 3100, 14, 13, 4, 0},
    {"Winter Lotus", "Break the ice around the frozen lotus.", 38, 3400, 14, 13, 0, 5},
    {"The Ember Ring", "Fire melts ice in all six neighboring cells.", 40, 3800, 16, 15, 4, 5},
    {"Prism Observatory", "Six in a straight line forge a sun prism.", 42, 4200, 16, 17, 4, 6},
    {"The Sixfold Seal", "Combine rays to clear all three axes.", 44, 4600, 18, 19, 5, 6},
    {"Heart of the Hexagon", "Uncover the ancient sun at the heart of the valley.", 46, 5000, 20, 22, 6, 6},
};

const char *level_shapes[LEVELS] = {"Hexagon", "Crescent",  "Diamond",     "Butterfly",  "Hourglass",
                                    "Lotus",   "Ring",      "Twin courts", "Crossroads", "Sun crown"};

static bool shape_cell(int lvl, int i)
{
    int q = hex_q(i), r = hex_r(i), s = -q - r, d = hex_distance(i, hex_center()), y = 2 * r + q;
    switch (lvl) {
    case 1: return q <= 1 || (r < 0 && q + r < 3);
    case 2: return abs(q) <= 3 && abs(r) <= 3;
    case 3: return abs(q) <= 1 || abs(y) >= 3;
    case 4: return abs(q) <= 2 || abs(y) <= 2;
    case 5: return d <= 3 || q == 0 || r == 0 || s == 0;
    case 6: return d > 1;
    case 7: return q != 0 || abs(r) <= 1;
    case 8: return abs(q) <= 1 || abs(r) <= 1 || abs(s) <= 1;
    case 9: return !(r < -1 && abs(q) <= 1);
    default: return true;
    }
}

/* Lower ranks get sand, chains and ice first, giving each level its pattern. */
static int terrain_rank(int lvl, int i)
{
    int q = hex_q(i), r = hex_r(i), s = -q - r, d = hex_distance(i, hex_center());
    switch (lvl) {
    case 1: return abs(d - 2) * 20 + abs(q + r) + q;
    case 2: return d * 12 + (q - r + 20) % 7;
    case 3: return (q == 0 || r == 0 || s == 0 ? 0 : 50) + d;
    case 4: return (q == 0 || s == 0 ? 0 : 40) + d;
    case 5: return abs(d - 2) * 20 + abs(q);
    case 6: return abs(d - 2) * 20 + abs(r);
    case 7: return (q == r || q == -r || r == 0 ? 0 : 40) + d;
    case 8: return abs(d - 3) * 20 + (q - r + 20) % 5;
    default: return d * 20 + (q - r + 20) % 6;
    }
}

/* --------------------------------------------------------------------- rules */

static uint32_t random_next(game *g)
{
    uint32_t x = g->rng;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    return g->rng = x ? x : 0x12345678;
}

static int randn(game *g, int n) { return (int)(random_next(g) % (unsigned)n); }
static void swap_tiles(game *g, int a, int b) { tile t = g->tiles[a]; g->tiles[a] = g->tiles[b]; g->tiles[b] = t; }
static bool locked(const game *g, int i) { return g->chain[i] || g->ice[i]; }

bool game_cell_active(const game *g, int cell) { return cell >= 0 && cell < CELLS && g->active[cell]; }

static bool equal(const game *g, int a, int b)
{
    return game_cell_active(g, a) && game_cell_active(g, b) && g->tiles[a].kind >= 0 && g->tiles[a].kind == g->tiles[b].kind;
}

static int ray_for_axis(int axis) { return axis == 0 ? ROW : axis == 1 ? COLUMN : DIAGONAL; }
static int axis_of_ray(int sp) { return sp == ROW ? 0 : sp == COLUMN ? 1 : 2; }

/* Flood fill of identical relics through shared hex edges. */
static int collect_group(const game *g, int start, int cells[CELLS])
{
    if (!game_cell_active(g, start) || g->tiles[start].kind < 0) return 0;
    unsigned char seen[CELLS] = {0};
    int n = 1, head = 0;
    cells[0] = start;
    seen[start] = 1;
    while (head < n) {
        int a = cells[head++];
        for (int d = 0; d < 6; d++) {
            int b = hex_neighbor(a, d);
            if (equal(g, start, b) && !seen[b]) seen[b] = 1, cells[n++] = b;
        }
    }
    return n;
}

static void mark_line(const game *g, match *m, int cell, int axis)
{
    if (game_cell_active(g, cell)) m->mask[cell] = 1;
    for (int sign = 0; sign < 2; sign++) {
        int d = axis + (sign ? 3 : 0);
        for (int c = hex_neighbor(cell, d); c >= 0; c = hex_neighbor(c, d))
            if (game_cell_active(g, c)) m->mask[c] = 1;
    }
}

static void mark_area(const game *g, match *m, int cell, int radius)
{
    for (int i = 0; i < CELLS; i++)
        if (game_cell_active(g, i) && hex_distance(cell, i) <= radius) m->mask[i] = 1;
}

static void mark_color(const game *g, match *m, int kind)
{
    for (int i = 0; i < CELLS; i++)
        if (game_cell_active(g, i) && g->tiles[i].kind == kind) m->mask[i] = 1;
}

void game_matches(const game *g, match *m, int preferred)
{
    memset(m, 0, sizeof *m);
    unsigned char seen[CELLS] = {0};
    for (int i = 0; i < CELLS; i++) {
        if (!game_cell_active(g, i) || g->tiles[i].kind < 0 || seen[i]) continue;
        int cells[CELLS], n = collect_group(g, i, cells), pick = -1, longest = 0, long_axis = 0;
        for (int k = 0; k < n; k++) seen[cells[k]] = 1;
        if (n < MATCH_MIN) continue;
        for (int k = 0; k < n; k++) {
            int a = cells[k];
            m->mask[a] = 1;
            m->hits++;
            if (!g->tiles[a].special && !locked(g, a) && (pick < 0 || a == preferred)) pick = a;
            for (int axis = 0; axis < 3; axis++) {
                if (equal(g, a, hex_neighbor(a, axis + 3))) continue;   /* count each run from its start */
                int run = 0;
                for (int c = a; c >= 0 && equal(g, a, c); c = hex_neighbor(c, axis)) run++;
                if (run > longest) longest = run, long_axis = axis;
            }
        }
        /* four is the base match; larger groups reward deliberate combinations */
        int sp = n >= 6 ? (longest >= 6 ? PRISM : BOMB) : n == 5 ? ray_for_axis(long_axis) : NORMAL;
        if (pick >= 0) m->make[pick] = sp;
    }
}

bool game_can_swap(const game *g, int a, int b)
{
    return game_cell_active(g, a) && game_cell_active(g, b) && hex_distance(a, b) == 1 && !locked(g, a) && !locked(g, b) &&
           g->tiles[a].kind >= 0 && g->tiles[b].kind >= 0;
}

bool game_swap(game *g, int a, int b, match *m)
{
    if (g->won || g->lost || !game_can_swap(g, a, b)) return false;
    swap_tiles(g, a, b);
    memset(m, 0, sizeof *m);
    int sa = g->tiles[a].special, sb = g->tiles[b].special;
    if (sa == PRISM || sb == PRISM) {
        int p = sa == PRISM ? a : b, o = p == a ? b : a;
        if (sa == PRISM && sb == PRISM) {
            for (int i = 0; i < CELLS; i++) m->mask[i] = game_cell_active(g, i);
        } else {
            int kind = g->tiles[o].kind;
            mark_color(g, m, kind);
            if (g->tiles[o].special)   /* prism + special: that colour turns special first */
                for (int i = 0; i < CELLS; i++)
                    if (g->tiles[i].kind == kind) g->tiles[i].special = g->tiles[o].special;
        }
        m->mask[p] = m->mask[o] = 1;
        g->tiles[p].special = NORMAL;
    } else if (sa && sb) {
        m->mask[a] = m->mask[b] = 1;
        if (sa == BOMB && sb == BOMB) mark_area(g, m, b, 2);
        else if (sa == BOMB || sb == BOMB) {
            for (int i = 0; i < CELLS; i++)
                if (hex_distance(b, i) <= 1)
                    for (int z = 0; z < 3; z++) mark_line(g, m, i, z);
        } else {
            for (int z = 0; z < 3; z++) mark_line(g, m, b, z);
        }
    } else {
        game_matches(g, m, b);
        if (!m->mask[a] && !m->mask[b]) {
            swap_tiles(g, a, b);
            memset(m, 0, sizeof *m);
            return false;
        }
    }
    m->hits = 0;
    for (int i = 0; i < CELLS; i++) m->hits += m->mask[i];
    if (!m->hits) {
        swap_tiles(g, a, b);
        return false;
    }
    g->moves--;
    g->combo = 0;
    return true;
}

int game_apply(game *g, match *m)
{
    int fired[CELLS] = {0}, thaw[CELLS] = {0};
    for (bool more = true; more;) {   /* specials hit by the wave fire, possibly hitting more specials */
        more = false;
        for (int i = 0; i < CELLS; i++) {
            if (!game_cell_active(g, i) || !m->mask[i] || m->make[i] || fired[i] || !g->tiles[i].special || locked(g, i)) continue;
            fired[i] = 1;
            more = true;
            int sp = g->tiles[i].special;
            if (sp == ROW || sp == COLUMN || sp == DIAGONAL) mark_line(g, m, i, axis_of_ray(sp));
            else if (sp == BOMB) mark_area(g, m, i, 1);
            else mark_color(g, m, g->tiles[i].kind);
        }
    }
    for (int i = 0; i < CELLS; i++)   /* matched flames thaw the ice around them */
        if (game_cell_active(g, i) && m->mask[i] && g->tiles[i].kind == RELIC_FLAME && !locked(g, i))
            for (int d = 0; d < 6; d++) {
                int j = hex_neighbor(i, d);
                if (game_cell_active(g, j) && g->ice[j] && !m->mask[j]) thaw[j] = 1;
            }
    int cleared = 0;
    g->last_gold = g->last_wood = g->last_stone = 0;
    g->combo++;
    for (int i = 0; i < CELLS; i++) {
        if (!game_cell_active(g, i)) continue;
        if (thaw[i]) g->ice[i]--, g->obstacles--;
        if (!m->mask[i]) continue;
        if (g->ice[i]) {
            g->ice[i]--, g->obstacles--, g->score += 20;
            continue;
        }
        if (g->chain[i]) {
            g->chain[i]--, g->obstacles--, g->score += 20;
            continue;
        }
        if (g->soil[i]) g->soil[i]--, g->dug++, g->score += 30;
        int k = g->tiles[i].kind;
        if (k < 0) continue;
        if (k == RELIC_IDOL) g->relics++, g->last_gold++;
        if (k == RELIC_LEAF) g->wood++, g->last_wood++;
        if (k == RELIC_CRYSTAL) g->stone++, g->last_stone++;
        g->score += 50 * g->combo;
        cleared++;
        if (m->make[i]) g->tiles[i].special = m->make[i];
        else g->tiles[i] = (tile){-1, NORMAL};
    }
    g->cleared += cleared;
    return cleared;
}

/* Gravity runs down each column (constant q) in segments separated by holes
 * and locked cells; new relics spawn at the top of each segment. */
void game_collapse(game *g, int from[CELLS])
{
    for (int i = 0; i < CELLS; i++) from[i] = i;
    for (int q = -HEX_RADIUS; q <= HEX_RADIUS; q++) {
        int lane[2 * HEX_RADIUS + 1], n = 0;
        for (int r = -HEX_RADIUS; r <= HEX_RADIUS; r++) {
            int i = hex_index(q, r);
            if (i >= 0) lane[n++] = i;
        }
        for (int bottom = n - 1; bottom >= 0;) {
            int i = lane[bottom];
            if (!game_cell_active(g, i) || locked(g, i)) {
                bottom--;
                continue;
            }
            int top = bottom;
            while (top > 0 && game_cell_active(g, lane[top - 1]) && !locked(g, lane[top - 1])) top--;
            int dst = bottom;
            for (int y = bottom; y >= top; y--)
                if (g->tiles[lane[y]].kind >= 0) {
                    g->tiles[lane[dst]] = g->tiles[lane[y]];
                    from[lane[dst]] = lane[y];
                    dst--;
                }
            for (int spawn = 1; dst >= top; dst--) {
                g->tiles[lane[dst]] = (tile){randn(g, COLORS), NORMAL};
                from[lane[dst]] = -spawn++;
            }
            bottom = top - 1;
        }
    }
}

bool game_hint(const game *g, int *a, int *b)
{
    for (int i = 0; i < CELLS; i++)
        for (int d = 0; d < 3; d++) {
            int j = hex_neighbor(i, d);
            if (!game_can_swap(g, i, j)) continue;
            game copy = *g;
            match m;
            if (game_swap(&copy, i, j, &m)) {
                if (a) *a = i;
                if (b) *b = j;
                return true;
            }
        }
    return false;
}

static bool fill_without_matches(game *g)
{
    int cells[CELLS];
    for (int i = 0; i < CELLS; i++)
        if (!locked(g, i)) g->tiles[i] = (tile){-1, NORMAL};
    for (int i = 0; i < CELLS; i++) {
        if (!game_cell_active(g, i) || locked(g, i)) continue;
        int choices[COLORS], n = 0;
        for (int k = 0; k < COLORS; k++) {
            g->tiles[i] = (tile){k, NORMAL};
            if (collect_group(g, i, cells) < MATCH_MIN) choices[n++] = k;
        }
        if (!n) return false;
        g->tiles[i] = (tile){choices[randn(g, n)], NORMAL};
    }
    return true;
}

void game_shuffle(game *g)
{
    /* never erase blockers or fill a hole merely to manufacture a move */
    for (int attempt = 0; attempt < 2000; attempt++)
        if (fill_without_matches(g)) {
            match m;
            game_matches(g, &m, -1);
            if (!m.hits && game_hint(g, 0, 0)) return;
        }
}

void game_start(game *g, int lvl, uint32_t seed)
{
    memset(g, 0, sizeof *g);
    g->level = clampi(lvl, 0, LEVELS - 1);
    g->rng = seed ? seed : 12345;
    const level *l = &levels[g->level];
    g->moves = l->moves;
    int order[CELLS], n = 0;
    for (int i = 0; i < CELLS; i++) {
        g->active[i] = shape_cell(g->level, i);
        g->tiles[i] = (tile){-1, NORMAL};
        if (g->active[i]) order[n++] = i;
    }
    game_shuffle(g);
    for (int i = 0; i < n; i++)
        for (int j = i + 1; j < n; j++)
            if (terrain_rank(g->level, order[j]) < terrain_rank(g->level, order[i])) {
                int t = order[i];
                order[i] = order[j];
                order[j] = t;
            }
    for (int i = 0; i < l->soil && i < n; i++) g->soil[order[i]] = 1;
    int taken[CELLS] = {0};
    for (int i = 0; i < l->chains && i < n; i++) {
        int cell = order[(i * 3 + 1) % n];
        g->chain[cell] = taken[cell] = 1;
    }
    for (int k = 0, count = 0; count < l->ice && k < n; k++) {
        int cell = order[(k + 4) % n];
        if (taken[cell] || hex_distance(cell, hex_center()) > 3) continue;
        g->ice[cell] = (g->level >= 6 && count % 3 == 0) ? 2 : 1;
        taken[cell] = 1;
        count++;
    }
    for (int i = 0; i < CELLS; i++) g->initial_obstacles += g->ice[i] + g->chain[i];
    g->obstacles = g->initial_obstacles;
    g->initial_soil = l->soil;
    g->tools[0] = g->tools[1] = g->tools[2] = 2;
    match m;
    game_matches(g, &m, -1);
    if (m.hits || !game_hint(g, 0, 0)) game_shuffle(g);
}

void game_check_end(game *g)
{
    const level *l = &levels[g->level];
    g->won = g->score >= l->score && g->relics >= l->relics && g->dug >= l->soil && g->obstacles == 0;
    g->lost = !g->won && g->moves <= 0;
    if (!g->won && !g->lost && !game_hint(g, 0, 0)) game_shuffle(g);
}

/* Tools: 0 pickaxe (one cell), 1 dynamite (radius 1), 2 sunburst (three axes). */
bool game_tool(game *g, int tool, int cell, match *m)
{
    if (tool < 0 || tool > 2 || g->tools[tool] <= 0 || g->won || g->lost || !game_cell_active(g, cell)) return false;
    memset(m, 0, sizeof *m);
    g->tools[tool]--;
    g->combo = 0;
    if (tool == 0) m->mask[cell] = 1;
    else if (tool == 1) mark_area(g, m, cell, 1);
    else
        for (int z = 0; z < 3; z++) mark_line(g, m, cell, z);
    for (int i = 0; i < CELLS; i++) m->hits += m->mask[i];
    return true;
}

/* How good a move is for a greedy player: score plus weighted goal progress. */
int game_evaluate_move(const game *g, int a, int b)
{
    game c = *g;
    match m;
    if (!game_swap(&c, a, b, &m)) return -1;
    game_apply(&c, &m);
    int goal = levels[g->level].relics;
    int relics = (c.relics < goal ? c.relics : goal) - (g->relics < goal ? g->relics : goal);
    return c.score - g->score + relics * 90 + (c.dug - g->dug) * 200 + (g->obstacles - c.obstacles) * 220;
}

/* ------------------------------------------------------------------- economy */

purse level_reward(const game *g)
{
    const building_def *w = &wonders[g->level];
    return (purse){{w->cost.v[GOLD] + g->relics + 20, w->cost.v[WOOD] + g->wood + 5, w->cost.v[STONE] + g->stone + 5, 3, 3}};
}

void progress_reward(progress *p, const game *g)
{
    if (!g->won || p->level != g->level) return;
    p->wallet = purse_add(p->wallet, level_reward(g));
    p->level++;
    p->seed = g->rng;
}
