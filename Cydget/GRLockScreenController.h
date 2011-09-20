#import <SpringBoardUI/SBAwayViewPluginController.h>

#import "GRGestureRecognizer.h"
#import "GRGestureController.h"

@interface GRLockScreenController  : SBAwayViewPluginController  {
    GRGestureRecognizer *_gestureRecognizer;
}

@property (nonatomic, retain) GRGestureRecognizer *gestureRecognizer;

@end
