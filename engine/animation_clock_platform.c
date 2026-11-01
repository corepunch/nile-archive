/* ORCA's scalar-clock pattern; the platform unit is Objective-C on iOS. */
#include "animation_clock.h"
#include <math.h>
#if defined(AX_PLATFORM_IOS)
#import <QuartzCore/QuartzCore.h>
#include "third_party/platform/ios/ios_local.h"
#define ANIMATION_PERIOD 3600.0
@interface EngineAnimationClock : CALayer
@property(nonatomic) float timeline;
@end
@implementation EngineAnimationClock
@dynamic timeline;
- (instancetype)initWithLayer:(id)layer {
    if ((self=[super initWithLayer:layer]) && [layer isKindOfClass:[EngineAnimationClock class]])
        self.timeline=((EngineAnimationClock *)layer).timeline;
    return self;
}
+ (BOOL)needsDisplayForKey:(NSString *)key { return [key isEqualToString:@"timeline"] || [super needsDisplayForKey:key]; }
- (void)display {}
@end
static EngineAnimationClock *animation_layer;
static double animation_begin, animation_last;
static void install_animation_clock(void) {
    if ([animation_layer animationForKey:@"timeline"]) return;
    CABasicAnimation *a=[CABasicAnimation animationWithKeyPath:@"timeline"];
    a.fromValue=@0; a.toValue=@(ANIMATION_PERIOD); a.duration=ANIMATION_PERIOD;
    a.beginTime=animation_begin; a.repeatCount=HUGE_VALF; a.removedOnCompletion=NO;
    a.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    if (@available(iOS 15.0,*)) a.preferredFrameRateRange=CAFrameRateRangeMake(80,120,120);
    [animation_layer addAnimation:a forKey:@"timeline"];
}
double animation_clock_seconds(void) {
    if (!animation_layer) {
        if (!ios_view) return CACurrentMediaTime();
        animation_layer=[EngineAnimationClock new]; animation_layer.bounds=CGRectMake(0,0,1,1);
        animation_begin=CACurrentMediaTime(); animation_last=0;
        [CATransaction begin]; [CATransaction setDisableActions:YES];
        animation_layer.timeline=ANIMATION_PERIOD;
        [ios_view.layer addSublayer:animation_layer]; install_animation_clock(); [CATransaction commit];
    }
    double elapsed=MAX([animation_layer convertTime:CACurrentMediaTime() fromLayer:nil]-animation_begin,0);
    EngineAnimationClock *p=(EngineAnimationClock *)animation_layer.presentationLayer;
    if (p) {
        double sample=floor(elapsed/ANIMATION_PERIOD)*ANIMATION_PERIOD+p.timeline;
        if (sample-elapsed>ANIMATION_PERIOD/2) sample-=ANIMATION_PERIOD;
        else if (elapsed-sample>ANIMATION_PERIOD/2) sample+=ANIMATION_PERIOD;
        elapsed=sample;
    }
    animation_last=MAX(animation_last,elapsed); return animation_last;
}
void animation_clock_pause(bool paused) {
    if (!animation_layer) return;
    if (!paused) install_animation_clock();
    if ((animation_layer.speed==0)==paused) return;
    if (paused) { double t=[animation_layer convertTime:CACurrentMediaTime() fromLayer:nil]; animation_layer.speed=0; animation_layer.timeOffset=t; }
    else { double t=animation_layer.timeOffset; animation_layer.speed=1; animation_layer.timeOffset=0; animation_layer.beginTime=0;
        animation_layer.beginTime=[animation_layer convertTime:CACurrentMediaTime() fromLayer:nil]-t; }
}
void animation_clock_reset(void) {
    [animation_layer removeAllAnimations]; [animation_layer removeFromSuperlayer];
    AXIOS_RELEASE(animation_layer); animation_layer=nil; animation_begin=animation_last=0;
}
#else
double animation_clock_seconds(void) { return axGetMilliseconds()/1000.0; }
void animation_clock_pause(bool paused) { (void)paused; }
void animation_clock_reset(void) {}
#endif
