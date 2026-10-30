/* launcher.c — main() for a Lua game: games/<name>/lua/main.lua on the engine.
 *
 * Built once per game with -DGAME_DIR="games/<name>": the game's assets are
 * GAME_DIR/data and its scripts GAME_DIR/lua (--data and --lua override them;
 * the web build preloads both as /data and /lua). The Xcode projects define
 * GAME_IN_BUNDLE: lua/ and data/ are then found inside the app bundle. */
#include "engine.h"

#include <stdio.h>
#include <string.h>

#ifndef GAME_DIR
#define GAME_DIR "."
#endif
#ifndef GAME_DATA_DIR
#define GAME_DATA_DIR GAME_DIR "/data"
#endif
#ifndef GAME_LUA_DIR
#define GAME_LUA_DIR GAME_DIR "/lua"
#endif

int main(int argc, char **argv)
{
    const char *lua_dir = GAME_LUA_DIR, *data_dir = GAME_DATA_DIR;
#ifdef GAME_IN_BUNDLE
    static char lua_path[1024], data_path[1024];
    char *base = SDL_GetBasePath();   /* the bundle's resources, ending with a slash */
    if (base) {
        snprintf(lua_path, sizeof lua_path, "%slua", base);
        snprintf(data_path, sizeof data_path, "%sdata", base);
        lua_dir = lua_path, data_dir = data_path;
        SDL_free(base);
    }
#endif
    for (int i = 1; i + 1 < argc; i++)   /* app_arg needs the app; the script root is needed first */
        if (!strcmp(argv[i], "--lua")) lua_dir = argv[i + 1];
    app_desc desc = script_boot(lua_dir, data_dir);
    int status = app_run(desc, argc, argv);
    script_close();
    return status;
}
