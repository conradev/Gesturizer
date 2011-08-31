#import <GraphicsServices/GraphicsServices.h>
#import <AppSupport/AppSupport.h>
#import <QuartzCore/CAWindowServer.h>
#import <QuartzCore/CAWindowServerDisplay.h>
#import <SpringBoard/SpringBoard.h>

#import <libactivator/libactivator.h>

#include <mach/mach_port.h>
#include <mach/mach_init.h>
#include <substrate.h>
#include <dlfcn.h>

#import "GRWindow.h"
#import "GRGestureRecognizer.h"

@interface GRGestureController : NSObject <LAListener, LAEventDataSource> {
    GRWindow *_window;
    GRGestureRecognizer *_gestureRecognizer;
    UIWindow *prevKeyWindow;

    BOOL windowIsActive;

    NSMutableArray *oneSuchOrdering;
    NSMutableArray *permutedStrokeOrderings;

    NSDictionary *_gestures;
}

@property (nonatomic, retain) GRWindow *window;
@property (nonatomic, retain) GRGestureRecognizer *gestureRecognizer;
@property (nonatomic, retain) NSDictionary *gestures;

+ (GRGestureController *)sharedInstance;

- (id)init;

- (void)activateWindow;
- (void)deactivateWindow;

- (void)permuteStrokeOrderings:(int)count;
- (void)createTemplates;

- (BOOL)executeActionForGesture:(NSDictionary *)gesture;
- (void)reloadSettings;
- (void)sendMouseRefocusAtLocation:(CGPoint)virtualLocation withPathIndex:(int)pathIndex;

@end
