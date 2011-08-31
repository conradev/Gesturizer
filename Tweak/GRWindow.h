#import <UIKit/UIKit.h>

#import "GRPaintView.h"

@interface GRWindow : UIWindow {
    GRPaintView *_paintView;
}

@property (nonatomic, retain) GRPaintView *paintView;

@end

