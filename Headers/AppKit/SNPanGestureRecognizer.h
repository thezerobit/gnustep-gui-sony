#import <AppKit/SNGestureRecognizer.h>

@interface SNPanGestureRecognizer : SNGestureRecognizer {
  NSUInteger numberOfTouchesRequired;
  float      minimumPanMovement;
  NSPoint    translationInWindow;

  NSPoint initialCentroid;
  NSPoint currentCentroid;
  NSPoint previousCentroid;
  NSPoint endCentroid;

  NSTimeInterval initialTimestamp;
  NSTimeInterval currentTimestamp;
  NSTimeInterval previousTimestamp;
  NSTimeInterval endTimestamp;

  // # of touches of the pan; must be equal to numberOfTouchesRequired
  NSUInteger touchCount;

  // # of touches remaining on screen when touchesEnded is called 
  NSUInteger touchesOnScreen; 
}

- (void) setNumberOfTouchesRequired: (NSUInteger)num;
- (void) setMinimumPanMovement: (float)movement;
- (void) touchesNotSynchronized: (NSTimer*)timer;
- (NSPoint) translationInWindow;
- (NSPoint) velocityInWindow;

@end
