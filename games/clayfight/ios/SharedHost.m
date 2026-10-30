#import "NativeHost.h"
#import <GameController/GameController.h>
#include <unistd.h>
extern void clay_suspend(int);
static BOOL initialized;
static UIView *overlay;
NSString *CFStoragePath(void) {return [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory,NSUserDomainMask,YES).firstObject stringByAppendingPathComponent:@"Clayfight"];}
NSString *CFCreaturesPath(void) {return [CFStoragePath() stringByAppendingPathComponent:@"creatures"];}
void CFSuspendGame(BOOL value) {clay_suspend(value);if(!value)overlay.hidden=NO;}
static UIViewController *root(void) {
    for(UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes)
        if([scene isKindOfClass:UIWindowScene.class])for(UIWindow *window in scene.windows)if(window.isKeyWindow)return window.rootViewController;
    return nil;
}
void CFPresentCreator(void) {
    UIViewController *r=root();if(!r||r.presentedViewController)return;
    CFSuspendGame(YES);overlay.hidden=YES;
    CFCaptureController *capture=[CFCaptureController new];capture.modalPresentationStyle=UIModalPresentationFullScreen;
    [r presentViewController:capture animated:YES completion:nil];
}
@interface ClayControls : NSObject
@end
static ClayControls *controls;
@implementation ClayControls
- (void)down:(UIButton*)b {event_t e={ev_keydown,(int)b.tag};D_PostEvent(&e);}
- (void)up:(UIButton*)b {event_t e={ev_keyup,(int)b.tag};D_PostEvent(&e);}
- (void)inactive {CFSuspendGame(YES);}
- (void)active {CFSuspendGame(NO);}
@end
const char *clay_ios_prepare(const char *data) {
    NSFileManager *fm=NSFileManager.defaultManager;
    [fm createDirectoryAtPath:[CFStoragePath() stringByAppendingPathComponent:@"build"] withIntermediateDirectories:YES attributes:nil error:nil];
    [fm createDirectoryAtPath:CFCreaturesPath() withIntermediateDirectories:YES attributes:nil error:nil];
    NSString *defaults=[@(data) stringByAppendingPathComponent:@"creatures"];
    for(NSString *name in [fm contentsOfDirectoryAtPath:defaults error:nil]) {
        NSString *dst=[CFCreaturesPath() stringByAppendingPathComponent:name];
        if(![fm fileExistsAtPath:dst])[fm copyItemAtPath:[defaults stringByAppendingPathComponent:name] toPath:dst error:nil];
    }
    chdir(CFStoragePath().fileSystemRepresentation);
    return CFCreaturesPath().fileSystemRepresentation;
}
void clay_ios_controls(void) {
    if(initialized)return;initialized=YES;controls=[ClayControls new];
    UIView *view=root().view;CGFloat width=view.bounds.size.width,height=view.bounds.size.height;
    overlay=[[UIView alloc]initWithFrame:CGRectMake(0,height-115,width,115)];overlay.autoresizingMask=UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;overlay.multipleTouchEnabled=YES;[view addSubview:overlay];
    NSArray *labels=@[@"↑",@"↓",@"←",@"→",@"HQ",@"HF",@"LQ",@"LF",@"SELECT",@"BACK",@"MENU"];
    int keys[]={'w','s','a','d','r','t','f','g',13,27,'q'};
    CGFloat w=MIN(68,(width-40)/6),gap=5;
    for(int i=0;i<11;i++) {
        CGFloat x=15+(i%6)*(w+gap),y=(i/6)*52;
        UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];b.frame=CGRectMake(x,y,w,47);b.tag=keys[i];[b setTitle:labels[i] forState:UIControlStateNormal];b.backgroundColor=[UIColor colorWithWhite:.1 alpha:.9];b.tintColor=UIColor.whiteColor;b.layer.cornerRadius=8;
        [b addTarget:controls action:@selector(down:) forControlEvents:UIControlEventTouchDown];[b addTarget:controls action:@selector(up:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];[overlay addSubview:b];
    }
    [NSNotificationCenter.defaultCenter addObserver:controls selector:@selector(inactive) name:UIApplicationWillResignActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:controls selector:@selector(active) name:UIApplicationDidBecomeActiveNotification object:nil];
}
void clay_ios_resume_overlay(void) {overlay.hidden=NO;}
void clay_creator_config(const char *s,const char *e) {}
bool I_StartCreator(const char *c,const char *d) {return true;}
int I_CreatorStatus(void) {return 1;}
const char *I_CreatorURL(bool phone) {return "";}
void I_OpenCreator(void) {CFPresentCreator();}
void I_CloseCreator(void) {}
