// Clayfight framebuffer size, sprite adapters and original font mappings.
#include <ctype.h>
#include <math.h>
#include "game/resources.h"
pixel_t screen[SCREENWIDTH * SCREENHEIGHT];
static raster surface(void) { return (raster){screen, SCREENWIDTH, SCREENHEIGHT, PIXELS_PER_UNIT}; }
void V_Clear(pixel_t c) { raster_clear(surface(), c); }
void V_FillRect(int x,int y,int w,int h,pixel_t c) { raster_fill(surface(),x,y,w,h,c); }
pixel_t V_Lerp(pixel_t a,pixel_t b,float t) { return raster_lerp(a,b,t); }
void V_VGradient(int y,int h,pixel_t a,pixel_t b) { raster_gradient(surface(),y,h,a,b); }
void V_DrawPatchScaled(int x,int y,const patch_t *p,const palette_t *pal,int flags,float sx,float sy) {
    if (!p) return;
    indexed_sprite src={p->w,p->h,p->x,p->y,p->pixels,p->detail,PIXELS_PER_UNIT};
    raster_draw(surface(),x,y,src,pal?pal->colors:NULL,flags,sx,sy);
}
void V_DrawPatch(int x,int y,const patch_t *p,const palette_t *pal,int flags) { V_DrawPatchScaled(x,y,p,pal,flags,1,1); }

// --- text, using the two complete alphabets in S04FONTS.GRA ------------------

static gra_t *fonts;
static short smallmap[128], bigmap[128];

static void map_run(short *map, const char *chars, int first)
{
    for (int i = 0; chars[i]; i++)
        map[(byte)chars[i]] = (short)(first + i);
}

void V_Init(void)
{
    fonts = W_LoadGra("S04FONTS.GRA");
    for (int i = 0; i < 128; i++)
        smallmap[i] = bigmap[i] = -1;
    // small 6px font: ASCII, with placeholder glyphs at a few slots
    map_run(smallmap, "!\"#$%&'", 111);
    map_run(smallmap, "()*+,-./", 119);
    map_run(smallmap, "01", 127);
    map_run(smallmap, "23456789:", 130);
    map_run(smallmap, "<", 139);
    map_run(smallmap, "=>?@", 142);
    map_run(smallmap, "ABCDE", 146);
    map_run(smallmap, "FGHIJKLMNO", 152);
    map_run(smallmap, "PQRSTUVWXY", 163);
    map_run(smallmap, "Z", 174);
    // big gold 11px font
    map_run(bigmap, "BCDEFGHIJKLMNOPQRSTUVWXYZ", 181);
    map_run(bigmap, "123456789", 206);
    map_run(bigmap, "0", 215);
    map_run(bigmap, "!.?", 217);
    map_run(bigmap, "A", 230);
}

static const patch_t *glyph(font_t font, char ch)
{
    int c = toupper((byte)ch) & 127;
    int i = font == FONT_BIG ? bigmap[c] : smallmap[c];
    return i >= 0 ? W_Frame(fonts, i) : NULL;
}

int V_TextWidth(font_t font, const char *text)
{
    int w = 0;
    for (; *text; text++) {
        const patch_t *p = glyph(font, *text);
        w += p ? p->w + 1 : (font == FONT_BIG ? 8 : 4);
    }
    return w;
}

static void DrawText(font_t font, int x, int y, const char *text, const palette_t *pal, float sx, float sy)
{
    float pen = x;
    for (; *text; text++) {
        const patch_t *p = glyph(font, *text);
        if (!p) {
            pen += (font == FONT_BIG ? 8 : 4) * sx;
            continue;
        }
        V_DrawPatchScaled((int)lroundf(pen + p->x * sx), y + (int)lroundf(p->y * sy), p, pal, 0, sx, sy);
        pen += (p->w + 1) * sx;
    }
}

void V_DrawText(font_t font, int x, int y, const char *text)
{
    DrawText(font, x, y, text, &fonts->palettes[0], 1, 1);
}

void V_DrawTextColor(font_t font, int x, int y, const char *text, pixel_t color)
{
    V_DrawTextScaled(font, x, y, text, color, 1, 1);
}

void V_DrawTextScaled(font_t font, int x, int y, const char *text, pixel_t color, float sx, float sy)
{
    palette_t pal = fonts->palettes[0];
    for (int i = 1; i <= pal.count; i++) {
        pixel_t c = pal.colors[i];
        int light = MAX((c >> 16) & 255, MAX((c >> 8) & 255, c & 255));
        pal.colors[i] = W_RGB(((color >> 16) & 255) * light / 255,
                             ((color >> 8) & 255) * light / 255, (color & 255) * light / 255);
    }
    DrawText(font, x, y, text, &pal, sx, sy);
}

void V_DrawTextCentered(font_t font, int cx, int y, const char *text)
{
    V_DrawText(font, cx - V_TextWidth(font, text) / 2, y, text);
}
