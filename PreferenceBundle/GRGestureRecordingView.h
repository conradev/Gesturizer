#import "GRPaintView.h"

@protocol GRGestureRecordingDelegate <NSObject>
- (void)gestureWasRecorded:(NSArray *)strokes;
@end

@interface GRGestureRecordingView : GRPaintView {
    NSMutableArray *strokes;
    NSMutableArray *currentStroke;

    NSTimer *waitTimer;
}

@property (nonatomic, retain) id<GRGestureRecordingDelegate> delegate;

- (void)doneDetectingStrokes;

@end
