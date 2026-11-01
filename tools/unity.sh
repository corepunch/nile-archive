#!/bin/sh
# Emit a unity translation unit on stdout; only Xcode writes it to disk.
set -eu
case "${1:-}" in
    engine) cat <<'UNITY'
/* Engine unity unit. Compile this, never its included modules separately. */
#include "core.c"
#include "render.c"
#include "gfx.c"
#include "font.c"
#include "ui.c"
#include "save.c"
#include "city.c"
#include "audio.c"
#include "story.c"
#include "sprite.c"
#include "nav.c"
#include "raster.c"
#include "photo.c"
UNITY
        ;;
    script) cat <<'UNITY'
/* Game scripting and generated API bindings. */
#include "script_modules.c"
#include "script.c"
#include "api_lua.c"
UNITY
        ;;
    lua) cat <<'UNITY'
/* Keep third-party Lua internals isolated from the engine's static symbols. */
#include "lua_lib.c"
UNITY
        ;;
    platform) cat <<'UNITY'
/* Shared platform unity unit; compile as Objective-C on Apple targets. */
#define HAVE_WINDOWING 1
#define GL_SILENCE_DEPRECATION
#include "third_party/platform/platform.h"
#if defined(__APPLE__)
#ifdef AX_PLATFORM_IOS
#include "third_party/platform/ios/ios_message_queue.m"
#include "third_party/platform/ios/ios_event.m"
#include "third_party/platform/ios/ios_system.m"
#include "third_party/platform/ios/ios_window.m"
#else
#include "third_party/platform/macos/macos_event.m"
#include "third_party/platform/macos/macos_file_dialog.m"
#include "third_party/platform/macos/macos_joystick.m"
#include "third_party/platform/macos/macos_menu.m"
#include "third_party/platform/macos/macos_system.m"
#include "third_party/platform/macos/macos_window.m"
#endif
#elif defined(__EMSCRIPTEN__)
#include "third_party/platform/webgl/webgl_event.c"
#include "third_party/platform/webgl/webgl_joystick.c"
#include "third_party/platform/webgl/webgl_log.c"
#include "third_party/platform/webgl/webgl_net.c"
#include "third_party/platform/webgl/webgl_system.c"
#include "third_party/platform/webgl/webgl_window.c"
#elif defined(ENGINE_WAYLAND)
#include "third_party/platform/wayland/wayland_egl.c"
#include "third_party/platform/wayland/wayland_event.c"
#include "third_party/platform/wayland/wayland_system.c"
#include "third_party/platform/wayland/wayland_window.c"
#include "third_party/platform/wayland/xdg-shell-client.c"
#else
#include "third_party/platform/x11/x11_egl.c"
#include "third_party/platform/x11/x11_event.c"
#include "third_party/platform/x11/x11_system.c"
#include "third_party/platform/x11/x11_window.c"
#endif
#ifndef __EMSCRIPTEN__
#include "third_party/platform/unix/unix_joystick.c"
#include "third_party/platform/unix/unix_log.c"
#include "third_party/platform/unix/unix_net.c"
#include "third_party/platform/unix/unix_rc.c"
/* axListDir zero-initializes its record before copying the bounded name.
 * GCC diagnoses that upstream strncpy even though its last byte stays zero. */
#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wstringop-truncation"
#endif
#include "third_party/platform/unix/unix_shared.c"
#if defined(__GNUC__) && !defined(__clang__)
#pragma GCC diagnostic pop
#endif
#endif
#include "third_party/platform/unix/unix_thread.c"
#ifdef __EMSCRIPTEN__
#include "web_audio.c"
#else
#include "third_party/platform/audio/audio_backend.c"
#endif
#include "third_party/platform/audio/audio_wav.c"
UNITY
        ;;
    launcher) cat <<'UNITY'
/* Per-game entry point; GAME_DIR selects the bundled Lua game. */
#include "launcher.c"
UNITY
        ;;
    *) echo "usage: $0 {engine|script|lua|platform|launcher}" >&2; exit 1 ;;
esac
