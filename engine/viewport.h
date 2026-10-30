/* Shared fit used by drawing, native input and injected clicks. Insets and
 * bounds are in window points; letterboxing can already absorb an inset. */
#ifndef ENGINE_VIEWPORT_H
#define ENGINE_VIEWPORT_H
static inline rect app_fit_view(size2 logical, rect safe)
{
    float scale = size2_fit(logical, safe.size);
    size2 view = size2_scale(logical, scale);
    return rect_make(vec2_add(safe.pos, vec2_scale(vec2_sub(size2_vec(safe.size), size2_vec(view)), .5f)), view);
}
#endif
