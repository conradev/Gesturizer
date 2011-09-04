#import <UIKit/UIGestureRecognizerSubclass.h>

@interface GRGestureRecognizer : UIGestureRecognizer {
    NSMutableArray *_gestures;
    NSMutableArray *_points;

    NSTimer *_waitTimer;
}

@property (nonatomic, retain) NSArray *gestures;
@property (nonatomic, retain) NSMutableArray *points;
@property (nonatomic, retain) NSArray *sortedResults;
@property (nonatomic, retain) NSTimer *waitTimer;
@property (nonatomic) int orientation;

- (void)recognizeGesture;
- (void)addPoint:(CGPoint)point;

@end
