#import <Preferences/Preferences.h>
#import <AppSupport/AppSupport.h>

@interface GRRootListController : PSListController {
    NSArray *gestureSpecifiers;

    NSMutableDictionary *_gestures;
    NSNumber *_enabled;
}

@property (nonatomic, retain) NSDictionary *settingsDict;
@property (nonatomic, retain) NSMutableDictionary *gestures;
@property (nonatomic, retain) NSNumber *enabled;

+ (id)sharedInstance;

- (void)deleteGesture:(NSDictionary *)gesture;
- (void)updateGesture:(NSDictionary *)gesture;

- (void)reloadSpecifiers;

@end
