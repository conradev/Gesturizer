#import <Preferences/Preferences.h>
#import <AppSupport/AppSupport.h>

@interface GRRootListController : PSListController {
    NSArray *gestureSpecifiers;

    NSMutableDictionary *_settingsDict;
    NSMutableDictionary *_gestures;
}

@property (nonatomic, retain) NSMutableDictionary *gestures;

+ (id)sharedInstance;

- (void)deleteGesture:(NSDictionary *)gesture;
- (void)updateGesture:(NSDictionary *)gesture;

- (void)reloadSpecifiers;

@end
