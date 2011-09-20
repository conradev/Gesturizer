#import "GRGestureRecordingView.h"

@implementation GRGestureRecordingView

@synthesize delegate=_delegate;

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor darkGrayColor];
        strokes = [[[NSMutableArray alloc] init] retain];
        waitTimer = nil;
    }
    return self;
}

- (void)dealloc {
    [strokes release];
    self.delegate = nil;
    [super dealloc];
}

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    if ([waitTimer isValid]) {
        [waitTimer invalidate];
        waitTimer = nil;
    }

    currentStroke = [[NSMutableArray alloc] init];

	CGPoint touchLocation = [[touches anyObject] locationInView:self];
    NSDictionary *touch = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:touchLocation.x], @"x", [NSNumber numberWithFloat:touchLocation.y], @"y", nil];
    [currentStroke addObject:touch];
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    CGPoint touchLocation = [[touches anyObject] locationInView:self];
    NSDictionary *touch = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:touchLocation.x], @"x", [NSNumber numberWithFloat:touchLocation.y], @"y", nil];
    [currentStroke addObject:touch];
}

// Handles the end of a touch event when the touch is a tap.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];

    CGPoint touchLocation = [[touches anyObject] locationInView:self];
    NSDictionary *touch = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:touchLocation.x], @"x", [NSNumber numberWithFloat:touchLocation.y], @"y", nil];
    [currentStroke addObject:touch];

    [strokes addObject:currentStroke];
    [currentStroke release];
    currentStroke = nil;

    if ([strokes count] >= 4) {
        [self doneDetectingStrokes];
        return;
    }

    waitTimer = [NSTimer scheduledTimerWithTimeInterval:1.75f target:self selector:@selector(doneDetectingStrokes) userInfo:nil repeats:NO];
}

// Handles the end of a touch event.
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];

    CGPoint touchLocation = [[touches anyObject] locationInView:self];
    NSDictionary *touch = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:touchLocation.x], @"x", [NSNumber numberWithFloat:touchLocation.y], @"y", nil];
    [currentStroke addObject:touch];


    [strokes addObject:currentStroke];
    [currentStroke release];
    currentStroke = nil;

    [self doneDetectingStrokes];
}

- (void)doneDetectingStrokes {
    if (self.delegate) {
        [self.delegate gestureWasRecorded:strokes];
    }
}

@end
