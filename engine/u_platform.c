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
#include "third_party/platform/unix/unix_shared.c"
#endif
#include "third_party/platform/unix/unix_thread.c"
#ifdef __EMSCRIPTEN__
#include "web_audio.c"
#else
#include "third_party/platform/audio/audio_backend.c"
#endif
#include "third_party/platform/audio/audio_wav.c"
