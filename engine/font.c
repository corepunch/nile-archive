/* font.c — TrueType text with outline, soft shadow and gradient fill.
 *
 * Glyphs are rasterised on demand with stb_truetype at the device pixel size
 * (so text stays crisp on Retina screens) into white-on-transparent atlas
 * pages. Colour is applied per vertex with render_geometry, which gives
 * gradients for free. Outlines and shadows come from stb_truetype's signed
 * distance fields: one cached "spread" layer per (outline, blur) pair. */
#include "render.h"

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define STB_TRUETYPE_IMPLEMENTATION
#include "third_party/stb_truetype.h"

#define FONT_PAGE_SIZE 1024
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
    struct render_texture *tex[MAX_PAGES];
    int pages;
    int shelf_x, shelf_y, shelf_h;
    glyph slots[CACHE_SLOTS];
    int used;
    bool full;                      /* atlas ran out: start over before the next glyph */
    render_vertex batch[BATCH];
    int batch_count;
    int batch_page;
} G = {.batch_page = -1};

/* ------------------------------------------------------------------ fonts */

font *font_load(const char *path)
{
    const char *full = app_path(path);
    FILE *file = fopen(full, "rb");
    if (!file) { fprintf(stderr, "font_load: cannot open %s\n", full); return NULL; }
    if (fseek(file, 0, SEEK_END)) { fclose(file); return NULL; }
    long size = ftell(file);
    rewind(file);
    if (size <= 0) { fclose(file); return NULL; }
    font *f = calloc(1, sizeof *f);
    if (!f) { fclose(file); return NULL; }
    f->data = malloc((size_t)size);
    bool ok = f->data && fread(f->data, 1, (size_t)size, file) == (size_t)size;
    fclose(file);
    if (!ok) { free(f->data); free(f); return NULL; }
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
    if (w > FONT_PAGE_SIZE || h > FONT_PAGE_SIZE) return false;
    if (G.pages == 0 || G.shelf_x + w > FONT_PAGE_SIZE) {
        G.shelf_x = 0;
        G.shelf_y += G.shelf_h;
        G.shelf_h = 0;
    }
    if (G.pages == 0 || G.shelf_y + h > FONT_PAGE_SIZE) {
        if (G.pages == MAX_PAGES) return false;
        if (!G.tex[G.pages]) {
            void *zero = calloc(FONT_PAGE_SIZE * FONT_PAGE_SIZE, 4);
            G.tex[G.pages] = render_texture_create(FONT_PAGE_SIZE, FONT_PAGE_SIZE, zero);
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
    render_texture_update(G.tex[page], x, y, pw, ph, rgba);
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
    if (G.batch_count && G.batch_page >= 0) render_geometry(G.tex[G.batch_page], G.batch, G.batch_count, NULL, 0);
    G.batch_count = 0;
}

static render_vertex gv(vec2 p, vec2 uv, color c) { return (render_vertex){{p.x, p.y}, {c.r, c.g, c.b, c.a}, {uv.x, uv.y}}; }

static void glyph_quad(const glyph *g, rect dst, color top, color bottom)
{
    if (g->page != G.batch_page || G.batch_count + 6 > BATCH) {
        batch_flush();
        G.batch_page = g->page;
    }
    float k = 1.0f / FONT_PAGE_SIZE;
    rect uv = rc(g->x * k, g->y * k, g->w * k, g->h * k);
    render_vertex a = gv(dst.pos, uv.pos, top), b = gv(rect_point(dst, v2(1, 0)), rect_point(uv, v2(1, 0)), top);
    render_vertex c = gv(rect_max(dst), rect_max(uv), bottom), d = gv(rect_point(dst, v2(0, 1)), rect_point(uv, v2(0, 1)), bottom);
    render_vertex *o = &G.batch[G.batch_count];
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

rect text_ink(text_style s, const char *utf8)
{
    if (!s.font || !utf8) return rect_make(v2(0, 0), sz2(0, 0));
    metrics m = metrics_for(s);
    float ascent = s.font->ascent * px_scale(s.font, m.px), pen = 0;
    vec2 lo = v2(1e9f, 1e9f), hi = v2(-1e9f, -1e9f);
    for (const char *p = utf8; *p;) {
        uint32_t cp;
        font *f;
        float adv = advance_px(m, &p, &cp, &f);
        float scale = px_scale(f, m.px);
        int x0, y0, x1, y1;
        stbtt_GetCodepointBitmapBox(&f->info, (int)cp, scale, scale, &x0, &y0, &x1, &y1);
        if (x1 > x0 && y1 > y0) {
            vec2 a = v2(roundf(pen) + x0, roundf(ascent) + y0), b = v2(roundf(pen) + x1, roundf(ascent) + y1);
            lo = vec2_min(lo, a);
            hi = vec2_max(hi, b);
        }
        pen += adv;
    }
    if (hi.x < lo.x) return rect_make(v2(0, 0), sz2(0, 0));
    return rect_corners(vec2_scale(lo, m.unit), vec2_scale(hi, m.unit));
}

rect text_in(text_style s, rect box, vec2 align, const char *utf8)
{
    rect ink = text_ink(s, utf8);
    if (ink.size.w <= 0 || ink.size.h <= 0) return rect_make(rect_point(box, align), sz2(0, 0));
    float k = minf(1, minf(box.size.w / ink.size.w, box.size.h / ink.size.h));
    if (k < 1) {
        s.size *= k;
        ink = text_ink(s, utf8);
    }
    rect target = rect_align(box, ink.size, align);
    text_draw(s, vec2_sub(target.pos, ink.pos), v2(0, 0), utf8);
    return target;
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

static int codepoints(const char *s, const char *end)
{
    int n = 0;
    for (; *s && s < end; s++) n += ((unsigned char)*s & 0xC0) != 0x80;
    return n;
}

/* Wraps (balanced), shrinks to fit, aligns and, when draw is set, draws the
 * first `visible` codepoints (-1 = all). Lines keep the place they will have
 * when complete, so revealed text never jumps. */
static rect box_layout(text_style s, rect box, vec2 align, const char *utf8, int visible, bool draw)
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
    if (n > 1) {   /* balance: the narrowest width that still needs only n lines */
        float lo = widest / n, hi = widest;
        for (int i = 0; i < 12 && hi - lo > 1; i++) {
            float mid = (lo + hi) * .5f, w;
            if (wrap(m, utf8, mid, starts, ends, &w) <= n) hi = mid;
            else lo = mid;
        }
        n = wrap(m, utf8, hi, starts, ends, &widest);
    }
    size2 total = sz2(widest * m.unit, n * line_h - (line_h - s.size));
    rect area = rect_align(box, total, align);
    char line[512];
    for (int i = 0; draw && i < n; i++) {
        size_t len = (size_t)(ends[i] - starts[i]);
        if (len >= sizeof line) len = sizeof line - 1;
        memcpy(line, starts[i], len);
        line[len] = 0;
        float full = text_measure(s, line).w;
        if (visible >= 0) {   /* cut the line at the first hidden codepoint */
            int shown = visible - codepoints(utf8, starts[i]);
            if (shown <= 0) break;
            int k = 0;
            char *p = line;
            for (; *p; p++)
                if (((unsigned char)*p & 0xC0) != 0x80 && k++ == shown) break;
            *p = 0;
        }
        float left = lerpf(area.pos.x, rect_max(area).x, align.x) - full * align.x;
        text_draw(s, v2(left, area.pos.y + i * line_h), v2(0, 0), line);
    }
    return area;
}

rect text_box(text_style s, rect box, vec2 align, const char *utf8) { return box_layout(s, box, align, utf8, -1, true); }

rect text_box_reveal(text_style s, rect box, vec2 align, const char *utf8, int visible)
{
    return box_layout(s, box, align, utf8, visible, true);
}

size2 text_box_size(text_style s, float width, const char *utf8)
{
    return box_layout(s, rc(0, 0, width, 1e6f), v2(0, 0), utf8, -1, false).size;
}

int text_length(const char *utf8) { return utf8 ? codepoints(utf8, utf8 + strlen(utf8)) : 0; }

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

void font_shutdown(void)
{
    for (int i = 0; i < MAX_PAGES; i++) render_texture_free(G.tex[i]);
    memset(&G, 0, sizeof G);
    G.batch_page = -1;
}
