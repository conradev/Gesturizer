#import "GRRootListController.h"

#import "GRGestureDetailListController.h"

GRRootListController *sharedInstance = nil;

void receivedReloadSettingsNotfication  (CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[GRRootListController sharedInstance] reloadGestures];
}

@implementation GRRootListController

+ (void)load {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&receivedReloadSettingsNotfication, CFSTR("org.thebigboss.gesturizer.settings"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

+ (id)sharedInstance {
    return sharedInstance;
}

- (id)init {
    if ((self = [super init])) {
        sharedInstance = self;
    }
    return self;
}

- (void)dealloc {
    sharedInstance = nil;
    [super dealloc];
}

- (id)specifiers {
	if(_specifiers == nil) {
		NSMutableArray *mutSpecs = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"RootListController" target:self]];
        NSMutableArray *mutGestureSpecs = [NSMutableArray array];

        NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.plist"];
        NSDictionary *gestures = [settingsDict objectForKey:@"gestures"];

        for (NSString *gestureID in [gestures allKeys]) {
            NSDictionary *gesture = [gestures objectForKey:gestureID];
            if (gesture) {
                PSSpecifier *gestureSpecifier = [PSSpecifier preferenceSpecifierNamed:[gesture objectForKey:@"name"] target:self set:NULL get:NULL detail:[GRGestureDetailListController class] cell:PSLinkCell edit:Nil];
                if (gestureSpecifier) {
                    [gestureSpecifier setProperty:gestureID forKey:@"gestureID"];
                    [mutGestureSpecs addObject:gestureSpecifier];
                }
            }
        }

        gestureSpecifiers = [mutGestureSpecs copy];

        NSIndexSet *specifierIndexes = nil;
        for (PSSpecifier *spec in mutSpecs) {
            NSString *specID = [[spec properties] objectForKey:@"id"];
	        if ([specID isEqualToString:@"gestureGroup"]) {
		        int startIndex = [mutSpecs indexOfObject:spec] + 1;
                NSRange specifierRange = NSMakeRange(startIndex, [gestureSpecifiers count]);
                specifierIndexes = [NSIndexSet indexSetWithIndexesInRange:specifierRange];
                break;
            }
        }
        [mutSpecs insertObjects:gestureSpecifiers atIndexes:specifierIndexes];

        _specifiers = [mutSpecs copy];
    }
    return _specifiers;
}

- (void)reloadGestures {
    NSMutableArray *newGestures = [NSMutableArray array];

    NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.plist"];
    NSDictionary *gestures = [settingsDict objectForKey:@"gestures"];

    for (NSString *gestureID in [gestures allKeys]) {
        NSDictionary *gesture = [gestures objectForKey:gestureID];
        if (gesture) {
            PSSpecifier *gestureSpecifier = [PSSpecifier preferenceSpecifierNamed:[gesture objectForKey:@"name"] target:self set:NULL get:NULL detail:[GRGestureDetailListController class] cell:PSLinkCell edit:Nil];
            if (gestureSpecifier) {
                [gestureSpecifier setProperty:gestureID forKey:@"gestureID"];
                [newGestures addObject:gestureSpecifier];
            }
        }
    }

    if ([gestureSpecifiers count] > 0 && [newGestures count] > 0) {
        [self replaceContiguousSpecifiers:gestureSpecifiers withSpecifiers:newGestures];
    } else if ([gestureSpecifiers count] > 0) {
        [self removeContiguousSpecifiers:gestureSpecifiers];
    } else if ([newGestures count] > 0) {
        [self insertContiguousSpecifiers:newGestures afterSpecifierID:@"gestureGroup"];
    }

    gestureSpecifiers = [newGestures copy];
}

@end
