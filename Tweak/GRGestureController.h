#import <AppSupport/AppSupport.h>

#import <libactivator/libactivator.h>

#import <objc/runtime.h>

#import "GRWindow.h"
#import "GRGestureRecognizer.h"

@interface SpringBoard : UIApplication
- (int)activeInterfaceOrientation;
- (BOOL)applicationCanOpenURL:(id)url publicURLsOnly:(BOOL)only;
- (void)applicationOpenURL:(id)url;
@end

@interface SBShowcaseContext : NSObject
@property(nonatomic) int appOrientation; // @synthesize appOrientation=_appOrientation;
@property(nonatomic) struct CGAffineTransform currentReleativeViewTransform; // @synthesize currentReleativeViewTransform=_currentReleativeViewTransform;
@property(nonatomic) float offset; // @synthesize offset=_offset;
@property(nonatomic) BOOL onApp; // @synthesize onApp=_onApp;
@property(nonatomic) BOOL onSpringBoard; // @synthesize onSpringBoard=_onSpringBoard;
@property(nonatomic) struct CGAffineTransform portraitRelativeViewTransform; // @synthesize portraitRelativeViewTransform=_portraitRelativeViewTransform;
@property(nonatomic) int showcaseOrientation; // @synthesize showcaseOrientation=_showcaseOrientation;
@end

@interface SBShowcaseViewController : NSObject
- (UIView *)view;
@end

@interface SBShowcaseController : NSObject
- (SBShowcaseViewController *)showcase;
- (UIControl *)blockingView;
- (float)bottomBarHeight;
- (int)orientation;
@end

@interface SBUIController : NSObject
+ (SBUIController *)sharedInstance;

// iOS 5 only
- (SBShowcaseController *)showcaseController;
- (SBShowcaseContext *)_showcaseContextForOffset:(float)offset;

- (UIWindow *)window;
- (BOOL)isSwitcherShowing;
- (void)dismissSwitcherAnimated:(BOOL)animated;
- (void)dismissSwitcher;
- (CGAffineTransform)_portraitViewTransformForSwitcherSize:(CGSize)switcherSize orientation:(int)orientation;
@end

@interface GRGestureController : NSObject <LAListener, LAEventDataSource> {
    GRWindow *_window;
    GRGestureRecognizer *_gestureRecognizer;

    BOOL switcherWindowIsActive;
    BOOL activatorWindowIsActive;

    NSMutableArray *oneSuchOrdering;
    NSMutableArray *permutedStrokeOrderings;

    NSMutableDictionary *_gestures;
    NSMutableDictionary *_settingsDict;

    NSOperationQueue *_asyncQueue;
    BOOL isInitializing;
}

@property (nonatomic, retain) GRWindow *window;
@property (nonatomic, retain) UIWindow *prevKeyWindow;
@property (nonatomic, retain) GRGestureRecognizer *gestureRecognizer;
@property (nonatomic, retain) NSMutableDictionary *settingsDict;
@property (nonatomic, retain) NSMutableDictionary *gestures;

+ (GRGestureController *)sharedInstance;

- (id)init;

- (void)activateWindow:(double)duration transform:(CGAffineTransform)transform;
- (void)deactivateWindow:(double)duration;

- (void)showSwitcherWindow:(double)duration;
- (void)updateSwitcherWindow:(double)duration orientation:(int)newOrientation;
- (void)hideSwitcherWindow:(double)duration;

- (void)memoryWarning;

- (void)updateGesture:(NSMutableDictionary *)gesture;
- (void)deleteGesture:(NSMutableDictionary *)gesture;
- (void)saveChanges;

- (void)createTemplates;
- (void)permuteStrokeOrderings:(int)count;

- (BOOL)executeActionForGesture:(NSDictionary *)gesture;

@end
