#import "GRGestureRecognizer.h"
#import "GRGestureController.h"

@interface SBAwayViewPluginController : NSObject {
        UIView *_view;
        BOOL _viewCanBeDisplayed;
        BOOL _fullscreen;
        BOOL _alwaysFullscreen;
        int _orientation;
}

+ (void)enableBundleNamed:(id)arg1;
+ (void)disableBundleNamed:(id)arg1;
- (id)init;
- (void)dealloc;
@property(retain, nonatomic) UIView *view;
- (void)loadView;
- (void)purgeView;
@property(nonatomic) BOOL viewCanBeDisplayed; // @synthesize viewCanBeDisplayed=_viewCanBeDisplayed;
- (void)viewWillAppear:(BOOL)arg1;
- (void)viewDidAppear:(BOOL)arg1;
- (void)viewWillDisappear:(BOOL)arg1;
- (void)viewDidDisappear:(BOOL)arg1;
- (void)disable;
- (void)setFullscreen:(BOOL)arg1 animated:(BOOL)arg2;
- (void)setFullscreen:(BOOL)arg1 duration:(double)arg2;
- (BOOL)viewWantsFullscreenLayout;
- (BOOL)shouldDisableOnRelock;
- (BOOL)shouldDisableOnUnlock;
- (BOOL)shouldShowLockStatusBarTime;
- (double)viewFadeInDuration;
- (void)setAlwaysFullscreen:(BOOL)arg1;
@property(readonly, nonatomic, getter=isAlwaysFullscreen) BOOL alwaysFullscreen;
- (BOOL)canBeAlwaysFullscreen;
- (void)alwaysFullscreenValueHasChanged;
- (void)deviceLockViewWillShow;
- (void)deviceLockViewDidHide;
- (BOOL)retainsPriorityWhileInactive;
- (int)pluginPriority;
- (BOOL)animateResumingToApplicationWithIdentifier:(id)arg1;
- (BOOL)showAwayItems;
- (BOOL)showDateView;
- (BOOL)canScreenDim;
- (BOOL)handleMenuButtonTap;
- (BOOL)handleMenuButtonDoubleTap;
- (BOOL)wantsMenuButtonHeldEvent;
- (BOOL)handleMenuButtonHeld;
- (BOOL)handleGesture:(int)arg1 fingerCount:(unsigned int)arg2;
- (BOOL)wantsAutomaticFullscreenTimer;
- (BOOL)wantsSwipeGestureRecognizer;
@property(nonatomic) int orientation; // @synthesize orientation=_orientation;
@property(readonly, nonatomic, getter=isFullscreen) BOOL fullscreen; // @synthesize fullscreen=_fullscreen;

@end

@interface GRLockScreenController  : SBAwayViewPluginController  {
    GRGestureRecognizer *_gestureRecognizer;
}

@property (nonatomic, retain) GRGestureRecognizer *gestureRecognizer;

@end
