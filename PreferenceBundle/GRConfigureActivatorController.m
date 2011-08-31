#import "GRConfigureActivatorController.h"

@implementation GRConfigureActivatorController

- (id)initWithEventName:(NSString *)eventName {
    if ((self = [super init])) {
        NSArray *modes = [NSArray arrayWithObjects:@"springboard", @"application", nil];
        eventSettings = [[LAEventSettingsController alloc] initWithModes:modes eventName:eventName];

        self.navigationItem.title = @"Gesturizer Event";
    }
    return self;
}

- (id)view {
    return eventSettings.view;
}

- (void)dealloc {
    [eventSettings release];

    [super dealloc];
 }

@end
