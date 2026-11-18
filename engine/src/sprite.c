/* Pivot-aware drawing and time sampling of trimmed, authored atlas frames. */
#include "engine.h"
#include <math.h>
rect sprite_bounds(sprite_frame f, vec2 anchor, float scale)
{
    size2 size = sz2(f.source.size.w * scale, f.source.size.h * scale);
    return rect_anchor(anchor, size, f.pivot);
}
void sprite_draw(texture atlas, sprite_frame f, vec2 anchor, float scale, color tint)
{
    draw_image_part(atlas, f.source, sprite_bounds(f, anchor, scale), tint);
}
sprite_frame sprite_sample(const sprite_frame *frames, int count, float fps, double seconds)
{
    if (!frames || count <= 0) return (sprite_frame){0};
    double index = fps > 0 ? floor(fmax(0, seconds) * fps) : 0;
    return frames[(int)fmod(index, count)];
}
