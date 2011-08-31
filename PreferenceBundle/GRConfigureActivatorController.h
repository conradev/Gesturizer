#import <Preferences/Preferences.h>

#import <libactivator/libactivator.h>

@interface GRConfigureActivatorController : PSViewController {
    LAEventSettingsController *eventSettings;
}

- (id)initWithEventName:(NSString *)eventName;

@end
