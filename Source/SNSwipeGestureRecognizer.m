#include <AppKit/SNSwipeGestureRecognizer.h>
#include <math.h>

#define PI 3.141593

@implementation SNSwipeGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action
{
   self = [super initWithTarget:target action:action];

   if (self)
   {
      // Default property values
      numberOfTouchesRequired = 1;
      direction = SNSwipeGestureRecognizerDirectionRight;
      minimumSwipeDistance = 50; // in pixels
      maximumSwipeDuration = 1; // in seconds
      allowableAngleDeviation = 15; // in degrees
   }

   return self;
}

- (void)reset
{
   [super reset];
   initialCentroid = NSZeroPoint;
   touchCount = 0;
   touchesOnScreen = 0;
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

   /*** Cannot assume touches will come simultaneously
   // not a swipe if fingers touch down at different times
   if ([_timer isValid])
   {
      [_timer invalidate];
      [_timer release];
      _timer = nil;
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }
   ***/

   /*** Cannot assume touches will come simultaneously
   if ([touches count] != numberOfTouchesRequired)
   {
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }
   ***/

   touchCount += [touches count];

   if (touchCount >= numberOfTouchesRequired)
   {
      if ([_touchCountTimer isValid])
      {
         [_touchCountTimer invalidate];
         [_touchCountTimer release];
         _touchCountTimer = nil;
      }

      if (touchCount > numberOfTouchesRequired)
      {
         printf("SNSwipeGestureRecognizer: Touch count exceeded\n");
         [self changeState: SNGestureRecognizerStateFailed];
         return;
      }
      else // touchCount == numberOfTouchesRequired
      {
         initialCentroid = [self centroidOfTouchesInWindow: [event touchesForView: _hitTestedView]];
      }
   }

   // fire timer as soon as we see the first touch
   if (touchesOnScreen == 0)
   {
      // Swipe must be fast enough; duration must be within a time limit
      _timer = [[NSTimer alloc] initWithFireDate: nil
                                        interval: maximumSwipeDuration
                                          target: self
                                        selector: @selector(durationExceeded:)
                                        userInfo: nil
                                         repeats: NO];

      [[NSRunLoop currentRunLoop] addTimer: _timer
                                   forMode: NSDefaultRunLoopMode];

      if (touchCount < numberOfTouchesRequired)
      {
         if ([_touchCountTimer isValid])
         {
            // _touchCounterTimer might have been fired by touchesEnded, so
            // we have a touch up & down situation, which is not valid
            [_touchCountTimer invalidate];
            [_touchCountTimer release];
            _touchCountTimer = nil;

            printf("SNSwipeGestureRecognizer: Touch up & down during swipe\n");
            [self changeState: SNGestureRecognizerStateFailed];
            return;
         }
         else
         {
            // Required # of touches must touch surface within 0.3 seconds
            _touchCountTimer = [[NSTimer alloc] initWithFireDate: nil
                                                        interval: 0.3
                                                          target: self
                                                        selector: @selector(touchesNotSynchronized:)
                                                        userInfo: nil
                                                         repeats: NO];

            [[NSRunLoop currentRunLoop] addTimer: _touchCountTimer
                                         forMode: NSDefaultRunLoopMode];
         }
      }
   }

   touchesOnScreen += [touches count];

}

- (void)touchesMoved:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesMoved:touches withEvent:event];

   /*** Cannot assume touches will move simultaneously
   if ([touches count] != numberOfTouchesRequired)
   {
      [_timer invalidate];
      [_timer release];
      _timer = nil;
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }
   ***/

   if (touchCount != numberOfTouchesRequired)
      return;

   float currentAngle = [self angleFrom: initialCentroid 
                         to: [self centroidOfTouchesInWindow: [event touchesForView: _hitTestedView]]];

   if (![self directionPermitted: currentAngle])
   {
      // Swipe direction doesn't match any of the permitted direction
      [self changeState: SNGestureRecognizerStateFailed];
   }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesEnded:touches withEvent:event];

   /*** Cannot assume touches will end simultaneously
   if ([touches count] != numberOfTouchesRequired)
   {
      [_timer invalidate];
      [_timer release];
      _timer = nil;
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }
   ***/

   if (touchCount != numberOfTouchesRequired)
   {
      if ([_touchCountTimer isValid])
      {
         [_touchCountTimer invalidate];
         [_touchCountTimer release];
         _touchCountTimer = nil;
      }
      
      printf("SNSwipeGestureRecognizer: Finger up before reaching touch count\n");
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }

   // Calculate end centroid, distance, and angle when first finger is lifted
   // Can't wait until last finger is lifted like Tap or Long Press b/c if we
   // waited until then, we wouldn't have the required # of touches to
   // calculate end centroid

   // Also fire a touch count timer if necessary
   if (touchesOnScreen == numberOfTouchesRequired)
   {
      NSPoint endCentroid = [self centroidOfTouchesInWindow: [event touchesForView: _hitTestedView]];

      //if (minimumSwipeDistance > [self distanceFrom: initialCentroid
      //                                           to: endCentroid])
      if (endCentroid.x - initialCentroid.x < minimumSwipeDistance  &&
          endCentroid.x - initialCentroid.x > -minimumSwipeDistance &&
          endCentroid.y - initialCentroid.y < minimumSwipeDistance  &&
          endCentroid.y - initialCentroid.y > -minimumSwipeDistance)
      {
         printf("SNSwipeGestureRecognizer: Swipe distance is not long enough\n");
         [self changeState: SNGestureRecognizerStateFailed];
         return;
      }

      float currentAngle = [self angleFrom: initialCentroid 
                                        to: endCentroid];

      if (![self directionPermitted: currentAngle])
      {
         // Swipe direction doesn't match any of the permitted direction
         [self changeState: SNGestureRecognizerStateFailed];
         return;
      }

      // There are still touches remaining on screen; fire touch count timer
      if (touchesOnScreen - [touches count] != 0)
      {
         // All touches must lift from surface within 0.3 seconds
         _touchCountTimer = [[NSTimer alloc] initWithFireDate: nil
                                                     interval: 0.3
                                                       target: self
                                                     selector: @selector(touchesNotSynchronized:)
                                                     userInfo: nil
                                                      repeats: NO];

         [[NSRunLoop currentRunLoop] addTimer: _touchCountTimer
                                      forMode: NSDefaultRunLoopMode];
      }
   }

   touchesOnScreen -= [touches count];

   if (touchesOnScreen == 0)
   {
      if ([_touchCountTimer isValid])
      {
         [_touchCountTimer invalidate];
         [_touchCountTimer release];
         _touchCountTimer = nil;
      }

      [self changeState: SNGestureRecognizerStateRecognized];
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

   if ([_touchCountTimer isValid])
   {
      [_touchCountTimer invalidate];
      [_touchCountTimer release];
      _touchCountTimer = nil;
   }
}

- (void) setNumberOfTouchesRequired: (NSUInteger)num
{
   numberOfTouchesRequired = num;
}

- (void) setDirection: (SNSwipeGestureRecognizerDirection)dir
{
   direction = dir;
}

- (void) setMinimumSwipeDistance: (float)distance
{
   minimumSwipeDistance = distance;
}

- (void) setMaximumSwipeDuration: (NSTimeInterval)duration;
{
   maximumSwipeDuration = duration;
}

- (void) setAllowableAngleDeviation: (float)angle
{
   allowableAngleDeviation = angle;
}

- (SNSwipeGestureRecognizerDirection) direction
{
   return recognizedDirection;
}

- (void) durationExceeded: (NSTimer*)timer
{
   printf("SNSwipeGestureRecognzier durationExceeded...\n");

   [self changeState: SNGestureRecognizerStateFailed];
   _timer = nil;

   if ([_touchCountTimer isValid])
   {
      [_touchCountTimer invalidate];
      [_touchCountTimer release];
      _touchCountTimer = nil;
   }
}

- (void) touchesNotSynchronized: (NSTimer*)timer
{
   printf("SNSwipeGestureRecognzier touchesNotSynchronized...\n");

   [self changeState: SNGestureRecognizerStateFailed];
   _timer = nil;
   _touchCountTimer = nil;
}

/* Returns angle between two points, expressed in degrees
 *
 *             90
 *      135    |     45
 *        \    |    /
 *          \  |  /
 *            \|/
 *  180 ----------------- 0
 *            /|\
 *          /  |  \
 *        /    |    \
 *     -135    |    -45
 *            -90
 *
 */
- (float) angleFrom: (NSPoint) p1 to: (NSPoint) p2
{
   float deltaX = p2.x - p1.x;
   float deltaY = p2.y - p1.y;
   return atan2(deltaY, deltaX) * 180 / PI;
}

/* 
 * Test swipe direction against each permitted direction
 * Return YES if at least one permitted direction matches
 */
- (BOOL) directionPermitted: (float)currentAngle
{

   if (direction & SNSwipeGestureRecognizerDirectionRight)
   {
      if (currentAngle >= (0-allowableAngleDeviation) && currentAngle <= allowableAngleDeviation)
      {
         recognizedDirection = SNSwipeGestureRecognizerDirectionRight;
         return YES;
      }
   }
   if (direction & SNSwipeGestureRecognizerDirectionLeft)
   {
      if ((currentAngle >= (180-allowableAngleDeviation) && currentAngle <= 180) ||
          (currentAngle >= -180 && currentAngle <= (-180+allowableAngleDeviation)))
      {
         recognizedDirection = SNSwipeGestureRecognizerDirectionLeft;
         return YES;
      }
   }
   if (direction & SNSwipeGestureRecognizerDirectionUp)
   {
      if (currentAngle >= (90-allowableAngleDeviation) && currentAngle <= (90+allowableAngleDeviation))
      {
         recognizedDirection = SNSwipeGestureRecognizerDirectionUp;
         return YES;
      }
   }
   if (direction & SNSwipeGestureRecognizerDirectionDown)
   {
      if (currentAngle >= (-90-allowableAngleDeviation) && currentAngle <= (-90+allowableAngleDeviation))
      {
         recognizedDirection = SNSwipeGestureRecognizerDirectionDown;
         return YES;
      }
   }

   return NO;
}

@end
