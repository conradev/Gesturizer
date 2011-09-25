#import "GRGestureController.h"

@interface SBUIController (iOS5)
- (float)_appSwitcherRevealAnimationDelay;
@end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    [GRGestureController sharedInstance];
}

%end

%hook SBUIController

// iOS 4.0-4.3
- (BOOL)_revealSwitcher:(double)duration {
    BOOL orig = %orig;
    GRGestureController *gestureController = [GRGestureController sharedInstance];
    [gestureController showSwitcherWindow:duration];
    return orig;
}

// iOS 4.3
- (BOOL)_revealSwitcher:(double)duration appOrientation:(int)orientation switcherOrientation:(int)orientation3 {
    BOOL orig = %orig;
    GRGestureController *gestureController = [GRGestureController sharedInstance];
    [gestureController showSwitcherWindow:duration];
    return orig;
}

// iOS 5
- (BOOL)_revealShowcase:(id)showcase duration:(double)duration from:(id)from to:(id)to {
    BOOL orig = %orig;
    GRGestureController *gestureController = [GRGestureController sharedInstance];
    [gestureController showSwitcherWindow:duration];
    return orig;
}

// iOS 4.0-4.3
- (void)_dismissSwitcher:(double)duration {
    GRGestureController *gestureController = [GRGestureController sharedInstance];
    [gestureController hideSwitcherWindow:duration];
    %orig;
}

// iOS 4.3
- (void)_dismissSwitcher:(double)duration unhost:(BOOL)unhost {
    GRGestureController *gestureController = [GRGestureController sharedInstance];
    [gestureController hideSwitcherWindow:duration];
    %orig;
}

// iOS 5
- (void)_dismissShowcase:(double)duration {
    GRGestureController *gestureController = [GRGestureController sharedInstance];
    [gestureController hideSwitcherWindow:duration];
    %orig;
}

// iOS 5
- (void)_dismissShowcase:(double)duration unhost:(BOOL)unhost {
    GRGestureController *gestureController = [GRGestureController sharedInstance];
    [gestureController hideSwitcherWindow:duration];
    %orig;
}

// iOS 4.0-4.3
- (void)lock {
    [[GRGestureController sharedInstance] deactivateWindow:0.0f];
    %orig;
}

// iOS 4.0-4.1?
- (void)lock:(BOOL)lock {
    [[GRGestureController sharedInstance] deactivateWindow:0.0f];
    %orig;
}

// iOS 4.0-4.1?
- (void)lock:(BOOL)lock disableLockSound:(BOOL)sound {
    [[GRGestureController sharedInstance] deactivateWindow:0.0f];
    %orig;
}

// iOS 4.0-4.3
- (void)lockWithType:(int)type {
    [[GRGestureController sharedInstance] deactivateWindow:0.0f];
    %orig;
}

// iOS 4.0-4.3
- (void)lockWithType:(int)type disableLockSound:(BOOL)sound {
    [[GRGestureController sharedInstance] deactivateWindow:0.0f];
    %orig;
}

// iOS 5
- (void)cleanUpOnFrontLocked {
    [[GRGestureController sharedInstance] deactivateWindow:0.0f];
    %orig;
}

// iOS 4.0-5.0
-(void)window:(id)window willAnimateRotationToInterfaceOrientation:(int)interfaceOrientation duration:(double)duration {
    GRGestureController *gestureController = [GRGestureController sharedInstance];
    [gestureController updateSwitcherWindow:duration orientation:interfaceOrientation];
    %orig;
}

%end
