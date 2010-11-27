#include <AppKit/SNTapGestureRecognizer.h>

@implementation SNTapGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action
{
   self = [super initWithTarget:target action:action];

   if (self)
   {
      // Default property values
      numberOfTapsRequired = 1;
      numberOfTouchesRequired = 1;
      allowableMovement = 3; // pixels
      tapCountDictionary = [[NSMutableDictionary alloc] initWithCapacity: 2];
      maximumTimeBetweenTaps = 0.3; //seconds
      maximumMovementBetweenTaps = 25; //pixels
   }

   return self;
}

- (void)reset
{
   // Don't fail recognizer immediately because more taps may come
   //[super reset];

   if (_actionSent)
   {
      [super reset];
      touchesOnScreen = 0;
      initialCentroid = NSZeroPoint;
      [tapCountDictionary removeAllObjects];
   }
   else if (_state == SNGestureRecognizerStateFailed)
   {
      [super reset];
      touchesOnScreen = 0;
      initialCentroid = NSZeroPoint;

      // Delay dictionary cleaning here because we're managing tap counts
      // ourselves. This will avoid situations like this: a 5-tap is picked
      // up by a double tap gesture recognizer because at tap #3, the GR
      // cleans the dictionary, and when it receives tap #4 and #5, it
      // mistakenly thinks it's a double tap

      // We don't move everything in the reset method to the timer action
      // method because we still want to reset the GR immediately so the 
      // GR can continue to receive touches, and hence the tap counts in
      // our dictionary will be correct
      cleanDictionaryTimer = [[NSTimer alloc] initWithFireDate: nil
                                                      interval: maximumTimeBetweenTaps
                                                        target: self
                                                      selector: @selector(cleanDictionary:)
                                                      userInfo: nil
                                                       repeats: NO];

      [[NSRunLoop currentRunLoop] addTimer: cleanDictionaryTimer
                                   forMode: NSDefaultRunLoopMode];
   }
}

- (NSPoint)locationInView:(NSView *)view
{
   if (view)
      return [view convertPoint: initialCentroid fromView: nil];
   else
      return initialCentroid;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesBegan:touches withEvent:event];

   if ([cleanDictionaryTimer isValid])
   {
      [cleanDictionaryTimer invalidate];
      [cleanDictionaryTimer release];
      cleanDictionaryTimer = nil;
   }

   if (touchesOnScreen == 0)
   {
      if ([_timer isValid])
      {
         [_timer invalidate];
         [_timer release];
         _timer = nil;
      }
   }

   if ([self testTapCount: touches withEvent: event])
   {
      printf("SNTapGestureRecognizer: Tap count exceeded\n");
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }

   /*** Cannot assume touches will come simultaneously
   if ([touches count] != numberOfTouchesRequired)
   {
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }
   ***/

   //if (touchCount > numberOfTouchesRequired)
   if ([tapCountDictionary count] > numberOfTouchesRequired)
   {
      printf("SNTapGestureRecognizer: Touch count exceeded\n");
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }

   //if (touchCount == numberOfTouchesRequired && tapCount == 1)
   if ([tapCountDictionary count] == numberOfTouchesRequired && [self allTouchesHaveTapCount: 1])
      initialCentroid = [self centroidOfTouchesInWindow: [event touchesForView: _hitTestedView]];

   // fire timer as soon as we see the first touch
   if (touchesOnScreen == 0)
   {
      _timer = [[NSTimer alloc] initWithFireDate: nil
                                        interval: 0.3 //1.0
                                          target: self
                                        selector: @selector(verifyTap:)
                                        userInfo: nil
                                         repeats: NO];

      [[NSRunLoop currentRunLoop] addTimer: _timer
                                   forMode: NSDefaultRunLoopMode];
   }

   touchesOnScreen += [touches count];

}

- (void)touchesMoved:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesMoved:touches withEvent:event];

   if ([_timer isValid])
   {
      NSPoint currentCentroid = [self centroidOfTouchesInWindow: [event touchesForView: _hitTestedView]];
     
      //if ([self distanceFrom: initialCentroid to: currentCentroid] > allowableMovement)
      if (currentCentroid.x - initialCentroid.x > allowableMovement  ||
          currentCentroid.x - initialCentroid.x < -allowableMovement ||
          currentCentroid.y - initialCentroid.y > allowableMovement  ||
          currentCentroid.y - initialCentroid.y < -allowableMovement)
      {
         printf("SNTapGestureRecognizer: finger(s) moved too far to be considered a tap\n");
         [self changeState: SNGestureRecognizerStateFailed];
      }
   }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesEnded:touches withEvent:event];

   touchesOnScreen -= [touches count];

   if (touchesOnScreen == 0 && [_timer isValid])
   {
      [_timer invalidate];
      [_timer release];
      _timer = nil;
   }

   // We don't need this; touches are not received in Failed state
   //if (_state == SNGestureRecognizerStateFailed) return;

   /*** Cannot assume touches will come simultaneously
   if ([touches count] != numberOfTouchesRequired)
   {
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }
   ***/

   if (touchesOnScreen == 0)
   {
      _timer = [[NSTimer alloc] initWithFireDate: nil
                                        interval: maximumTimeBetweenTaps //0.3 //1.0
                                          target: self
                                        selector: @selector(verifyTap:)
                                        userInfo: nil //touches
                                         repeats: NO];

      [[NSRunLoop currentRunLoop] addTimer: _timer
                                   forMode: NSDefaultRunLoopMode];
   }
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesCancelled:touches withEvent:event];

   if ([_timer isValid])
   {
      [_timer invalidate];
      [_timer release];
      _timer = nil;
   }
}

- (void) setNumberOfTapsRequired: (NSUInteger)num
{
   numberOfTapsRequired = num;
}

- (void) setNumberOfTouchesRequired: (NSUInteger)num
{
   numberOfTouchesRequired = num;
}

- (void) setAllowableMovement: (float)movement
{
   allowableMovement = movement;
}

- (void) setMaximumTimeBetweenTaps: (NSTimeInterval)time
{
   maximumTimeBetweenTaps = time;
}

- (void) setMaximumMovementBetweenTaps: (float)move
{
   maximumMovementBetweenTaps = move;
}

- (void) verifyTap: (NSTimer*)timer
{
   //BOOL tapRecognized = YES;

   if (touchesOnScreen != 0)
   {
      printf("SNTapGestureRecognizer: looks like we have a long press\n");
      //[self notifyFailure];
      [self changeState: SNGestureRecognizerStateFailed];
      //[self reset];
   }
   //else if (tapCount == numberOfTapsRequired && touchCount == numberOfTouchesRequired)
   else if ([tapCountDictionary count] == numberOfTouchesRequired && [self allTouchesHaveTapCount: numberOfTapsRequired])
   {
      [self changeState: SNGestureRecognizerStateRecognized];
   }
   else
   {
      [self changeState: SNGestureRecognizerStateFailed];

      // We end up here when touchesOnScreen == 0, so this timer must have been
      // fired by touchesEnded. By the time this block is executed, which is 
      // delayed by 0.3 seconds, NSWindow would have reset the state already.
      // Therefore, after transitioning the state to "Failed" here, we must reset
      // manually or this GR will not receive touches for the next MT sequence. 
      [self reset];
   }

   /*** It's now touchesBegan's job to verify # of taps
   else
   {
      NSSet *touches = [timer userInfo];
      NSEnumerator *enumerator = [touches objectEnumerator];
      SNTouch *theTouch;

      while ((theTouch = [enumerator nextObject]))
      {
         if ([theTouch tapCount] != numberOfTapsRequired)
         {
            tapRecognized = NO;
            break;
         }
      }

      if (tapRecognized)
      {
         //_state = SNGestureRecognizerStateRecognized;
         //[self tryToSendAction];
         [self changeState: SNGestureRecognizerStateRecognized];
      }
   }
   ***/

   [_timer release];
   _timer = nil;
}

/*
 * Returns YES when at least one of the tap counts exceeds 
 * the requirement, NO otherwise
 */
- (BOOL) testTapCount: (NSSet*)touches withEvent:(NSEvent*)event
{
   NSEnumerator *enumerator = [touches objectEnumerator];
   SNTouch *touch;
   NSNumber *key;
   SNTouchPhase phase;
   LastTouch *lastTouch;
   BOOL tapCountExceeded = NO;

   while ((touch = [enumerator nextObject]))
   {
      //if ([touch userTapCount] != 0)
      //   continue;

      phase = [touch phase];
      key = [NSNumber numberWithUnsignedInteger: [touch identity]];

      switch (phase)
      {
         case SNTouchPhaseBegan:
           if ((lastTouch = [tapCountDictionary objectForKey: key]))
           {
              BOOL incrementCount = YES;
              NSPoint location = [touch locationInWindow];

	      if ([event timestamp] > lastTouch->timestamp + maximumTimeBetweenTaps)
	         incrementCount = NO;
	      else if ((lastTouch->location).x - location.x > maximumMovementBetweenTaps)
	         incrementCount = NO;
	      else if ((lastTouch->location).x - location.x < -maximumMovementBetweenTaps)
	         incrementCount = NO;
	      else if ((lastTouch->location).y - location.y > maximumMovementBetweenTaps)
	         incrementCount = NO;
	      else if ((lastTouch->location).y - location.y < -maximumMovementBetweenTaps)
	         incrementCount = NO;

	      if (incrementCount == YES)
	      {
	         (lastTouch->tapCount)++;

                 //printf("lastTouch->tapCount = %i\n", lastTouch->tapCount);
                 if (lastTouch->tapCount > numberOfTapsRequired)
                    tapCountExceeded = YES;
	      }
              else
              {
	         // Not a multiple-tap, so we must set the stored
	         // location of the tap to the new values and
	         // reset the counter.
                 lastTouch->tapCount = 1;
                 lastTouch->location = [touch locationInWindow];
              }

              lastTouch->timestamp = [event timestamp]; 
              
           }
           else
           {
              // first time seeing this touch ID
              lastTouch = [[LastTouch alloc] init];
              lastTouch->timestamp = [event timestamp]; 
              lastTouch->location = [touch locationInWindow];
              lastTouch->tapCount = 1;
              [tapCountDictionary setObject: lastTouch forKey: key];
              [lastTouch release];
           }

           //touch->userTapCount = lastTouch->tapCount;

           break;
         default:
           /***
           if ((lastTouch = [tapCountDictionary objectForKey: key]))
           {
              touch->userTapCount = lastTouch->tapCount;
           }
           else
           {
              // We should never run into this situation where it is not
              // a touchBegan yet the tap record for this ID isn't found 
              // in the dictionary
              touch->userTapCount = 1;
           }
           ***/
           break;
      }

   }

   return tapCountExceeded;
}

- (BOOL) allTouchesHaveTapCount: (NSUInteger)tap;
{
   NSEnumerator *enumerator = [tapCountDictionary objectEnumerator];
   LastTouch *lastTouch;

   while ((lastTouch = [enumerator nextObject]))
   {
      if (lastTouch->tapCount != tap)
         return NO;
   }

   return YES;
}

- (void) cleanDictionary: (NSTimer*)timer
{
   [tapCountDictionary removeAllObjects];
   [cleanDictionaryTimer release];
   cleanDictionaryTimer = nil;
}

- (void)dealloc
{
   RELEASE(tapCountDictionary);
   [super dealloc];
}

@end
