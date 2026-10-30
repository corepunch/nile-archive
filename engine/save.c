/* save.c — key=value save files with a single serialize function per game.
 *
 * The same function reads and writes: save_int(s, "coins", &g.coins) loads the
 * value when reading and stores it when writing, so fields can never drift
 * apart. Missing keys keep their defaults, which makes old saves forward
 * compatible. Native builds retain the original save directories; the web build uses
 * localStorage. */
#include "engine.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>

EM_JS(char *, web_storage_get, (const char *key), {
    var v = null;
    try { v = localStorage.getItem(UTF8ToString(key)); } catch (e) {}
    if (v === null) return 0;
    var n = lengthBytesUTF8(v) + 1, p = _malloc(n);
    stringToUTF8(v, p, n);
    return p;
});
EM_JS(int, web_storage_set, (const char *key, const char *value), {
    try { localStorage.setItem(UTF8ToString(key), UTF8ToString(value)); return 1; } catch (e) { return 0; }
});
#endif

struct save {
    bool reading;
    char *buf;
    size_t len, cap;
};

static struct { char slot[64]; char *text; } injected;

bool save_is_reading(const save *s) { return s->reading; }

const char *app_web_storage(const char *key)
{
#ifdef __EMSCRIPTEN__
    static char *last;
    free(last);
    return last = web_storage_get(key);
#else
    (void)key;
    return NULL;
#endif
}

static char *copy_text(const char *t)
{
    size_t n = strlen(t) + 1;
    return memcpy(malloc(n), t, n);
}

static void append(save *s, const char *text)
{
    size_t n = strlen(text);
    if (s->len + n + 1 > s->cap) {
        s->cap = (s->len + n + 1) * 2;
        s->buf = realloc(s->buf, s->cap);
    }
    memcpy(s->buf + s->len, text, n + 1);
    s->len += n;
}

/* Value text for key, or NULL. Keys are matched at line starts. */
static const char *lookup(const save *s, const char *key)
{
    size_t k = strlen(key);
    for (const char *line = s->buf; line && *line; line = strchr(line, '\n'), line = line ? line + 1 : NULL)
        if (!strncmp(line, key, k) && line[k] == '=') return line + k + 1;
    return NULL;
}

void save_int(save *s, const char *key, int *v)
{
    if (s->reading) {
        const char *t = lookup(s, key);
        if (t) *v = atoi(t);
    } else {
        append(s, fmt("%s=%d\n", key, *v));
    }
}

void save_double(save *s, const char *key, double *v)
{
    if (s->reading) {
        const char *t = lookup(s, key);
        if (t) *v = strtod(t, NULL);
    } else {
        append(s, fmt("%s=%.3f\n", key, *v));
    }
}

void save_float(save *s, const char *key, float *v)
{
    double d = *v;
    save_double(s, key, &d);
    *v = (float)d;
}

void save_ints(save *s, const char *key, int *v, int n)
{
    if (s->reading) {
        const char *t = lookup(s, key);
        for (int i = 0; t && i < n; i++) {
            char *end;
            long x = strtol(t, &end, 10);
            if (end == t) break;
            v[i] = (int)x;
            t = end;
        }
        return;
    }
    append(s, key);
    append(s, "=");
    for (int i = 0; i < n; i++) append(s, fmt(i ? " %d" : "%d", v[i]));
    append(s, "\n");
}

void save_vec2(save *s, const char *key, vec2 *v)
{
    if (s->reading) {
        const char *t = lookup(s, key);
        if (t) sscanf(t, "%f %f", &v->x, &v->y);
    } else {
        append(s, fmt("%s=%.1f %.1f\n", key, v->x, v->y));
    }
}

void save_inject(const char *slot, const char *text)
{
    free(injected.text);
    snprintf(injected.slot, sizeof injected.slot, "%s", slot);
    injected.text = text ? copy_text(text) : NULL;
}

static bool saves_disabled(void) { return app_arg("fresh") != NULL; }

#ifndef __EMSCRIPTEN__
static const char *file_for(const char *slot)
{
    static char path[1024];
    /* Isolate native test/preview saves without changing the user's HOME. */
    const char *override = getenv("SPRITE_SAVE_DIR");
    if (override && *override) {
        snprintf(path, sizeof path, "%s/%s.sav", override, slot);
        return path;
    }
    char dir[1024];
#if defined(__APPLE__)
    /* Keep existing progress, including sandboxed app containers. */
    const char *base = axSettingsDirectory();
#ifdef AX_PLATFORM_IOS
    snprintf(dir, sizeof dir, "%s/corepunch/%s", base, app_id());
#else
    snprintf(dir, sizeof dir, "%s/../corepunch/%s", base, app_id());
#endif
#else
    const char *base = getenv("XDG_DATA_HOME"), *home = getenv("HOME");
    if (base && *base) snprintf(dir, sizeof dir, "%s/corepunch/%s", base, app_id());
    else snprintf(dir, sizeof dir, "%s/.local/share/corepunch/%s", home ? home : ".", app_id());
#endif
    for (char *p = dir + 1; *p; p++) if (*p == '/') {
        *p = 0; axMkDir(dir); *p = '/';
    }
    axMkDir(dir);
    snprintf(path, sizeof path, "%s/%s.sav", dir, slot);
    return path;
}
#endif

static char *storage_read(const char *slot)
{
#ifdef __EMSCRIPTEN__
    return web_storage_get(fmt("%s/%s", app_id(), slot));
#else
    FILE *file = fopen(file_for(slot), "rb");
    if (!file) return NULL;
    if (fseek(file, 0, SEEK_END)) { fclose(file); return NULL; }
    long n = ftell(file);
    if (n < 0) { fclose(file); return NULL; }
    rewind(file);
    char *text = malloc((size_t)n + 1);
    if (!text) { fclose(file); return NULL; }
    size_t got = fread(text, 1, (size_t)n, file);
    bool ok = !ferror(file);
    fclose(file);
    if (!ok) { free(text); return NULL; }
    text[got] = 0;
    return text;
#endif
}

static bool storage_write(const char *slot, const char *text)
{
#ifdef __EMSCRIPTEN__
    return web_storage_set(fmt("%s/%s", app_id(), slot), text);
#else
    const char *path = file_for(slot);
    char tmp[1100];
    snprintf(tmp, sizeof tmp, "%s.tmp", path);
    FILE *f = fopen(tmp, "wb");
    if (!f) return false;
    bool ok = fwrite(text, 1, strlen(text), f) == strlen(text);
    ok = fclose(f) == 0 && ok;
    return ok && rename(tmp, path) == 0;
#endif
}

bool save_read(const char *slot, save_fn fn, void *user)
{
    if (saves_disabled()) return false;
    char *text = storage_read(slot);
    if (!text && injected.text && !strcmp(injected.slot, slot)) text = copy_text(injected.text);
    if (!text) return false;
    save s = {.reading = true, .buf = text, .len = strlen(text)};
    fn(&s, user);
    free(text);
    return true;
}

bool save_write(const char *slot, save_fn fn, void *user)
{
    if (saves_disabled()) return false;
    save s = {.reading = false};
    append(&s, "");
    fn(&s, user);
    bool ok = storage_write(slot, s.buf);
    free(s.buf);
    return ok;
}
