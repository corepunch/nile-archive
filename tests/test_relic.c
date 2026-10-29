/* Relic Rush rules: hex grid, match-4 detection, specials, blockers, gravity,
 * tools, the campaign's boards and economy, and the island on the engine
 * city. Ported from the original tests/test_game.c. */
#include "relic.h"

#include <stdio.h>
#include <string.h>

static int fails, *count;

#define CHECK(cond)                                                                                 \
    do {                                                                                            \
        (*count)++;                                                                                 \
        if (!(cond)) fails++, fprintf(stderr, "%s:%d: CHECK(%s)\n", __FILE__, __LINE__, #cond);   \
    } while (0)

static void blank(game *g)
{
    memset(g, 0, sizeof *g);
    g->moves = 80;
    g->rng = 123;
    for (int i = 0; i < CELLS; i++) {
        g->active[i] = 1;
        g->tiles[i] = (tile){-1, NORMAL};
    }
}

/* A board with no group of four anywhere. */
static void pattern(game *g)
{
    blank(g);
    for (int i = 0; i < CELLS; i++) g->tiles[i].kind = (hex_q(i) + 2 * hex_r(i) + 12) % 6;
}

static bool resolve(game *g, match *m)
{
    for (int k = 0; k < 200; k++) {
        game_apply(g, m);
        int from[CELLS];
        game_collapse(g, from);
        game_matches(g, m, -1);
        if (!m->hits) {
            game_check_end(g);
            return true;
        }
    }
    return false;
}

static int line(game *g, int start, int axis, int n, int kind)
{
    int cell = start;
    for (int k = 0; k < n; k++) {
        g->tiles[cell] = (tile){kind, NORMAL};
        if (k < n - 1) cell = hex_neighbor(cell, axis);
    }
    return cell;
}

static void test_grid(void)
{
    int c = hex_center();
    CHECK(c == hex_index(0, 0));
    for (int i = 0; i < CELLS; i++) {
        CHECK(hex_index(hex_q(i), hex_r(i)) == i);
        int n = 0;
        for (int d = 0; d < 6; d++) {
            int j = hex_neighbor(i, d);
            if (j < 0) continue;
            n++;
            CHECK(hex_distance(i, j) == 1 && hex_neighbor(j, (d + 3) % 6) == i);
        }
        if (hex_distance(i, c) < 4) CHECK(n == 6);
    }
}

static void test_matching(void)
{
    game g;
    match m;
    int c = hex_center();
    for (int lvl = 0; lvl < LEVELS; lvl++)
        for (uint32_t seed = 1; seed <= 100; seed++) {
            game_start(&g, lvl, seed);
            game_matches(&g, &m, -1);
            CHECK(!m.hits && game_hint(&g, 0, 0));
            CHECK(g.initial_soil == levels[lvl].soil);
            int obstacles = 0;
            for (int i = 0; i < CELLS; i++) obstacles += g.ice[i] + g.chain[i];
            CHECK(g.obstacles == obstacles);
        }
    for (int axis = 0; axis < 3; axis++) {
        int start = hex_neighbor(hex_neighbor(c, axis + 3), axis + 3);
        blank(&g);
        line(&g, start, axis, 4, 2);
        game_matches(&g, &m, c);
        CHECK(m.hits == 4 && m.make[c] == NORMAL);
        blank(&g);
        line(&g, start, axis, 5, 2);
        game_matches(&g, &m, c);
        CHECK(m.hits == 5 && m.make[c] == (axis == 0 ? ROW : axis == 1 ? COLUMN : DIAGONAL));
        blank(&g);
        line(&g, hex_neighbor(start, axis + 3), axis, 6, 2);
        game_matches(&g, &m, c);
        CHECK(m.hits == 6 && m.make[c] == PRISM);
        pattern(&g);   /* a ray clears exactly its axis */
        g.tiles[c] = (tile){3, axis == 0 ? ROW : axis == 1 ? COLUMN : DIAGONAL};
        memset(&m, 0, sizeof m);
        m.mask[c] = 1;
        game_apply(&g, &m);
        for (int i = 0; i < CELLS; i++) {
            int q = hex_q(i), r = hex_r(i);
            bool on = axis == 0 ? r == 0 : axis == 1 ? q == 0 : q + r == 0;
            CHECK((g.tiles[i].kind < 0) == on);
        }
    }
    blank(&g);
    line(&g, hex_neighbor(c, 3), 0, 4, 0);
    line(&g, hex_neighbor(c, 4), 1, 4, 0);
    game_matches(&g, &m, c);
    CHECK(m.make[c] == BOMB);
    for (int d = 0; d < 6; d++) {   /* every rotation of a bent four counts; three never do */
        blank(&g);
        int a = hex_neighbor(c, d), b = hex_neighbor(c, (d + 1) % 6), e = hex_neighbor(a, d);
        g.tiles[c].kind = g.tiles[a].kind = g.tiles[b].kind = 0;
        game_matches(&g, &m, c);
        CHECK(m.hits == 0);
        g.tiles[e].kind = 0;
        game_matches(&g, &m, c);
        CHECK(m.hits == 4 && m.make[c] == NORMAL);
    }
    blank(&g);   /* two compact triangles make a four-cell diamond */
    g.tiles[c].kind = g.tiles[hex_index(1, 0)].kind = g.tiles[hex_index(0, 1)].kind = g.tiles[hex_index(1, 1)].kind = 2;
    game_matches(&g, &m, c);
    CHECK(m.hits == 4);
}

static void test_holes_and_shapes(void)
{
    game g;
    match m;
    int c = hex_center();
    blank(&g);   /* a missing cell splits a group, refuses swaps and tools, and stays empty */
    line(&g, hex_index(0, -2), 1, 5, 0);
    g.active[c] = 0;
    g.tiles[c].kind = -1;
    game_matches(&g, &m, c);
    CHECK(m.hits == 0 && !game_can_swap(&g, c, hex_neighbor(c, 1)) && !game_tool(&g, 0, c, &m));
    g.tiles[hex_index(0, -1)].kind = -1;
    tile below = g.tiles[hex_index(0, 1)];
    int from[CELLS];
    game_collapse(&g, from);
    CHECK(g.tiles[c].kind == -1 && !memcmp(&below, &g.tiles[hex_index(0, 1)], sizeof below));

    unsigned char shapes[LEVELS][CELLS];
    for (int lvl = 0; lvl < LEVELS; lvl++) {   /* ten unique connected masks, nothing in the voids */
        game_start(&g, lvl, 31);
        memcpy(shapes[lvl], g.active, CELLS);
        int n_active = 0, start = -1;
        for (int i = 0; i < CELLS; i++) {
            if (g.active[i]) n_active++, start = i;
            else CHECK(g.tiles[i].kind == -1 && !g.soil[i] && !g.ice[i] && !g.chain[i] && !game_tool(&g, 0, i, &m));
        }
        for (int earlier = 0; earlier < lvl; earlier++) CHECK(memcmp(shapes[lvl], shapes[earlier], CELLS));
        int queue[CELLS], head = 0, n = 1;
        unsigned char seen[CELLS] = {0};
        queue[0] = start;
        seen[start] = 1;
        while (head < n) {
            int i = queue[head++];
            for (int d = 0; d < 6; d++) {
                int j = hex_neighbor(i, d);
                if (j >= 0 && g.active[j] && !seen[j]) seen[j] = 1, queue[n++] = j;
            }
        }
        CHECK(n == n_active);
        game_collapse(&g, from);
        for (int i = 0; i < CELLS; i++) CHECK(g.active[i] ? g.tiles[i].kind >= 0 : g.tiles[i].kind == -1);
    }
}

static void test_moves_and_blockers(void)
{
    game g, before;
    match m;
    int c = hex_center(), a, b;
    game_start(&g, 0, 5);
    CHECK(game_hint(&g, &a, &b));
    before = g;
    CHECK(game_swap(&g, a, b, &m) && g.moves == before.moves - 1);
    CHECK(resolve(&g, &m) && g.score > 0);
    game_start(&g, 0, 7);
    before = g;
    CHECK(!game_swap(&g, 0, CELLS - 1, &m) && !memcmp(&before, &g, sizeof g) && !game_can_swap(&g, -1, c));

    pattern(&g);
    g.chain[c] = 1;
    CHECK(!game_can_swap(&g, c, hex_neighbor(c, 0)));
    g.chain[c] = 0;
    g.ice[c] = 2;
    g.obstacles = 2;
    g.tools[0] = 2;
    CHECK(game_tool(&g, 0, c, &m));
    game_apply(&g, &m);
    CHECK(g.ice[c] == 1 && g.obstacles == 1);
    CHECK(game_tool(&g, 0, c, &m));
    game_apply(&g, &m);
    CHECK(!g.ice[c]);

    pattern(&g);   /* a matched flame thaws one layer of ice on all six sides */
    g.tiles[c].kind = RELIC_FLAME;
    for (int d = 0; d < 6; d++) g.ice[hex_neighbor(c, d)] = 2;
    g.obstacles = 12;
    memset(&m, 0, sizeof m);
    m.mask[c] = 1;
    game_apply(&g, &m);
    for (int d = 0; d < 6; d++) CHECK(g.ice[hex_neighbor(c, d)] == 1);
    CHECK(g.obstacles == 6);

    pattern(&g);
    g.tools[1] = 1;
    CHECK(game_tool(&g, 1, c, &m) && m.hits == 7);
    pattern(&g);
    g.tools[2] = 1;
    CHECK(game_tool(&g, 2, c, &m) && m.hits == 25);

    pattern(&g);   /* prism + relic clears that colour */
    g.tiles[c].special = PRISM;
    b = hex_neighbor(c, 0);
    int colour = g.tiles[b].kind;
    CHECK(game_swap(&g, c, b, &m));
    game_apply(&g, &m);
    for (int i = 0; i < CELLS; i++) CHECK(g.tiles[i].kind != colour);

    pattern(&g);   /* gravity stops at a chained relic */
    g.chain[c] = 1;
    int above = hex_index(0, -2), top = hex_index(0, -4), under = hex_index(0, 1);
    g.tiles[above].kind = g.tiles[top].kind = -1;
    tile lock = g.tiles[c], lower = g.tiles[under];
    int from[CELLS];
    game_collapse(&g, from);
    CHECK(!memcmp(&lock, &g.tiles[c], sizeof lock) && !memcmp(&lower, &g.tiles[under], sizeof lower));
    for (int i = 0; i < CELLS; i++) CHECK(g.tiles[i].kind >= 0 && g.tiles[i].kind < COLORS);
}

static void test_island(void)
{
    static city c;
    game g;

    /* every win pays for the next wonder exactly once, and it fits somewhere */
    memset(&c, 0, sizeof c);
    island_setup(&c);
    progress p = {0};
    for (int i = 0; i < LEVELS; i++) {
        game_start(&g, i, i + 1);
        g.won = true;
        progress_reward(&p, &g);
        int gold = p.wallet.v[GOLD];
        progress_reward(&p, &g);
        CHECK(p.wallet.v[GOLD] == gold && p.level == i + 1);
        for (int z = 1; z < ISLAND_ZONES; z++) city_unlock(&c, z, &p.wallet);
        CHECK(island_place_next(&c, &p.wallet, p.level, 0) && c.count == i + 1);
        CHECK(!island_place_next(&c, &p.wallet, p.level, 0));
    }
    CHECK(p.wallet.v[STARS] == 30);

    /* shoreline, collisions, failed builds change nothing, moving is free */
    memset(&c, 0, sizeof c);
    island_setup(&c);
    c.open = 63;
    purse wallet = {{5000, 5000, 5000}};
    city_begin_place(&c, 0, v2(10, 10));
    CHECK(city_confirm(&c, &wallet, 0).result == CITY_BLOCKED && c.count == 0 && wallet.v[GOLD] == 5000);
    city_begin_place(&c, 0, v2(760, 2030));
    CHECK(city_confirm(&c, &wallet, 0).result == CITY_BUILT);
    city_begin_place(&c, 1, v2(760, 2030));
    CHECK(city_confirm(&c, &wallet, 0).result == CITY_BLOCKED);
    city_cancel(&c);
    int gold = wallet.v[GOLD];
    city_begin_move(&c, 0);
    c.ghost = v2(836, 2040);
    CHECK(city_confirm(&c, &wallet, 0).result == CITY_MOVED && wallet.v[GOLD] == gold);
    city_begin_move(&c, 0);
    c.ghost = v2(12, 12);
    CHECK(city_confirm(&c, &wallet, 0).result == CITY_BLOCKED);

    /* regions need stars (kept) and compasses (spent), and must touch open land */
    memset(&c, 0, sizeof c);
    island_setup(&c);
    wallet = (purse){{0}};
    CHECK(!city_unlock(&c, 1, &wallet) && !city_can_place(&c, v2(1330, 2100), 0, -1));
    wallet.v[STARS] = 6;
    CHECK(!city_unlock(&c, 1, &wallet));
    wallet.v[COMPASSES] = 2;
    CHECK(city_unlock(&c, 1, &wallet) && wallet.v[COMPASSES] == 0 && wallet.v[STARS] == 6);
    CHECK(!city_unlock(&c, 1, &wallet) && city_can_place(&c, v2(1330, 2100), 0, -1));
    CHECK(!island_zone_touches(5, 1));   /* the temple ridge is far from the harbour */
}

static void test_campaign(void)
{
    game g;
    match m;
    int total = 0;
    for (int lvl = 0; lvl < LEVELS; lvl++) {
        int wins = 0;
        for (uint32_t seed = 1; seed <= 30; seed++) {
            game_start(&g, lvl, seed);
            for (int turn = 0; turn < 100 && !g.won && !g.lost; turn++) {
                int best = -1, ba = -1, bb = -1;
                for (int i = 0; i < CELLS; i++)
                    for (int d = 0; d < 3; d++) {
                        int j = hex_neighbor(i, d), v = game_evaluate_move(&g, i, j);
                        if (v > best) best = v, ba = i, bb = j;
                    }
                if (ba < 0) {
                    game_shuffle(&g);
                    continue;
                }
                CHECK(game_swap(&g, ba, bb, &m));
                CHECK(resolve(&g, &m));
            }
            wins += g.won;
        }
        CHECK(wins >= 5);
        total += wins;
    }
    printf("relic rush: greedy bot won %d of 300 expeditions without tools\n", total);
}

int test_relic(int *checks)
{
    count = checks;
    test_grid();
    test_matching();
    test_holes_and_shapes();
    test_moves_and_blockers();
    test_island();
    test_campaign();
    return fails;
}
