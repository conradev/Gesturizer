#import "GRGestureController.h"

#include <notify.h>
#include <substrate.h>

extern "C" {
    #import "GRGestureRecognitionFunctions.h"
}

GRGestureController *sharedInstance;

@implementation GRGestureController

@synthesize window=_window, gestures=_gestures, gestureRecognizer=_gestureRecognizer, settingsDict=_settingsDict, prevKeyWindow=_prevKeyWindow;

+ (GRGestureController *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[[GRGestureController alloc] init] retain];
        [[LAActivator sharedInstance] registerListener:sharedInstance forName:@"org.thebigboss.gesturizer"];
    }
    return sharedInstance;
}

- (id)init {
    if ((self = [super init])) {
        switcherWindowIsActive = NO;
        activatorWindowIsActive = NO;
        isInitializing = YES;

        CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"org.thebigboss.gesturizer.server"];
        [messagingCenter registerForMessageName:@"updateGesture" target:self selector:@selector(gestureChangeWithName:gesture:)];
        [messagingCenter registerForMessageName:@"deleteGesture" target:self selector:@selector(gestureChangeWithName:gesture:)];
        [messagingCenter registerForMessageName:@"setSwitcherEnabled" target:self selector:@selector(setSwitcherEnabled:userInfo:)];
        [messagingCenter registerForMessageName:@"returnSettings" target:self selector:@selector(returnSettings:)];
        [messagingCenter runServerOnCurrentThread];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

        _asyncQueue = [[NSOperationQueue alloc] init];

        BOOL isDefault = NO;
        self.settingsDict = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.plist"];

        if (!self.settingsDict) {
            isDefault = YES;
            self.settingsDict = [NSMutableDictionary dictionaryWithContentsOfFile:@"/Library/PreferenceBundles/GesturizerSettings.bundle/org.thebigboss.gesturizer.default.plist"];
        }

        if ([self.settingsDict objectForKey:@"enabled"]) {
            [self.settingsDict setObject:[self.settingsDict objectForKey:@"enabled"] forKey:@"switcherEnabled"];
            [self.settingsDict removeObjectForKey:@"enabled"];
        }

        self.gestures = [NSMutableDictionary dictionaryWithDictionary:[self.settingsDict objectForKey:@"gestures"]];

        for (NSDictionary *statGesture in [self.gestures allValues]) {
            NSMutableDictionary *gesture = [NSMutableDictionary dictionaryWithDictionary:statGesture];
            [gesture removeObjectForKey:@"score"];
        }

        LAActivator *activator = [LAActivator sharedInstance];
        for (NSString *gestureID in [self.gestures allKeys]) {
            NSString *eventName = [NSString stringWithFormat:@"org.thebigboss.gesturizer.event.%@", gestureID];
            [activator registerEventDataSource:self forEventName:eventName];

            NSString *listenerName = nil;
            if ([gestureID isEqualToString:@"2D3944CB-022D-46CB-A85D-980C9C582A3A"]) {
                listenerName = @"libactivator.system.spotlight";
            } else if ([gestureID isEqualToString:@"B25667A8-D2B4-4CD6-9CAA-4214CB322160"]) {
                listenerName = @"com.apple.youtube";
            }

            if (listenerName && isDefault) {
                for (NSString *mode in [activator availableEventModes]) {
                    LAEvent *gestureEvent = [LAEvent eventWithName:eventName mode:mode];
                    gestureEvent.handled = NO;
                    if (![activator assignedListenerNameForEvent:gestureEvent]) {
                        [activator assignEvent:gestureEvent toListenerWithName:listenerName];
                    }
                }
            }
        }

        isInitializing = NO;
        [self saveChanges];
    }
    return self;
}

- (void)dealloc {
    self.gestureRecognizer = nil;
    self.window = nil;
    self.gestures = nil;
    self.settingsDict = nil;
    [_asyncQueue cancelAllOperations];
    [_asyncQueue release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)memoryWarning {
    if ([_asyncQueue operationCount] > 0 || isInitializing) {
        [_asyncQueue cancelAllOperations];

        NSError *error = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *evilPath = @"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.evil.plist";
        NSString *regularPath = @"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.plist";

       if ([fileManager fileExistsAtPath:evilPath]) {
           NSLog(@"Gesturizer ::: File at evil path exists, removing...");
           if (![fileManager removeItemAtPath:evilPath error:&error]) {
                NSLog(@"Gesturizer ::: File at evil path was unable to be removed! Trying to nullify existing one!");
                if ([[NSDictionary dictionary] writeToFile:regularPath atomically:NO]) {
                    NSLog(@"Gesturizer ::: Successfully nullified existing settings file!");
                    NSLog(@"Gesturizer ::: Safety operations were a success!");
                    notify_post("org.thebigboss.gesturizer.settings");
                    return;
                } else {
                    NSLog(@"Gesturizer ::: Existing settings file cannot be nullified!");
                    NSLog(@"Gesturizer ::: FATAL ERROR: IF YOU ARE READING THIS, EMAIL support@kramerapps.com ASAP FOR ASSISTANCE.");
                }
            } else {
                NSLog(@"Gesturizer ::: File at evil path successfully removed!");
            }
        }
        if ([[NSFileManager defaultManager] moveItemAtPath:regularPath toPath:evilPath error:&error]) {
            NSLog(@"Gesturizer ::: Successfully quarantined config file!");
            NSLog(@"Gesturizer ::: Safety operations were a success!");
            notify_post("org.thebigboss.gesturizer.settings");
            return;
        } else {
            NSLog(@"Gesturizer ::: Could not quarantine config file!");
            if ([[NSDictionary dictionary] writeToFile:regularPath atomically:NO]) {
                NSLog(@"Gesturizer ::: Successfully nullified existing settings file!");
                NSLog(@"Gesturizer ::: Safety operations were a success!");
                notify_post("org.thebigboss.gesturizer.settings");
                return;
            } else {
                NSLog(@"Gesturizer ::: Existing settings file cannot be nullified!");
                NSLog(@"Gesturizer ::: FATAL ERROR: IF YOU ARE READING THIS, EMAIL support@kramerapps.com ASAP FOR ASSISTANCE.");
            }
        }
    }
}

#pragma mark -
#pragma mark Settings

- (NSDictionary *)returnSettings:(NSString *)name {
    return self.settingsDict;
}

- (void)gestureChangeWithName:(NSString *)name gesture:(NSDictionary *)theGesture {
    NSMutableDictionary *gesture = [NSMutableDictionary dictionaryWithDictionary:theGesture];

    if ([name isEqualToString:@"updateGesture"]) {
        [self updateGesture:gesture];
    } else if ([name isEqualToString:@"deleteGesture"]) {
        [self deleteGesture:gesture];
    }
}

- (void)setSwitcherEnabled:(NSString *)name userInfo:(NSDictionary *)userInfo {
    [self.settingsDict setObject:[userInfo objectForKey:@"switcherEnabled"] forKey:@"switcherEnabled"];
    [self saveChanges];
}

- (void)deleteGesture:(NSMutableDictionary *)gesture {
    NSInvocationOperation *deleteGestureOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(deleteGestureOperation:) object:gesture];
    [_asyncQueue addOperation:deleteGestureOperation];
    [deleteGestureOperation release];
}

- (void)updateGesture:(NSMutableDictionary *)gesture {
    NSInvocationOperation *updateGestureOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(updateGestureOperation:) object:gesture];
    [_asyncQueue addOperation:updateGestureOperation];
    [updateGestureOperation release];
}

- (void)saveChanges {
    NSInvocationOperation *saveChangesOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(saveChangesOperation) object:nil];
    [_asyncQueue addOperation:saveChangesOperation];
    [saveChangesOperation release];
}

- (void)deleteGestureOperation:(NSDictionary *)gesture {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self.gestures removeObjectForKey:[gesture objectForKey:@"id"]];
    NSString *eventName = [NSString stringWithFormat:@"org.thebigboss.gesturizer.event.%@", [gesture objectForKey:@"id"]];
    LAActivator *activator = [LAActivator sharedInstance];
    for (NSString *mode in [activator availableEventModes]) {
        LAEvent *gestureEvent = [LAEvent eventWithName:eventName mode:mode];
        [activator unassignEvent:gestureEvent];
    }
    [activator unregisterEventDataSourceWithEventName:eventName];
    [self.settingsDict setObject:self.gestures forKey:@"gestures"];
    [self.settingsDict writeToFile:@"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.plist" atomically:YES];
    [pool release];
}

- (void)updateGestureOperation:(NSDictionary *)gesture {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self.gestures setObject:gesture forKey:[gesture objectForKey:@"id"]];
    NSString *eventName = [NSString stringWithFormat:@"org.thebigboss.gesturizer.event.%@", [gesture objectForKey:@"id"]];
    LAActivator *activator = [LAActivator sharedInstance];
    [activator unregisterEventDataSourceWithEventName:eventName];
    [activator registerEventDataSource:self forEventName:eventName];
    [self createTemplates];
    [self.settingsDict setObject:self.gestures forKey:@"gestures"];
    [self.settingsDict writeToFile:@"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.plist" atomically:YES];
    [pool release];
}

- (void)saveChangesOperation {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self createTemplates];
    [self.settingsDict setObject:self.gestures forKey:@"gestures"];
    [self.settingsDict writeToFile:@"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.plist" atomically:YES];
    [pool release];
}

#pragma mark -
#pragma mark Activator Data Source

- (NSNumber *)activator:(LAActivator *)activator requiresIsCompatibleWithEventName:(NSString *)eventName listenerName:(NSString *)listenerName {
    if ([listenerName isEqualToString:@"org.thebigboss.gesturizer"]) {
        if ([eventName hasPrefix:@"org.thebigboss.gesturizer.event"]) {
            return [NSNumber numberWithBool:NO];
        }
    }

    return [NSNumber numberWithBool:YES];
}

- (BOOL)eventWithNameIsHidden:(NSString *)eventName {
   return YES;
}

- (BOOL)eventWithName:(NSString *)eventName isCompatibleWithMode:(NSString *)eventMode {
   return YES;
}

- (NSString *)localizedTitleForEventName:(NSString *)eventName {
    NSString *gestureID = [eventName stringByReplacingOccurrencesOfString:@"org.thebigboss.gesturizer.event." withString:@""];
    NSString *name = [[self.gestures objectForKey:gestureID] objectForKey:@"name"];
    if (!name) {
        name = @"Gesturizer Event";
    }
    return name;
}

- (NSString *)localizedGroupForEventName:(NSString *)eventName {
    return @"Gestures";
}

- (NSString *)localizedDescriptionForEventName:(NSString *)eventName {
    return @"Gesturizer Event";
}


#pragma mark -
#pragma mark Event Activation

- (void)gestureWasRecognized:(UIGestureRecognizer *)theGestureRecognizer {
    NSDictionary *gesture = [self.gestureRecognizer.sortedResults objectAtIndex:0];
    self.gestureRecognizer.sortedResults = nil;

    for (NSDictionary *statGesture in self.gestureRecognizer.gestures) {
        NSMutableDictionary *gesture = [NSMutableDictionary dictionaryWithDictionary:statGesture];
        [gesture removeObjectForKey:@"score"];
    }

    if (switcherWindowIsActive) {
        SBUIController *uiController = [objc_getClass("SBUIController") sharedInstance];
        if ([uiController respondsToSelector:@selector(dismissSwitcherAnimated:)]) {
            [uiController dismissSwitcherAnimated:YES];
        } else {
            [uiController dismissSwitcher];
        }
    } else if (activatorWindowIsActive) {
        [self deactivateWindow:0.25f];
        activatorWindowIsActive = NO;
    }

    [self performSelector:@selector(executeActionForGesture:) withObject:gesture afterDelay:0.25f];
}

- (BOOL)executeActionForGesture:(NSDictionary *)gesture {
    NSString *action = [gesture objectForKey:@"action"];
    if ([action isEqualToString:@"activator"]) {
        LAActivator *activator = [LAActivator sharedInstance];

        NSString *eventName = [NSString stringWithFormat:@"org.thebigboss.gesturizer.event.%@", [gesture objectForKey:@"id"]];
        LAEvent *gestureEvent = [LAEvent eventWithName:eventName mode:[activator currentEventMode]];
        gestureEvent.handled = NO;

        [activator sendEventToListener:gestureEvent];

        /*
        NSString *listenerName = nil;
        if ((listenerName = [activator assignedListenerNameForEvent:gestureEvent])) {

            return gestureEvent.handled;
        }

        return NO;
        */

    } else if ([action isEqualToString:@"url"]) {
        NSURL *url = [NSURL URLWithString:[gesture objectForKey:@"url"]];
        SpringBoard *springboard = (SpringBoard *)[objc_getClass("SpringBoard") sharedApplication];
        if ([springboard applicationCanOpenURL:url publicURLsOnly:NO]) {
            [springboard applicationOpenURL:url];
            return YES;
        }

        return NO;
    }

    return NO;
}

#pragma mark -
#pragma mark Touch Data Pre-Processing

- (void)createTemplates {
    for (NSMutableDictionary *gesture in [self.gestures allValues]) {
        if ([gesture objectForKey:@"strokes"]) {
            if (![gesture objectForKey:@"templates"]) {
                NSArray *strokes = [gesture objectForKey:@"strokes"];
                int amountOfStrokes = [strokes count];

                oneSuchOrdering = [[NSMutableArray alloc] init];
                for (int i=0; i < amountOfStrokes; i++) {
                    [oneSuchOrdering addObject:[NSNumber numberWithInt:i]];
                }

                // Permute the n! stroke orderings
                permutedStrokeOrderings = [[NSMutableArray alloc] init];
                [self permuteStrokeOrderings:amountOfStrokes];
                [oneSuchOrdering release];

                // Generate the n! * 2^n possible unistroke permutations
                NSMutableArray *unistrokes = [NSMutableArray array];
                for (NSArray *oneOrdering in permutedStrokeOrderings) {
                    for (int x = 0; x < pow(2, amountOfStrokes); x++) {
                        NSMutableArray *unistroke = [NSMutableArray array];
                        for (int y = 0; y < amountOfStrokes; y++) {
                            NSArray *stroke = [strokes objectAtIndex:[[oneOrdering objectAtIndex:y] intValue]];

                            if (((x >> y) & 1) == 1) {
                                stroke = [[stroke reverseObjectEnumerator] allObjects];
                            }

                            [unistroke addObjectsFromArray:stroke];
                        }
                        [unistrokes addObject:unistroke];
                    }
                }
                [permutedStrokeOrderings release];

                // Normalization procedure
                NSMutableArray *templates = [NSMutableArray array];
                for (NSArray *unistroke in unistrokes) {
                    NSMutableArray *normalizedPoints = [NSMutableArray arrayWithArray:TranslateToOrigin(Scale(Resample(unistroke, GRResamplePointsCount), GRResolution, GR1DThreshold))];
                    NSDictionary *startUnitVector = CalcStartUnitVector(normalizedPoints, GRStartAngleIndex);
                    NSMutableArray *vector = [NSMutableArray arrayWithArray:Vectorize(normalizedPoints)];

                    NSMutableDictionary *theTemplate = [NSMutableDictionary dictionaryWithObjectsAndKeys:startUnitVector, @"startUnitVector", vector, @"vector", nil];
                    [templates addObject:theTemplate];
                }

                [gesture setObject:templates forKey:@"templates"];
                [gesture removeObjectForKey:@"strokes"];
            }
        }
    }
}

- (void)permuteStrokeOrderings:(int)count {
    if (count == 1) {
        [permutedStrokeOrderings addObject:[[oneSuchOrdering copy] autorelease]];
    } else {
        for (int i = 0; i < count; i++) {
            [self permuteStrokeOrderings:(count-1)];

            NSNumber *last = [oneSuchOrdering objectAtIndex:(count - 1)];
            if (count % 2 == 1) {
                NSNumber *first = [oneSuchOrdering objectAtIndex:0];
                [oneSuchOrdering replaceObjectAtIndex:0 withObject:last];
                [oneSuchOrdering replaceObjectAtIndex:(count-1) withObject:first];
            } else {
                NSNumber *next = [oneSuchOrdering objectAtIndex:i];
                [oneSuchOrdering replaceObjectAtIndex:i withObject:last];
                [oneSuchOrdering replaceObjectAtIndex:(count-1) withObject:next];
            }
        }
    }
}


#pragma mark -
#pragma mark Window Activation

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
	if (!activatorWindowIsActive && !switcherWindowIsActive) {

        int gestureCount = 0;
        for (NSDictionary *gesture in [self.gestures allValues]) {
            if ([gesture objectForKey:@"templates"]) {
                gestureCount++;
            }
        }

        if (gestureCount < 1) {
            // POP AN ALERT!!!!!!!
        }

        [self activateWindow:0.25f transform:CGAffineTransformIdentity];
        activatorWindowIsActive = YES;
        event.handled = YES;

	} else if (activatorWindowIsActive) {

        [self deactivateWindow:0.25f];
        activatorWindowIsActive = NO;
        event.handled = YES;
    }
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event {
    if (activatorWindowIsActive) {
        [self deactivateWindow:0.25f];
        activatorWindowIsActive = NO;
        event.handled = YES;
    }
}

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
    [self deactivateWindow:0.25f];
}

- (void)activateWindow:(double)duration transform:(CGAffineTransform)transform {
    if (!switcherWindowIsActive && !activatorWindowIsActive) {
        [_asyncQueue waitUntilAllOperationsAreFinished];

        self.prevKeyWindow = [[UIApplication sharedApplication] keyWindow];

        self.gestureRecognizer = [[[GRGestureRecognizer alloc] initWithTarget:self action:@selector(gestureWasRecognized:)] autorelease];
        self.gestureRecognizer.cancelsTouchesInView = NO;
        self.gestureRecognizer.delaysTouchesBegan = NO;
        self.gestureRecognizer.delaysTouchesEnded = NO;
        self.gestureRecognizer.gestures = [self.gestures allValues];
        self.gestureRecognizer.orientation = [(SpringBoard *)[objc_getClass("SpringBoard") sharedApplication] activeInterfaceOrientation];

        CGRect screenFrame = [[UIScreen mainScreen] bounds];
        self.window = [[[GRWindow alloc] initWithFrame:screenFrame] autorelease];
        [self.window setWindowLevel:UIWindowLevelAlert + 6];
        [self.window addGestureRecognizer:self.gestureRecognizer];

        [self.window setHidden:NO];
        [self.window makeKeyAndVisible];
        [UIView animateWithDuration:duration animations: ^ {
            [self.window setAlpha:0.70];
            [self.window setTransform:transform];
         }];
     }
}

- (void)deactivateWindow:(double)duration {
    if (switcherWindowIsActive || activatorWindowIsActive) {
        [UIView animateWithDuration:duration animations: ^ {
            [self.window setAlpha:0];
            [self.window setTransform:CGAffineTransformIdentity];
        } completion: ^ (BOOL finished) {
            [self.window setHidden:YES];
            self.window = nil;
            self.gestureRecognizer = nil;
        }];

        if (self.prevKeyWindow.hidden) {
            SBUIController *uiController = [objc_getClass("SBUIController") sharedInstance];
            [uiController.window makeKeyAndVisible];
        } else {
            [self.prevKeyWindow makeKeyAndVisible];
        }

        self.prevKeyWindow = nil;

        switcherWindowIsActive = NO;
        activatorWindowIsActive = NO;
    }
}

- (void)showSwitcherWindow:(double)duration {

    int gestureCount = 0;
    for (NSDictionary *gesture in [self.gestures allValues]) {
        if ([gesture objectForKey:@"templates"]) {
            gestureCount++;
        }
    }

    BOOL shouldShow = ([[self.settingsDict objectForKey:@"switcherEnabled"] boolValue] && !switcherWindowIsActive && !activatorWindowIsActive && (gestureCount > 0));

    if (shouldShow) {
        SBUIController *uiController = [objc_getClass("SBUIController") sharedInstance];

        SBShowcaseController *showcaseController = nil;
        if ([uiController respondsToSelector:@selector(showcaseController)]) {
            showcaseController = [uiController showcaseController];
        }

        UIWindow *blockingWindow = nil;
        if (!showcaseController) {
            blockingWindow = MSHookIvar<UIWindow *>(uiController, "_blockingWindow");
            blockingWindow.hidden = YES;
        }

        CGAffineTransform windowTransform = CGAffineTransformIdentity;
        if ([uiController isSwitcherShowing]) {
            
            if ([uiController respondsToSelector:@selector(_portraitViewTransformForSwitcherSize:orientation:)] || showcaseController) {
                int switcherOrientation = 0;
                CGSize switcherSize = CGSizeMake(0, 0);

                if (showcaseController) {
                    float bottomBarHeight = [showcaseController bottomBarHeight];
                    SBShowcaseContext *context = [uiController _showcaseContextForOffset:bottomBarHeight];
                    windowTransform = [context portraitRelativeViewTransform];
                } else {
                    switcherOrientation = MSHookIvar<int>(uiController, "_switcherOrientation");
                    switcherSize = MSHookIvar<UIView *>(uiController, "_switcherView").frame.size;
                    windowTransform = [uiController _portraitViewTransformForSwitcherSize:switcherSize orientation:switcherOrientation]; // iOS 4.0 incompatibility
                }

            } else {
                windowTransform = CGAffineTransformMakeTranslation(0, -94);
            }
            
        } else {
            return;
        }

        [self activateWindow:duration transform:windowTransform];

        switcherWindowIsActive = YES;
    }
}

- (void)updateSwitcherWindow:(double)duration orientation:(int)newOrientation {
    if (switcherWindowIsActive) {

        SBUIController *uiController = [objc_getClass("SBUIController") sharedInstance];

        SBShowcaseController *showcaseController = nil;
        if ([uiController respondsToSelector:@selector(showcaseController)]) {
            showcaseController = [uiController showcaseController];
        }

        CGAffineTransform windowTransform;
        if ([uiController isSwitcherShowing]) {
            if ([uiController respondsToSelector:@selector(_portraitViewTransformForSwitcherSize:orientation:)] || showcaseController) {
                int switcherOrientation = 0;
                CGSize switcherSize = CGSizeMake(0, 0);
                
                if (showcaseController) {
                    float bottomBarHeight = [showcaseController bottomBarHeight];
                    SBShowcaseContext *context = [uiController _showcaseContextForOffset:bottomBarHeight];
                    windowTransform = [context portraitRelativeViewTransform];
                } else {
                    switcherOrientation = MSHookIvar<int>(uiController, "_switcherOrientation");
                    switcherSize = MSHookIvar<UIView *>(uiController, "_switcherView").frame.size;
                    windowTransform = [uiController _portraitViewTransformForSwitcherSize:switcherSize orientation:switcherOrientation]; // iOS 4.0 incompatibility
                }
                
            } else {
                windowTransform = CGAffineTransformMakeTranslation(0, -94);
            }
        }

        self.gestureRecognizer.orientation = newOrientation;

        [UIView animateWithDuration:duration animations: ^ {
            [self.window setTransform:windowTransform];
         }];
    }
}

- (void)hideSwitcherWindow:(double)duration  {
    if (!switcherWindowIsActive)
        return;

    [self deactivateWindow:duration];

}

@end
