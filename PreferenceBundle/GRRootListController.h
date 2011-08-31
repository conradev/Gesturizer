#import <Preferences/Preferences.h>

@interface GRRootListController : PSListController {
    NSArray *gestureSpecifiers;
}

+ (id)sharedInstance;

- (void)reloadGestures;

@end
