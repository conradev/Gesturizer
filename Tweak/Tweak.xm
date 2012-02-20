#import "GRGestureController.h"

#include <sys/types.h>
#include <sys/sysctl.h>

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    
    [GRGestureController sharedInstance];
    
    NSError *error;
    
    // Get device platform
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = (char *)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:machine encoding:NSUTF8StringEncoding];
    free(machine);
    
    // Get device version
    NSString *version = [[UIDevice currentDevice] systemVersion];
    
    // Set custom variables
    GRATracker *tracker = [GRATracker sharedTracker];
    [tracker setCustomVariableAtIndex:1 name:@"platform" value:platform scope:kGRAVisitorScope withError:&error];
    [tracker setCustomVariableAtIndex:2 name:@"ios_version" value:version scope:kGRAVisitorScope withError:&error];
    [tracker setCustomVariableAtIndex:3 name:@"package_version" value:@"1.0.2-1" scope:kGRAVisitorScope withError:&error];
}

%end

%hook GRAPersistentHitStore

- (id)initWithHitBuilder:(id)hitBuilder path:(id)path {
    // Store Google Analytics data in Preferences directory
    return %orig(hitBuilder, @"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.sqlite");
}

%end

%hook SBUIController

// iOS 4.0-4.3
- (BOOL)_revealSwitcher:(double)duration {
    BOOL orig = %orig;
    if (orig) {
        GRGestureController *gestureController = [GRGestureController sharedInstance];
        [gestureController showSwitcherWindow:duration];
    }
    return orig;
}

// iOS 4.3
- (BOOL)_revealSwitcher:(double)duration appOrientation:(int)orientation switcherOrientation:(int)orientation3 {
    BOOL orig = %orig;
    if (orig) {
        GRGestureController *gestureController = [GRGestureController sharedInstance];
        [gestureController showSwitcherWindow:duration];
    }
    return orig;
}

// iOS 5
- (BOOL)_revealShowcase:(id)showcase duration:(double)duration from:(id)from to:(id)to {
    BOOL orig = %orig;
    if (orig) {
        GRGestureController *gestureController = [GRGestureController sharedInstance];
        [gestureController showSwitcherWindow:duration];
    }
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