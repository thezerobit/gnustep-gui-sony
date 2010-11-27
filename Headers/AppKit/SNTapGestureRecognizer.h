#import <AppKit/SNGestureRecognizer.h>

@interface SNTapGestureRecognizer : SNGestureRecognizer {
  NSUInteger numberOfTapsRequired;
  NSUInteger numberOfTouchesRequired;
  NSPoint initialCentroid;
  float allowableMovement;

  // # of touches remaining on screen when verifyTap is called
  // must be equal to zero for the tap to be recognized
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
- (void) setAllowableMovement: (float)movement;
- (void) verifyTap: (NSTimer*)timer;
- (BOOL) testTapCount: (NSSet*)touches withEvent:(NSEvent*)event;
- (BOOL) allTouchesHaveTapCount: (NSUInteger)tap;
- (void) cleanDictionary: (NSTimer*)timer;

@end
