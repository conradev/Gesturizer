#import "GRGestureRecognitionFunctions.h"

int const WTMGlyphMinInflectionPointCount = 10;
int const GRResolution = 320;
int const GRResamplePointsCount = 96;
int const GRStartAngleIndex = 12;
float const GR1DThreshold = 0.25;

float min(float a, float b) {
    return a < b ? a : b;
}

float max(float a, float b) {
    return a > b ? a : b;
}

NSArray* Resample(NSArray *stroke, int num) {
    NSMutableArray *workingStroke = [NSMutableArray arrayWithArray:stroke];
    NSMutableArray *newStroke = [NSMutableArray arrayWithObject:[stroke objectAtIndex:0]];
    float resampledDistance = PathLength(stroke) / (num - 1);

    float workingDistance = 0.0f;
    for (int i=1; i < [workingStroke count]; i++) {
        CGPoint previousPoint = CGPointMake([[[workingStroke objectAtIndex:(i-1)] objectForKey:@"x"] floatValue], [[[workingStroke objectAtIndex:(i-1)] objectForKey:@"y"] floatValue]);
        CGPoint currentPoint  = CGPointMake([[[workingStroke objectAtIndex:i] objectForKey:@"x"] floatValue], [[[workingStroke objectAtIndex:i] objectForKey:@"y"] floatValue]);
        float currentDistance = Distance(previousPoint, currentPoint);

        if ((workingDistance + currentDistance) >= resampledDistance) {
            float x = previousPoint.x + ((resampledDistance - workingDistance) / currentDistance) * (currentPoint.x - previousPoint.x);
            float y = previousPoint.y + ((resampledDistance - workingDistance) / currentDistance) * (currentPoint.y - previousPoint.y);
            NSDictionary *newPoint = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:x], @"x", [NSNumber numberWithFloat:y], @"y", nil];
            [newStroke addObject:newPoint];
            workingStroke = Splice(workingStroke, newPoint, i);
            workingDistance = 0.0f;
        } else {
            workingDistance += currentDistance;
        }
    }

    NSDictionary *lastPoint = [newStroke lastObject];
    for (int i=0; i < (num - [newStroke count]); i++) {
        [newStroke addObject:lastPoint];
    }

    return newStroke;
}

NSArray* Scale(NSArray *originalStroke, int resolution, float threshold) {
    NSMutableArray *scaledStroke = [NSMutableArray array];

    CGRect boundingBox = BoundingBox(originalStroke);
    BOOL isOneDimensional = min(boundingBox.size.width / boundingBox.size.height, boundingBox.size.height / boundingBox.size.width) <= threshold;

    for (NSDictionary *pointDict in originalStroke) {
        CGPoint point = CGPointMake([[pointDict objectForKey:@"x"] floatValue], [[pointDict objectForKey:@"y"] floatValue]);
        float newX;
        float newY;

        if (isOneDimensional) {
            float scale = (resolution / max(boundingBox.size.width, boundingBox.size.height));
            newX = point.x * scale;
            newY = point.y * scale;
        } else {
            newX = point.x * (resolution / boundingBox.size.width);
            newY = point.y * (resolution / boundingBox.size.height);
        }

        NSDictionary *newPointDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:newX], @"x", [NSNumber numberWithFloat:newY], @"y", nil];
        [scaledStroke addObject:newPointDict];
    }

    return scaledStroke;
}

CGRect BoundingBox(NSArray *stroke) {
    float minX = FLT_MAX;
    float maxX = -FLT_MAX;
    float minY = FLT_MAX;
    float maxY = -FLT_MAX;

    for (NSDictionary *pointDict in stroke) {
        CGPoint point = CGPointMake([[pointDict objectForKey:@"x"] floatValue], [[pointDict objectForKey:@"y"] floatValue]);

        if (point.x < minX)
            minX = point.x;
        if (point.y < minY)
            minY = point.y;
        if (point.x > maxX)
            maxX = point.x;
        if (point.y > maxY)
            maxY = point.y;
    }

    return CGRectMake(minX, minY, (maxX-minX), (maxY-minY));
}

NSMutableArray* Splice(NSMutableArray *original, id newObject, int index) {
    NSArray *frontSlice = [original subarrayWithRange:NSMakeRange(0, index)];
    NSArray *backSlice = [original subarrayWithRange:NSMakeRange(index, [original count]  - index)];
    NSMutableArray *spliced = [NSMutableArray arrayWithArray:frontSlice];
    [spliced addObject:newObject];
    [spliced addObjectsFromArray:backSlice];
    return spliced;
}

float PathLength(NSArray *stroke) {
    float distance = 0.0f;
    for (int i=1; i < [stroke count]; i++ ) {
        CGPoint previousPoint = CGPointMake([[[stroke objectAtIndex:(i-1)] objectForKey:@"x"] floatValue], [[[stroke objectAtIndex:(i-1)] objectForKey:@"y"] floatValue]);
        CGPoint currentPoint  = CGPointMake([[[stroke objectAtIndex:i] objectForKey:@"x"] floatValue], [[[stroke objectAtIndex:i] objectForKey:@"y"] floatValue]);

        distance += Distance(previousPoint, currentPoint);
    }
    return distance;
}

float Distance(CGPoint point1, CGPoint point2) {
    int dX = point2.x - point1.x;
    int dY = point2.y - point1.y;
    return sqrt( dX * dX + dY * dY );
}

CGPoint Centroid(NSArray *stroke) {
    float x = 0.0f;
    float y = 0.0f;

    for (NSDictionary *pointDict in stroke) {
        x += [[pointDict objectForKey:@"x"] floatValue];
        y += [[pointDict objectForKey:@"y"] floatValue];
    }

    x /= [stroke count];
    y /= [stroke count];

    return CGPointMake(x, y);
}

// Potential for error here: NDollar uses double!
float IndicativeAngle(NSArray *stroke) {
    CGPoint centroid = Centroid(stroke);
    CGPoint firstPoint = CGPointMake([[[stroke objectAtIndex:0] objectForKey:@"x"] floatValue], [[[stroke objectAtIndex:0] objectForKey:@"y"] floatValue]);
    float x = (centroid.x - firstPoint.x);
    float y = (centroid.y - firstPoint.y);

    return atan2f(y, x);
}

NSArray* TranslateToOrigin(NSArray *originalStroke) {
    NSMutableArray *translatedStroke = [NSMutableArray array];
    CGPoint centroid = Centroid(originalStroke);

    for (NSDictionary *pointDict in originalStroke) {
        CGPoint point = CGPointMake([[pointDict objectForKey:@"x"] floatValue], [[pointDict objectForKey:@"y"] floatValue]);
        float newX = point.x - centroid.x;
        float newY = point.y - centroid.y;
        NSDictionary *newPointDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:newX], @"x", [NSNumber numberWithFloat:newY], @"y", nil];
        [translatedStroke addObject:newPointDict];
    }

    return translatedStroke;
}

NSDictionary* CalcStartUnitVector(NSArray *stroke, int startAngleIndex) {
    CGPoint pointAtIndex = CGPointMake([[[stroke objectAtIndex:startAngleIndex] objectForKey:@"x"] floatValue], [[[stroke objectAtIndex:startAngleIndex] objectForKey:@"y"] floatValue]);
    CGPoint firstPoint   = CGPointMake([[[stroke objectAtIndex:0] objectForKey:@"x"] floatValue], [[[stroke objectAtIndex:0] objectForKey:@"y"] floatValue]);

    float distance = Distance(firstPoint, pointAtIndex);
    NSDictionary *startUnitVector = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:((pointAtIndex.x - firstPoint.x) / distance)], @"x", [NSNumber numberWithFloat:((pointAtIndex.y - firstPoint.y) / distance)], @"y", nil];

    return startUnitVector;
}

float AngleBetweenUnitVectors(NSDictionary *unitVectorOne, NSDictionary *unitVectorTwo) {
    return acosf([[unitVectorOne objectForKey:@"x"] floatValue] * [[unitVectorTwo objectForKey:@"x"] floatValue] + [[unitVectorOne objectForKey:@"y"] floatValue] * [[unitVectorTwo objectForKey:@"y"] floatValue]);
}

NSArray* Vectorize(NSArray *stroke) {
    NSMutableArray *vector = [NSMutableArray array];

    float cos = 1.0;
    float sin = 0.0;
    float sum = 0;

    for (NSDictionary *pointDict in stroke) {
        CGPoint point = CGPointMake([[pointDict objectForKey:@"x"] floatValue], [[pointDict objectForKey:@"y"] floatValue]);
        float newX = point.x * cos - point.y * sin;
        float newY = point.y * cos + point.x * sin;
        [vector addObject:[NSNumber numberWithFloat:newX]];
        [vector addObject:[NSNumber numberWithFloat:newY]];
        sum += newX * newX + newY * newY;
    }

    float magnitude = sqrtf(sum);
    for (int i=0; i < [vector count]; i++) {
        NSNumber *value = [vector objectAtIndex:i];
        NSNumber *scaledValue = [NSNumber numberWithFloat:([value floatValue] / magnitude)];
        [vector replaceObjectAtIndex:i withObject:scaledValue];
    }

    return vector;
}

float OptimalCosineDistance(NSArray *vectorOne, NSArray *vectorTwo) {
    float a = 0.0f;
    float b = 0.0f;

    int minCount = ([vectorOne count] < [vectorTwo count] ? [vectorOne count] : [vectorTwo count]);
    for (int i = 0; i < minCount; i+=2) {
        float valueOne = [[vectorOne objectAtIndex:i] floatValue];
        float valueTwo = [[vectorTwo objectAtIndex:i] floatValue];
        float nextValueOne = [[vectorOne objectAtIndex:(i+1)] floatValue];
        float nextValueTwo = [[vectorTwo objectAtIndex:(i+1)] floatValue];

        a += valueOne * valueTwo + nextValueOne * nextValueTwo;
        b += valueOne * nextValueTwo + nextValueOne * valueTwo;
    }

    float angle = atanf( b / a );
    float score = acosf(a * cos(angle) + b * sin(angle));

    return score;
}
