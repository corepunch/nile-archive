#ifndef ENGINE_ANIMATION_CLOCK_H
#define ENGINE_ANIMATION_CLOCK_H
#include <stdbool.h>
/* One platform timeline drives shared tweens, scrolling and frame painting. */
double animation_clock_seconds(void);
void animation_clock_pause(bool paused);
void animation_clock_reset(void);
#endif
