#include <AppKit/SNPinchGestureRecognizer.h>
#include <math.h>

// Time threshold (in seconds) for calculating end velocity
#define STOP_LIFT_TIME 0.07

@implementation SNPinchGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action
{
   self = [super initWithTarget:target action:action];

   if (self)
   {
      // Default property values
      minimumPinchMovement = 4; // in pixels

      //initialCentroid  = NSZeroPoint;
      currentCentroid  = NSZeroPoint;
      //previousCentroid = NSZeroPoint;
      //endCentroid      = NSZeroPoint;

      initialDistance  = 0;
      currentDistance  = 0;
      previousDistance = 0;
      endDistance      = 0;

      initialTimestamp  = 0;
      currentTimestamp  = 0;
      previousTimestamp = 0;
      endTimestamp      = 0;

      scale = 1;
      movement = 0;
   }

   return self;
}

- (void)reset
{
   [super reset];
   //initialCentroid  = NSZeroPoint;
   currentCentroid  = NSZeroPoint;
   //previousCentroid = NSZeroPoint;
   //endCentroid      = NSZeroPoint;

   initialDistance  = 0;
   currentDistance  = 0;
   previousDistance = 0;
   endDistance      = 0;

   initialTimestamp  = 0;
   currentTimestamp  = 0;
   previousTimestamp = 0;
   endTimestamp      = 0;

   scale = 1;
   movement = 0;
}

- (NSPoint)locationInView:(NSView *)view
{
   if (view)
      return [view convertPoint: currentCentroid fromView: nil];
   else
      return currentCentroid;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesBegan:touches withEvent:event];

   // not a valid pinch if we have more than 2 fingers in view
   //if ([_view touchCount] > 2)
   if ([_hitTestedView touchCount] > 2)
   {
      printf("SNPinchGestureRecognizer: more than 2 fingers in view\n");

      if (_state == SNGestureRecognizerStatePossible)
         [self changeState: SNGestureRecognizerStateFailed];
      else
         [self changeState: SNGestureRecognizerStateCancelled];

      return;
   }

   //if ([_view touchCount] == 2)
   if ([_hitTestedView touchCount] == 2)
   {
      //NSArray *touchArray = [[event touchesForView: _view] allObjects];
      NSArray *touchArray = [[event touchesForView: _hitTestedView] allObjects];
      NSPoint p1 = [[touchArray objectAtIndex: 0] locationInWindow];
      NSPoint p2 = [[touchArray objectAtIndex: 1] locationInWindow];

      initialDistance = [self distanceFrom: p1 to: p2];
      currentDistance = initialDistance;
      initialTimestamp = [event timestamp];
      currentTimestamp = initialTimestamp;
   }
}

- (void)touchesMoved:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesMoved:touches withEvent:event];

   /*** this should be blocked by touchesBegan
   if ([_view touchCount] > 2)
   {
      printf("SNPinchGestureRecognizer: more than 2 fingers in view\n");

      if (_state == SNGestureRecognizerStatePossible)
         [self changeState: SNGestureRecognizerStateFailed];
      else
         [self changeState: SNGestureRecognizerStateCancelled];

      return;
   }
   ***/

   //if ([_view touchCount] == 2)
   if ([_hitTestedView touchCount] == 2)
   {
      //NSSet *touchSet = [event touchesForView: _view];
      NSSet *touchSet = [event touchesForView: _hitTestedView];
      NSArray *touchArray = [touchSet allObjects];
      NSPoint p1 = [[touchArray objectAtIndex: 0] locationInWindow];
      NSPoint p2 = [[touchArray objectAtIndex: 1] locationInWindow];

      previousDistance = currentDistance;
      currentDistance = [self distanceFrom: p1 to: p2];
      previousTimestamp = currentTimestamp;
      currentTimestamp = [event timestamp];
      currentCentroid = [self centroidOfTouchesInWindow: touchSet];

      if (_state == SNGestureRecognizerStatePossible)
      {
         movement = currentDistance - initialDistance;
         if (movement < minimumPinchMovement && movement > -1*minimumPinchMovement)
         {
            // Fingers have not moved enough to be considered a pinch
            return;
         }
         else
         {
            scale = currentDistance/initialDistance;
            [self changeState: SNGestureRecognizerStateBegan];
         }
      }
      else // StateBegan or StateChanged
      {
         movement = currentDistance - previousDistance;
         scale = currentDistance/previousDistance;
         [self changeState: SNGestureRecognizerStateChanged];
      }
   }

}

- (void)touchesEnded:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesEnded:touches withEvent:event];

   //if ([_view touchCount] == 1)
   if ([_hitTestedView touchCount] == 1)
   {
      // We get here when we had one finger in view and that finger lifts up
      // If there were 3 or more fingers in view, the gesture would have failed in touchesBegan
      // Note: touch count is decremented *after* event delivery
      printf("SNPinchGestureRecognizer: last finger up\n");

      // always in possible state? (since we change state back to possible below
      // when only one finger lifts up?)
      if (_state == SNGestureRecognizerStatePossible)
         [self changeState: SNGestureRecognizerStateFailed];
      else
         [self changeState: SNGestureRecognizerStateCancelled];

      return;
   }

   //if ([_view touchCount] == 2)
   if ([_hitTestedView touchCount] == 2)
   {
      //NSSet *touchSet = [event touchesForView: _view];
      NSSet *touchSet = [event touchesForView: _hitTestedView];
      NSArray *touchArray = [touchSet allObjects];
      NSPoint p1 = [[touchArray objectAtIndex: 0] locationInWindow];
      NSPoint p2 = [[touchArray objectAtIndex: 1] locationInWindow];

      endDistance = [self distanceFrom: p1 to: p2];
      endTimestamp = [event timestamp];
      currentCentroid = [self centroidOfTouchesInWindow: touchSet];

      if ([touches count] == 1) // one of two fingers lifts up
      {
         if (_state == SNGestureRecognizerStatePossible)
         {
            // do nothing; state remains possible
            endDistance = 0;
            endTimestamp = 0;
         }
         else //stateBegan or stateChanged
         {
            // don't change state to Cancelled; change to Ended instead so client code can query scale/velocity info?
            //[self changeState: SNGestureRecognizerStateCancelled];
            movement = endDistance - currentDistance;
            scale = endDistance/currentDistance;
            [self changeState: SNGestureRecognizerStateEnded];

            // Should we call reset here, or just set state to possible?
            // reset will be called twice in the following scenario:
            // 1. pinch is recognized
            // 2. one finger lifts up -> reset called by recognizer itself
            // 3. the other finger lifts up -> reset called by NSWindow
            [self reset];
         }
      }
      else // both fingers up
      {
         if (_state == SNGestureRecognizerStatePossible)
         {
            movement = endDistance - initialDistance;
            if (movement < minimumPinchMovement && movement > -1*minimumPinchMovement)
            {
               // Fingers have not moved enough to be considered a pinch
               [self changeState: SNGestureRecognizerStateFailed];
            }
            else
            {
               [self changeState: SNGestureRecognizerStateEnded];
            }
            return;
         }

         movement = endDistance - currentDistance;
         scale = endDistance/currentDistance;
         [self changeState: SNGestureRecognizerStateEnded];
      }
   }

}

- (void)touchesCancelled:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesCancelled:touches withEvent:event];

}


- (void) setMinimumPinchMovement: (float)minMovement
{
   minimumPinchMovement = minMovement;
}

- (float) movement
{
   return movement;
}

- (float) scale
{
   return scale;
}

- (float) distanceFrom: (NSPoint) p1 to: (NSPoint) p2
{
   float x = p2.x - p1.x;
   float y = p2.y - p1.y;
   return sqrt(x*x + y*y);
}

/*
 * Returns the current velocity of the pinch in pixels per second.
 *
 * If we have a non-zero end timestamp, the client code is querying the velocity 
 * "at the time the fingers lift up". We calculate velocity using the "end" point
 * and the "previous" point (as opposed to "end" and "current"). This is because 
 * a touchesEnded event usually has the same x-y location and timestamp as the last
 * touchesMoved event (even in a fast move). Using them could result in a zero
 * velocity or division by zero.
 *
 *       *---------------*----*
 *   previous        current  end
 *
 * In case the fingers have stopped moving before they lift up, where the time
 * difference between the touchesEnded event and the last touchesMoved event is 
 * greater than STOP_LIFT_TIME, we return a zero velocity.
 *
 */
- (float) velocityOfMovement
{
   NSTimeInterval time_diff;

   if (endTimestamp != 0)
   {
      if ((endTimestamp - currentTimestamp) > STOP_LIFT_TIME)
      {
         // Fingers stopped moving before lifting, so velocity is zero
         return 0;
      }
      else
      {
         time_diff = endTimestamp - previousTimestamp;
         return (endDistance - previousDistance)/time_diff;
      }
   }

   time_diff = currentTimestamp - previousTimestamp;
   return (currentDistance - previousDistance)/time_diff;
}

/*
 * Returns the current velocity of the pinch in scale factor per second.
 */
- (float) velocityOfScale
{
   NSTimeInterval time_diff;

   if (endTimestamp != 0)
   {
      if ((endTimestamp - currentTimestamp) > STOP_LIFT_TIME)
      {
         // Fingers stopped moving before lifting, so velocity is zero
         return 0;
      }
      else
      {
         time_diff = endTimestamp - previousTimestamp;
         return 1 + ((endDistance-previousDistance)/previousDistance)/time_diff;
      }
   }

   time_diff = currentTimestamp - previousTimestamp;
   return 1 + ((currentDistance-previousDistance)/previousDistance)/time_diff;
}

@end
