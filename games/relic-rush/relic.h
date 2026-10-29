/* relic.h — Relic Rush match-3 rules, shared by the game and the tests. */
#ifndef RELIC_H
#define RELIC_H

#include "engine.h"

enum { BOARD_W = 8, BOARD_H = 8, KINDS = 6, ORB_KIND = KINDS, EMPTY = -1, MAX_FX = 64 };

typedef enum { SP_NONE, SP_ROW, SP_COL, SP_BOMB, SP_ORB } special;

typedef struct { int8_t kind; uint8_t special; } piece;   /* kind EMPTY, 0..KINDS-1 or ORB_KIND */

typedef struct {
    piece cell[BOARD_H][BOARD_W];   /* [row][column], row 0 at the top */
    int kinds;                      /* gem kinds in play (difficulty) */
    rng rng;
} board;

/* What one resolution step did, for scoring, goals and effects. */
typedef struct {
    bool cleared[BOARD_H][BOARD_W];
    piece before[BOARD_H][BOARD_W];   /* the board before the step, to animate what vanished */
    int by_kind[KINDS];
    int count;
    int created;                      /* specials made from 4+, L/T matches */
    struct { ivec2 at; special type; } fired[MAX_FX];
    int fired_count;
} step;

bool board_inside(ivec2 p);
piece board_at(const board *b, ivec2 p);
void board_init(board *b, uint32_t seed, int kinds);
void board_swap(board *b, ivec2 a, ivec2 c);
/* True if swapping a and c (adjacent) would clear something. */
bool board_swap_works(const board *b, ivec2 a, ivec2 c);
/* Clear matches (and swap combos when `swap` is given, as {a, c}); places new specials. */
bool board_resolve(board *b, const ivec2 *swap, step *out);
/* Gravity and refill; fall[row][col] = rows each piece dropped. */
void board_collapse(board *b, int fall[BOARD_H][BOARD_W]);
bool board_find_move(const board *b, ivec2 *a, ivec2 *c);
void board_shuffle(board *b);

#endif
