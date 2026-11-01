/* Private triangle renderer. Platform owns the window, GL context and swap. */
#ifndef ENGINE_RENDER_H
#define ENGINE_RENDER_H
#include "engine.h"

typedef struct { vec2 position; color color; vec2 uv; } render_vertex;
void app_step(void);
void app_stop(void);
void sfx_shutdown(void);
void font_shutdown(void);
bool render_init(void);
void render_shutdown(void);
bool render_ready(void);
void render_begin(size2 pixels, size2 logical, rect viewport, color clear);
void render_geometry(struct render_texture *tex, const render_vertex *v, int n, const int *indices, int count);
struct render_texture *render_texture_create(int w, int h, const void *rgba);
void render_texture_update(struct render_texture *tex, int x, int y, int w, int h, const void *rgba);
void render_texture_free(struct render_texture *tex);
void render_texture_additive(struct render_texture *tex, bool on);
void render_additive(bool on);
void render_clip(const rect *r);   /* NULL: the logical screen, or the display while bleeding */
void render_bleed(bool on);
void render_backdrop(float radius, color dim);
void render_image(texture tex, rect src, rect dst, float angle, color tint);
bool render_read_pixels(void *rgba, int w, int h);
#endif
