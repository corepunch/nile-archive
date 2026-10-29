/* font.c — TrueType text with outline, soft shadow and gradient fill.
 *
 * Glyphs are rasterised on demand with stb_truetype at the device pixel size
 * (so text stays crisp on Retina screens) into white-on-transparent atlas
 * pages. Colour is applied per vertex with SDL_RenderGeometry, which gives
 * gradients for free. Outlines and shadows come from stb_truetype's signed
 * distance fields: one cached "spread" layer per (outline, blur) pair. */
#include "engine.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define STB_TRUETYPE_IMPLEMENTATION
#include "third_party/stb_truetype.h"

#define PAGE_SIZE 1024
#define MAX_PAGES 8
#define CACHE_SLOTS 8192
#define BATCH 1536

struct font {
    stbtt_fontinfo info;
    unsigned char *data;
    font *fallback;
    int ascent, descent, line_gap;
};

typedef struct {
    font *font;
    uint32_t cp;
    uint16_t px, spread, blur;      /* spread/blur in 1/4 px; spread 0xFFFF = fill layer */
    bool used;
    uint8_t page;
    int16_t x, y, w, h;             /* in page */
    int16_t ox, oy;                 /* offset from pen position on the baseline, px */
} glyph;

static struct {
    SDL_Texture *tex[MAX_PAGES];
    int pages;
    int shelf_x, shelf_y, shelf_h;
    glyph slots[CACHE_SLOTS];
    int used;
    bool full;                      /* atlas ran out: start over before the next glyph */
    SDL_Vertex batch[BATCH];
    int batch_count;
    int batch_page;
} G = {.batch_page = -1};

/* ------------------------------------------------------------------ fonts */

font *font_load(const char *path)
{
    const char *full = app_path(path);
    SDL_RWops *rw = SDL_RWFromFile(full, "rb");
    if (!rw) {
        fprintf(stderr, "font_load: %s: %s\n", full, SDL_GetError());
        return NULL;
    }
    Sint64 size = SDL_RWsize(rw);
    font *f = calloc(1, sizeof *f);
    f->data = malloc((size_t)size);
    SDL_RWread(rw, f->data, 1, (size_t)size);
    SDL_RWclose(rw);
    if (!stbtt_InitFont(&f->info, f->data, stbtt_GetFontOffsetForIndex(f->data, 0))) {
        fprintf(stderr, "font_load: %s: not a TrueType font\n", full);
        free(f->data);
        free(f);
        return NULL;
    }
    stbtt_GetFontVMetrics(&f->info, &f->ascent, &f->descent, &f->line_gap);
    return f;
}

void font_set_fallback(font *f, font *fallback)
{
    if (f) f->fallback = fallback;
}

static uint32_t utf8_next(const char **s)
{
    const unsigned char *p = (const unsigned char *)*s;
    uint32_t c = *p++;
    int extra = c >= 0xF0 ? 3 : c >= 0xE0 ? 2 : c >= 0xC0 ? 1 : 0;
    if (extra) c &= 0x3F >> extra;
    while (extra-- > 0 && (*p & 0xC0) == 0x80) c = c << 6 | (*p++ & 0x3F);
    *s = (const char *)p;
    return c;
}

static font *font_for(font *f, uint32_t cp)
{
    for (font *it = f; it; it = it->fallback)
        if (stbtt_FindGlyphIndex(&it->info, (int)cp)) return it;
    return f;
}

static float px_scale(font *f, int px) { return stbtt_ScaleForPixelHeight(&f->info, (float)px); }

/* ------------------------------------------------------------ glyph cache */

static void cache_reset(void)
{
    memset(G.slots, 0, sizeof G.slots);
    G.used = 0;
    G.shelf_x = G.shelf_y = G.shelf_h = 0;
    G.pages = G.pages ? 1 : 0;
}

static bool pack(int w, int h, int *page, int *x, int *y)
{
    if (w > PAGE_SIZE || h > PAGE_SIZE) return false;
    if (G.pages == 0 || G.shelf_x + w > PAGE_SIZE) {
        G.shelf_x = 0;
        G.shelf_y += G.shelf_h;
        G.shelf_h = 0;
    }
    if (G.pages == 0 || G.shelf_y + h > PAGE_SIZE) {
        if (G.pages == MAX_PAGES) return false;
        if (!G.tex[G.pages]) {
            G.tex[G.pages] = SDL_CreateTexture(app_renderer(), SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STATIC, PAGE_SIZE, PAGE_SIZE);
            SDL_SetTextureBlendMode(G.tex[G.pages], SDL_BLENDMODE_BLEND);
            void *zero = calloc(PAGE_SIZE * PAGE_SIZE, 4);
            SDL_UpdateTexture(G.tex[G.pages], NULL, zero, PAGE_SIZE * 4);
            free(zero);
        }
        G.pages++;
        G.shelf_x = G.shelf_y = G.shelf_h = 0;
    }
    *page = G.pages - 1;
    *x = G.shelf_x;
    *y = G.shelf_y;
    G.shelf_x += w;
    if (h > G.shelf_h) G.shelf_h = h;
    return true;
}

/* Upload an 8-bit coverage bitmap as white RGBA with a 1px transparent border. */
static bool upload(glyph *g, const unsigned char *alpha, int w, int h)
{
    int pw = w + 2, ph = h + 2, page, x, y;
    if (!pack(pw, ph, &page, &x, &y)) {
        G.full = true;
        return false;
    }
    uint32_t *rgba = calloc((size_t)pw * ph, 4);
    for (int j = 0; j < h; j++)
        for (int i = 0; i < w; i++) rgba[(j + 1) * pw + i + 1] = 0x00FFFFFFu | (uint32_t)alpha[j * w + i] << 24;
    SDL_Rect r = {x, y, pw, ph};
    SDL_UpdateTexture(G.tex[page], &r, rgba, pw * 4);
    free(rgba);
    g->page = (uint8_t)page;
    g->x = (int16_t)(x + 1);
    g->y = (int16_t)(y + 1);
    g->w = (int16_t)w;
    g->h = (int16_t)h;
    return true;
}

static void rasterise(glyph *g)
{
    float scale = px_scale(g->font, g->px);
    int w = 0, h = 0, ox = 0, oy = 0;
    unsigned char *bmp = NULL;
    if (g->spread == 0xFFFF) {
        bmp = stbtt_GetCodepointBitmap(&g->font->info, scale, scale, (int)g->cp, &w, &h, &ox, &oy);
    } else {
        float r = g->spread / 4.0f, b = g->blur / 4.0f, soft = maxf(b, .5f);
        int pad = (int)ceilf(r + soft) + 2;
        float dist_scale = 120.0f / pad;
        bmp = stbtt_GetCodepointSDF(&g->font->info, scale, (int)g->cp, pad, 128, dist_scale, &w, &h, &ox, &oy);
        for (int i = 0; bmp && i < w * h; i++) {
            float d = (bmp[i] - 128.0f) / dist_scale;   /* signed distance in px, + inside */
            bmp[i] = (unsigned char)(255 * saturate((d + r + soft) / (2 * soft)));
        }
    }
    g->ox = (int16_t)ox;
    g->oy = (int16_t)oy;
    if (bmp && w > 0 && h > 0) upload(g, bmp, w, h);
    if (bmp) stbtt_FreeSDF(bmp, NULL);
}

static glyph *glyph_get(font *f, uint32_t cp, int px, int spread, int blur)
{
    if (G.full) {
        G.full = false;
        cache_reset();
    }
    uint32_t hsh = (uint32_t)(uintptr_t)f * 2654435761u ^ cp * 40503u ^ (uint32_t)px * 9176u ^ (uint32_t)spread * 31u ^ (uint32_t)blur * 7u;
    for (int probe = 0; probe < CACHE_SLOTS; probe++) {
        glyph *g = &G.slots[(hsh + probe) & (CACHE_SLOTS - 1)];
        if (g->used) {
            if (g->font == f && g->cp == cp && g->px == px && g->spread == spread && g->blur == blur) return g;
            continue;
        }
        if (G.used > CACHE_SLOTS * 3 / 4) {
            cache_reset();
            return glyph_get(f, cp, px, spread, blur);
        }
        *g = (glyph){.font = f, .cp = cp, .px = (uint16_t)px, .spread = (uint16_t)spread, .blur = (uint16_t)blur, .used = true};
        G.used++;
        rasterise(g);
        return g;
    }
    return NULL;
}

/* ------------------------------------------------------------------ layout */

typedef struct {
    text_style s;
    int px;          /* device pixel size */
    float unit;      /* logical units per device pixel */
} metrics;

static metrics metrics_for(text_style s)
{
    float ps = maxf(app_pixel_scale(), .25f);
    int px = clampi((int)lroundf(s.size * ps), 4, 400);
    return (metrics){s, px, 1 / ps};
}

static float advance_px(metrics m, const char **p, uint32_t *out_cp, font **out_font)
{
    uint32_t cp = utf8_next(p);
    font *f = font_for(m.s.font, cp);
    int adv, lsb;
    stbtt_GetCodepointHMetrics(&f->info, (int)cp, &adv, &lsb);
    float a = adv * px_scale(f, m.px);
    if (**p) {
        const char *q = *p;
        uint32_t next = utf8_next(&q);
        if (font_for(m.s.font, next) == f) a += stbtt_GetCodepointKernAdvance(&f->info, (int)cp, (int)next) * px_scale(f, m.px);
    }
    *out_cp = cp;
    *out_font = f;
    return a + m.s.tracking / m.unit;
}

static float width_px(metrics m, const char *s, const char *end)
{
    float w = 0;
    uint32_t cp;
    font *f;
    while (*s && (!end || s < end)) w += advance_px(m, &s, &cp, &f);
    return w;
}

size2 text_measure(text_style s, const char *utf8)
{
    if (!s.font || !utf8) return sz2(0, s.size);
    metrics m = metrics_for(s);
    return sz2(roundf(width_px(m, utf8, NULL)) * m.unit, s.size);
}

/* ----------------------------------------------------------------- drawing */

static void batch_flush(void)
{
    if (G.batch_count && G.batch_page >= 0) SDL_RenderGeometry(app_renderer(), G.tex[G.batch_page], G.batch, G.batch_count, NULL, 0);
    G.batch_count = 0;
}

static SDL_Vertex gv(vec2 p, vec2 uv, color c) { return (SDL_Vertex){{p.x, p.y}, {c.r, c.g, c.b, c.a}, {uv.x, uv.y}}; }

static void glyph_quad(const glyph *g, rect dst, color top, color bottom)
{
    if (g->page != G.batch_page || G.batch_count + 6 > BATCH) {
        batch_flush();
        G.batch_page = g->page;
    }
    float k = 1.0f / PAGE_SIZE;
    rect uv = rc(g->x * k, g->y * k, g->w * k, g->h * k);
    SDL_Vertex a = gv(dst.pos, uv.pos, top), b = gv(rect_point(dst, v2(1, 0)), rect_point(uv, v2(1, 0)), top);
    SDL_Vertex c = gv(rect_max(dst), rect_max(uv), bottom), d = gv(rect_point(dst, v2(0, 1)), rect_point(uv, v2(0, 1)), bottom);
    SDL_Vertex *o = &G.batch[G.batch_count];
    o[0] = a, o[1] = b, o[2] = c, o[3] = a, o[4] = c, o[5] = d;
    G.batch_count += 6;
}

/* One pass over the string for one layer (shadow, outline or fill). */
static void draw_layer(metrics m, vec2 origin_px, const char *s, int spread, int blur, color c0, color c1, float grad_top, float grad_h)
{
    float pen = 0;
    while (*s) {
        uint32_t cp;
        font *f;
        float adv = advance_px(m, &s, &cp, &f);
        glyph *g = glyph_get(f, cp, m.px, spread, blur);
        if (g && g->w > 0) {
            vec2 p = vec2_add(origin_px, v2(roundf(pen) + g->ox, (float)g->oy));
            rect dst = rect_make(vec2_scale(p, m.unit), sz2(g->w * m.unit, g->h * m.unit));
            color top = color_lerp(c0, c1, saturate((dst.pos.y - grad_top) / grad_h));
            color bottom = color_lerp(c0, c1, saturate((rect_max(dst).y - grad_top) / grad_h));
            glyph_quad(g, dst, top, bottom);
        }
        pen += adv;
    }
    batch_flush();
}

rect text_draw(text_style s, vec2 pos, vec2 pivot, const char *utf8)
{
    if (!s.font || !utf8 || s.fade >= 1) return rect_make(pos, sz2(0, s.size));
    metrics m = metrics_for(s);
    rect box = rect_anchor(pos, text_measure(s, utf8), pivot);
    float scale = px_scale(s.font, m.px);
    vec2 origin_px = vec2_round(v2(box.pos.x / m.unit, box.pos.y / m.unit + s.font->ascent * scale));
    float opacity = 1 - s.fade;
    color fill = s.fill.a || s.fill.r || s.fill.g || s.fill.b ? s.fill : WHITE;
    color fill2 = s.fill2.a ? s.fill2 : fill;
    float grad_top = box.pos.y + s.size * .12f, grad_h = s.size * .8f;
    int outline = (int)lroundf(s.outline_width / m.unit * 4);

    if (s.shadow.a) {
        vec2 off = vec2_round(vec2_scale(s.shadow_offset, 1 / m.unit));
        color c = color_alpha(s.shadow, opacity);
        draw_layer(m, vec2_add(origin_px, off), utf8, outline, (int)lroundf(s.shadow_blur / m.unit * 4), c, c, 0, 1);
    }
    if (s.outline.a && outline > 0) {
        color c = color_alpha(s.outline, opacity);
        draw_layer(m, origin_px, utf8, outline, 0, c, c, 0, 1);
    }
    draw_layer(m, origin_px, utf8, 0xFFFF, 0, color_alpha(fill, opacity), color_alpha(fill2, opacity), grad_top, grad_h);
    return box;
}

/* Greedy word wrap: returns the number of lines, line starts/ends in out arrays. */
#define MAX_LINES 32

static int wrap(metrics m, const char *s, float max_px, const char **starts, const char **ends, float *widest)
{
    int n = 0;
    *widest = 0;
    while (*s && n < MAX_LINES) {
        const char *line = s, *end = s, *p = s;
        float w_end = 0;
        while (*p && *p != '\n') {
            const char *word_end = p;
            while (*word_end && *word_end != ' ' && *word_end != '\n') word_end++;
            float w = width_px(m, line, word_end);
            if (w > max_px && end != line) break;
            end = word_end;
            w_end = w;
            p = word_end;
            while (*p == ' ') p++;
        }
        if (end == line) end = p;    /* empty line */
        starts[n] = line;
        ends[n] = end;
        n++;
        if (w_end > *widest) *widest = w_end;
        s = end;
        while (*s == ' ') s++;
        if (*s == '\n') s++;
    }
    return n;
}

rect text_box(text_style s, rect box, vec2 align, const char *utf8)
{
    if (!s.font || !utf8) return rect_make(box.pos, sz2(0, 0));
    const char *starts[MAX_LINES], *ends[MAX_LINES];
    float base = s.size, widest = 0, line_h = 0;
    int n = 0;
    metrics m;
    for (int attempt = 0; attempt < 8; attempt++) {
        s.size = base * powf(.93f, (float)attempt);
        m = metrics_for(s);
        n = wrap(m, utf8, box.size.w / m.unit, starts, ends, &widest);
        line_h = s.size * 1.22f;
        if (widest * m.unit <= box.size.w + .5f && n * line_h - (line_h - s.size) <= box.size.h + .5f) break;
    }
    size2 total = sz2(widest * m.unit, n * line_h - (line_h - s.size));
    rect area = rect_align(box, total, align);
    char line[512];
    for (int i = 0; i < n; i++) {
        size_t len = (size_t)(ends[i] - starts[i]);
        if (len >= sizeof line) len = sizeof line - 1;
        memcpy(line, starts[i], len);
        line[len] = 0;
        vec2 at = v2(lerpf(area.pos.x, rect_max(area).x, align.x), area.pos.y + i * line_h);
        text_draw(s, at, v2(align.x, 0), line);
    }
    return area;
}

rect text_fit(text_style s, rect box, vec2 align, const char *utf8)
{
    size2 m = text_measure(s, utf8);
    if (m.w > box.size.w && m.w > 0) s.size *= maxf(.5f, box.size.w / m.w);
    return text_draw(s, rect_point(box, align), align, utf8);
}

const char *fmt(const char *f, ...)
{
    static char buf[8][256];
    static int slot;
    char *out = buf[slot++ & 7];
    va_list ap;
    va_start(ap, f);
    vsnprintf(out, sizeof buf[0], f, ap);
    va_end(ap);
    return out;
}
