#import <AppKit/SNGestureRecognizer.h>

typedef enum {
   SNSwipeGestureRecognizerDirectionRight = 1 << 0,
   SNSwipeGestureRecognizerDirectionLeft  = 1 << 1,
   SNSwipeGestureRecognizerDirectionUp    = 1 << 2,
   SNSwipeGestureRecognizerDirectionDown  = 1 << 3
} SNSwipeGestureRecognizerDirection;

@interface SNSwipeGestureRecognizer : SNGestureRecognizer {
  NSUInteger                        numberOfTouchesRequired;
  SNSwipeGestureRecognizerDirection direction;
  SNSwipeGestureRecognizerDirection recognizedDirection;
  float                             minimumSwipeDistance;
  NSTimeInterval                    maximumSwipeDuration;
  float                             allowableAngleDeviation;

  NSPoint initialCentroid;

  // Fingers can touch down & lift up at different times
  // This timer is used so that all required fingers must touch down
  // within 0.3 second, and when ending the gesture, all of them
  // must lift up within 0.3 second too
  NSTimer *_touchCountTimer;

  // # of touches of the swipe; must be equal to numberOfTouchesRequired
  NSUInteger touchCount;

  // # of touches remaining on screen when touchesEnded is called 
  NSUInteger touchesOnScreen; 
}

- (void) setNumberOfTouchesRequired: (NSUInteger)num;
- (void) setDirection: (SNSwipeGestureRecognizerDirection)dir;
- (void) setMinimumSwipeDistance: (float)distance;
- (void) setMaximumSwipeDuration: (NSTimeInterval)duration;
- (void) setAllowableAngleDeviation: (float)angle;
- (SNSwipeGestureRecognizerDirection) direction;

- (void) durationExceeded: (NSTimer*)timer;
- (void) touchesNotSynchronized: (NSTimer*)timer;
- (float) angleFrom: (NSPoint) p1 to: (NSPoint) p2;
- (BOOL) directionPermitted: (float)currentAngle;

@end
