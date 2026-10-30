#import <GameController/GameController.h>
#include "source/game/game.h"
#import <TargetConditionals.h>
#include <unistd.h>
static GCController *pads[2];
static bool state[2][10];
static void update(int i) {
    GCExtendedGamepad *g=pads[i].extendedGamepad;if(!g)return;
    bool down[]={g.dpad.up.pressed||g.leftThumbstick.yAxis.value>.5,
        g.dpad.down.pressed||g.leftThumbstick.yAxis.value<-.5,
        g.dpad.left.pressed||g.leftThumbstick.xAxis.value<-.5,
        g.dpad.right.pressed||g.leftThumbstick.xAxis.value>.5,
        g.buttonX.pressed,g.buttonY.pressed,g.buttonA.pressed,g.buttonB.pressed,
        g.buttonMenu.pressed,g.buttonOptions.pressed};
    for(int k=0;k<10;k++)if(down[k]!=state[i][k]){state[i][k]=down[k];event_t e={down[k]?ev_keydown:ev_keyup,PADKEY(i,k)};D_PostEvent(&e);}
}
static void connect_pad(GCController *c) {
    if(!c.extendedGamepad)return;
    for(int i=0;i<2;i++)if(pads[i]==c)return;
    for(int i=0;i<2;i++)if(!pads[i]){pads[i]=c;c.handlerQueue=dispatch_get_main_queue();c.extendedGamepad.valueChangedHandler=^(GCExtendedGamepad *g,GCControllerElement *e){update(i);};break;}
}
void clay_controllers_init(void) {
    for(GCController *c in GCController.controllers)connect_pad(c);
    [NSNotificationCenter.defaultCenter addObserverForName:GCControllerDidConnectNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *n){connect_pad(n.object);}];
    [NSNotificationCenter.defaultCenter addObserverForName:GCControllerDidDisconnectNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification *n){for(int i=0;i<2;i++)if(pads[i]==n.object){for(int k=0;k<10;k++)if(state[i][k]){state[i][k]=false;event_t e={ev_keyup,PADKEY(i,k)};D_PostEvent(&e);}pads[i]=nil;}}];
}

#if !TARGET_OS_IPHONE
/* Bundles are read-only. Keep workshop publications and options in user storage. */
const char *clay_macos_prepare(const char *data) {
    NSFileManager *fm=NSFileManager.defaultManager;
    NSString *storage=[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:@"Clayfight"];
    NSString *creatures=[storage stringByAppendingPathComponent:@"creatures"];
    [fm createDirectoryAtPath:[storage stringByAppendingPathComponent:@"build"] withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createDirectoryAtPath:creatures withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *defaults=[@(data) stringByAppendingPathComponent:@"creatures"];
    for(NSString *name in [fm contentsOfDirectoryAtPath:defaults error:nil]) {
        NSString *dst=[creatures stringByAppendingPathComponent:name];
        if(![fm fileExistsAtPath:dst])[fm copyItemAtPath:[defaults stringByAppendingPathComponent:name] toPath:dst error:nil];
    }
    chdir(storage.fileSystemRepresentation);
    return creatures.fileSystemRepresentation;
}
void clay_macos_creator(void) {
    extern void clay_creator_config(const char *,const char *);
    NSString *script=[NSBundle.mainBundle.resourcePath stringByAppendingPathComponent:@"tools/capture_server.py"];
    clay_creator_config(script.fileSystemRepresentation,NSBundle.mainBundle.executablePath.fileSystemRepresentation);
}
#endif
