#include <AppKit/SNPanGestureRecognizer.h>
#include <math.h>

// Time threshold (in seconds) for calculating end velocity
#define STOP_LIFT_TIME 0.07

@implementation SNPanGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action
{
   self = [super initWithTarget:target action:action];

   if (self)
   {
      // Default property values
      numberOfTouchesRequired = 1;
      minimumPanMovement = 4; // in pixels

      initialCentroid  = NSZeroPoint;
      currentCentroid  = NSZeroPoint;
      previousCentroid = NSZeroPoint;
      endCentroid      = NSZeroPoint;

      initialTimestamp  = 0;
      currentTimestamp  = 0;
      previousTimestamp = 0;
      endTimestamp      = 0;

      translationInWindow = NSZeroPoint;
      touchCount = 0;
      touchesOnScreen = 0;
   }

   return self;
}

- (void)reset
{
   [super reset];
   initialCentroid  = NSZeroPoint;
   currentCentroid  = NSZeroPoint;
   previousCentroid = NSZeroPoint;
   endCentroid      = NSZeroPoint;

   initialTimestamp  = 0;
   currentTimestamp  = 0;
   previousTimestamp = 0;
   endTimestamp      = 0;

   translationInWindow = NSZeroPoint;
   touchCount = 0;
   touchesOnScreen = 0;
}

- (NSPoint)locationInView:(NSView *)view
{
   if (endTimestamp == 0)
   {
      if (view)
         return [view convertPoint: currentCentroid fromView: nil];
      else
         return currentCentroid;
   }
   else
   {
      if (view)
         return [view convertPoint: endCentroid fromView: nil];
      else
         return endCentroid;
   }

   //if (view == _view)
   //   return currentCentroid;
   //else
   //   return [_view convertPoint: currentCentroid toView: view];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesBegan:touches withEvent:event];

   /*** Cannot assume touches will come simultaneously
   // Not a valid pan if # of touches on view doesn't match
   if ([touches count] != numberOfTouchesRequired ||
       //[_view touchCount] != numberOfTouchesRequired)
       [_hitTestedView touchCount] != numberOfTouchesRequired)
   {
      if (_state == SNGestureRecognizerStatePossible)
         [self changeState: SNGestureRecognizerStateFailed];
      else
         [self changeState: SNGestureRecognizerStateCancelled];

      return;
   }
   ***/

   touchCount += [touches count];
   printf("=== PAN GESTURE TOUCH COUNT = %i ===\n", touchCount);

   if (touchCount >= numberOfTouchesRequired)
   {
      if ([_timer isValid])
      {
         [_timer invalidate];
         [_timer release];
         _timer = nil;
      }

      if (touchCount > numberOfTouchesRequired)
      {
         printf("SNPanGestureRecognizer: Touch count exceeded\n");
         if (_state == SNGestureRecognizerStatePossible)
            [self changeState: SNGestureRecognizerStateFailed];
         else
            [self changeState: SNGestureRecognizerStateCancelled];

         return;
      }
      else // touchCount == numberOfTouchesRequired
      {
         initialCentroid = [self centroidOfTouchesInWindow: [event touchesForView: _hitTestedView]];
         currentCentroid = initialCentroid;
         initialTimestamp = [event timestamp];
         currentTimestamp = initialTimestamp;
      }
   }

   // if touch count < required, fire timer as soon as we see the first touch
   if (touchesOnScreen == 0 && touchCount < numberOfTouchesRequired)
   {
      if ([_timer isValid])
      {
         // _timer might have been fired by touchesEnded, so
         // we have a touch up & down situation, which is not valid
         [_timer invalidate];
         [_timer release];
         _timer = nil;

         printf("SNPanGestureRecognizer: Touch up & down during pan\n");
         if (_state == SNGestureRecognizerStatePossible)
            [self changeState: SNGestureRecognizerStateFailed];
         else
            [self changeState: SNGestureRecognizerStateCancelled];

         return;
      }
      else
      {
         // Required # of touches must touch surface within 0.3 seconds
         _timer = [[NSTimer alloc] initWithFireDate: nil
                                           interval: 0.3
                                             target: self
                                           selector: @selector(touchesNotSynchronized:)
                                           userInfo: nil
                                            repeats: NO];

         [[NSRunLoop currentRunLoop] addTimer: _timer
                                      forMode: NSDefaultRunLoopMode];
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
      // fingers not moving together
      if (_state == SNGestureRecognizerStatePossible)
         [self changeState: SNGestureRecognizerStateFailed];
      else
         [self changeState: SNGestureRecognizerStateCancelled];

      return;
   }
   ***/

   if (touchCount != numberOfTouchesRequired)
      return;

   previousCentroid = currentCentroid;
   currentCentroid = [self centroidOfTouchesInWindow: [event touchesForView: _hitTestedView]];
   previousTimestamp = currentTimestamp;
   currentTimestamp = [event timestamp];

   if (_state == SNGestureRecognizerStatePossible)
   {
      //if ([self distanceFrom: initialCentroid to: currentCentroid] < minimumPanMovement)
      if (currentCentroid.x - initialCentroid.x < minimumPanMovement  &&
          currentCentroid.x - initialCentroid.x > -minimumPanMovement &&
          currentCentroid.y - initialCentroid.y < minimumPanMovement  &&
          currentCentroid.y - initialCentroid.y > -minimumPanMovement)
      {
         // Fingers have not moved enough to be considered a pan
         return;
      }
      else
      {
         translationInWindow = NSMakePoint(currentCentroid.x - initialCentroid.x,
                                           currentCentroid.y - initialCentroid.y);
         [self changeState: SNGestureRecognizerStateBegan];
      }
   }
   else // StateBegan or StateChanged
   {
      translationInWindow = NSMakePoint(currentCentroid.x - initialCentroid.x,
                                        currentCentroid.y - initialCentroid.y);
      [self changeState: SNGestureRecognizerStateChanged];
   }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesEnded:touches withEvent:event];

   /*** Cannot assume touches will lift simultaneously
   if ([touches count] != numberOfTouchesRequired)
   {
      // All fingers should lift together
      if (_state == SNGestureRecognizerStatePossible)
         [self changeState: SNGestureRecognizerStateFailed];
      else
         [self changeState: SNGestureRecognizerStateCancelled];

      return;
   }
   ***/

   if (touchCount != numberOfTouchesRequired)
   {
      printf("SNPanGestureRecognizer: Finger up before reaching touch count\n");
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
      // end centroid usually has the same x-y values as last move centroid
      endCentroid = [self centroidOfTouchesInWindow: [event touchesForView: _hitTestedView]];
      endTimestamp = [event timestamp];

      //printf("prev centroid = (%f, %f), current centroid = (%f, %f), end centroid = (%f, %f)\n", 
      //        previousCentroid.x, previousCentroid.y, currentCentroid.x, currentCentroid.y, endCentroid.x, endCentroid.y);
      //printf("prev timestamp = %f, current timestamp = %f, end timestamp = %f\n", 
      //        previousTimestamp, currentTimestamp, endTimestamp);

      if (_state == SNGestureRecognizerStatePossible)
      {
         //if ([self distanceFrom: initialCentroid to: endCentroid] < minimumPanMovement)
         if (endCentroid.x - initialCentroid.x < minimumPanMovement  &&
             endCentroid.x - initialCentroid.x > -minimumPanMovement &&
             endCentroid.y - initialCentroid.y < minimumPanMovement  &&
             endCentroid.y - initialCentroid.y > -minimumPanMovement)
         {
            [self changeState: SNGestureRecognizerStateFailed];
            return;
         }
      }

      translationInWindow = NSMakePoint(endCentroid.x - initialCentroid.x,
                                        endCentroid.y - initialCentroid.y);

      // There are still touches remaining on screen; fire touch count timer
      if (touchesOnScreen - [touches count] != 0)
      {
         // All touches must lift from surface within 0.3 seconds
         _timer = [[NSTimer alloc] initWithFireDate: nil
                                           interval: 0.3
                                             target: self
                                           selector: @selector(touchesNotSynchronized:)
                                           userInfo: nil
                                            repeats: NO];

         [[NSRunLoop currentRunLoop] addTimer: _timer
                                      forMode: NSDefaultRunLoopMode];
      }
   }

   touchesOnScreen -= [touches count];

   if (touchesOnScreen == 0)
   {
      [self changeState: SNGestureRecognizerStateEnded];
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

- (void) setNumberOfTouchesRequired: (NSUInteger)num
{
   numberOfTouchesRequired = num;
}

- (void) setMinimumPanMovement: (float)movement
{
   minimumPanMovement = movement;
}

- (void) touchesNotSynchronized: (NSTimer*)timer
{
   printf("SNPanGestureRecognzier touchesNotSynchronized...\n");
   if (_state == SNGestureRecognizerStatePossible)
      [self changeState: SNGestureRecognizerStateFailed];
   else
      [self changeState: SNGestureRecognizerStateCancelled];

   _timer = nil;
}

- (NSPoint) translationInWindow
{
   return translationInWindow;
}

/*
 * Returns the current velocity with respect to window, expressed in points
 * per second. The velocity is broken into horizontal and vertical components.
 *
 * If we have a non-zero end timestamp, the client code is querying the velocity 
 * "at the time the fingers lift up". We calculate velocity using the "end" point
 * and the "previous" point (as opposed to "end" and "current"). This is because 
 * a touchesEnded event usually has the same x-y location and timestamp as the last
 * touchesMoved event (even in a fast move). Using them could result in a zero
 * velocity or division by zero exception.
 *
 *       *---------------*----*
 *   previous        current  end
 *
 * In case the fingers have stopped moving before they lift up, where the time
 * difference between the touchesEnded event and the last touchesMoved event is 
 * greater than STOP_LIFT_TIME, we return a zero velocity.
 *
 */
- (NSPoint) velocityInWindow
{
   NSTimeInterval time_diff;

   if (endTimestamp != 0)
   {
      if ((endTimestamp - currentTimestamp) > STOP_LIFT_TIME)
      {
         // Fingers stopped moving before lifting, so velocity is zero
         return NSMakePoint(0, 0);
      }
      else
      {
         time_diff = endTimestamp - previousTimestamp;
         return NSMakePoint((endCentroid.x - previousCentroid.x)/time_diff,
                            (endCentroid.y - previousCentroid.y)/time_diff);
      }

   }

   time_diff = currentTimestamp - previousTimestamp;

   return NSMakePoint((currentCentroid.x - previousCentroid.x)/time_diff,
                      (currentCentroid.y - previousCentroid.y)/time_diff);
}

@end
