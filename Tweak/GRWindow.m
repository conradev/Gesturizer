
#import "GRWindow.h"

@implementation GRWindow

@synthesize paintView=_paintView;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor blackColor];
        self.multipleTouchEnabled = NO;
        self.alpha = 0.0f;

        self.paintView = [[[GRPaintView alloc] initWithFrame:frame] autorelease];
        [self addSubview:self.paintView];
    }
    return self;
}

- (void)dealloc {
    self.paintView = nil;

    [super dealloc];
}

@end
