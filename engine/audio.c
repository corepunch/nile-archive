/* Shared 16-voice unsigned 8-bit PCM mixer and feedback-tone synthesiser.
 * One lazy stereo device serves both; silent games never open audio. */
#include "engine.h"
#include <string.h>

#define AUDIO_RATE 44100
#define AUDIO_VOICES 16

typedef struct {
    sfx_sample sample;
    uint64_t pos, step;           /* 16.16 source position */
    int left, right;              /* 0..256 */
} audio_voice;
static struct {
    int device;
    bool tried, disabled;
    float phase, freq, remaining, duration;
    audio_voice voices[AUDIO_VOICES];
} audio_state;

static void audio_mix(void *user, uint8_t *stream, int length)
{
    (void)user;
    memset(stream, 0, length);
    int16_t *out = (int16_t *)stream;
    for (int i = 0; i < length / 4; i++) {
        if (audio_state.disabled) continue;
        int l = 0, r = 0;
        for (int c = 0; c < AUDIO_VOICES; c++) {
            audio_voice *v = &audio_state.voices[c];
            if (!v->sample.data) continue;
            uint64_t idx = v->pos >> 16;
            if (idx >= (uint64_t)v->sample.length) {
                v->sample.data = NULL;
                continue;
            }
            int s = (v->sample.data[idx] - 128) * 256;
            l += (s * v->left) >> 8;
            r += (s * v->right) >> 8;
            v->pos += v->step;
        }
        if (audio_state.remaining > 0) {
            float env = audio_state.remaining / audio_state.duration;
            float attack = minf(1, (audio_state.duration - audio_state.remaining) / .006f);
            float tone = (sinf(audio_state.phase) + .22f * sinf(audio_state.phase * 2) + .1f * sinf(audio_state.phase * 3)) * powf(env, 1.6f) * attack * .06f;
            l += (int)(tone * 32767); r += (int)(tone * 32767);
            audio_state.phase += 2 * ENGINE_PI * audio_state.freq / AUDIO_RATE;
            audio_state.remaining -= 1.0f / AUDIO_RATE;
        }
        out[i * 2] = (int16_t)clampi(l, -32768, 32767);
        out[i * 2 + 1] = (int16_t)clampi(r, -32768, 32767);
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

void sfx_play(sfx_sample sample, float volume, float pan)
{
    if (!sample.data || sample.length <= 0 || sample.rate <= 0 || !isfinite(volume) || !isfinite(pan) ||
        audio_state.disabled || app_arg("mute") || !audio_open()) return;
    axAudioLock(audio_state.device);
    int best = 0;
    uint64_t bestpos = 0;
    for (int c = 0; c < AUDIO_VOICES; c++) {
        audio_voice *v = &audio_state.voices[c];
        if (!v->sample.data || (v->pos >> 16) >= (uint64_t)v->sample.length) { best = c; break; }
        if (v->pos > bestpos) { bestpos = v->pos; best = c; }
    }
    volume = clampf(volume, 0, 1); pan = clampf(pan, -1, 1);
    audio_state.voices[best] = (audio_voice){sample, 0, ((uint64_t)sample.rate << 16) / AUDIO_RATE,
        (int)(256 * volume * (pan > 0 ? 1 - pan : 1)),
        (int)(256 * volume * (pan < 0 ? 1 + pan : 1))};
    axAudioUnlock(audio_state.device);
}

void sfx_stop_samples(void)
{
    if (audio_state.device) axAudioLock(audio_state.device);
    memset(audio_state.voices, 0, sizeof audio_state.voices);
    if (audio_state.device) axAudioUnlock(audio_state.device);
}

void sfx_tone(float hz, float seconds)
{
    if (!isfinite(hz) || !isfinite(seconds) || hz <= 0 ||
        audio_state.disabled || app_arg("mute") || !audio_open()) return;
    axAudioLock(audio_state.device);
    audio_state.freq = hz;
    audio_state.duration = audio_state.remaining = maxf(seconds, .01f);
    axAudioUnlock(audio_state.device);
}

void sfx_enable(bool on)
{
    if (audio_state.device) axAudioLock(audio_state.device);
    audio_state.disabled = !on;
    if (!on) {
        memset(audio_state.voices, 0, sizeof audio_state.voices);
        audio_state.remaining = 0;
    }
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
