#import "GRRootListController.h"
#import "GRGestureDetailListController.h"

#import <notify.h>

GRRootListController *sharedInstance = nil;

@implementation GRRootListController

@synthesize gestures=_gestures, enabled=_enabled, settingsDict=_settingsDict;

+ (id)sharedInstance {
    return sharedInstance;
}

- (id)init {
    if ((self = [super init])) {
        sharedInstance = self;
        CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"org.thebigboss.gesturizer.server"];
        self.settingsDict = [messagingCenter sendMessageAndReceiveReplyName:@"returnSettings" userInfo:nil];
        self.gestures = [NSMutableDictionary dictionaryWithDictionary:[self.settingsDict objectForKey:@"gestures"]];
        self.enabled = [self.settingsDict objectForKey:@"enabled"];
    }
    return self;
}

- (void)dealloc {
    sharedInstance = nil;
    self.gestures = nil;
    self.enabled = nil;
    self.settingsDict = nil;
    [super dealloc];
}

- (id)specifiers {
	if(_specifiers == nil) {
		NSMutableArray *mutSpecs = [NSMutableArray arrayWithArray:[self loadSpecifiersFromPlistName:@"RootListController" target:self]];
        NSMutableArray *mutGestureSpecs = [NSMutableArray array];

        for (NSDictionary *gesture in [self.gestures allValues]) {
            PSSpecifier *gestureSpecifier = [PSSpecifier preferenceSpecifierNamed:[gesture objectForKey:@"name"] target:self set:NULL get:NULL detail:[GRGestureDetailListController class] cell:PSLinkCell edit:Nil];
            if (gestureSpecifier) {
                [gestureSpecifier setProperty:gesture forKey:@"gesture"];
                [mutGestureSpecs addObject:gestureSpecifier];
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

- (void)setEnabled:(NSNumber *)value specifier:(PSSpecifier *)spec {
    CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"org.thebigboss.gesturizer.server"];
    [messagingCenter sendMessageName:@"setEnabled" userInfo:[NSDictionary dictionaryWithObject:value forKey:@"enabled"]];
    self.enabled = value;
}

- (NSNumber *)getEnabled:(PSSpecifier *)spec {
    return self.enabled;
}

- (void)deleteGesture:(NSDictionary *)gesture {
    [self.gestures removeObjectForKey:[gesture objectForKey:@"id"]];
    CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"org.thebigboss.gesturizer.server"];
    [messagingCenter sendMessageName:@"deleteGesture" userInfo:gesture];
    [self reloadSpecifiers];
}

- (void)updateGesture:(NSDictionary *)gesture {
    [self.gestures setObject:gesture forKey:[gesture objectForKey:@"id"]];
    CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"org.thebigboss.gesturizer.server"];
    [messagingCenter sendMessageName:@"updateGesture" userInfo:gesture];
    [self reloadSpecifiers];
}

- (void)reloadSpecifiers {
    NSMutableArray *newSpecifiers = [NSMutableArray array];

    for (NSDictionary *gesture in [self.gestures allValues]) {
        PSSpecifier *gestureSpecifier = [PSSpecifier preferenceSpecifierNamed:[gesture objectForKey:@"name"] target:self set:NULL get:NULL detail:[GRGestureDetailListController class] cell:PSLinkCell edit:Nil];
        if (gestureSpecifier) {
            [gestureSpecifier setProperty:gesture forKey:@"gesture"];
            [newSpecifiers addObject:gestureSpecifier];
        }
    }

    if ([gestureSpecifiers count] > 0 && [newSpecifiers count] > 0) {
        [self replaceContiguousSpecifiers:gestureSpecifiers withSpecifiers:newSpecifiers];
    } else if ([gestureSpecifiers count] > 0) {
        [self removeContiguousSpecifiers:gestureSpecifiers];
    } else if ([newSpecifiers count] > 0) {
        [self insertContiguousSpecifiers:newSpecifiers afterSpecifierID:@"gestureGroup"];
    }

    [gestureSpecifiers release];
    gestureSpecifiers = [newSpecifiers copy];
}

@end
