/* Game Center for every game. Games name boards and achievements; this file
 * decides when to talk to the platform. Reports are saved until confirmed,
 * so a game offline or before sign-in loses nothing, and every request is
 * asynchronous: the game polls gamecenter_entries each frame. Without a
 * gc_backend (macOS, the web, headless runs) the player's own results are kept
 * and shown as a one-row board, so a game's screens work everywhere. */
#include "gamecenter.h"

#include "render.h"

#include <stdio.h>
#include <string.h>

#define GC_RECORDS 64
#define GC_SLOTS 16
#define GC_PHOTOS 64
#define GC_SLOT "gamecenter"

struct gc_record {
    bool achievement;
    char name[48];
    double value, acked;   /* best known; best Game Center has confirmed */
    bool inflight;
};

struct gc_slot {
    char board[48];
    int scope, count;
    bool used, loaded, loading, wanted;   /* wanted: ask once signed in */
    int n;
    gamecenter_entry entries[GAMECENTER_ENTRY_MAX];
    double stamp;
};

struct gc_photo {
    char id[48];
    texture tex;       /* tex.tex == NULL while loading, or when the player has none */
    double stamp;
    int rev;
    bool used;
};

static struct gc_state {
    int state;
    char alias[48];
    bool native, demo;
    int nrecords;
    struct gc_record records[GC_RECORDS];
    struct gc_slot slots[GC_SLOTS];
    struct gc_photo photos[GC_PHOTOS];
    double clock;
#ifdef ENGINE_TEST
    bool fake_platform;
    int calls[6];
    double last_value;
    char last_name[48];
#endif
} GC;

/* ------------------------------------------------------------- platform */

#ifdef ENGINE_TEST
enum { T_START, T_SCORE, T_ACH, T_LOAD, T_SHOW, T_ACCESS };
static void gc_note(int what, const char *name, double value)
{
    GC.calls[what]++;
    GC.last_value = value;
    snprintf(GC.last_name, sizeof GC.last_name, "%s", name ? name : "");
}
static bool gc_backend(void) { return GC.fake_platform; }
static void p_start(void) { gc_note(T_START, "", 0); }
static void p_score(const char *b, double v) { gc_note(T_SCORE, b, v); }
static void p_ach(const char *a, double v) { gc_note(T_ACH, a, v); }
static void p_load(const char *b, int scope, int count) { (void)scope; gc_note(T_LOAD, b, count); }
static void p_show(int view, const char *b) { gc_note(T_SHOW, b, view); }
static void p_access(bool on) { gc_note(T_ACCESS, "", on); }
#else
static bool gc_backend(void)
{
    return gamecenter_platform_available() && !app_arg("headless") && !app_arg("shot") && !app_arg("smoke") && !app_arg("no-gamecenter");
}
#define p_start gamecenter_platform_start
#define p_score gamecenter_platform_report_score
#define p_ach gamecenter_platform_report_achievement
#define p_load gamecenter_platform_load
#define p_show gamecenter_platform_show
#define p_access gamecenter_platform_access_point
#endif

/* ----------------------------------------------------------- persistence */

static void gc_visit(save *s, void *user)
{
    (void)user;
    int n = GC.nrecords;
    save_int(s, "count", &n);
    if (n < 0 || n > GC_RECORDS) n = 0;
    for (int i = 0; i < n; i++) {
        struct gc_record *r = &GC.records[i];
        char text[sizeof r->name];
        int ach = r->achievement;
        snprintf(text, sizeof text, "%s", r->name);
        save_text(s, fmt("n%d", i), text, sizeof text);
        save_int(s, fmt("k%d", i), &ach);
        save_double(s, fmt("v%d", i), &r->value);
        save_double(s, fmt("a%d", i), &r->acked);
        if (save_is_reading(s)) {
            snprintf(r->name, sizeof r->name, "%s", text);
            r->achievement = ach != 0;
        }
    }
    if (save_is_reading(s)) GC.nrecords = n;
}

static void gc_persist(void) { save_write(GC_SLOT, gc_visit, NULL); }

static struct gc_record *gc_find(bool achievement, const char *name, bool create)
{
    for (int i = 0; i < GC.nrecords; i++)
        if (GC.records[i].achievement == achievement && !strcmp(GC.records[i].name, name)) return &GC.records[i];
    if (!create || GC.nrecords >= GC_RECORDS) return NULL;
    struct gc_record *r = &GC.records[GC.nrecords++];
    *r = (struct gc_record){.achievement = achievement};
    snprintf(r->name, sizeof r->name, "%s", name);
    return r;
}

/* Send whatever Game Center has not confirmed. Failures stay queued and
 * are tried again at the next sign-in, foreground or report. */
static void gc_flush(void)
{
    if (GC.state != GAMECENTER_SIGNED_IN || !GC.native) return;
    for (int i = 0; i < GC.nrecords; i++) {
        struct gc_record *r = &GC.records[i];
        if (r->inflight || r->value <= r->acked) continue;
        r->inflight = true;
        if (r->achievement) p_ach(r->name, r->value);
        else p_score(r->name, r->value);
    }
}

/* ---------------------------------------------------------------- boards */

static struct gc_slot *gc_slot_for(const char *board, int scope, bool create)
{
    struct gc_slot *victim = NULL;
    for (int i = 0; i < GC_SLOTS; i++) {
        struct gc_slot *s = &GC.slots[i];
        if (s->used && s->scope == scope && !strcmp(s->board, board)) return s;
        if (!victim || (victim->used && (!s->used || s->stamp < victim->stamp))) victim = s;
    }
    if (!create) return NULL;
    *victim = (struct gc_slot){.used = true, .scope = scope};
    snprintf(victim->board, sizeof victim->board, "%s", board);
    return victim;
}

/* ---------------------------------------------------------------- photos */

static struct gc_photo *gc_photo_find(const char *id, bool create)
{
    struct gc_photo *victim = NULL;
    for (int i = 0; i < GC_PHOTOS; i++) {
        struct gc_photo *p = &GC.photos[i];
        if (p->used && !strcmp(p->id, id)) return p;
        if (!victim || (victim->used && (!p->used || p->stamp < victim->stamp))) victim = p;
    }
    if (!create) return NULL;
    if (victim->used && victim->tex.tex) tex_free(victim->tex);
    *victim = (struct gc_photo){.used = true, .stamp = ++GC.clock};
    snprintf(victim->id, sizeof victim->id, "%s", id);
    return victim;
}

bool gamecenter_wants_photo(const char *id)
{
    if (!id || !*id || gc_photo_find(id, false)) return false;
    gc_photo_find(id, true);   /* in flight: nobody asks twice */
    return true;
}

void gamecenter_on_photo(const char *id, const unsigned char *rgba, int w, int h)
{
    struct gc_photo *p = id && *id ? gc_photo_find(id, true) : NULL;
    if (!p) return;
    p->stamp = ++GC.clock;
    if (rgba && w > 0 && h > 0 && render_ready()) {
        if (p->tex.tex) tex_free(p->tex);
        p->tex = tex_from_pixels(rgba, w, h);
    }
    p->rev++;
}

texture gamecenter_photo(const char *id)
{
    struct gc_photo *p = id && *id ? gc_photo_find(id, false) : NULL;
    return p && p->tex.tex ? p->tex : (texture){0};
}

/* A round placeholder portrait for --gamecenter-demo, tinted by the player's id. */
static void gc_demo_photo(const char *id, int index)
{
    if (!gamecenter_wants_photo(id)) return;
    enum { N = 64 };
    static unsigned char px[N * N * 4];
    static const unsigned char tints[][3] = {{214, 120, 78}, {96, 150, 196}, {128, 178, 104}, {196, 150, 70}, {150, 110, 170}, {84, 170, 160}, {200, 100, 120}};
    const unsigned char *c = tints[index % 7];
    for (int y = 0; y < N; y++)
        for (int x = 0; x < N; x++) {
            float dx = x + .5f - N / 2, dy = y + .5f - N / 2, d = sqrtf(dx * dx + dy * dy);
            float cover = fminf(1, fmaxf(0, N / 2 - d));
            float head = fminf(1, fmaxf(0, 11 - sqrtf(dx * dx + (dy + 8) * (dy + 8))));   /* a simple bust */
            float body = fminf(1, fmaxf(0, 22 - sqrtf(dx * dx * .5f + (dy - 26) * (dy - 26) * .8f)));
            float figure = fmaxf(head, body);
            unsigned char *o = &px[(y * N + x) * 4];
            for (int k = 0; k < 3; k++) o[k] = (unsigned char)(c[k] * (1 - .45f * figure) + 255 * .45f * figure);
            o[3] = (unsigned char)(255 * cover);
        }
    gamecenter_on_photo(id, px, N, N);
}

/* The player's own best as a one-row board; sample rivals under --gamecenter-demo. */
static void gc_fill_local(struct gc_slot *s)
{
    s->n = 0;
    double best = gamecenter_best(s->board);
    const char *me = *GC.alias ? GC.alias : "You";
    if (GC.demo) {
        static const char *const names[] = {"Nefertari", "Imhotep", "Khafre", "Hatshepsut", "Ankhesen", "Sobek", "Menkaure"};
        if (best <= 0) best = 1200;
        int ranks = GAMECENTER_ENTRY_MAX < 7 ? GAMECENTER_ENTRY_MAX : 7;
        for (int i = 0; i < ranks && s->n < s->count; i++) {
            gamecenter_entry *e = &s->entries[s->n++];
            e->rank = s->n;
            e->me = i == 3;
            e->score = floor(best * (1.5 - 0.15 * i));
            snprintf(e->name, sizeof e->name, "%s", e->me ? me : names[i]);
            snprintf(e->id, sizeof e->id, "demo-%s", e->me ? "me" : names[i]);
            gc_demo_photo(e->id, i);
        }
        if (s->scope == GAMECENTER_FRIENDS) { /* friends only: the first three and me */
            int keep = 0;
            for (int i = 0; i < s->n; i++)
                if (i < 2 || s->entries[i].me) s->entries[keep] = s->entries[i], s->entries[keep].rank = keep + 1, keep++;
            s->n = keep;
        }
    } else if (best > 0) {
        gamecenter_entry *e = &s->entries[s->n++];
        *e = (gamecenter_entry){.rank = 1, .score = best, .me = true};
        snprintf(e->name, sizeof e->name, "%s", me);
    }
    s->loaded = true;
    s->loading = s->wanted = false;
}

static void gc_request(struct gc_slot *s)
{
    if (!GC.native) { gc_fill_local(s); return; }
    if (GC.state == GAMECENTER_PENDING) { s->wanted = s->loading = true; return; }
    if (GC.state != GAMECENTER_SIGNED_IN) { gc_fill_local(s); return; }
    s->wanted = false;
    s->loading = true;
    p_load(s->board, s->scope, s->count);
}

/* ------------------------------------------------------------ public API */

int gamecenter_state(void) { return GC.state; }
const char *gamecenter_player(void) { return GC.alias; }

void gamecenter_submit(const char *board, double score)
{
    if (!board || !*board || !isfinite(score) || score <= 0) return;
    struct gc_record *r = gc_find(false, board, true);
    if (!r || score <= r->value) return;
    r->value = score;
    gc_persist();
    gc_flush();
    for (int i = 0; i < GC_SLOTS; i++)   /* a cached board is stale now */
        if (GC.slots[i].used && !strcmp(GC.slots[i].board, board) && GC.slots[i].loaded && !GC.native) gc_fill_local(&GC.slots[i]);
}

void gamecenter_unlock(const char *achievement, float percent)
{
    if (!achievement || !*achievement || !isfinite(percent) || percent <= 0) return;
    if (percent > 100) percent = 100;
    struct gc_record *r = gc_find(true, achievement, true);
    if (!r || percent <= r->value) return;
    r->value = percent;
    gc_persist();
    gc_flush();
}

float gamecenter_progress(const char *achievement)
{
    struct gc_record *r = achievement ? gc_find(true, achievement, false) : NULL;
    return r ? (float)r->value : 0;
}

double gamecenter_best(const char *board)
{
    struct gc_record *r = board ? gc_find(false, board, false) : NULL;
    return r ? r->value : 0;
}

void gamecenter_load(const char *board, int scope, int count)
{
    if (!board || !*board) return;
    if (scope != GAMECENTER_FRIENDS) scope = GAMECENTER_GLOBAL;
    struct gc_slot *s = gc_slot_for(board, scope, true);
    if (s->loading) return;
    s->count = count < 1 ? 10 : count > GAMECENTER_ENTRY_MAX ? GAMECENTER_ENTRY_MAX : count;
    s->stamp = ++GC.clock;
    gc_request(s);
}

bool gamecenter_loading(const char *board, int scope)
{
    struct gc_slot *s = board ? gc_slot_for(board, scope, false) : NULL;
    return s && s->loading;
}

int gamecenter_entries(const char *board, int scope, gamecenter_entry *out, int max)
{
    struct gc_slot *s = board ? gc_slot_for(board, scope, false) : NULL;
    if (!s || !s->loaded) return -1;
    int n = s->n < max ? s->n : max;
    if (out) {
        memcpy(out, s->entries, (size_t)n * sizeof *out);
        for (int i = 0; i < n; i++) {
            struct gc_photo *p = gc_photo_find(out[i].id, false);
            out[i].photo_rev = p && p->tex.tex ? p->rev : 0;
        }
    }
    return n;
}

void gamecenter_show(int view, const char *board)
{
    if (GC.native && GC.state == GAMECENTER_SIGNED_IN) p_show(view, board ? board : "");
}

void gamecenter_access_point(bool on)
{
    if (GC.native) p_access(on);
}

/* ------------------------------------------------------ backend callbacks */

void gamecenter_on_auth(bool signed_in, const char *alias)
{
    GC.state = signed_in ? GAMECENTER_SIGNED_IN : GAMECENTER_UNAVAILABLE;
    snprintf(GC.alias, sizeof GC.alias, "%s", signed_in && alias ? alias : "");
    if (signed_in) gc_flush();
    else for (int i = 0; i < GC.nrecords; i++) GC.records[i].inflight = false;
    for (int i = 0; i < GC_SLOTS; i++)
        if (GC.slots[i].used && GC.slots[i].wanted) gc_request(&GC.slots[i]);
}

void gamecenter_on_report(bool achievement, const char *name, double value, bool ok)
{
    struct gc_record *r = name ? gc_find(achievement, name, false) : NULL;
    if (!r) return;
    r->inflight = false;
    if (!ok) return;
    if (value > r->acked) r->acked = value;
    gc_persist();
    if (r->value > r->acked) gc_flush();   /* improved while the last report was in flight */
}

void gamecenter_on_entries(const char *board, int scope, const gamecenter_entry *entries, int n, bool ok)
{
    struct gc_slot *s = board ? gc_slot_for(board, scope, false) : NULL;
    if (!s) return;
    s->loading = false;
    if (!ok) { if (!s->loaded) gc_fill_local(s); return; }   /* keep the last good rows, else show our own */
    if (n < 0) n = 0;
    if (n > GAMECENTER_ENTRY_MAX) n = GAMECENTER_ENTRY_MAX;
    memcpy(s->entries, entries, (size_t)n * sizeof *entries);
    s->n = n;
    s->loaded = true;
}

/* --------------------------------------------------------- engine hooks */

void gamecenter_restart(void)
{
    for (int i = 0; i < GC_PHOTOS; i++)
        if (GC.photos[i].used && GC.photos[i].tex.tex) tex_free(GC.photos[i].tex);
    memset(&GC, 0, sizeof GC);
    GC.state = GAMECENTER_UNAVAILABLE;   /* until gamecenter_start finds a backend */
}

void gamecenter_start(void)
{
    gamecenter_restart();
    save_read(GC_SLOT, gc_visit, NULL);
    for (int i = 0; i < GC.nrecords; i++) GC.records[i].inflight = false;
    GC.native = gc_backend();
    GC.demo = app_arg("gamecenter-demo") != NULL;
    if (GC.native) {
        GC.state = GAMECENTER_PENDING;
        p_start();
    } else {
        GC.state = GC.demo ? GAMECENTER_SIGNED_IN : GAMECENTER_UNAVAILABLE;
        if (GC.demo) snprintf(GC.alias, sizeof GC.alias, "Player");
    }
}

void gamecenter_focus(bool active)
{
    if (active) gc_flush();
}

#ifdef ENGINE_TEST
void gamecenter_test_wipe(void)
{
    gamecenter_restart();
    gc_persist();
}
void gamecenter_test_platform(bool on)
{
    GC.fake_platform = on;
    GC.native = on;
    GC.state = on ? GAMECENTER_PENDING : GAMECENTER_UNAVAILABLE;
    if (on) p_start();
}
int gamecenter_test_calls(const char *what)
{
    static const char *const names[] = {"start", "score", "achievement", "load", "show", "access"};
    for (int i = 0; i < 6; i++)
        if (!strcmp(names[i], what)) return GC.calls[i];
    return -1;
}
double gamecenter_test_last_value(void) { return GC.last_value; }
const char *gamecenter_test_last_name(void) { return GC.last_name; }
#endif
