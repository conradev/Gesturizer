#import "GRGestureController.h"

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    [GRGestureController sharedInstance];
}

%end
