#import <UIKit/UIKit.h>

#import "GRGestureRecordingView.h"

@interface GRGestureRecordingViewController : UIViewController {
    GRGestureRecordingView *recordingView;
}

@property (nonatomic, retain) id<GRGestureRecordingDelegate> delegate;

- (id)initWithDelegate:(id<GRGestureRecordingDelegate>)delegate;

@end
