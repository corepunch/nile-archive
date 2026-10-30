#include "game/game.h"
#include <stdio.h>
#include <string.h>
static bool initialized, suspended;
int clay_start(int argc,char **argv) { initialized=D_InitGame(argc,argv)<0;return initialized; }
void clay_tick(void) {if(initialized && !suspended)D_RunTic();}
void clay_draw(void) {if(initialized)D_Display();}
const uint32_t *clay_pixels(void) {return screen;}
void clay_key(int key,int down) {event_t ev={down?ev_keydown:ev_keyup,key};D_PostEvent(&ev);}
void clay_focus(void) {D_ProcessEvents(NULL,0);G_ClearInput();}
void clay_suspend(int value) {suspended=value;clay_focus();}
void clay_stop(void) {I_Shutdown();}
int clay_state(void) {return gamestate;}
