/* Feedback-tone synthesiser; silent games never open the stereo device. */
#include "engine.h"
#include <string.h>

#define AUDIO_RATE 44100
static struct {
    int device;
    bool tried, disabled;
    float phase, freq, remaining, duration;
} audio_state;

static void audio_mix(void *user, uint8_t *stream, int length)
{
    (void)user;
    memset(stream, 0, length);
    int16_t *out = (int16_t *)stream;
    for (int i = 0; i < length / 4; i++) {
        if (audio_state.disabled) continue;
        int sample = 0;
        if (audio_state.remaining > 0) {
            float env = audio_state.remaining / audio_state.duration;
            float attack = minf(1, (audio_state.duration - audio_state.remaining) / .006f);
            float tone = (sinf(audio_state.phase) + .22f * sinf(audio_state.phase * 2) + .1f * sinf(audio_state.phase * 3)) * powf(env, 1.6f) * attack * .06f;
            sample = (int)(tone * 32767);
            audio_state.phase += 2 * ENGINE_PI * audio_state.freq / AUDIO_RATE;
            audio_state.remaining -= 1.0f / AUDIO_RATE;
        }
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
    if (!on) audio_state.remaining = 0;
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
