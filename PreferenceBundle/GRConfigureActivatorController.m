#import "GRConfigureActivatorController.h"

#import <libactivator/libactivator.h>

@implementation GRConfigureActivatorController

- (id)initWithEventName:(NSString *)eventName {
    if ((self = [super init])) {
        LAActivator *activator = [LAActivator sharedInstance];
        eventSettings = [[LAEventSettingsController alloc] initWithModes:[activator availableEventModes] eventName:eventName];

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
