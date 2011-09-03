#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern int const WTMGlyphMinInflectionPointCount;
extern int const GRResolution;
extern int const GRResamplePointsCount;
extern int const GRStartAngleIndex;
extern float const GR1DThreshold;
extern float const GRAngleSimilarityThreshold;

float Distance(CGPoint pointOne, CGPoint pointTwo);
CGRect BoundingBox(NSArray *stroke);
float PathLength(NSArray *stroke);

NSArray* Resample(NSArray *stroke, int num);
NSArray* Scale(NSArray *stroke, int resolution, float threshold);
NSMutableArray* Splice(NSMutableArray *originalStroke, id newObject, int index);

float IndicativeAngle(NSArray *stroke);
NSArray* TranslateToOrigin(NSArray *stroke);
NSDictionary* CalcStartUnitVector(NSArray *stroke, int count);
float AngleBetweenUnitVectors(NSDictionary *unitVectorOne, NSDictionary *unitVectorTwo);
NSArray* Vectorize(NSArray *stroke);
float OptimalCosineDistance(NSArray *vectorOne, NSArray *vectorTwo);
