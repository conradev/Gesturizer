#import "GRLockScreenController.h"
#import "GRLockScreenView.h"

@implementation GRLockScreenController

@synthesize gestureRecognizer=_gestureRecognizer;

+ (id)rootViewController {
    return [[[self alloc] init] autorelease];
}

- (void)dealloc{
    self.gestureRecognizer = nil;

    [super dealloc];
}

- (void)loadView {
    self.view = [[[GRLockScreenView alloc] init] autorelease];
}

- (void)purgeView {
    self.view = nil;
}


- (void)gestureWasRecognized:(UIGestureRecognizer *)theGestureRecognizer {
    GRGestureController *gestureController;
    if (!(gestureController = [objc_getClass("GRGestureController") sharedInstance])) {
        return;
    }

    if ([self.gestureRecognizer.sortedResults count] > 0) {
        NSDictionary *gesture = [self.gestureRecognizer.sortedResults objectAtIndex:0];
        [gestureController performSelector:@selector(executeActionForGesture:) withObject:gesture afterDelay:0.25f];
    }

    self.gestureRecognizer.sortedResults = nil;

    for (NSDictionary *statGesture in self.gestureRecognizer.gestures) {
        NSMutableDictionary *gesture = [NSMutableDictionary dictionaryWithDictionary:statGesture];
        [gesture removeObjectForKey:@"score"];
    }

    [self.view setFrame:self.view.frame];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    GRGestureController *gestureController;
    if (!(gestureController = [objc_getClass("GRGestureController") sharedInstance])) {
        return;
    }

    Class $GRGestureRecognizer;
    if (!($GRGestureRecognizer = objc_getClass("GRGestureRecognizer"))) {
        return;
    }

    NSArray *gestures = [[gestureController gestures] allValues];

    self.gestureRecognizer = [[[$GRGestureRecognizer alloc] initWithTarget:self action:@selector(gestureWasRecognized:)] autorelease];
    self.gestureRecognizer.cancelsTouchesInView = NO;
    self.gestureRecognizer.delaysTouchesBegan = NO;
    self.gestureRecognizer.delaysTouchesEnded = NO;
    self.gestureRecognizer.gestures = gestures;
    self.gestureRecognizer.orientation = self.orientation;

    [self.view addGestureRecognizer:self.gestureRecognizer];
}

- (void)setOrientation:(int)orientation {
    [super setOrientation:orientation];
    self.gestureRecognizer.orientation = orientation;
}

- (void)viewDidDisappear:(BOOL)animated {
    self.gestureRecognizer = nil;
}

- (BOOL)canScreenDim {
    if ([self.gestureRecognizer.points count] > 0) {
        return NO;
    }

    return YES;
}

- (BOOL)shouldDisableOnRelock {
    return YES;
}

- (BOOL)viewWantsFullscreenLayout {
    return YES;
}

- (BOOL)isFullscreen {
    return NO;
}

- (BOOL)isAlwaysFullscreen {
    return NO;
}

- (BOOL)canBeAlwaysFullscreen {
    return NO;
}

- (BOOL)shouldShowLockStatusBarTime {
    return NO;
}

- (BOOL)showAwayItems {
    return YES;
}

- (BOOL)showDateView {
    return YES;
}

- (BOOL)wantsAutomaticFullscreenTimer {
    return NO;
}

- (BOOL)wantsSwipeGestureRecognizer {
    return NO;
}

- (BOOL)shouldDisableOnUnlock {
    return YES;
}

@end
