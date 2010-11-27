#import <AppKit/SNGestureRecognizer.h>

@interface SNPinchGestureRecognizer : SNGestureRecognizer {

  float minimumPinchMovement;
  float scale;
  float movement;

  //NSPoint initialCentroid;
  NSPoint currentCentroid;
  //NSPoint previousCentroid;
  //NSPoint endCentroid;

  float initialDistance;
  float currentDistance;
  float previousDistance;
  float endDistance;

  NSTimeInterval initialTimestamp;
  NSTimeInterval currentTimestamp;
  NSTimeInterval previousTimestamp;
  NSTimeInterval endTimestamp;
}

- (void) setMinimumPinchMovement: (float)minMovement;
- (float) movement;
- (float) scale;
- (float) distanceFrom: (NSPoint) p1 to: (NSPoint) p2;
- (float) velocityOfMovement;
- (float) velocityOfScale;

@end
