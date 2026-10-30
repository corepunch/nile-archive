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

struct render_texture { GLuint id; bool additive; };
static struct {
    GLuint program, vao, vertices, indices, white;
    GLint screen;
    size2 pixels, logical;
    float scale;
    vec2 offset;
    bool additive;
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

bool render_init(void)
{
    GLuint vs = render_shader(GL_VERTEX_SHADER,
        "in vec2 position; in vec4 color; in vec2 uv; uniform vec2 screen;\n"
        "out vec4 tint; out vec2 texcoord;\n"
        "void main(){gl_Position=vec4(position/screen*vec2(2,-2)+vec2(-1,1),0,1);tint=color;texcoord=uv;}\n");
    GLuint fs = render_shader(GL_FRAGMENT_SHADER,
        "in vec4 tint; in vec2 texcoord; uniform sampler2D image; out vec4 pixel;\n"
        "void main(){pixel=texture(image,texcoord)*tint;}\n");
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
    R.white = t->id; free(t);
    return true;
}

bool render_ready(void) { return R.program != 0; }
void render_shutdown(void)
{
    glDeleteTextures(1, &R.white);
    glDeleteBuffers(1, &R.vertices); glDeleteBuffers(1, &R.indices);
    glDeleteVertexArrays(1, &R.vao); glDeleteProgram(R.program);
    memset(&R, 0, sizeof R);
}

void render_begin(size2 pixels, size2 logical, rect viewport, color clear)
{
    R.pixels = pixels; R.logical = logical;
    R.scale = viewport.size.w / logical.w;
    size2 view = viewport.size;
    R.offset = viewport.pos;
    glDisable(GL_SCISSOR_TEST); glDisable(GL_DEPTH_TEST); glDisable(GL_CULL_FACE);
    glViewport(0, 0, (int)pixels.w, (int)pixels.h);
    glClearColor(clear.r / 255.f, clear.g / 255.f, clear.b / 255.f, 1);
    glClear(GL_COLOR_BUFFER_BIT);
    glViewport((int)R.offset.x, (int)(pixels.h - R.offset.y - view.h), (int)view.w, (int)view.h);
    glEnable(GL_BLEND); R.additive = false;
    glUseProgram(R.program); glUniform2f(R.screen, logical.w, logical.h);
    glActiveTexture(GL_TEXTURE0); glBindVertexArray(R.vao);
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
    return t;
}
void render_texture_update(struct render_texture *t, int x, int y, int w, int h, const void *rgba)
{
    if (!t) return;
    glBindTexture(GL_TEXTURE_2D, t->id);
    glTexSubImage2D(GL_TEXTURE_2D, 0, x, y, w, h, GL_RGBA, GL_UNSIGNED_BYTE, rgba);
}
void render_texture_free(struct render_texture *t) { if (t) { glDeleteTextures(1, &t->id); free(t); } }
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
        v[i] = (render_vertex){p[i], tint, vec2_div(uv[i], size2_vec(t.size))};
    }
    const int idx[] = {0, 1, 2, 0, 2, 3};
    render_geometry(t.tex, v, 4, idx, 6);
}

void render_clip(const rect *r)
{
    if (!render_ready()) return;
    if (!r) { glDisable(GL_SCISSOR_TEST); return; }
    rect clipped = rect_intersect(*r, rect_make(v2(0, 0), R.logical));
    int x = (int)floorf(R.offset.x + clipped.pos.x * R.scale);
    int y = (int)floorf(R.pixels.h - R.offset.y - (clipped.pos.y + clipped.size.h) * R.scale);
    int w = (int)ceilf(clipped.size.w * R.scale), h = (int)ceilf(clipped.size.h * R.scale);
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
