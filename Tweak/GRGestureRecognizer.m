#import "GRGestureRecognizer.h"
#import "GRGestureRecognitionFunctions.h"

@implementation GRGestureRecognizer

@synthesize gestures=_gestures, points=_points, sortedResults=_sortedResults, waitTimer=_waitTimer;

- (id)initWithTarget:(id)target action:(SEL)action {
    if ((self = [super initWithTarget:target action:action])) {
        self.points = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc {
    self.gestures = nil;
    self.points = nil;
    self.sortedResults = nil;

    [super dealloc];
}

// Handles the start of a touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([self.waitTimer isValid]) {
        [self.waitTimer invalidate];
    }
    self.waitTimer = nil;

    CGPoint touchLocation = [[touches anyObject] locationInView:nil];
    NSDictionary *touchDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:touchLocation.x], @"x", [NSNumber numberWithFloat:touchLocation.y], @"y", nil];
    [self.points addObject:touchDict];
}

// Handles the continuation of a touch.
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint touchLocation = [[touches anyObject] locationInView:nil];
    NSDictionary *touchDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:touchLocation.x], @"x", [NSNumber numberWithFloat:touchLocation.y], @"y", nil];
    [self.points addObject:touchDict];

}

// Handles the end of a touch event when the touch is a tap.
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint touchLocation = [[touches anyObject] locationInView:nil];
    NSDictionary *touchDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:touchLocation.x], @"x", [NSNumber numberWithFloat:touchLocation.y], @"y", nil];
    [self.points addObject:touchDict];

    self.waitTimer = [NSTimer scheduledTimerWithTimeInterval:1.75f target:self selector:@selector(recognizeGesture) userInfo:nil repeats:NO];
}

// Handles the end of a touch event.
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
   CGPoint touchLocation = [[touches anyObject] locationInView:nil];
    NSDictionary *touchDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:touchLocation.x], @"x", [NSNumber numberWithFloat:touchLocation.y], @"y", nil];
    [self.points addObject:touchDict];

    [self recognizeGesture];
}

- (void)recognizeGesture {
    self.waitTimer = nil;

    NSMutableArray *normalizedPoints = [NSMutableArray arrayWithArray:TranslateToOrigin(Scale(Resample(self.points, GRResamplePointsCount), GRResolution, GR1DThreshold))];
    NSDictionary *startUnitVector = CalcStartUnitVector(normalizedPoints, GRStartAngleIndex);
    NSMutableArray *vector = [NSMutableArray arrayWithArray:Vectorize(normalizedPoints)];
    NSMutableDictionary *inputTemplate = [NSMutableDictionary dictionaryWithObjectsAndKeys:startUnitVector, @"startUnitVector", vector, @"vector", nil];
    [self.points removeAllObjects];

    for (NSMutableDictionary *gesture in self.gestures) {
        float lowestDistance = FLT_MAX;
        for (NSDictionary *template in [gesture objectForKey:@"templates"]) {
            //if (AngleBetweenUnitVectors([template objectForKey:@"startUnitVector"], [inputTemplate objectForKey:@"startUnitVector"]) <= GRAngleSimilarityThreshold) {
                float distance = OptimalCosineDistance([template objectForKey:@"vector"], [inputTemplate objectForKey:@"vector"]);

                if (distance < lowestDistance)
                    lowestDistance = distance;
            //}
        }
        float score = 1 / lowestDistance;
        [gesture setObject:[NSNumber numberWithFloat:score] forKey:@"score"];
    }

    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO] autorelease];
    NSArray *sortedResults = [self.gestures sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    self.sortedResults = sortedResults;

    self.state = UIGestureRecognizerStateRecognized;
}

@end
