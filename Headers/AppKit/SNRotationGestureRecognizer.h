#import <AppKit/SNGestureRecognizer.h>

@interface SNRotationGestureRecognizer : SNGestureRecognizer {

  NSUInteger identity1;
  NSUInteger identity2;

  float minimumRotation;
  float rotation;

  //NSPoint initialCentroid;
  NSPoint currentCentroid;
  //NSPoint previousCentroid;
  //NSPoint endCentroid;

  float initialAngle;
  float currentAngle;
  float previousAngle;
  float endAngle;

  NSTimeInterval initialTimestamp;
  NSTimeInterval currentTimestamp;
  NSTimeInterval previousTimestamp;
  NSTimeInterval endTimestamp;
}

- (void) setMinimumRotation: (float)minRotation;
- (float) rotation;
- (float) velocity;
- (float) angleFrom: (NSPoint) p1 to: (NSPoint) p2;
- (float) rotationFrom: (float) angle1 to: (float) angle2;

@end
