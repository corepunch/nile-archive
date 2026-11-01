#include "test.h"
#include "haptic.h"

TEST(haptic_frame_priority_and_cooldown)
{
    app_test_reset();
    haptic_play(HAPTIC_TICK, .3f);
    haptic_play(HAPTIC_COMBO, .8f);
    haptic_play(HAPTIC_MATCH, 1);
    haptic_flush();
    CHECK(haptic_test_count() == 1 && haptic_test_effect() == HAPTIC_COMBO);
    NEAR(haptic_test_strength(), .8f);
    app_test_advance(.02);
    haptic_play(HAPTIC_TICK, 1);
    haptic_flush();
    CHECK(haptic_test_count() == 1);
    haptic_play(HAPTIC_SUCCESS, 1);   /* completion can preempt a cascade */
    haptic_flush();
    CHECK(haptic_test_count() == 2 && haptic_test_effect() == HAPTIC_SUCCESS);
    app_test_advance(1);
    haptic_flush();
    CHECK(haptic_test_count() == 2);  /* suppressed events never come back */
    haptic_play(HAPTIC_TICK, .4f);
    haptic_flush();
    CHECK(haptic_test_count() == 3);
}

TEST(haptic_disable_focus_and_reset)
{
    app_test_reset();
    haptic_play(HAPTIC_PLACE, 1);
    haptic_enable(false);
    CHECK(!haptic_enabled());
    haptic_enable(true);
    haptic_flush();
    CHECK(haptic_test_count() == 0);
    haptic_play(HAPTIC_MATCH, 1);
    haptic_focus(false);
    haptic_play(HAPTIC_SUCCESS, 1);
    haptic_focus(true);
    haptic_flush();
    CHECK(haptic_test_count() == 0);
    haptic_play(HAPTIC_TICK, NAN);
    haptic_play(HAPTIC_TICK, 0);
    haptic_play(HAPTIC_TICK, -1);
    haptic_play(900, 1);
    haptic_flush();
    CHECK(haptic_test_count() == 0);
    haptic_play(HAPTIC_PLACE, 4);
    haptic_flush();
    NEAR(haptic_test_strength(), 1);
    haptic_enable(false);
    app_test_reset();
    CHECK(haptic_enabled() && haptic_test_count() == 0);
    haptic_play(HAPTIC_TICK, .3f);
    haptic_flush();
    CHECK(haptic_test_count() == 1);  /* no cooldown leaks across runs */
}
