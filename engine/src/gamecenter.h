/* Private bridge: policy, queueing and caching live in gamecenter.c; the
 * native GameKit calls stay in the platform unity unit. Completions come back
 * through the gamecenter_on_* functions, on the thread that runs the game. */
#ifndef ENGINE_GAMECENTER_H
#define ENGINE_GAMECENTER_H
#include "engine.h"

/* Native side. Board and achievement names are the game's own; the backend
 * turns them into Game Center identifiers. */
bool gamecenter_platform_available(void);
void gamecenter_platform_start(void);                          /* -> gamecenter_on_auth */
void gamecenter_platform_report_score(const char *board, double score);          /* -> gamecenter_on_report */
void gamecenter_platform_report_achievement(const char *name, double percent);   /* -> gamecenter_on_report */
void gamecenter_platform_load(const char *board, int scope, int count);          /* -> gamecenter_on_entries */
void gamecenter_platform_show(int view, const char *board);
void gamecenter_platform_access_point(bool on);

/* Engine side, called by the backend. */
void gamecenter_on_auth(bool signed_in, const char *alias);
void gamecenter_on_report(bool achievement, const char *name, double value, bool ok);
bool gamecenter_wants_photo(const char *id);   /* true once per player: load their portrait now */
void gamecenter_on_photo(const char *id, const unsigned char *rgba, int w, int h);   /* NULL rgba: none available */
void gamecenter_on_entries(const char *board, int scope, const gamecenter_entry *entries, int n, bool ok);

/* Core hooks. */
void gamecenter_start(void);
void gamecenter_restart(void);
void gamecenter_focus(bool active);

#ifdef ENGINE_TEST
void gamecenter_test_wipe(void);          /* forget every saved report */
void gamecenter_test_platform(bool on);   /* pretend a backend exists; calls are recorded, not made */
int gamecenter_test_calls(const char *what);   /* "start" "score" "achievement" "load" "show" "access" */
double gamecenter_test_last_value(void);
const char *gamecenter_test_last_name(void);
#endif
#endif
