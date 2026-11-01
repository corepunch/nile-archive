/* OpenGL 3.2 / ES 3: one shader, streamed triangles, RGBA textures. */
#include "render.h"
#include <stddef.h>
#include <string.h>
#include <stdio.h>
#if defined(__APPLE__)
#include <TargetConditionals.h>
#if TARGET_OS_IPHONE
#include <OpenGLES/ES3/gl.h>
#else
#define GL_SILENCE_DEPRECATION
#include <OpenGL/gl3.h>
#endif
#elif defined(__EMSCRIPTEN__)
#include <GLES3/gl3.h>
#else
#define GL_GLEXT_PROTOTYPES
#include <GL/gl.h>
#include <GL/glext.h>
#endif

struct render_texture {
    GLuint id;
    bool additive;
#ifdef ENGINE_TEST
    struct render_texture *prev, *next;
#endif
};
static struct {
    GLuint program, vao, vertices, indices, white;
    GLint screen, origin, stripes, stripe_rect, stripe_color;
    size2 pixels, logical;
    float scale;
    vec2 offset;
    bool additive, bleed;
    GLuint blur_program, blur_texture[4], blur_fbo[4];
    int blur_w, blur_h;
    bool blur_failed;
} R;

static GLuint render_shader(GLenum type, const char *body)
{
#if defined(__EMSCRIPTEN__) || (defined(__APPLE__) && TARGET_OS_IPHONE)
    const char *version = "#version 300 es\nprecision highp float;\n";
#else
    const char *version = "#version 150\n";
#endif
    const char *parts[] = {version, body};
    GLuint shader = glCreateShader(type);
    glShaderSource(shader, 2, parts, NULL);
    glCompileShader(shader);
    GLint ok;
    glGetShaderiv(shader, GL_COMPILE_STATUS, &ok);
    if (ok) return shader;
    char error[2048];
    glGetShaderInfoLog(shader, sizeof error, NULL, error);
    fprintf(stderr, "renderer shader: %s\n", error);
    glDeleteShader(shader);
    return 0;
}

#ifdef ENGINE_TEST
/* Every test shares this process, so a test that ends frees all its textures. */
static struct render_texture *live_textures;

static void texture_track(struct render_texture *t)
{
    t->next = live_textures;
    if (live_textures) live_textures->prev = t;
    live_textures = t;
}

static void texture_forget(struct render_texture *t)
{
    if (t->prev) t->prev->next = t->next;
    else if (live_textures == t) live_textures = t->next;
    if (t->next) t->next->prev = t->prev;
    t->prev = t->next = NULL;
}
#else
#define texture_track(t) ((void)0)
#define texture_forget(t) ((void)0)
#endif

bool render_init(void)
{
    GLuint vs = render_shader(GL_VERTEX_SHADER,
        "in vec2 position; in vec4 color; in vec2 uv; uniform vec2 screen, origin;\n"
        "out vec4 tint; out vec2 texcoord, point;\n"
        "void main(){gl_Position=vec4((position+origin)/screen*vec2(2,-2)+vec2(-1,1),0,1);tint=color;texcoord=uv;point=position;}\n");
    GLuint fs = render_shader(GL_FRAGMENT_SHADER,
        "in vec4 tint; in vec2 texcoord, point; uniform sampler2D image; out vec4 pixel;\n"
        "uniform vec4 stripes, stripe_rect, stripe_color;\n"
        "void main(){vec4 base=texture(image,texcoord);"
        "if(stripes.z>0.){vec2 q=(point-stripe_rect.xy)/stripe_rect.zw-.5;"
        "float phase=dot(q,stripes.xy)*stripes.z;float aa=max(fwidth(phase),.001);"
        "float band=1.-smoothstep(stripes.w*.5-aa,stripes.w*.5+aa,abs(fract(phase+.5)-.5));"
        "float shade=.65+.35*dot(base.rgb,vec3(.2126,.7152,.0722));"
        "base.rgb=mix(base.rgb,stripe_color.rgb*shade,band*stripe_color.a);}"
        "pixel=base*tint;}\n");
    if (!vs || !fs) { glDeleteShader(vs); glDeleteShader(fs); return false; }
    R.program = glCreateProgram();
    glAttachShader(R.program, vs); glAttachShader(R.program, fs);
    glBindAttribLocation(R.program, 0, "position");
    glBindAttribLocation(R.program, 1, "color");
    glBindAttribLocation(R.program, 2, "uv");
    glLinkProgram(R.program);
    glDeleteShader(vs); glDeleteShader(fs);
    GLint ok;
    glGetProgramiv(R.program, GL_LINK_STATUS, &ok);
    if (!ok) {
        char error[2048]; glGetProgramInfoLog(R.program, sizeof error, NULL, error);
        fprintf(stderr, "renderer link: %s\n", error);
        render_shutdown(); return false;
    }
    R.screen = glGetUniformLocation(R.program, "screen");
    R.origin = glGetUniformLocation(R.program, "origin");
    R.stripes = glGetUniformLocation(R.program, "stripes");
    R.stripe_rect = glGetUniformLocation(R.program, "stripe_rect");
    R.stripe_color = glGetUniformLocation(R.program, "stripe_color");
    glUseProgram(R.program);
    glUniform1i(glGetUniformLocation(R.program, "image"), 0);
    glGenVertexArrays(1, &R.vao); glBindVertexArray(R.vao);
    glGenBuffers(1, &R.vertices); glBindBuffer(GL_ARRAY_BUFFER, R.vertices);
    glGenBuffers(1, &R.indices);
    glEnableVertexAttribArray(0); glEnableVertexAttribArray(1); glEnableVertexAttribArray(2);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(render_vertex), (void *)offsetof(render_vertex, position));
    glVertexAttribPointer(1, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(render_vertex), (void *)offsetof(render_vertex, color));
    glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, sizeof(render_vertex), (void *)offsetof(render_vertex, uv));
    uint32_t white = UINT32_MAX;
    struct render_texture *t = render_texture_create(1, 1, &white);
    if (!t) { render_shutdown(); return false; }
    R.white = t->id; texture_forget(t); free(t);
    return true;
}

bool render_ready(void) { return R.program != 0; }
void render_shutdown(void)
{
#ifdef ENGINE_TEST
    /* Handles may outlive this in Lua until its state closes, so only the GL side goes now. */
    while (live_textures) {
        struct render_texture *t = live_textures;
        glDeleteTextures(1, &t->id);
        t->id = 0;
        texture_forget(t);
    }
#endif
    glDeleteTextures(4, R.blur_texture);
    glDeleteFramebuffers(4, R.blur_fbo);
    glDeleteProgram(R.blur_program);
    glDeleteTextures(1, &R.white);
    glDeleteBuffers(1, &R.vertices); glDeleteBuffers(1, &R.indices);
    glDeleteVertexArrays(1, &R.vao); glDeleteProgram(R.program);
    memset(&R, 0, sizeof R);
}

/* The whole framebuffer is the viewport: logical coordinates map onto the
 * fitted view, and whatever lies outside it (letterbox bars, safe-area
 * margins) is still addressable, at negative or beyond-size coordinates.
 * Drawing is clipped to the logical screen unless bleed is on. */
void render_begin(size2 pixels, size2 logical, rect viewport, color clear)
{
    R.pixels = pixels; R.logical = logical;
    R.scale = viewport.size.w / logical.w;
    R.offset = viewport.pos;
    R.bleed = false;
    glDisable(GL_SCISSOR_TEST); glDisable(GL_DEPTH_TEST); glDisable(GL_CULL_FACE);
    glViewport(0, 0, (int)pixels.w, (int)pixels.h);
    glClearColor(clear.r / 255.f, clear.g / 255.f, clear.b / 255.f, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glEnable(GL_BLEND); R.additive = false;
    glUseProgram(R.program);
    glUniform2f(R.screen, pixels.w / R.scale, pixels.h / R.scale);
    glUniform2f(R.origin, R.offset.x / R.scale, R.offset.y / R.scale);
    glUniform4f(R.stripes, 0, 0, 0, 0);
    glActiveTexture(GL_TEXTURE0); glBindVertexArray(R.vao);
    render_clip(NULL);
}

struct render_texture *render_texture_create(int w, int h, const void *rgba)
{
    if (!render_ready() || w <= 0 || h <= 0) return NULL;
    struct render_texture *t = calloc(1, sizeof *t);
    if (!t) return NULL;
    glGenTextures(1, &t->id); glBindTexture(GL_TEXTURE_2D, t->id);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, rgba);
    texture_track(t);
    return t;
}
void render_texture_update(struct render_texture *t, int x, int y, int w, int h, const void *rgba)
{
    if (!t) return;
    glBindTexture(GL_TEXTURE_2D, t->id);
    glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, w, h, GL_RGBA, GL_UNSIGNED_BYTE, rgba);
}
void render_texture_free(struct render_texture *t)
{
    if (!t) return;
    if (t->id) glDeleteTextures(1, &t->id);   /* zero: already gone with its test */
    texture_forget(t);
    free(t);
}
void render_texture_additive(struct render_texture *t, bool on) { if (t) t->additive = on; }
void render_additive(bool on) { R.additive = on; }

void render_geometry(struct render_texture *t, const render_vertex *v, int n, const int *idx, int count)
{
    if (!render_ready() || n <= 0) return;
    bool add = t ? t->additive : R.additive;
    glBlendFuncSeparate(GL_SRC_ALPHA, add ? GL_ONE : GL_ONE_MINUS_SRC_ALPHA, GL_ONE, add ? GL_ONE : GL_ONE_MINUS_SRC_ALPHA);
    glBindTexture(GL_TEXTURE_2D, t ? t->id : R.white);
    glBindBuffer(GL_ARRAY_BUFFER, R.vertices);
    glBufferData(GL_ARRAY_BUFFER, (GLsizeiptr)n * sizeof *v, v, GL_STREAM_DRAW);
    if (idx && count > 0) {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, R.indices);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, (GLsizeiptr)count * sizeof *idx, idx, GL_STREAM_DRAW);
        glDrawElements(GL_TRIANGLES, count, GL_UNSIGNED_INT, NULL);
    } else glDrawArrays(GL_TRIANGLES, 0, n);
}

void render_image(texture t, rect src, rect dst, float angle, color tint)
{
    if (!t.tex) return;
    vec2 p[4] = {dst.pos, rect_point(dst, v2(1, 0)), rect_max(dst), rect_point(dst, v2(0, 1))};
    vec2 uv[4] = {src.pos, rect_point(src, v2(1, 0)), rect_max(src), rect_point(src, v2(0, 1))};
    render_vertex v[4];
    for (int i = 0; i < 4; i++) {
        if (angle) p[i] = vec2_add(rect_center(dst), vec2_rotate(vec2_sub(p[i], rect_center(dst)), angle));
        vec2 local_uv = vec2_div(uv[i], size2_vec(t.size));
        if (t.uv.size.w > 0) local_uv = vec2_add(t.uv.pos, vec2_mul(local_uv, size2_vec(t.uv.size)));
        v[i] = (render_vertex){p[i], tint, local_uv};
    }
    const int idx[] = {0, 1, 2, 0, 2, 3};
    bool original_blend = t.tex->additive;
    if (t.additive) t.tex->additive = true;
    render_geometry(t.tex, v, 4, idx, 6);
    t.tex->additive = original_blend;
}

void render_image_striped(texture t, rect dst, float angle, float repeats, float width, color ink, color tint)
{
    if (!render_ready() || !t.tex || dst.size.w <= 0 || dst.size.h <= 0) return;
    if (!isfinite(angle) || !isfinite(repeats) || !isfinite(width) || repeats <= 0 || width <= 0 || !ink.a) {
        render_image(t, tex_rect(t), dst, 0, tint);
        return;
    }
    /* Pattern coordinates belong to the piece, so its stripes follow squash,
     * translation and atlas-region UVs while retaining the source alpha. */
    glUniform4f(R.stripes, -sinf(angle), cosf(angle), repeats, saturate(width));
    glUniform4f(R.stripe_rect, dst.pos.x, dst.pos.y, dst.size.w, dst.size.h);
    glUniform4f(R.stripe_color, ink.r / 255.f, ink.g / 255.f, ink.b / 255.f, ink.a / 255.f);
    render_image(t, tex_rect(t), dst, 0, tint);
    glUniform4f(R.stripes, 0, 0, 0, 0);   /* following ordinary images/shapes stay unstriped */
}

/* The area drawing may reach: the logical screen, or the whole display. */
static rect render_bounds(void)
{
    if (!R.bleed || R.scale <= 0) return rect_make(v2(0, 0), R.logical);
    return rect_make(vec2_scale(R.offset, -1 / R.scale), size2_scale(R.pixels, 1 / R.scale));
}

void render_bleed(bool on)
{
    R.bleed = on;
    render_clip(NULL);
}

void render_clip(const rect *r)
{
    if (!render_ready()) return;
    rect clipped = rect_intersect(r ? *r : render_bounds(), render_bounds());
    int x = (int)floorf(R.offset.x + clipped.pos.x * R.scale);
    int y = (int)floorf(R.pixels.h - R.offset.y - (clipped.pos.y + clipped.size.h) * R.scale);
    /* Round both endpoints. Rounding an origin just below zero to -1 and
     * rounding the length separately can omit the display's last pixel. */
    int right = (int)ceilf(R.offset.x + (clipped.pos.x + clipped.size.w) * R.scale);
    int top = (int)ceilf(R.pixels.h - R.offset.y - clipped.pos.y * R.scale);
    int w = clipped.size.w > 0 ? right - x : 0, h = clipped.size.h > 0 ? top - y : 0;
    glEnable(GL_SCISSOR_TEST); glScissor(x, y, w, h);
}

bool render_read_pixels(void *rgba, int w, int h)
{
    glReadPixels(0, 0, w, h, GL_RGBA, GL_UNSIGNED_BYTE, rgba);
    if (glGetError() != GL_NO_ERROR) return false;
    uint8_t *p = rgba;
    for (int y = 0; y < h / 2; y++)
        for (int x = 0; x < w * 4; x++) {
            uint8_t a = p[y * w * 4 + x];
            p[y * w * 4 + x] = p[(h - y - 1) * w * 4 + x];
            p[(h - y - 1) * w * 4 + x] = a;
        }
    return true;
}

/* Drawing order is the layer stack. Capture all earlier draws, resolve/downsample,
 * then two separable GPU passes. No readback, game-owned textures or scene copies.
 * Save the real default FBO: on iOS it is not necessarily zero. */
static bool render_blur_prepare(int w, int h)
{
    if (R.blur_failed) return false;
    if (!R.blur_program) {
        GLuint vs = render_shader(GL_VERTEX_SHADER,
            "out vec2 uv; void main(){vec2 p=vec2((gl_VertexID<<1)&2,gl_VertexID&2);"
            "uv=p;gl_Position=vec4(p*2.-1.,0,1);}");
        GLuint fs = render_shader(GL_FRAGMENT_SHADER,
            "in vec2 uv; uniform sampler2D image; uniform vec2 delta; uniform vec4 dim; out vec4 pixel;"
            "uniform int pairs; uniform float center_weight, weights[8], offsets[8];"
            "void main(){vec3 c=texture(image,uv).rgb*center_weight;"
            "for(int i=0;i<8;i++){if(i>=pairs)break;vec2 d=delta*offsets[i];"
            "c+=(texture(image,uv+d).rgb+texture(image,uv-d).rgb)*weights[i];}"
            "pixel=vec4(mix(c,dim.rgb,dim.a),1);}");
        if (vs && fs) {
            R.blur_program = glCreateProgram();
            glAttachShader(R.blur_program, vs); glAttachShader(R.blur_program, fs);
            glLinkProgram(R.blur_program);
            GLint ok = 0; glGetProgramiv(R.blur_program, GL_LINK_STATUS, &ok);
            if (!ok) { glDeleteProgram(R.blur_program); R.blur_program = 0; }
        }
        glDeleteShader(vs); glDeleteShader(fs);
        if (!R.blur_program) {
            fprintf(stderr, "renderer: backdrop shader unavailable; using dim-only fallback\n");
            R.blur_failed = true; return false;
        }
    }
    if (w == R.blur_w && h == R.blur_h) return true;
    glDeleteTextures(4, R.blur_texture); memset(R.blur_texture, 0, sizeof R.blur_texture);
    glDeleteFramebuffers(4, R.blur_fbo); memset(R.blur_fbo, 0, sizeof R.blur_fbo);
    glGenFramebuffers(4, R.blur_fbo);
    for (int i = 0; i < 4; i++) {
        int divisor = i == 0 ? 1 : i == 1 ? 2 : 4;
        int tw = (w + divisor - 1) / divisor, th = (h + divisor - 1) / divisor;
        struct render_texture *t = render_texture_create(tw, th, NULL);
        if (!t) { R.blur_failed = true; break; }
        R.blur_texture[i] = t->id; texture_forget(t); free(t);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, R.blur_fbo[i]);
        glFramebufferTexture2D(GL_DRAW_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, R.blur_texture[i], 0);
        if (glCheckFramebufferStatus(GL_DRAW_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) { R.blur_failed = true; break; }
    }
    if (R.blur_failed) {
        fprintf(stderr, "renderer: backdrop targets unavailable at %dx%d; using dim-only fallback\n", w, h);
        return false;
    }
    R.blur_w = w; R.blur_h = h;
    return true;
}

void render_backdrop(float radius, color dim)
{
    if (!render_ready()) return;
    if (!isfinite(radius)) radius = 0;
    radius = clampf(radius, 0, 32);
    if (radius <= 0 && dim.a == 0) return;
    GLint draw_fbo, read_fbo, viewport[4], scissor[4];
    glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &draw_fbo);
    glGetIntegerv(GL_READ_FRAMEBUFFER_BINDING, &read_fbo);
    glGetIntegerv(GL_VIEWPORT, viewport); glGetIntegerv(GL_SCISSOR_BOX, scissor);
    GLboolean clipping = glIsEnabled(GL_SCISSOR_TEST), blending = glIsEnabled(GL_BLEND);
    glDisable(GL_SCISSOR_TEST);
    int w = (int)R.pixels.w, h = (int)R.pixels.h;
    bool blurred = radius > 0 && render_blur_prepare(w, h);
    if (blurred) {
        int bw = (w + 3) / 4, bh = (h + 3) / 4;
        glDisable(GL_BLEND);
        /* Equal-sized first blit also resolves a multisampled platform FBO. */
        glBindFramebuffer(GL_READ_FRAMEBUFFER, (GLuint)draw_fbo);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, R.blur_fbo[0]);
        glBlitFramebuffer(0, 0, w, h, 0, 0, w, h, GL_COLOR_BUFFER_BIT, GL_NEAREST);
        /* Two filtered half steps suppress high-frequency aliasing before blur. */
        int hw = (w + 1) / 2, hh = (h + 1) / 2;
        glBindFramebuffer(GL_READ_FRAMEBUFFER, R.blur_fbo[0]);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, R.blur_fbo[1]);
        glBlitFramebuffer(0, 0, w, h, 0, 0, hw, hh, GL_COLOR_BUFFER_BIT, GL_LINEAR);
        glBindFramebuffer(GL_READ_FRAMEBUFFER, R.blur_fbo[1]);
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, R.blur_fbo[2]);
        glBlitFramebuffer(0, 0, hw, hh, 0, 0, bw, bh, GL_COLOR_BUFFER_BIT, GL_LINEAR);
        glUseProgram(R.blur_program); glBindVertexArray(R.vao); glActiveTexture(GL_TEXTURE0);
        glUniform1i(glGetUniformLocation(R.blur_program, "image"), 0);
        GLint delta = glGetUniformLocation(R.blur_program, "delta"), tint = glGetUniformLocation(R.blur_program, "dim");
        glUniform4f(tint, 0, 0, 0, 0);
        /* A real Gaussian at contiguous texel positions. Adjacent weights are
         * combined into one bilinear fetch; never space a small fixed kernel
         * apart, which leaves a visible grid through text and fine geometry. */
        float sigma = clampf(radius * R.scale / 8, .35f, 5.3f);
        int taps = clampi((int)ceilf(3 * sigma), 1, 16);
        float kernel[17], total = 0, weights[8] = {0}, offsets[8] = {0};
        for (int i = 0; i <= taps; i++) {
            kernel[i] = expf(-(float)(i * i) / (2 * sigma * sigma));
            total += kernel[i] * (i ? 2 : 1);
        }
        int pairs = 0;
        for (int i = 1; i <= taps; i += 2) {
            float a = kernel[i] / total, b = i + 1 <= taps ? kernel[i + 1] / total : 0;
            weights[pairs] = a + b;
            offsets[pairs++] = (i * a + (i + 1) * b) / (a + b);
        }
        glUniform1i(glGetUniformLocation(R.blur_program, "pairs"), pairs);
        glUniform1f(glGetUniformLocation(R.blur_program, "center_weight"), kernel[0] / total);
        glUniform1fv(glGetUniformLocation(R.blur_program, "weights[0]"), 8, weights);
        glUniform1fv(glGetUniformLocation(R.blur_program, "offsets[0]"), 8, offsets);
        glViewport(0, 0, bw, bh);
        for (int pass = 0; pass < 2; pass++) {
            glBindFramebuffer(GL_DRAW_FRAMEBUFFER, R.blur_fbo[pass ? 2 : 3]);
            glBindTexture(GL_TEXTURE_2D, R.blur_texture[pass ? 3 : 2]);
            glUniform2f(delta, pass ? 0 : 1.f / bw, pass ? 1.f / bh : 0);
            glDrawArrays(GL_TRIANGLES, 0, 3);
        }
        glBindFramebuffer(GL_DRAW_FRAMEBUFFER, (GLuint)draw_fbo);
        glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
        glBindTexture(GL_TEXTURE_2D, R.blur_texture[2]);
        glUniform2f(delta, 0, 0);
        glUniform1i(glGetUniformLocation(R.blur_program, "pairs"), 0);
        glUniform1f(glGetUniformLocation(R.blur_program, "center_weight"), 1);
        glUniform4f(tint, dim.r / 255.f, dim.g / 255.f, dim.b / 255.f, dim.a / 255.f);
        glDrawArrays(GL_TRIANGLES, 0, 3);
    }
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, (GLuint)draw_fbo);
    glBindFramebuffer(GL_READ_FRAMEBUFFER, (GLuint)read_fbo);
    glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
    glUseProgram(R.program); glBindVertexArray(R.vao); glActiveTexture(GL_TEXTURE0);
    if (blending) glEnable(GL_BLEND); else glDisable(GL_BLEND);
    if (!blurred && dim.a) {
        vec2 lo = vec2_scale(R.offset, -1 / R.scale);
        vec2 hi = vec2_add(lo, size2_vec(size2_scale(R.pixels, 1 / R.scale)));
        render_vertex v[] = {{lo,dim,{0,0}},{{hi.x,lo.y},dim,{0,0}},{hi,dim,{0,0}},
                             {lo,dim,{0,0}},{hi,dim,{0,0}},{{lo.x,hi.y},dim,{0,0}}};
        bool saved_additive = R.additive; R.additive = false;
        glEnable(GL_BLEND); render_geometry(NULL, v, 6, NULL, 0);
        R.additive = saved_additive;
        if (!blending) glDisable(GL_BLEND);
    }
    glScissor(scissor[0], scissor[1], scissor[2], scissor[3]);
    if (clipping) glEnable(GL_SCISSOR_TEST); else glDisable(GL_SCISSOR_TEST);
}
