/* Music: a sequenced stereo synthesiser that loops one song under the tones.
 *
 * A song is a list of notes (instrument, beat, length in beats, MIDI pitch,
 * velocity) staged from Lua with music_note; music_play swaps it in with a
 * short fade. The voices are studio-synth patches rather than chip tones:
 * detuned polyBLEP saw pads through zero-delay-feedback filters, two-operator
 * FM keys and bells, a filtered saw/sine bass, plucks with a filter envelope,
 * a breathy lead with delayed vibrato and soft synthesised drums. They feed a
 * stereo chorus, a tempo-synced ping-pong delay and a Freeverb-style hall.
 * Everything renders in 32-sample control blocks on the audio thread. */
#include "engine.h"
#include "render.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MRATE 44100.0f
#define MEVENTS 4096
#define MVOICES 64
#define MBLOCK 32
#define MTAU (2 * ENGINE_PI)

typedef struct { float beat, length, pitch, velocity; int instrument; } music_event;
typedef struct { float gain, chorus, delay, reverb; } music_patch;

/* Dry level and effect sends per instrument. */
static const music_patch patches[MUSIC_INSTRUMENTS] = {
    [MUSIC_PAD]    = {.075f, .55f, 0,    .50f},
    [MUSIC_KEYS]   = {.110f, .45f, .10f, .30f},
    [MUSIC_BASS]   = {.230f, 0,    0,    .05f},
    [MUSIC_PLUCK]  = {.085f, .20f, .45f, .30f},
    [MUSIC_BELL]   = {.100f, .15f, .35f, .40f},
    [MUSIC_LEAD]   = {.110f, .30f, .30f, .35f},
    [MUSIC_KICK]   = {.300f, 0,    0,    .04f},
    [MUSIC_SNARE]  = {.120f, 0,    .05f, .35f},
    [MUSIC_HAT]    = {.050f, 0,    .10f, .15f},
    [MUSIC_SHAKER] = {.060f, 0,    0,    .20f},
    [MUSIC_JINGLE] = {.030f, 0,    .10f, .30f},
};

typedef struct {
    bool on;
    int inst;
    float freq, pitch, vel, t, gate, pan, last;
    float ph[6];
    float s1[2], s2[2], s3[2], s4[2];   /* filter integrators per side */
    uint32_t seed;
} music_voice;

typedef struct { float buf[1800]; int size, at; float filt; } music_comb;
typedef struct { float buf[600]; int size, at; } music_allpass;

#define CHORUS_SIZE 2048
#define DELAY_SIZE 40000

static struct {
    /* staged by the game, swapped in by the mixer */
    music_event stage[MEVENTS];
    int stage_count;
    float stage_bpm, stage_beats;
    bool swap;
    /* the playing song */
    music_event live[MEVENTS];
    int count, next;
    float bpm, beats, pos;
    bool playing, stopping;
    float gain, target, rate, volume;
    bool volume_set;
    float duck;   /* seconds since the last kick */
    music_voice voices[MVOICES];
    /* effects */
    float chorus[2][CHORUS_SIZE];
    int chorus_at;
    float chorus_phase;
    float delay[2][DELAY_SIZE];
    int delay_at;
    float delay_damp[2];
    music_comb comb[2][8];
    music_allpass allpass[2][4];
    float reverb_hp, reverb_hp_in;
    bool reverb_ready;
} M;

/* ------------------------------------------------------------ building blocks */

static float noise(uint32_t *seed)
{
    uint32_t x = *seed ? *seed : 0x9e3779b9u;
    x ^= x << 13; x ^= x >> 17; x ^= x << 5;
    *seed = x;
    return (float)(int32_t)x * (1.0f / 2147483648.0f);
}

static float blep(float t, float dt)
{
    if (t < dt) { t /= dt; return t + t - t * t - 1; }
    if (t > 1 - dt) { t = (t - 1) / dt; return t * t + t + t + 1; }
    return 0;
}

static float saw(float *ph, float inc)
{
    *ph += inc;
    if (*ph >= 1) *ph -= 1;
    return 2 * *ph - 1 - blep(*ph, inc);
}

static float cycle(float *ph, float inc)
{
    *ph += inc;
    if (*ph >= 1) *ph -= floorf(*ph);
    return *ph;
}

/* Andrew Simper's trapezoidal state-variable filter. */
typedef struct { float k, a1, a2, a3; } music_svf;
static music_svf svf_make(float hz, float k)
{
    float g = tanf(ENGINE_PI * clampf(hz, 20, MRATE * .45f) / MRATE);
    music_svf f = {.k = k};
    f.a1 = 1 / (1 + g * (g + k));
    f.a2 = g * f.a1;
    f.a3 = g * f.a2;
    return f;
}
static float svf_run(const music_svf *f, float *ic1, float *ic2, float v0, float *band, float *high)
{
    float v3 = v0 - *ic2, v1 = f->a1 * *ic1 + f->a2 * v3, v2 = *ic2 + f->a2 * *ic1 + f->a3 * v3;
    *ic1 = 2 * v1 - *ic1;
    *ic2 = 2 * v2 - *ic2;
    if (band) *band = v1;
    if (high) *high = v0 - f->k * v1 - v2;
    return v2;
}

/* Attack to 1, exponential decay towards the sustain level, exponential
 * release once the gate closes. */
static float adsr(float t, float gate, float a, float d, float s, float r)
{
    float x = t < gate ? t : gate;
    float level = x < a ? x / a : s + (1 - s) * expf(-(x - a) / d);
    if (t > gate) level *= expf(-(t - gate) / r);
    return level;
}

static float release_of(int inst)
{
    switch (inst) {
    case MUSIC_PAD: return 1.3f;
    case MUSIC_KEYS: return .3f;
    case MUSIC_BASS: return .07f;
    case MUSIC_PLUCK: return .12f;
    case MUSIC_BELL: return .8f;
    case MUSIC_LEAD: return .22f;
    default: return 0;
    }
}

static float voice_env(const music_voice *v, float t)
{
    switch (v->inst) {
    case MUSIC_PAD: return adsr(t, v->gate, .7f, 1.8f, .75f, 1.3f);
    case MUSIC_KEYS: {
        float low = 1 - clampf((v->pitch - 48) / 36, 0, 1);   /* low notes ring longer */
        return adsr(t, v->gate, .003f, 1.1f + 2.0f * low, 0, .3f);
    }
    case MUSIC_BASS: return adsr(t, v->gate, .004f, .35f, .8f, .07f);
    case MUSIC_PLUCK: return adsr(t, v->gate, .002f, .34f, 0, .12f);
    case MUSIC_BELL: return adsr(t, v->gate, .001f, 1.5f, 0, .8f);
    case MUSIC_LEAD: return adsr(t, v->gate, .05f, .4f, .85f, .22f);
    default: return 1;   /* drums shape themselves per sample */
    }
}

static float voice_length(const music_voice *v)
{
    switch (v->inst) {
    case MUSIC_KICK: return .8f;
    case MUSIC_SNARE: return .6f;
    case MUSIC_HAT: return .5f;
    case MUSIC_SHAKER: return .3f;
    case MUSIC_JINGLE: return .6f;
    case MUSIC_KEYS: case MUSIC_PLUCK: case MUSIC_BELL:
        return minf(v->gate, 6) + 7 * release_of(v->inst);
    default: return v->gate + 7 * release_of(v->inst);
    }
}

/* ------------------------------------------------------------------- voices */

static void voice_start(const music_event *e)
{
    music_voice *slot = NULL, *quiet = &M.voices[0];
    for (int k = 0; k < MVOICES; k++) {
        music_voice *v = &M.voices[k];
        if (!v->on) { slot = v; break; }
        if (v->last * (v->t < v->gate ? 2 : 1) < quiet->last * (quiet->t < quiet->gate ? 2 : 1)) quiet = v;
    }
    if (!slot) slot = quiet;   /* steal the quietest, preferring released voices */
    uint32_t seed = (uint32_t)(e->pitch * 977) ^ (uint32_t)(e->beat * 7919) ^ 0x2545f491u;
    *slot = (music_voice){
        .on = true, .inst = e->instrument, .pitch = e->pitch,
        .freq = 440 * powf(2, (e->pitch - 69) / 12), .vel = clampf(e->velocity, 0, 1.5f),
        .gate = maxf(e->length * 60 / M.bpm, .02f), .seed = seed,
    };
    for (int k = 0; k < 6; k++) slot->ph[k] = (noise(&slot->seed) + 1) * .5f;
    /* a stable stereo place per pitch for melodic voices, centred low end */
    float spread = e->instrument == MUSIC_PLUCK ? .55f : e->instrument == MUSIC_BELL ? .35f :
                   e->instrument == MUSIC_JINGLE ? .5f : e->instrument == MUSIC_HAT ? .25f :
                   e->instrument == MUSIC_SHAKER ? .3f : e->instrument == MUSIC_KEYS ? .15f : 0;
    slot->pan = .5f + .5f * spread * sinf(e->pitch * 2.3f + e->beat * .7f);
    if (e->instrument == MUSIC_KICK) M.duck = 0;
}

static void pan_out(float x, float pan, float *l, float *r)
{
    *l += x * sqrtf(1 - pan) * 1.4142f;
    *r += x * sqrtf(pan) * 1.4142f;
}

/* Render n samples of one voice, adding to the left/right buffers. */
static void voice_render(music_voice *v, float *l, float *r, int n)
{
    const float dt = 1 / MRATE;
    float e0 = v->t == 0 ? 0 : v->last, e1 = voice_env(v, v->t + n * dt);
    float f = v->freq, vel = v->vel, t = v->t;
    if (v->inst == MUSIC_PAD || v->inst == MUSIC_KEYS) {   /* the kick ducks sustained chords */
        float duck = 1 - .32f * expf(-M.duck / .16f);
        e0 *= duck; e1 *= duck;
    }
    switch (v->inst) {
    case MUSIC_PAD: {
        static const float detune[6] = {-.0081f, -.0043f, -.0012f, .0016f, .0047f, .0084f};
        float drift = 1 + .0012f * sinf(MTAU * .13f * t + v->pitch);
        music_svf filt = svf_make(500 + f * 2.2f + 1100 * e1 * vel + 300 * sinf(MTAU * .09f * t + f), 1.55f);
        for (int i = 0; i < n; i++) {
            float a = 0, b = 0, env = e0 + (e1 - e0) * i / n;
            for (int k = 0; k < 6; k++) {
                float s = saw(&v->ph[k], f * (1 + detune[k]) * drift * dt);
                if (k & 1) b += s; else a += s;
            }
            float yl = svf_run(&filt, &v->s1[0], &v->s2[0], a * .33f, NULL, NULL);
            float yr = svf_run(&filt, &v->s1[1], &v->s2[1], b * .33f, NULL, NULL);
            l[i] += yl * env * vel; r[i] += yr * env * vel;
        }
        break;
    }
    case MUSIC_KEYS: {
        float i0 = (.8f + 1.5f * vel) * expf(-t / .45f) + .35f;
        float i1 = (.8f + 1.5f * vel) * expf(-(t + n * dt) / .45f) + .35f;
        for (int i = 0; i < n; i++) {
            float u = (float)i / n, tt = t + i * dt, env = e0 + (e1 - e0) * u;
            float idx = i0 + (i1 - i0) * u, tine = 1.1f * vel * expf(-tt / .025f);
            float c = cycle(&v->ph[0], f * dt), m = cycle(&v->ph[1], f * 1.0007f * dt), h = cycle(&v->ph[2], f * 13 * dt);
            float x = sinf(MTAU * c + idx * sinf(MTAU * m) + tine * sinf(MTAU * h)) * env * vel;
            pan_out(x, v->pan + .14f * sinf(MTAU * 3.2f * tt), &l[i], &r[i]);
        }
        break;
    }
    case MUSIC_BASS: {
        music_svf filt = svf_make(f * 1.2f + (250 + 1500 * vel) * expf(-t / .11f), 1.4f);
        for (int i = 0; i < n; i++) {
            float env = e0 + (e1 - e0) * i / n;
            float s = saw(&v->ph[0], f * dt), sub = sinf(MTAU * v->ph[0]);
            float y = svf_run(&filt, &v->s1[0], &v->s2[0], .55f * s + .8f * sub, NULL, NULL);
            float x = tanhf(1.6f * y) * .8f * env * vel;
            l[i] += x; r[i] += x;
        }
        break;
    }
    case MUSIC_PLUCK: {
        music_svf filt = svf_make(f * 1.5f + 4200 * vel * expf(-t / .07f), 1.3f);
        for (int i = 0; i < n; i++) {
            float env = e0 + (e1 - e0) * i / n;
            float s = .5f * (saw(&v->ph[0], f * 1.004f * dt) + saw(&v->ph[1], f * .996f * dt));
            float y = svf_run(&filt, &v->s1[0], &v->s2[0], s, NULL, NULL);
            pan_out(y * env * vel, v->pan, &l[i], &r[i]);
        }
        break;
    }
    case MUSIC_BELL: {
        for (int i = 0; i < n; i++) {
            float tt = t + i * dt, env = e0 + (e1 - e0) * i / n;
            float idx = 1.4f * vel * expf(-tt / .18f) + .15f;
            float c = cycle(&v->ph[0], f * dt), m = cycle(&v->ph[1], f * 4 * dt);
            float x = sinf(MTAU * c + idx * sinf(MTAU * m)) + .25f * expf(-tt / .4f) * sinf(MTAU * 2 * c);
            pan_out(x * env * vel, v->pan, &l[i], &r[i]);
        }
        break;
    }
    case MUSIC_LEAD: {
        music_svf body = svf_make(f * 3 + 400, 1.5f), breath = svf_make(f * 2, .8f);
        for (int i = 0; i < n; i++) {
            float tt = t + i * dt, env = e0 + (e1 - e0) * i / n;
            float depth = .0045f * clampf((tt - .25f) / .4f, 0, 1);
            float hz = f * (1 + depth * sinf(MTAU * 5.1f * tt));
            float p = cycle(&v->ph[0], hz * dt);
            float soft = sinf(MTAU * p) + .28f * sinf(MTAU * 2 * p) + .1f * sinf(MTAU * 3 * p);
            float s = svf_run(&body, &v->s1[0], &v->s2[0], saw(&v->ph[1], hz * dt), NULL, NULL);
            float air;
            svf_run(&breath, &v->s1[1], &v->s2[1], noise(&v->seed), &air, NULL);
            float x = (.6f * soft + .45f * s + .08f * air) * env * vel;
            l[i] += x; r[i] += x;
        }
        break;
    }
    case MUSIC_KICK:
        for (int i = 0; i < n; i++) {
            float tt = t + i * dt;
            float p = cycle(&v->ph[0], (45 + 85 * expf(-tt / .03f)) * dt);
            float x = sinf(MTAU * p) * expf(-tt / .32f) + .25f * noise(&v->seed) * expf(-tt / .0025f);
            x = tanhf(1.4f * x) * vel;
            l[i] += x; r[i] += x;
        }
        break;
    case MUSIC_SNARE: {
        music_svf filt = svf_make(2000, 1.2f);
        for (int i = 0; i < n; i++) {
            float tt = t + i * dt, band;
            svf_run(&filt, &v->s1[0], &v->s2[0], noise(&v->seed), &band, NULL);
            float tone = sinf(MTAU * cycle(&v->ph[0], 185 * dt)) * expf(-tt / .05f) * .6f;
            float x = (band * 1.6f * expf(-tt / .1f) + tone) * vel;
            l[i] += x; r[i] += x;
        }
        break;
    }
    case MUSIC_HAT: {
        music_svf filt = svf_make(7500, 1.4f);
        float decay = clampf(v->gate * .3f, .02f, .25f);
        for (int i = 0; i < n; i++) {
            float high, tt = t + i * dt;
            svf_run(&filt, &v->s1[0], &v->s2[0], noise(&v->seed), NULL, &high);
            pan_out(high * expf(-tt / decay) * vel, v->pan, &l[i], &r[i]);
        }
        break;
    }
    case MUSIC_SHAKER: {
        music_svf filt = svf_make(5500, 1.0f);
        for (int i = 0; i < n; i++) {
            float band, tt = t + i * dt;
            svf_run(&filt, &v->s1[0], &v->s2[0], noise(&v->seed), &band, NULL);
            float env = (1 - expf(-tt / .006f)) * expf(-tt / .06f);
            pan_out(band * 1.5f * env * vel, v->pan, &l[i], &r[i]);
        }
        break;
    }
    case MUSIC_JINGLE: {
        static const float partials[5] = {2730, 3640, 4890, 6120, 7350};
        static const float strikes[3] = {0, .011f, .024f};
        music_svf filt = svf_make(8000, 1.4f);
        float shift = 1 + .02f * sinf(v->pitch * 3.7f);
        for (int i = 0; i < n; i++) {
            float tt = t + i * dt, x = 0, high;
            for (int s = 0; s < 3; s++) {
                float u = tt - strikes[s];
                if (u < 0) continue;
                float ring = 0;
                for (int k = 0; k < 5; k++) ring += sinf(MTAU * (partials[k] * shift * (1 + .013f * s) * u + v->ph[k]));
                x += ring * expf(-u / .12f) * (1 - .25f * s);
            }
            svf_run(&filt, &v->s1[0], &v->s2[0], noise(&v->seed), NULL, &high);
            x += high * 1.5f * expf(-tt / .03f);
            pan_out(x * vel, v->pan, &l[i], &r[i]);
        }
        break;
    }
    }
    v->t += n * dt;
    v->last = e1;
    if (v->t > voice_length(v) || (v->t > v->gate + .05f && e1 < 3e-3f && release_of(v->inst) > 0)) v->on = false;
}

/* ------------------------------------------------------------------ effects */

static void reverb_init(void)
{
    static const int combs[8] = {1116, 1188, 1277, 1356, 1422, 1491, 1557, 1617};
    static const int passes[4] = {556, 441, 341, 225};
    memset(M.comb, 0, sizeof M.comb);
    memset(M.allpass, 0, sizeof M.allpass);
    for (int side = 0; side < 2; side++) {
        for (int k = 0; k < 8; k++) M.comb[side][k].size = combs[k] + side * 23;
        for (int k = 0; k < 4; k++) M.allpass[side][k].size = passes[k] + side * 23;
    }
    M.reverb_ready = true;
}

static float reverb_side(int side, float x)
{
    float out = 0;
    for (int k = 0; k < 8; k++) {
        music_comb *c = &M.comb[side][k];
        float y = c->buf[c->at];
        c->filt = y * .65f + c->filt * .35f;
        c->buf[c->at] = x + c->filt * .86f;
        if (++c->at >= c->size) c->at = 0;
        out += y;
    }
    for (int k = 0; k < 4; k++) {
        music_allpass *a = &M.allpass[side][k];
        float b = a->buf[a->at];
        a->buf[a->at] = out + b * .5f;
        out = b - out;
        if (++a->at >= a->size) a->at = 0;
    }
    return out;
}

static float delay_read(const float *buf, int size, int at, float back)
{
    float pos = (float)at - back;
    while (pos < 0) pos += size;
    int i = (int)pos;
    float frac = pos - i;
    return buf[i] + (buf[(i + 1) % size] - buf[i]) * frac;
}

/* ------------------------------------------------------------------- mixing */

static void song_swap(void)
{
    memcpy(M.live, M.stage, sizeof(music_event) * (size_t)M.stage_count);
    M.count = M.stage_count;
    M.bpm = M.stage_bpm;
    M.beats = M.stage_beats;
    M.pos = 0;
    M.next = 0;
    M.swap = false;
    M.playing = true;
    M.stopping = false;
    M.target = 1;
    M.rate = 1 / (.6f * MRATE);
    memset(M.voices, 0, sizeof M.voices);
}

static void sequence(int n)
{
    if (!M.playing || M.stopping || M.beats <= 0 || M.bpm <= 0) return;
    float end = M.pos + n * M.bpm / 60 / MRATE;
    for (;;) {
        while (M.next < M.count && M.live[M.next].beat < end && M.live[M.next].beat < M.beats)
            voice_start(&M.live[M.next++]);
        if (end < M.beats) break;
        end -= M.beats;
        M.next = 0;
    }
    M.pos = end;
}

static void mix_block(float *out_l, float *out_r, int n)
{
    float dry[2][MBLOCK] = {{0}}, chorus[2][MBLOCK] = {{0}}, echo[MBLOCK] = {0}, hall[MBLOCK] = {0};
    if (M.swap) {
        M.target = 0;
        M.rate = 1 / (.5f * MRATE);
        if (M.gain <= .0005f) song_swap();
    }
    sequence(n);
    for (int k = 0; k < MVOICES; k++) {
        music_voice *v = &M.voices[k];
        if (!v->on) continue;
        float l[MBLOCK] = {0}, r[MBLOCK] = {0};
        voice_render(v, l, r, n);
        const music_patch *p = &patches[v->inst];
        for (int i = 0; i < n; i++) {
            float a = l[i] * p->gain, b = r[i] * p->gain;
            dry[0][i] += a; dry[1][i] += b;
            chorus[0][i] += a * p->chorus; chorus[1][i] += b * p->chorus;
            echo[i] += (a + b) * .5f * p->delay;
            hall[i] += (a + b) * .5f * p->reverb;
        }
    }
    M.duck += n / MRATE;
    if (!M.reverb_ready) reverb_init();
    int echo_len = (int)clampf(.75f * 60 / maxf(M.bpm, 1) * MRATE, 100, DELAY_SIZE - 2);
    for (int i = 0; i < n; i++) {
        /* stereo chorus: two delay lines swept in quadrature */
        M.chorus[0][M.chorus_at] = chorus[0][i];
        M.chorus[1][M.chorus_at] = chorus[1][i];
        M.chorus_phase += .27f / MRATE;
        if (M.chorus_phase >= 1) M.chorus_phase -= 1;
        float cl = delay_read(M.chorus[0], CHORUS_SIZE, M.chorus_at, (.011f + .003f * sinf(MTAU * M.chorus_phase)) * MRATE);
        float cr = delay_read(M.chorus[1], CHORUS_SIZE, M.chorus_at, (.011f + .003f * cosf(MTAU * M.chorus_phase)) * MRATE);
        M.chorus_at = (M.chorus_at + 1) % CHORUS_SIZE;
        /* ping-pong delay, darkened on each repeat */
        int back = (M.delay_at - echo_len + DELAY_SIZE) % DELAY_SIZE;
        float dl = M.delay[0][back], dr = M.delay[1][back];
        M.delay_damp[0] += (dr - M.delay_damp[0]) * .45f;
        M.delay_damp[1] += (dl - M.delay_damp[1]) * .45f;
        M.delay[0][M.delay_at] = echo[i] + M.delay_damp[0] * .38f;
        M.delay[1][M.delay_at] = M.delay_damp[1] * .38f;
        M.delay_at = (M.delay_at + 1) % DELAY_SIZE;
        /* hall: high-passed send into Freeverb */
        float in = hall[i];
        M.reverb_hp = .97f * (M.reverb_hp + in - M.reverb_hp_in);
        M.reverb_hp_in = in;
        float send = M.reverb_hp * .05f;
        float rl = reverb_side(0, send), rr = reverb_side(1, send);
        /* fade towards the target */
        if (M.gain < M.target) M.gain = minf(M.target, M.gain + M.rate);
        else if (M.gain > M.target) M.gain = maxf(M.target, M.gain - M.rate);
        float g = M.gain * M.volume * .5f;   /* under the feedback tones */
        out_l[i] += (dry[0][i] + cl * .55f + dl * .45f + rl * .9f) * g;
        out_r[i] += (dry[1][i] + cr * .55f + dr * .45f + rr * .9f) * g;
    }
    if (M.stopping && M.gain <= 0) {
        M.playing = M.stopping = false;
        memset(M.voices, 0, sizeof M.voices);
    }
}

void music_mix(float *left, float *right, int frames)
{
    if (!M.playing && !M.swap) return;
    if (!M.volume_set) { M.volume = 1; M.volume_set = true; }
    for (int at = 0; at < frames; at += MBLOCK) mix_block(left + at, right + at, frames - at < MBLOCK ? frames - at : MBLOCK);
}

/* ---------------------------------------------------------------------- API */

static int event_order(const void *a, const void *b)
{
    float x = ((const music_event *)a)->beat, y = ((const music_event *)b)->beat;
    return (x > y) - (x < y);
}

void music_clear(void)
{
    audio_lock();
    M.stage_count = 0;
    audio_unlock();
}

void music_note(int instrument, float beat, float length, float pitch, float velocity)
{
    if (instrument < 0 || instrument >= MUSIC_INSTRUMENTS || !isfinite(beat) || !isfinite(length) ||
        !isfinite(pitch) || !isfinite(velocity) || beat < 0 || velocity <= 0) return;
    audio_lock();
    if (M.stage_count < MEVENTS)
        M.stage[M.stage_count++] = (music_event){beat, maxf(length, 0), clampf(pitch, 0, 127), velocity, instrument};
    audio_unlock();
}

void music_play(float bpm, float beats)
{
    if (!isfinite(bpm) || !isfinite(beats) || bpm <= 0 || beats <= 0) return;
    audio_lock();
    qsort(M.stage, (size_t)M.stage_count, sizeof(music_event), event_order);
    M.stage_bpm = bpm;
    M.stage_beats = beats;
    M.swap = true;
    if (!M.volume_set) { M.volume = 1; M.volume_set = true; }
    audio_unlock();
    audio_start();
}

void music_stop(float fade)
{
    audio_lock();
    M.swap = false;
    if (M.playing) {
        M.stopping = true;
        M.target = 0;
        M.rate = 1 / (maxf(fade, .01f) * MRATE);
    }
    audio_unlock();
}

void music_volume(float volume)
{
    audio_lock();
    M.volume = isfinite(volume) ? clampf(volume, 0, 2) : 1;
    M.volume_set = true;
    audio_unlock();
}

bool music_playing(void) { return (M.playing && !M.stopping) || M.swap; }
float music_beat(void) { return M.pos; }

/* Render the staged or playing song to a 16-bit stereo WAV for auditioning,
 * without an audio device. Starts from the song's first beat. */
bool music_render(const char *path, float seconds)
{
    if (!path || !*path || !isfinite(seconds) || seconds <= 0) return false;
    FILE *file = fopen(path, "wb");
    if (!file) return false;
    audio_lock();
    if (M.swap || M.playing) {
        if (!M.swap) { M.stage_count = M.count; memcpy(M.stage, M.live, sizeof(music_event) * (size_t)M.count);
                       M.stage_bpm = M.bpm; M.stage_beats = M.beats; }
        song_swap();
        M.gain = 1;
    }
    if (!M.volume_set) { M.volume = 1; M.volume_set = true; }
    uint32_t frames = (uint32_t)(seconds * MRATE), bytes = frames * 4;
    uint8_t header[44] = {'R','I','F','F', 0,0,0,0, 'W','A','V','E', 'f','m','t',' ', 16,0,0,0, 1,0, 2,0,
                          0x44,0xac,0,0, 0x10,0xb1,2,0, 4,0, 16,0, 'd','a','t','a', 0,0,0,0};
    uint32_t riff = bytes + 36;
    memcpy(header + 4, &riff, 4);
    memcpy(header + 40, &bytes, 4);
    bool ok = fwrite(header, 1, 44, file) == 44;
    for (uint32_t at = 0; ok && at < frames; at += 1024) {
        int n = (int)minf(1024, (float)(frames - at));
        float l[1024] = {0}, r[1024] = {0};
        int16_t out[2048];
        music_mix(l, r, n);
        for (int i = 0; i < n; i++) {
            out[i * 2] = (int16_t)(clampf(l[i] / (1 + fabsf(l[i]) * .8f), -1, 1) * 32767);
            out[i * 2 + 1] = (int16_t)(clampf(r[i] / (1 + fabsf(r[i]) * .8f), -1, 1) * 32767);
        }
        ok = fwrite(out, 4, (size_t)n, file) == (size_t)n;
    }
    audio_unlock();
    return fclose(file) == 0 && ok;
}

void music_restart(void)
{
    audio_lock();
    memset(&M, 0, sizeof M);
    audio_unlock();
}
