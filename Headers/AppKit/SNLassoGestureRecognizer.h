#import <AppKit/SNGestureRecognizer.h>

/***
typedef enum {
   Undecided        = 0,
   Clockwise        = 1 << 0,
   CounterClockwise = 1 << 1,
} RotationDirection;
***/

@interface SNLassoGestureRecognizer : SNGestureRecognizer {

  NSMutableArray *vertices;
  NSPoint initialPoint;
  NSPoint currentPoint;
  NSPoint previousPoint;

  float granularity;
  float maxEndToBeginDistance;

  float currentTangent;
  float previousTangent;

  /***
  float currentRotation;
  float previousRotation;
  float totalRotation;
  float rotationBeganThreshold;
  float minTotalRotation;
  float maxTotalRotation;
  float rotationStepCeiling;
  float rotationStepFloor;
  float currentStepFloor;
  ***/

  float totalRotation;
  float minRotation;
  BOOL minRotationReached;

  float maxX;
  float maxY;
  float minX;
  float minY;

  float winding;
  //RotationDirection rotationDirection;

}


- (void) setGranularity: (float) aGranularity;
- (void) setMaxEndToBeginDistance: (float) distance;
- (void) setMinRotation: (float) rotation;
- (float) windingNumber;
//- (float) rotation;
//- (RotationDirection) direction;
//- (void) setRotationBeganThreshold: (float) rotation;
//- (void) setMinTotalRotation: (float) minRotation;
//- (void) setMaxTotalRotation: (float) maxRotation;
- (float) distanceFrom: (NSPoint) p1 to: (NSPoint) p2;
- (float) angleFrom: (NSPoint) p1 to: (NSPoint) p2;
- (float) rotationFrom: (float) angle1 to: (float) angle2;
- (BOOL) pointInLasso: (NSPoint) point inView: (NSView *) view;
- (float) calculateWindingNumberFrom: (NSPoint) v1 to: (NSPoint) v2;

@end
