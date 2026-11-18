/* Private bridge: gameplay requests live in haptic.c; native APIs stay in
 * the platform unity unit. No game or Lua binding depends on a native type. */
#ifndef ENGINE_HAPTIC_H
#define ENGINE_HAPTIC_H
#include "engine.h"

bool haptic_platform_available(void);
void haptic_platform_play(int effect, float strength);
void haptic_platform_stop(void);
void haptic_restart(void);
void haptic_focus(bool active);
void haptic_flush(void);

#ifdef ENGINE_TEST
int haptic_test_count(void);
int haptic_test_effect(void);
float haptic_test_strength(void);
#endif
#endif
