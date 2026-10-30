/* WebAudio device for platform's mixer (its upstream WebGL backend is silent).
 * All mixing stays in ax_audio_device_fill, in the same format as native audio. */
#include "third_party/platform/audio/audio_backend.h"
#include <emscripten.h>

EMSCRIPTEN_KEEPALIVE void engine_web_audio_fill(uint8_t *data, int bytes)
{
    ax_audio_device_fill(data, bytes);
}

EM_JS(int, web_audio_open, (int freq, int channels), {
    try {
        var Audio = window.AudioContext || window.webkitAudioContext;
        if (!Audio) return 0;
        var context = new Audio({sampleRate: freq});
        if (context.sampleRate !== freq) { context.close(); return 0; }
        var frames = 1024, bytes = frames * channels * 2, ptr = _malloc(bytes);
        if (!ptr) { context.close(); return 0; }
        var node = context.createScriptProcessor(frames, 0, channels);
        var device = {context: context, node: node, ptr: ptr, paused: true};
        node.onaudioprocess = function(event) {
            if (!device.paused) _engine_web_audio_fill(ptr, bytes);
            for (var channel = 0; channel < channels; channel++) {
                var out = event.outputBuffer.getChannelData(channel);
                for (var i = 0; i < frames; i++)
                    out[i] = device.paused ? 0 : HEAP16[(ptr >> 1) + i * channels + channel] / 32768;
            }
        };
        device.resume = function() { context.resume().catch(function() {}); };
        window.addEventListener('pointerdown', device.resume, true);
        window.addEventListener('keydown', device.resume, true);
        Module['engineAudio'] = device;
        node.connect(context.destination);
        device.resume();
        return 1;
    } catch (e) { return 0; }
});

EM_JS(void, web_audio_pause, (int paused), {
    var device = Module['engineAudio'];
    if (device) { device.paused = !!paused; if (!paused) device.resume(); }
});

EM_JS(void, web_audio_close, (void), {
    var device = Module['engineAudio'];
    if (!device) return;
    device.node.disconnect(); device.node.onaudioprocess = null;
    window.removeEventListener('pointerdown', device.resume, true);
    window.removeEventListener('keydown', device.resume, true);
    device.context.close(); _free(device.ptr);
    delete Module['engineAudio'];
});

bool_t ax_audio_hw_open(int freq, int channels, int frames)
{
    (void)frames;
    return web_audio_open(freq, channels);
}
void ax_audio_hw_pause(bool_t pause) { web_audio_pause(pause); }
void ax_audio_hw_close(void) { web_audio_close(); }
