#import "GRGestureController.h"

extern "C" {
    #import "GRGestureRecognitionFunctions.h"
}

static BOOL PurpleAllocated = NO;
static uint8_t  touchEvent[sizeof(GSEventRecord) + sizeof(GSHandInfo) + sizeof(GSPathInfo)];
static mach_port_t (*GSTakePurpleSystemEventPort)(void);

struct GSTouchEvent {
    GSEventRecord record;
    GSHandInfo    handInfo;
};

GRGestureController *sharedInstance;

@interface GRGestureController (Private)
- (void)sendGSEvent:(GSEventRecord *)eventRecord atLocation:(CGPoint)location;
@end


void receivedReloadSettingsNotfication  (CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [[GRGestureController sharedInstance] reloadSettings];
}

@implementation GRGestureController

@synthesize window=_window, gestures=_gestures, gestureRecognizer=_gestureRecognizer;

+ (void)load {
    MSHookSymbol(GSTakePurpleSystemEventPort, "GSGetPurpleSystemEventPort");
    if (GSTakePurpleSystemEventPort == NULL) {
        MSHookSymbol(GSTakePurpleSystemEventPort, "GSCopyPurpleSystemEventPort");
        PurpleAllocated = YES;
    }
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)&receivedReloadSettingsNotfication, CFSTR("org.thebigboss.gesturizer.settings"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}

+ (GRGestureController *)sharedInstance {
    if (!sharedInstance)
        sharedInstance = [[[GRGestureController alloc] init] retain];
        [[LAActivator sharedInstance] registerListener:sharedInstance forName:@"org.thebigboss.gesturizer"];
    return sharedInstance;
}

- (id)init {
    if ((self = [super init])) {
        windowIsActive = NO;

        CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"org.thebigboss.gesturizer.uikit"];
        [messagingCenter registerForMessageName:@"longPress" target:self selector:@selector(handleLongPress:withUserInfo:)];
        [messagingCenter runServerOnCurrentThread];

        [self reloadSettings];
    }
    return self;
}

- (void)dealloc {
    self.gestureRecognizer = nil;

    [super dealloc];
}

- (void)reloadSettings {
    LAActivator *activator = [LAActivator sharedInstance];

    for (NSString *gestureID in [self.gestures allKeys]) {
        NSString *eventName = [NSString stringWithFormat:@"org.thebigboss.gesturizer.event.%@", gestureID];
        [activator unregisterEventDataSourceWithEventName:eventName];
    }

    self.gestures = nil;

    NSDictionary *settingsDict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.plist"];
    for (NSString *key in [settingsDict allKeys]) {
        if ([key isEqualToString:@"gestures"]) {
            self.gestures = [settingsDict objectForKey:key];
        }
    }

    for (NSString *gestureID in [self.gestures allKeys]) {
        NSString *eventName = [NSString stringWithFormat:@"org.thebigboss.gesturizer.event.%@", gestureID];
        [activator registerEventDataSource:self forEventName:eventName];
    }

    [self createTemplates];
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

    [self executeActionForGesture:gesture];
    [self deactivateWindow];
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

    NSMutableDictionary *settingsDict = [NSMutableDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.plist"];
    [settingsDict setObject:self.gestures forKey:@"gestures"];
    [settingsDict writeToFile:@"/var/mobile/Library/Preferences/org.thebigboss.gesturizer.plist" atomically:YES];
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

- (void)handleLongPress:(NSString *)name withUserInfo:(NSDictionary *)userinfo {
    CGPoint touchPoint = CGPointMake([[userinfo objectForKey:@"x"] floatValue], [[userinfo objectForKey:@"y"] floatValue]);
    int pathIndex = [[userinfo objectForKey:@"pathIndex"] intValue];
    if (!windowIsActive) {
        [self activateWindow];
        [self sendMouseRefocusAtLocation:touchPoint withPathIndex:pathIndex];
    }
}

- (void)activateWindow {
    LAActivator *activator = [LAActivator sharedInstance];
    if ([[activator currentEventMode] isEqualToString:@"lockscreen"])
        return;

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

#pragma mark -
#pragma mark Event Injection

- (void)sendMouseRefocusAtLocation:(CGPoint)virtualLocation withPathIndex:(int)pathIndex {

    CGPoint location;
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];

    // Convert window location to absolute location
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        location.x = virtualLocation.y;
        location.y = (screenSize.height - virtualLocation.x);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        location.x = (screenSize.width - virtualLocation.y);
        location.y = virtualLocation.x;
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        location.x = (screenSize.width - virtualLocation.x);
        location.y = (screenSize.height - virtualLocation.y);
    } else {
        location = virtualLocation;
    }

    GSTouchEvent* event = (GSTouchEvent*)&touchEvent;
    bzero(touchEvent, sizeof(touchEvent));

    event->record.type = kGSEventHand;
    event->record.windowLocation = location;
    event->record.timestamp = GSCurrentEventTimestamp();
    event->record.infoSize = sizeof(GSHandInfo) + sizeof(GSPathInfo);
    event->handInfo.type = kGSHandInfoTypeTouchUp;
    event->handInfo.pathInfosCount = 1;
    bzero(&event->handInfo.pathInfos[0], sizeof(GSPathInfo));
    event->handInfo.pathInfos[0].pathIndex     = pathIndex;
    event->handInfo.pathInfos[0].pathIdentity  = 2;
    event->handInfo.pathInfos[0].pathProximity = 0x00;
    event->handInfo.pathInfos[0].pathLocation  = location;

    [self sendGSEvent:(GSEventRecord*)event atLocation:location];

    event->handInfo.type = kGSHandInfoTypeTouchDown;
    event->handInfo.pathInfos[0].pathProximity = 0x03;

    [self sendGSEvent:(GSEventRecord*)event atLocation:location];
}

- (void)sendGSEvent:(GSEventRecord *)eventRecord atLocation:(CGPoint)location {
    mach_port_t port(0);
    mach_port_t purple(0);

    // Attempts to get the event port of the currently open application
    CAWindowServer *server;
    if ((server = [CAWindowServer serverIfRunning])) {
        NSArray *displays([server displays]);
        if (displays != nil && [displays count] != 0) {
            CAWindowServerDisplay *display;
            if ((display = [displays objectAtIndex:0])) {
                port = [display clientPortAtPosition:location];
            }
        }
    }

    // If it fails, it gets SpringBoard's Purple system event port
    if (!port) {
        if (!purple) {
            purple = (*GSTakePurpleSystemEventPort)();
        }
        port = purple;
    }

    if (port) {
        GSSendEvent(eventRecord, port);
    }

    if (purple && PurpleAllocated){
        mach_port_deallocate(mach_task_self(), purple);
    }
}

@end
