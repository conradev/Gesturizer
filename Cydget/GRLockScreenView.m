#import "GRLockScreenView.h"

#import "GRGestureRecognizer.h"

@implementation GRLockScreenView

@synthesize paintView=_paintView;

- (id)init {
    if ((self = [super init])) {
        self.backgroundColor = [UIColor blackColor];
        self.multipleTouchEnabled = NO;
    }

    return self;
}

- (void)setAlpha:(float)alpha {
    [super setAlpha:(alpha * 0.45)];
}

- (void)dealloc {
    self.paintView = nil;

    [super dealloc];
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];

    Class $GRPaintView;
    if (!($GRPaintView = objc_getClass("GRPaintView"))) {
        return;
    }

    [UIView animateWithDuration:.5 animations: ^ { [self.paintView setAlpha:0]; } completion: ^ (BOOL finished) {
            [self.paintView removeFromSuperview];
            self.paintView = [[[$GRPaintView alloc] initWithFrame:frame] autorelease];
            self.paintView.backgroundColor = [UIColor clearColor];
            [self addSubview:self.paintView];
        }];

    for (GRGestureRecognizer *gestureRecognizer in self.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:objc_getClass("GRGestureRecognizer")]) {
            if ([gestureRecognizer.waitTimer isValid]) {
                [gestureRecognizer.waitTimer invalidate];
            }

            gestureRecognizer.waitTimer = nil;
        }
    }
}

@end
