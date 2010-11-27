#import <AppKit/SNGestureRecognizer.h>

@interface SNLongPressGestureRecognizer : SNGestureRecognizer {
  NSUInteger numberOfTapsRequired;
  NSUInteger numberOfTouchesRequired;
  NSTimeInterval minimumPressDuration;
  float allowableMovement;
  NSPoint initialCentroid;

  // # of touches remaining on screen; must be equal to numberOfTouchesRequired 
  // when verifyLongPress is called
  NSUInteger touchesOnScreen; 

  NSMutableDictionary *tapCountDictionary;
  NSTimeInterval maximumTimeBetweenTaps;
  float maximumMovementBetweenTaps;

  NSTimer *cleanDictionaryTimer;
}

- (void) setNumberOfTapsRequired: (NSUInteger)num;
- (void) setNumberOfTouchesRequired: (NSUInteger)num;
- (void) setMaximumTimeBetweenTaps: (NSTimeInterval)time;
- (void) setMaximumMovementBetweenTaps: (float)move;
- (void) setMinimumPressDuration: (NSTimeInterval)duration;
- (void) setAllowableMovement: (float)movement;
- (void) verifyLongPress: (NSTimer*)timer;
- (void) failLongPress: (NSTimer*)timer;
- (BOOL) testTapCount: (NSSet*)touches withEvent:(NSEvent*)event;
- (BOOL) allTouchesHaveTapCount: (NSUInteger)tap;
- (void) cleanDictionary: (NSTimer*)timer;

@end
