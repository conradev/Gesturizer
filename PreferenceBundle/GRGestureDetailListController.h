#import <Preferences/Preferences.h>

#import "GRGestureRecordingViewController.h"

@interface GRGestureDetailListController : PSListController <GRGestureRecordingDelegate, UIActionSheetDelegate> {
    NSMutableDictionary *_gesture;

    PSSpecifier *_urlField;
    PSSpecifier *_activatorConfigure;
    PSSpecifier *_changeGesture;
    PSSpecifier *_recordGesture;
}

@property (nonatomic, retain) NSMutableDictionary *gesture;

- (void)saveChanges;
- (void)deleteGesture;
- (void)close;

@end
