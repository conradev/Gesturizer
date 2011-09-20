#import <UIKit/UIKit.h>
#import "GRPaintView.h"

@interface GRLockScreenView : UIView {
    GRPaintView *_paintView;
}

@property (nonatomic, retain) GRPaintView *paintView;

@end
