/* How to Hook with Logos
Hooks are written with syntax similar to that of an Objective-C @implementation.
You don't need to #include <substrate.h>, it will be done automatically, as will
the generation of a class list and an automatic constructor.
*/

#import <UIKit/UIKit.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

@interface UIApplication (Gesturizer)
- (void)reloadGesturizerSettings;
@end

@interface GRLongPressGestureRecognizer : UILongPressGestureRecognizer @end
@implementation GRLongPressGestureRecognizer @end

static BOOL longPressEnabled;
static float minimumPressDuration;

static int currentPathIndex;

void receivedReloadSettingsNotfication  (CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[UIApplication sharedApplication] reloadGesturizerSettings];
}

%hook UIWindow

- (void)becomeKeyWindow {
    Class $GRWindow = objc_getClass("GRWindow");
    if ($GRWindow) {
        if ([self isKindOfClass:$GRWindow]) {
            return;
        }
    }

    for (UIGestureRecognizer *gestureRecognizer in [self gestureRecognizers]) {
        if ([gestureRecognizer isKindOfClass:[GRLongPressGestureRecognizer class]]) {
            [self removeGestureRecognizer:gestureRecognizer];
        }
    }
    if (longPressEnabled) {
        GRLongPressGestureRecognizer *longPressRecognizer = [[GRLongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressFired:)];
        longPressRecognizer.cancelsTouchesInView = YES;
        longPressRecognizer.delaysTouchesBegan = NO;
        longPressRecognizer.delaysTouchesEnded = YES;
        longPressRecognizer.minimumPressDuration = minimumPressDuration;
        [self addGestureRecognizer:longPressRecognizer];
    }
}

- (void)resignKeyWindow {
    Class $GRWindow = objc_getClass("GRWindow");
    if ($GRWindow) {
        if ([self isKindOfClass:$GRWindow]) {
            return;
        }
    }

    for (UIGestureRecognizer *gestureRecognizer in [self gestureRecognizers]) {
        if ([gestureRecognizer isKindOfClass:[GRLongPressGestureRecognizer class]]) {
            [self removeGestureRecognizer:gestureRecognizer];
        }
    }
}

%new(v@:@)
- (void)longPressFired:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint touchPoint = [gestureRecognizer locationInView:nil];
    CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"org.thebigboss.gesturizer.uikit"];
    [messagingCenter sendMessageName:@"longPress" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:touchPoint.x], @"x", [NSNumber numberWithFloat:touchPoint.y], @"y", [NSNumber numberWithInt:currentPathIndex], @"pathIndex", nil]];
}

%end

%hook UIApplication

- (void)_reportAppLaunchFinished {
    NSLog(@"Application did finish launching");
    %orig;
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&receivedReloadSettingsNotfication, CFSTR("org.thebigboss.gesturizer.settings"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    [self reloadGesturizerSettings];
}

%new(v@:)
- (void)reloadGesturizerSettings {
    longPressEnabled = YES;
    minimumPressDuration = 0.5f;
    NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.plist"];
    for (NSString *key in [settingsDict allKeys]) {
        if ([key isEqualToString:@"GRLongPressEnabled"]) {
            longPressEnabled = [[settingsDict objectForKey:key] boolValue];
        } else if ([key isEqualToString:@"GRLongPressMinDuration"]) {
            minimumPressDuration = [[settingsDict objectForKey:key] floatValue];
        }
    }

    NSArray *windows = [self windows];
    for (UIWindow *window in windows) {
        for (UIGestureRecognizer *gestureRecognizer in [window gestureRecognizers]) {
            if ([gestureRecognizer isKindOfClass:[GRLongPressGestureRecognizer class]]) {
                [window removeGestureRecognizer:gestureRecognizer];
            }
        }
    }

    if (longPressEnabled) {
        for (UIWindow *window in windows) {
            GRLongPressGestureRecognizer *longPressRecognizer = [[GRLongPressGestureRecognizer alloc] initWithTarget:window action:@selector(longPressFired:)];
            longPressRecognizer.cancelsTouchesInView = YES;
            longPressRecognizer.delaysTouchesBegan = NO;
            longPressRecognizer.delaysTouchesEnded = YES;
            longPressRecognizer.minimumPressDuration = minimumPressDuration;
            [window addGestureRecognizer:longPressRecognizer];
        }
    }
}

- (BOOL)handleEvent:(GSEventRef)event {
    if (GSEventIsHandEvent(event)) {
        GSHandInfo handInfo = GSEventGetHandInfo(event);
        NSLog(@"CBK ::: Hand Info Type: %i", handInfo.type);
        GSPathInfo pathInfo = GSEventGetPathInfoAtIndex(event, 0);
        currentPathIndex = (int)pathInfo.pathIndex;
    }
    return %orig;
}

- (BOOL)handleEvent:(GSEventRef)event withNewEvent:(id)newEvent {
    if (GSEventIsHandEvent(event)) {
        GSHandInfo handInfo = GSEventGetHandInfo(event);
        NSLog(@"CBK ::: Hand Info Type: %i", handInfo.type);
        GSPathInfo pathInfo = GSEventGetPathInfoAtIndex(event, 0);
        currentPathIndex = (int)pathInfo.pathIndex;
    }
    return %orig;
}

%end
