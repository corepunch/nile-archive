/* audio.c — a one-voice synthesiser: short bell-like tones for game feedback.
 * The device opens on the first note, so silent games never touch audio. */
#include "engine.h"

static struct {
    int device;
    bool tried, disabled;
    float phase, freq, remaining, duration;
} audio_state;

static void callback(void *user, uint8_t *stream, int length)
{
    (void)user;
    float *out = (float *)stream;
    int n = length / (int)sizeof(float);
    for (int i = 0; i < n; i++) {
        if (audio_state.remaining <= 0) {
            out[i] = 0;
            continue;
        }
        float env = audio_state.remaining / audio_state.duration, attack = minf(1, (audio_state.duration - audio_state.remaining) / .006f);
        out[i] = (sinf(audio_state.phase) + .22f * sinf(audio_state.phase * 2) + .1f * sinf(audio_state.phase * 3)) * powf(env, 1.6f) * attack * .06f;
        audio_state.phase += 2 * ENGINE_PI * audio_state.freq / 44100;
        audio_state.remaining -= 1.0f / 44100;
    }
}

static bool open_device(void)
{
    if (audio_state.tried) return audio_state.device != 0;
    audio_state.tried = true;
    if (!axAudioInit()) return false;
    AXaudiospec want = {.freq = 44100, .format = AX_AUDIO_F32, .channels = 1, .samples = 1024, .callback = callback}, got;
    audio_state.device = axAudioOpen(&want, &got);
    if (audio_state.device) axAudioPause(audio_state.device, 0);
    return audio_state.device != 0;
}

void sfx_tone(float hz, float seconds)
{
    if (audio_state.disabled || app_arg("mute") || !open_device()) return;
    axAudioLock(audio_state.device);
    audio_state.freq = hz;
    audio_state.duration = audio_state.remaining = maxf(seconds, .01f);
    axAudioUnlock(audio_state.device);
}

void sfx_enable(bool on) { audio_state.disabled = !on; }
bool sfx_enabled(void) { return !audio_state.disabled; }

/* Close before the renderer/platform are torn down; callbacks must stop first. */
void sfx_shutdown(void)
{
    if (audio_state.device) axAudioClose(audio_state.device);
    axAudioShutdown();
    audio_state.device = 0;
    audio_state.tried = false;
}
