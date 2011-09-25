#import "GRPaintView.h"

@implementation GRPaintView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0.45f;
        drawPath = [[UIBezierPath alloc] init];
        drawPath.lineWidth = 32;
        drawPath.lineCapStyle = kCGLineCapRound;
        drawPath.lineJoinStyle = kCGLineJoinRound;
        brushPattern = [[UIColor whiteColor] retain];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [brushPattern setStroke];
    [drawPath strokeWithBlendMode:kCGBlendModeDestinationAtop alpha:1.0f];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [drawPath moveToPoint:[[touches anyObject] locationInView:self]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [drawPath addLineToPoint:[[touches anyObject] locationInView:self]];
    [self setNeedsDisplay];
}

- (void)dealloc {
    [brushPattern release];
    [drawPath release];

    [super dealloc];
}

@end
