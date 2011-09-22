#import "GRGestureController.h"

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    [GRGestureController sharedInstance];
}

%end

%hook SBUIController

- (void)applicationHideSwitcherGestureRecognized {
    return;
}

- (BOOL)_revealSwitcher:(double)duration {
    BOOL orig = %orig;
    GRGestureController *gestureController = [GRGestureController sharedInstance];
    [gestureController showSwitcherWindow:duration];
    return orig;
}

- (BOOL)_revealSwitcher:(double)duration appOrientation:(int)orientation switcherOrientation:(int)orientation3 {
    BOOL orig = %orig;
    GRGestureController *gestureController = [GRGestureController sharedInstance];
    [gestureController showSwitcherWindow:duration];
    return orig;
}

- (void)_dismissSwitcher:(double)duration {
    GRGestureController *gestureController = [GRGestureController sharedInstance];
    [gestureController hideSwitcherWindow:duration];
    %orig;
}

- (void)_dismissSwitcher:(double)duration unhost:(BOOL)unhost {
    GRGestureController *gestureController = [GRGestureController sharedInstance];
    [gestureController hideSwitcherWindow:duration];
    %orig;
}

-(void)window:(id)window willAnimateRotationToInterfaceOrientation:(int)interfaceOrientation duration:(double)duration {
    %orig;
    GRGestureController *gestureController = [GRGestureController sharedInstance];
    [gestureController updateSwitcherWindow:duration orientation:interfaceOrientation];
}

%end
