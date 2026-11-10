/* Game Center policy: queueing, retry, caching and the local fallback.
 * The native backend is replaced by a recorder; part of build/test/engine. */
#include "gamecenter.h"
#include "test.h"
#include <string.h>

static void restart(bool backend)
{
    gamecenter_start();
    if (backend) gamecenter_test_platform(true);
}

static void fresh(bool backend)
{
    app_test_reset();
    gamecenter_test_wipe();
    restart(backend);
}

TEST(gamecenter_reports_wait_for_sign_in_then_retry)
{
    fresh(true);
    CHECK(gamecenter_state() == GAMECENTER_PENDING && gamecenter_test_calls("start") == 1);
    gamecenter_submit("stars", 40);
    gamecenter_unlock("first_island", 50);
    CHECK(gamecenter_test_calls("score") == 0 && gamecenter_test_calls("achievement") == 0);   /* queued, not lost */
    gamecenter_on_auth(true, "Nefertari");
    CHECK(gamecenter_state() == GAMECENTER_SIGNED_IN && !strcmp(gamecenter_player(), "Nefertari"));
    CHECK(gamecenter_test_calls("score") == 1 && gamecenter_test_calls("achievement") == 1);
    gamecenter_submit("stars", 30);   /* not a record */
    gamecenter_submit("stars", NAN);
    gamecenter_submit("", 99);
    CHECK(gamecenter_test_calls("score") == 1);
    gamecenter_on_report(false, "stars", 40, false);   /* the network dropped it */
    gamecenter_focus(true);
    CHECK(gamecenter_test_calls("score") == 2);   /* resent when the app comes back */
    gamecenter_on_report(false, "stars", 40, true);
    gamecenter_focus(true);
    CHECK(gamecenter_test_calls("score") == 2);   /* confirmed: never resent */
    gamecenter_submit("stars", 55);               /* better while nothing is in flight */
    CHECK(gamecenter_test_calls("score") == 3);
    NEAR(gamecenter_test_last_value(), 55);
}

TEST(gamecenter_improvement_during_flight_follows_confirmation)
{
    fresh(true);
    gamecenter_on_auth(true, "A");
    gamecenter_submit("stars", 10);
    gamecenter_submit("stars", 20);   /* the first is still in flight */
    CHECK(gamecenter_test_calls("score") == 1);
    gamecenter_on_report(false, "stars", 10, true);
    CHECK(gamecenter_test_calls("score") == 2);
    NEAR(gamecenter_test_last_value(), 20);
}

TEST(gamecenter_achievements_only_advance)
{
    fresh(false);
    gamecenter_unlock("a", 40);
    gamecenter_unlock("a", 10);
    gamecenter_unlock("a", 900);
    NEAR(gamecenter_progress("a"), 100);
    gamecenter_unlock("b", -5);
    gamecenter_unlock("b", NAN);
    NEAR(gamecenter_progress("b"), 0);
}

TEST(gamecenter_queue_survives_a_restart)
{
    fresh(true);
    gamecenter_submit("stars", 70);
    gamecenter_unlock("fort", 100);
    restart(true);   /* a new launch reads the saved queue */
    gamecenter_on_auth(true, "A");
    CHECK(gamecenter_test_calls("score") == 1 && gamecenter_test_calls("achievement") == 1);
    NEAR(gamecenter_best("stars"), 70);
}

TEST(gamecenter_load_waits_for_sign_in_and_keeps_good_rows)
{
    fresh(true);
    gamecenter_entry rows[GAMECENTER_ENTRY_MAX];
    gamecenter_load("stars", GAMECENTER_GLOBAL, 3);
    CHECK(gamecenter_loading("stars", GAMECENTER_GLOBAL) && gamecenter_entries("stars", GAMECENTER_GLOBAL, rows, 5) < 0);
    CHECK(gamecenter_test_calls("load") == 0);   /* asked once signed in */
    gamecenter_on_auth(true, "Me");
    CHECK(gamecenter_test_calls("load") == 1);
    gamecenter_load("stars", GAMECENTER_GLOBAL, 3);   /* ignored while running */
    CHECK(gamecenter_test_calls("load") == 1);
    gamecenter_entry in[2] = {{.rank = 1, .score = 90, .name = "Khafre"}, {.rank = 2, .score = 80, .name = "Me", .me = true}};
    gamecenter_on_entries("stars", GAMECENTER_GLOBAL, in, 2, true);
    CHECK(!gamecenter_loading("stars", GAMECENTER_GLOBAL));
    CHECK(gamecenter_entries("stars", GAMECENTER_GLOBAL, rows, 5) == 2 && rows[1].me && !strcmp(rows[0].name, "Khafre"));
    CHECK(gamecenter_entries("stars", GAMECENTER_FRIENDS, rows, 5) < 0);   /* scopes are separate */
    gamecenter_load("stars", GAMECENTER_GLOBAL, 3);
    gamecenter_on_entries("stars", GAMECENTER_GLOBAL, NULL, 0, false);
    CHECK(gamecenter_entries("stars", GAMECENTER_GLOBAL, rows, 1) == 1);   /* failed refresh: last rows stay, and max caps */
}

TEST(gamecenter_declined_sign_in_falls_back_to_local_board)
{
    fresh(true);
    gamecenter_entry rows[GAMECENTER_ENTRY_MAX];
    gamecenter_submit("stars", 12);
    gamecenter_on_auth(false, "");
    CHECK(gamecenter_state() == GAMECENTER_UNAVAILABLE);
    gamecenter_load("stars", GAMECENTER_GLOBAL, 10);
    CHECK(gamecenter_entries("stars", GAMECENTER_GLOBAL, rows, 5) == 1 && rows[0].me && rows[0].rank == 1);
    NEAR(rows[0].score, 12);
    gamecenter_show(GAMECENTER_DASHBOARD, NULL);
    CHECK(gamecenter_test_calls("show") == 0);   /* nothing to show without Game Center */
}

TEST(gamecenter_without_a_backend_keeps_results_locally)
{
    fresh(false);
    gamecenter_entry rows[GAMECENTER_ENTRY_MAX];
    CHECK(gamecenter_state() == GAMECENTER_UNAVAILABLE);
    gamecenter_load("stars", GAMECENTER_GLOBAL, 10);
    CHECK(gamecenter_entries("stars", GAMECENTER_GLOBAL, rows, 5) == 0);   /* loaded, empty */
    gamecenter_submit("stars", 7);
    CHECK(gamecenter_entries("stars", GAMECENTER_GLOBAL, rows, 5) == 1);   /* the cached board follows */
    NEAR(rows[0].score, 7);
}

TEST(gamecenter_cache_evicts_the_oldest_board)
{
    fresh(false);
    for (int i = 0; i < 20; i++) {
        char name[16];
        snprintf(name, sizeof name, "board%d", i);
        gamecenter_load(name, GAMECENTER_GLOBAL, 5);
    }
    CHECK(gamecenter_entries("board19", GAMECENTER_GLOBAL, NULL, 0) == 0);
    CHECK(gamecenter_entries("board0", GAMECENTER_GLOBAL, NULL, 0) < 0);
}

TEST(gamecenter_portraits_load_once_and_survive_failure)
{
    fresh(true);
    CHECK(gamecenter_wants_photo("p1") && !gamecenter_wants_photo("p1"));   /* in flight: nobody asks twice */
    gamecenter_on_photo("p1", NULL, 0, 0);                                  /* no portrait available */
    CHECK(!gamecenter_wants_photo("p1") && gamecenter_photo("p1").tex == NULL);
    CHECK(!gamecenter_wants_photo("") && !gamecenter_wants_photo(NULL));
    gamecenter_on_auth(true, "Me");
    gamecenter_load("stars", GAMECENTER_GLOBAL, 3);
    gamecenter_entry in[1] = {{.rank = 1, .score = 5, .name = "A", .id = "p1"}};
    gamecenter_on_entries("stars", GAMECENTER_GLOBAL, in, 1, true);
    gamecenter_entry rows[2];
    CHECK(gamecenter_entries("stars", GAMECENTER_GLOBAL, rows, 2) == 1 && !strcmp(rows[0].id, "p1") && rows[0].photo_rev == 0);
    for (int i = 0; i < 100; i++) {   /* more players than the cache holds */
        char id[16];
        snprintf(id, sizeof id, "q%d", i);
        CHECK(gamecenter_wants_photo(id));
    }
    CHECK(gamecenter_wants_photo("q0"));   /* the oldest was evicted, so it may load again */
}
