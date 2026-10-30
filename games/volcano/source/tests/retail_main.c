/* Retail regression runner. Requires the original Rescue Team resources:
 *   build/test_retail reference/rescue-team
 * Mission and core suites run without them. */
#include "game_test.h"
#include <stdio.h>
#include <string.h>

int main(int argc,char **argv)
{
    if (argc<2 || argc>3 || (argc==3 && strcmp(argv[2],"--fire"))) {
        fprintf(stderr,"Usage: %s RETAIL_ASSET_FOLDER [--fire]\n",argv[0]);return 2;
    }
    const char *mounts[]={argv[1],"assets/particles"};
    bool ok=test_startup(mounts,2) && (argc==3?game_fire_selftest():
        assets_selftest() && retail_level_selftest() && game_selftest());
    if (!ok) fprintf(stderr,"%s\n",last_error[0]?last_error:"Retail regression failed");
    test_shutdown();
    return ok?0:1;
}
