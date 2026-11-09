/* Feedback-tone synthesiser; silent games never open the stereo device. */
#include "engine.h"
#include <string.h>

#define AUDIO_RATE 44100
#define VOICES 16
typedef struct { float phase, freq, remaining, duration, delay, volume; } voice;
static struct {
    int device;
    bool tried, disabled;
    voice voices[VOICES];
} audio_state;

/* One soft bell partial stack per voice; voices wait out their delay first,
 * so a chord or jingle is scheduled in one call and plays sample-exactly. */
static float voice_sample(voice *v)
{
    if (v->delay > 0) { v->delay -= 1.0f / AUDIO_RATE; return 0; }
    if (v->remaining <= 0) return 0;
    float env = v->remaining / v->duration;
    float attack = minf(1, (v->duration - v->remaining) / .006f);
    float tone = (sinf(v->phase) + .22f * sinf(v->phase * 2) + .1f * sinf(v->phase * 3)) * powf(env, 1.6f) * attack * .06f * v->volume;
    v->phase += 2 * ENGINE_PI * v->freq / AUDIO_RATE;
    if (v->phase > 2 * ENGINE_PI * 64) v->phase -= 2 * ENGINE_PI * 64;
    v->remaining -= 1.0f / AUDIO_RATE;
    return tone;
}

static void audio_mix(void *user, uint8_t *stream, int length)
{
    (void)user;
    memset(stream, 0, length);
    int16_t *out = (int16_t *)stream;
    for (int i = 0; i < length / 4; i++) {
        if (audio_state.disabled) continue;
        float mix = 0;
        for (int k = 0; k < VOICES; k++) mix += voice_sample(&audio_state.voices[k]);
        mix = mix / (1 + fabsf(mix) * .8f);   /* soft-clip stacked chords */
        int sample = (int)(clampf(mix, -1, 1) * 32767);
        out[i * 2] = out[i * 2 + 1] = (int16_t)sample;
    }
}

static bool audio_open(void)
{
    if (audio_state.tried) return audio_state.device != 0;
    audio_state.tried = true;
    if (!axAudioInit()) return false;
    AXaudiospec want = {.freq = AUDIO_RATE, .format = AX_AUDIO_S16, .channels = 2, .samples = 1024, .callback = audio_mix}, got;
    audio_state.device = axAudioOpen(&want, &got);
    if (audio_state.device) axAudioPause(audio_state.device, 0);
    return audio_state.device != 0;
}

void sfx_note(float hz, float seconds, float delay, float volume)
{
    if (!isfinite(hz) || !isfinite(seconds) || !isfinite(delay) || !isfinite(volume) || hz <= 0 ||
        audio_state.disabled || app_arg("mute") || !audio_open()) return;
    axAudioLock(audio_state.device);
    voice *slot = &audio_state.voices[0];   /* a free voice, else the one closest to its end */
    for (int k = 0; k < VOICES; k++) {
        voice *v = &audio_state.voices[k];
        if (v->remaining <= 0 && v->delay <= 0) { slot = v; break; }
        if (v->delay + v->remaining < slot->delay + slot->remaining) slot = v;
    }
    *slot = (voice){.freq = hz, .duration = maxf(seconds, .01f), .remaining = maxf(seconds, .01f),
                    .delay = maxf(delay, 0), .volume = clampf(volume, 0, 2)};
    axAudioUnlock(audio_state.device);
}

void sfx_tone(float hz, float seconds) { sfx_note(hz, seconds, 0, 1); }

void sfx_enable(bool on)
{
    if (audio_state.device) axAudioLock(audio_state.device);
    audio_state.disabled = !on;
    if (!on) memset(audio_state.voices, 0, sizeof audio_state.voices);
    if (audio_state.device) axAudioUnlock(audio_state.device);
}
bool sfx_enabled(void) { return !audio_state.disabled; }

/* Close before the renderer/platform are torn down; callbacks must stop first. */
void sfx_shutdown(void)
{
    if (audio_state.device) axAudioClose(audio_state.device);
    axAudioShutdown();
    memset(&audio_state, 0, sizeof audio_state);
}
