/* audio.c — a one-voice synthesiser: short bell-like tones for game feedback.
 * The device opens on the first note, so silent games never touch audio. */
#include "engine.h"

static struct {
    SDL_AudioDeviceID device;
    bool tried, disabled;
    float phase, freq, remaining, duration;
} S;

static void callback(void *user, Uint8 *stream, int length)
{
    (void)user;
    float *out = (float *)stream;
    int n = length / (int)sizeof(float);
    for (int i = 0; i < n; i++) {
        if (S.remaining <= 0) {
            out[i] = 0;
            continue;
        }
        float env = S.remaining / S.duration, attack = minf(1, (S.duration - S.remaining) / .006f);
        out[i] = (sinf(S.phase) + .22f * sinf(S.phase * 2) + .1f * sinf(S.phase * 3)) * powf(env, 1.6f) * attack * .06f;
        S.phase += 2 * ENGINE_PI * S.freq / 44100;
        S.remaining -= 1.0f / 44100;
    }
}

static bool open_device(void)
{
    if (S.tried) return S.device != 0;
    S.tried = true;
    if (SDL_InitSubSystem(SDL_INIT_AUDIO) != 0) return false;
    SDL_AudioSpec want = {.freq = 44100, .format = AUDIO_F32SYS, .channels = 1, .samples = 1024, .callback = callback}, got;
    S.device = SDL_OpenAudioDevice(NULL, 0, &want, &got, 0);
    if (S.device) SDL_PauseAudioDevice(S.device, 0);
    return S.device != 0;
}

void sfx_tone(float hz, float seconds)
{
    if (S.disabled || app_arg("mute") || !open_device()) return;
    SDL_LockAudioDevice(S.device);
    S.freq = hz;
    S.duration = S.remaining = maxf(seconds, .01f);
    SDL_UnlockAudioDevice(S.device);
}

void sfx_enable(bool on) { S.disabled = !on; }
bool sfx_enabled(void) { return !S.disabled; }
