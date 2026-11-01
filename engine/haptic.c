/* Semantic, frame-coalesced feedback. Rule solvers and rendering stay silent;
 * presentation events and committed city transactions request these effects. */
#include "haptic.h"

static struct haptic_state {
    bool disabled, suspended;
    int pending, last;
    float strength;
    double next;
#ifdef ENGINE_TEST
    int count, effect;
    float played_strength;
#endif
} H;

static int haptic_priority(int effect)
{
    switch (effect) {
    case HAPTIC_TICK: return 1;
    case HAPTIC_COLLECT: return 2;
    case HAPTIC_MATCH: return 3;
    case HAPTIC_COMBO: case HAPTIC_ERROR: return 4;
    case HAPTIC_PLACE: return 5;
    case HAPTIC_SUCCESS: return 6;
    default: return 0;
    }
}

bool haptic_available(void) { return haptic_platform_available(); }
bool haptic_enabled(void) { return !H.disabled; }

void haptic_enable(bool on)
{
    H.disabled = !on;
    if (!on) { H.pending = 0; haptic_platform_stop(); }
}

void haptic_focus(bool active)
{
    H.suspended = !active;
    if (!active) { H.pending = 0; haptic_platform_stop(); }
}

void haptic_restart(void)
{
    haptic_platform_stop();
    H = (struct haptic_state){0};
}

void haptic_play(int effect, float strength)
{
    if (H.disabled || H.suspended || !haptic_priority(effect) || !isfinite(strength) || strength <= 0) return;
    strength = saturate(strength);
    int priority = haptic_priority(effect), pending = haptic_priority(H.pending);
    if (priority > pending || (effect == H.pending && strength > H.strength)) {
        H.pending = effect;
        H.strength = strength;
    }
}

void haptic_flush(void)
{
    int effect = H.pending;
    H.pending = 0;   /* drop suppressed requests; never replay a stale event */
    if (!effect || H.disabled || H.suspended) return;
    double now = app_time();
    if (now < H.next && haptic_priority(effect) <= haptic_priority(H.last)) return;
    H.last = effect;
    H.next = now + (effect == HAPTIC_TICK ? .075 : effect == HAPTIC_SUCCESS ? .24 : .10);
#ifdef ENGINE_TEST
    H.count++;
    H.effect = effect;
    H.played_strength = H.strength;
#else
    if (!app_arg("headless") && !app_arg("shot") && !app_arg("smoke") && !app_arg("no-haptics"))
        haptic_platform_play(effect, H.strength);
#endif
}

#ifdef ENGINE_TEST
int haptic_test_count(void) { return H.count; }
int haptic_test_effect(void) { return H.effect; }
float haptic_test_strength(void) { return H.played_strength; }
#endif
