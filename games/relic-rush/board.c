/* board.c — match-3 rules: matches, specials, chain reactions, gravity.
 *
 * Specials: four in a line makes a ROW/COL blaster (along the match), an L or
 * T makes a BOMB (3x3), five in a line makes an ORB that clears every gem of
 * the kind it is swapped with. Swapping two specials fires both; swapping an
 * orb with a special turns every gem of that kind into that special. */
#include "relic.h"

#include <string.h>

static const ivec2 dirs[4] = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};

bool board_inside(ivec2 p) { return p.x >= 0 && p.y >= 0 && p.x < BOARD_W && p.y < BOARD_H; }
piece board_at(const board *b, ivec2 p) { return board_inside(p) ? b->cell[p.y][p.x] : (piece){EMPTY, SP_NONE}; }
static piece *at(board *b, ivec2 p) { return &b->cell[p.y][p.x]; }
static bool gem(piece p) { return p.kind >= 0 && p.kind < KINDS; }
static bool same(piece a, piece c) { return gem(a) && a.kind == c.kind; }

static piece random_piece(board *b) { return (piece){(int8_t)rng_int(&b->rng, b->kinds), SP_NONE}; }

void board_swap(board *b, ivec2 a, ivec2 c)
{
    piece t = *at(b, a);
    *at(b, a) = *at(b, c);
    *at(b, c) = t;
}

/* Length of the run through p along d (both directions). */
static int run(const board *b, ivec2 p, ivec2 d)
{
    piece k = board_at(b, p);
    if (!gem(k)) return 0;
    int n = 1;
    for (ivec2 q = ivec2_add(p, d); same(board_at(b, q), k); q = ivec2_add(q, d)) n++;
    for (ivec2 q = ivec2_sub(p, d); same(board_at(b, q), k); q = ivec2_sub(q, d)) n++;
    return n;
}

static bool matches_at(const board *b, ivec2 p) { return run(b, p, dirs[0]) >= 3 || run(b, p, dirs[2]) >= 3; }

static bool any_match(const board *b)
{
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++)
            if (matches_at(b, iv2(x, y))) return true;
    return false;
}

bool board_swap_works(const board *b, ivec2 a, ivec2 c)
{
    if (!board_inside(a) || !board_inside(c) || ivec2_manhattan(a, c) != 1) return false;
    piece pa = board_at(b, a), pc = board_at(b, c);
    if (pa.kind == EMPTY || pc.kind == EMPTY) return false;
    if (pa.special == SP_ORB || pc.special == SP_ORB) return true;
    if (pa.special && pc.special) return true;
    board t = *b;
    board_swap(&t, a, c);
    return matches_at(&t, a) || matches_at(&t, c);
}

bool board_find_move(const board *b, ivec2 *a, ivec2 *c)
{
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++)
            for (int d = 0; d < 4; d += 2) {   /* right and down cover every pair */
                ivec2 p = iv2(x, y), q = ivec2_add(p, dirs[d]);
                if (board_swap_works(b, p, q)) {
                    if (a) *a = p;
                    if (c) *c = q;
                    return true;
                }
            }
    return false;
}

void board_init(board *b, uint32_t seed, int kinds)
{
    b->kinds = clampi(kinds, 3, KINDS);
    b->rng.s = seed ? seed : 1;
    do {
        for (int y = 0; y < BOARD_H; y++)
            for (int x = 0; x < BOARD_W; x++) b->cell[y][x] = (piece){EMPTY, SP_NONE};
        for (int y = 0; y < BOARD_H; y++)
            for (int x = 0; x < BOARD_W; x++)
                do b->cell[y][x] = random_piece(b);
                while (matches_at(b, iv2(x, y)));
    } while (!board_find_move(b, NULL, NULL));
}

void board_shuffle(board *b)
{
    for (int attempt = 0; attempt < 200; attempt++) {
        for (int i = BOARD_W * BOARD_H - 1; i > 0; i--) {
            int j = rng_int(&b->rng, i + 1);
            piece *p = &b->cell[i / BOARD_W][i % BOARD_W], *q = &b->cell[j / BOARD_W][j % BOARD_W];
            piece t = *p;
            *p = *q;
            *q = t;
        }
        if (!any_match(b) && board_find_move(b, NULL, NULL)) return;
    }
    board_init(b, rng_next(&b->rng), b->kinds);
}

/* ------------------------------------------------------------- resolving */

typedef struct {
    board *b;
    step *out;
    bool keep[BOARD_H][BOARD_W];   /* cells receiving a new special this step */
    ivec2 queue[BOARD_W * BOARD_H * 2];
    int head, tail;
} resolver;

static int most_common_kind(const board *b)
{
    int count[KINDS] = {0}, best = 0;
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++)
            if (gem(b->cell[y][x])) count[b->cell[y][x].kind]++;
    for (int k = 1; k < KINDS; k++)
        if (count[k] > count[best]) best = k;
    return best;
}

static void mark(resolver *r, ivec2 p)
{
    if (!board_inside(p) || r->out->cleared[p.y][p.x] || r->b->cell[p.y][p.x].kind == EMPTY) return;
    r->out->cleared[p.y][p.x] = true;
    if (r->tail < (int)(sizeof r->queue / sizeof r->queue[0])) r->queue[r->tail++] = p;
}

static void clear_kind(resolver *r, int kind)
{
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++)
            if (r->b->cell[y][x].kind == kind) mark(r, iv2(x, y));
}

static void fire(resolver *r, ivec2 p, special s)
{
    step *o = r->out;
    if (o->fired_count < MAX_FX) o->fired[o->fired_count].at = p, o->fired[o->fired_count++].type = s;
    switch (s) {
    case SP_ROW:
        for (int x = 0; x < BOARD_W; x++) mark(r, iv2(x, p.y));
        break;
    case SP_COL:
        for (int y = 0; y < BOARD_H; y++) mark(r, iv2(p.x, y));
        break;
    case SP_BOMB:
        for (int dy = -1; dy <= 1; dy++)
            for (int dx = -1; dx <= 1; dx++) mark(r, ivec2_add(p, iv2(dx, dy)));
        break;
    case SP_ORB: clear_kind(r, most_common_kind(r->b)); break;
    default: break;
    }
}

/* Clear everything in the queue, firing specials as they are hit. */
static void drain(resolver *r)
{
    while (r->head < r->tail) {
        ivec2 p = r->queue[r->head++];
        piece *c = at(r->b, p);
        if (r->keep[p.y][p.x]) continue;    /* new special: the old gem counts, the cell survives */
        if (c->special) fire(r, p, (special)c->special);
    }
}

static void create(resolver *r, ivec2 p, special s, int kind)
{
    if (r->keep[p.y][p.x]) return;
    r->keep[p.y][p.x] = true;
    r->out->created++;
    piece old = *at(r->b, p);
    if (old.special) fire(r, p, (special)old.special);   /* an old special under the new one still goes off */
    *at(r->b, p) = (piece){(int8_t)(s == SP_ORB ? ORB_KIND : kind), (uint8_t)s};
}

/* Where to put the special made by a run: the swapped cell if it is in it, else the middle. */
static ivec2 pivot(const ivec2 *swap, ivec2 start, ivec2 d, int len)
{
    for (int i = 0; swap && i < 2; i++)
        for (int k = 0; k < len; k++)
            if (ivec2_eq(swap[i], ivec2_add(start, iv2(d.x * k, d.y * k)))) return swap[i];
    return ivec2_add(start, iv2(d.x * (len / 2), d.y * (len / 2)));
}

static void mark_run_used(const board *b, bool used[BOARD_H][BOARD_W], ivec2 p, ivec2 d)
{
    piece k = board_at(b, p);
    used[p.y][p.x] = true;
    for (ivec2 q = ivec2_add(p, d); same(board_at(b, q), k); q = ivec2_add(q, d)) used[q.y][q.x] = true;
    for (ivec2 q = ivec2_sub(p, d); same(board_at(b, q), k); q = ivec2_sub(q, d)) used[q.y][q.x] = true;
}

static void find_matches(resolver *r, const ivec2 *swap)
{
    board *b = r->b;
    int hlen[BOARD_H][BOARD_W] = {{0}}, vlen[BOARD_H][BOARD_W] = {{0}};
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++) {
            hlen[y][x] = run(b, iv2(x, y), dirs[0]);
            vlen[y][x] = run(b, iv2(x, y), dirs[2]);
        }
    /* L and T shapes: a cell in both a horizontal and a vertical run */
    bool used[BOARD_H][BOARD_W] = {{false}};
    struct { ivec2 at; special s; int kind; } made[BOARD_W * BOARD_H];
    int made_n = 0;
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++)
            if (hlen[y][x] >= 3 && vlen[y][x] >= 3 && !used[y][x]) {
                special s = hlen[y][x] >= 5 || vlen[y][x] >= 5 ? SP_ORB : SP_BOMB;
                made[made_n].at = iv2(x, y), made[made_n].s = s, made[made_n++].kind = b->cell[y][x].kind;
                mark_run_used(b, used, iv2(x, y), dirs[0]);
                mark_run_used(b, used, iv2(x, y), dirs[2]);
            }
    /* straight runs: scan each run once from its first cell */
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++) {
            ivec2 p = iv2(x, y);
            for (int d = 0; d < 4; d += 2) {
                int len = d == 0 ? hlen[y][x] : vlen[y][x];
                if (len < 3 || same(board_at(b, ivec2_sub(p, dirs[d])), b->cell[y][x])) continue;
                bool fresh = true;
                for (int k = 0; k < len; k++) {
                    ivec2 q = ivec2_add(p, iv2(dirs[d].x * k, dirs[d].y * k));
                    fresh = fresh && !used[q.y][q.x];
                    mark(r, q);
                }
                if (fresh && len >= 4) {
                    made[made_n].at = pivot(swap, p, dirs[d], len);
                    made[made_n].s = len >= 5 ? SP_ORB : d == 0 ? SP_ROW : SP_COL;
                    made[made_n++].kind = b->cell[y][x].kind;
                }
            }
        }
    for (int i = 0; i < made_n; i++) create(r, made[i].at, made[i].s, made[i].kind);
}

static void swap_combo(resolver *r, const ivec2 *swap)
{
    board *b = r->b;
    bool first_orb = board_at(b, swap[0]).special == SP_ORB;
    ivec2 orb = first_orb ? swap[0] : swap[1];
    piece pa = board_at(b, orb), pc = board_at(b, first_orb ? swap[1] : swap[0]);
    if (pa.special == SP_ORB) {
        mark(r, orb);
        b->cell[orb.y][orb.x].special = SP_NONE;   /* the orb is spent on its target */
        if (pc.special == SP_ORB) {
            for (int y = 0; y < BOARD_H; y++)
                for (int x = 0; x < BOARD_W; x++) mark(r, iv2(x, y));
        } else {
            for (int y = 0; y < BOARD_H; y++)
                for (int x = 0; x < BOARD_W; x++)
                    if (b->cell[y][x].kind == pc.kind) {
                        if (pc.special && !b->cell[y][x].special)
                            b->cell[y][x].special = (uint8_t)(pc.special == SP_ROW && (x + y) % 2 ? SP_COL : pc.special);
                        mark(r, iv2(x, y));
                    }
        }
        if (r->out->fired_count < MAX_FX) r->out->fired[r->out->fired_count].at = orb, r->out->fired[r->out->fired_count++].type = SP_ORB;
    } else if (pa.special && pc.special) {
        mark(r, swap[0]);
        mark(r, swap[1]);
    }
}

bool board_resolve(board *b, const ivec2 *swap, step *out)
{
    memset(out, 0, sizeof *out);
    memcpy(out->before, b->cell, sizeof b->cell);
    resolver r = {.b = b, .out = out};
    if (swap) swap_combo(&r, swap);
    find_matches(&r, swap);
    drain(&r);
    for (int y = 0; y < BOARD_H; y++)
        for (int x = 0; x < BOARD_W; x++) {
            if (!out->cleared[y][x]) continue;
            piece was = out->before[y][x];
            if (gem(was)) out->by_kind[was.kind]++;
            out->count++;
            if (!r.keep[y][x]) b->cell[y][x] = (piece){EMPTY, SP_NONE};
        }
    return out->count > 0;
}

void board_collapse(board *b, int fall[BOARD_H][BOARD_W])
{
    memset(fall, 0, sizeof(int) * BOARD_W * BOARD_H);
    for (int x = 0; x < BOARD_W; x++) {
        int write = BOARD_H - 1;
        for (int y = BOARD_H - 1; y >= 0; y--) {
            if (b->cell[y][x].kind == EMPTY) continue;
            b->cell[write][x] = b->cell[y][x];
            fall[write][x] = write - y;
            write--;
        }
        int missing = write + 1;
        for (int y = write; y >= 0; y--) {
            b->cell[y][x] = random_piece(b);
            fall[y][x] = missing;
        }
    }
}
