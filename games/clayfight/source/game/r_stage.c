// Original arcade playfield tiles, maps, palette banks and floor strips.
#include "game/game.h"
stage_t stages[] = {
    {.name="THE COVE"}, {.name="THE INFERNO"}, {.name="THE HOLLOWS"},
    {.name="THE TOMB"}, {.name="THE CLIFF"}, {.name="THE STRIP"},
    {.name="THE RUINS"}, {.name="DINOSAUR GRAVEYARD"},
};
int numstages=sizeof stages/sizeof stages[0];
void R_PrepareStage(stage_t *st) {st->prepared=true;}
void R_DrawStage(const stage_t *st,int camx) {W_DrawArcadeStage((int)(st-stages),camx);}
