#import <AppSupport/AppSupport.h>
#import <SpringBoard/SpringBoard.h>

#import <libactivator/libactivator.h>

#import <objc/runtime.h>

#import "GRWindow.h"
#import "GRGestureRecognizer.h"

@interface GRGestureController : NSObject <LAListener, LAEventDataSource> {
    GRWindow *_window;
    GRGestureRecognizer *_gestureRecognizer;
    UIWindow *prevKeyWindow;

    BOOL windowIsActive;

    NSMutableArray *oneSuchOrdering;
    NSMutableArray *permutedStrokeOrderings;

    NSMutableDictionary *_gestures;
    NSMutableDictionary *_settingsDict;

    NSOperationQueue *_asyncQueue;
    BOOL isInitializing;
}

@property (nonatomic, retain) GRWindow *window;
@property (nonatomic, retain) GRGestureRecognizer *gestureRecognizer;
@property (nonatomic, retain) NSMutableDictionary *settingsDict;
@property (nonatomic, retain) NSMutableDictionary *gestures;

+ (GRGestureController *)sharedInstance;

- (id)init;

- (void)activateWindow;
- (void)deactivateWindow;

- (void)memoryWarning;

- (void)updateGesture:(NSMutableDictionary *)gesture;
- (void)deleteGesture:(NSMutableDictionary *)gesture;
- (void)saveChanges;

- (void)createTemplates;
- (void)permuteStrokeOrderings:(int)count;

- (BOOL)executeActionForGesture:(NSDictionary *)gesture;
- (BOOL)canExecuteActionForGesture:(NSDictionary *)gesture;

@end
