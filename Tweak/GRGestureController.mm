#import "GRGestureController.h"

#import <notify.h>

extern "C" {
    #import "GRGestureRecognitionFunctions.h"
}

GRGestureController *sharedInstance;

@implementation GRGestureController

@synthesize window=_window, gestures=_gestures, gestureRecognizer=_gestureRecognizer, settingsDict=_settingsDict;

+ (GRGestureController *)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[[GRGestureController alloc] init] retain];
        [[LAActivator sharedInstance] registerListener:sharedInstance forName:@"org.thebigboss.gesturizer"];
    }
    return sharedInstance;
}

- (id)init {
    if ((self = [super init])) {
        windowIsActive = NO;
        isInitializing = YES;

        CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"org.thebigboss.gesturizer.server"];
        [messagingCenter registerForMessageName:@"updateGesture" target:self selector:@selector(gestureChangeWithName:gesture:)];
        [messagingCenter registerForMessageName:@"deleteGesture" target:self selector:@selector(gestureChangeWithName:gesture:)];
        [messagingCenter registerForMessageName:@"returnSettings" target:self selector:@selector(returnSettings:)];
        [messagingCenter runServerOnCurrentThread];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

        _asyncQueue = [[NSOperationQueue alloc] init];

        self.settingsDict = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.plist"];
        self.gestures = [NSMutableDictionary dictionaryWithDictionary:[self.settingsDict objectForKey:@"gestures"]];

        if (!self.gestures) {
            // DEFAULTS GO HERE
            self.gestures = [NSMutableDictionary dictionary];
        }
        if (!self.settingsDict) {
            self.settingsDict = [NSMutableDictionary dictionary];
            [self.settingsDict setObject:self.gestures forKey:@"gestures"];
        }

        LAActivator *activator = [LAActivator sharedInstance];
        for (NSString *gestureID in [self.gestures allKeys]) {
            NSString *eventName = [NSString stringWithFormat:@"org.thebigboss.gesturizer.event.%@", gestureID];
            [activator registerEventDataSource:self forEventName:eventName];
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

- (void)gestureChangeWithName:(NSString *)name gesture:(NSDictionary *)gesture {
    gesture = [NSMutableDictionary dictionaryWithDictionary:gesture];
    LAActivator *activator = [LAActivator sharedInstance];
    if ([name isEqualToString:@"updateGesture"]) {
        [self.gestures setObject:gesture forKey:[gesture objectForKey:@"id"]];
        NSString *eventName = [NSString stringWithFormat:@"org.thebigboss.gesturizer.event.%@", [gesture objectForKey:@"id"]];
        [activator unregisterEventDataSourceWithEventName:eventName];
        [activator registerEventDataSource:self forEventName:eventName];
    } else if ([name isEqualToString:@"deleteGesture"]) {
        [self.gestures removeObjectForKey:[gesture objectForKey:@"id"]];
        NSString *eventName = [NSString stringWithFormat:@"org.thebigboss.gesturizer.event.%@", [gesture objectForKey:@"id"]];
        [activator unregisterEventDataSourceWithEventName:eventName];
    }

    [self saveChanges];
}

- (void)saveChanges {
    NSInvocationOperation *saveChangesOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(saveChangesOperation) object:nil];
    [_asyncQueue addOperation:saveChangesOperation];
    [saveChangesOperation release];
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

- (void)activator:(LAActivator *)activator abortEvent:(LAEvent *)event {
	[self deactivateWindow];
}

- (BOOL)eventWithNameIsHidden:(NSString *)eventName {
   return YES;
}

- (BOOL)eventWithName:(NSString *)eventName isCompatibleWithMode:(NSString *)eventMode {
   if (![eventMode isEqualToString:@"lockscreen"]) {
        return YES;
   }

   return NO;
}

- (NSString *)localizedTitleForEventName:(NSString *)eventName {
    NSString *gestureID = [eventName stringByReplacingOccurrencesOfString:@"org.thebigboss.gesturizer." withString:@""];
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

    [self deactivateWindow];
    [self performSelector:@selector(executeActionForGesture:) withObject:gesture afterDelay:0.4f];
}

- (BOOL)canExecuteActionForGesture:(NSDictionary *)gesture {
    NSString *action = [gesture objectForKey:@"action"];
    if ([action isEqualToString:@"activator"]) {
        LAActivator *activator = [LAActivator sharedInstance];

        NSString *eventName = [NSString stringWithFormat:@"org.thebigboss.gesturizer.event.%@", [gesture objectForKey:@"id"]];
        LAEvent *gestureEvent = [LAEvent eventWithName:eventName mode:[activator currentEventMode]];
        gestureEvent.handled = NO;

        if ( [activator assignedListenerNameForEvent:gestureEvent]) {
            return YES;
        }
    } else if ([action isEqualToString:@"url"]) {
        NSURL *url = [NSURL URLWithString:[gesture objectForKey:@"url"]];
        SpringBoard *springboard = [objc_getClass("SpringBoard") sharedApplication];
        if ([springboard applicationCanOpenURL:url publicURLsOnly:NO]) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)executeActionForGesture:(NSDictionary *)gesture {
    NSString *action = [gesture objectForKey:@"action"];
    if ([action isEqualToString:@"activator"]) {
        LAActivator *activator = [LAActivator sharedInstance];

        NSString *eventName = [NSString stringWithFormat:@"org.thebigboss.gesturizer.event.%@", [gesture objectForKey:@"id"]];
        LAEvent *gestureEvent = [LAEvent eventWithName:eventName mode:[activator currentEventMode]];
        gestureEvent.handled = NO;

        NSString *listenerName = nil;
        if ((listenerName = [activator assignedListenerNameForEvent:gestureEvent])) {
            [activator sendEventToListener:gestureEvent];
            if (!gestureEvent.handled)
                NSLog(@"Did not handle event!");

            return gestureEvent.handled;
        }

        return NO;

    } else if ([action isEqualToString:@"url"]) {
        NSURL *url = [NSURL URLWithString:[gesture objectForKey:@"url"]];
        SpringBoard *springboard = [objc_getClass("SpringBoard") sharedApplication];
        if ([springboard applicationCanOpenURL:url publicURLsOnly:NO]) {
            [springboard applicationOpenURL:url publicURLsOnly:NO];
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
    if (windowIsActive) {
        [self deactivateWindow];
    } else {
        [self activateWindow];
    }

    [event setHandled:YES];
}

- (void)activator:(LAActivator *)activator receiveDeactivateEvent:(LAEvent *)event {
	if (windowIsActive) {
        [self deactivateWindow];
        event.handled = YES;
    }
}

- (void)activateWindow {
    LAActivator *activator = [LAActivator sharedInstance];
    if ([[activator currentEventMode] isEqualToString:@"lockscreen"])
        return;

    [_asyncQueue waitUntilAllOperationsAreFinished];

    int gestureCount = 0;
    for (NSDictionary *gesture in [self.gestures allValues]) {
        if ([gesture objectForKey:@"templates"]) {
            gestureCount++;
        }
    }

    if (gestureCount < 1) {
        // POP AN ALERT
        return;
    }

    if (!windowIsActive) {
        prevKeyWindow = [[UIApplication sharedApplication] keyWindow];

        self.gestureRecognizer = [[[GRGestureRecognizer alloc] initWithTarget:self action:@selector(gestureWasRecognized:)] autorelease];
        self.gestureRecognizer.cancelsTouchesInView = NO;
        self.gestureRecognizer.delaysTouchesBegan = NO;
        self.gestureRecognizer.delaysTouchesEnded = NO;
        self.gestureRecognizer.gestures = [self.gestures allValues];

        CGRect screenFrame = [[UIScreen mainScreen] bounds];
        self.window = [[GRWindow alloc] initWithFrame:screenFrame];
        [self.window setWindowLevel:UIWindowLevelStatusBar + 1001];
        [self.window addGestureRecognizer:self.gestureRecognizer];

        [self.window setHidden:NO];
        [UIView animateWithDuration:.5 animations: ^ { [self.window setAlpha:0.45]; }];
        [self.window makeKeyAndVisible];

        windowIsActive = YES;
    }
}

- (void)deactivateWindow {
    if (windowIsActive) {
        [UIView animateWithDuration:.5 animations: ^ { [self.window setAlpha:0]; } completion: ^ (BOOL finished) {
            [self.window setHidden:YES];
            self.window = nil;
            self.gestureRecognizer = nil;
        }];
        [prevKeyWindow makeKeyAndVisible];
        windowIsActive = NO;
    }
}

@end
