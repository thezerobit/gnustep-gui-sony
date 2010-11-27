#include <AppKit/SNRotationGestureRecognizer.h>
#include <math.h>

// Time threshold (in seconds) for calculating end velocity
#define STOP_LIFT_TIME 0.07

#define PI 3.141593

@implementation SNRotationGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action
{
   self = [super initWithTarget:target action:action];

   if (self)
   {
      // Default property values
      minimumRotation = 0.05; // in radians

      //initialCentroid  = NSZeroPoint;
      currentCentroid  = NSZeroPoint;
      //previousCentroid = NSZeroPoint;
      //endCentroid      = NSZeroPoint;

      identity1 = 0;
      identity2 = 0;

      initialAngle  = 0;
      currentAngle  = 0;
      previousAngle = 0;
      endAngle      = 0;

      initialTimestamp  = 0;
      currentTimestamp  = 0;
      previousTimestamp = 0;
      endTimestamp      = 0;

      rotation = 0;
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

   identity1 = 0;
   identity2 = 0;

   initialAngle  = 0;
   currentAngle  = 0;
   previousAngle = 0;
   endAngle      = 0;

   initialTimestamp  = 0;
   currentTimestamp  = 0;
   previousTimestamp = 0;
   endTimestamp      = 0;

   rotation = 0;
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

   // not a valid rotation if we have more than 2 fingers in view
   //if ([_view touchCount] > 2)
   if ([_hitTestedView touchCount] > 2)
   {
      printf("SNRotationGestureRecognizer: more than 2 fingers in view\n");

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
      SNTouch *touch1 = [touchArray objectAtIndex: 0];
      SNTouch *touch2 = [touchArray objectAtIndex: 1];
      identity1 = [touch1 identity];
      identity2 = [touch2 identity];

      initialAngle = [self angleFrom: [touch1 locationInWindow] 
                                  to: [touch2 locationInWindow]];

      currentAngle = initialAngle;

      initialTimestamp = [event timestamp];
      currentTimestamp = initialTimestamp;
   }

}

- (void)touchesMoved:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesMoved:touches withEvent:event];

   //if ([_view touchCount] == 2)
   if ([_hitTestedView touchCount] == 2)
   {
      //NSSet *touchSet = [event touchesForView: _view];
      NSSet *touchSet = [event touchesForView: _hitTestedView];
      NSArray *touchArray = [touchSet allObjects];
      SNTouch *touch1 = [touchArray objectAtIndex: 0];
      SNTouch *touch2;

      if ([touch1 identity] != identity1)
      {
         touch2 = touch1;
         touch1 = [touchArray objectAtIndex: 1];
      }
      else
      {
         touch2 = [touchArray objectAtIndex: 1];
      }

      if ([touch1 identity] != identity1 || [touch2 identity] != identity2)
      {
         printf("SNRotationGestureRecognizer: inconsistency in touch IDs\n");

         if (_state == SNGestureRecognizerStatePossible)
            [self changeState: SNGestureRecognizerStateFailed];
         else
            [self changeState: SNGestureRecognizerStateCancelled];

         return;
      }

      previousAngle = currentAngle;
      currentAngle = [self angleFrom: [touch1 locationInWindow] 
                                  to: [touch2 locationInWindow]];

      previousTimestamp = currentTimestamp;
      currentTimestamp = [event timestamp];
      currentCentroid = [self centroidOfTouchesInWindow: touchSet];

      if (_state == SNGestureRecognizerStatePossible)
      {
         rotation = [self rotationFrom: initialAngle to: currentAngle];
         if (rotation < minimumRotation && rotation > -1*minimumRotation)
         {
            // Fingers have not moved enough to be considered a rotation
            return;
         }
         else
         {
            [self changeState: SNGestureRecognizerStateBegan];
         }
      }
      else // StateBegan or StateChanged
      {
         rotation = [self rotationFrom: previousAngle to: currentAngle];
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
      printf("SNRotationGestureRecognizer: last finger up\n");

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
      SNTouch *touch1 = [touchArray objectAtIndex: 0];
      SNTouch *touch2;

      if ([touch1 identity] != identity1)
      {
         touch2 = touch1;
         touch1 = [touchArray objectAtIndex: 1];
      }
      else
      {
         touch2 = [touchArray objectAtIndex: 1];
      }

      if ([touch1 identity] != identity1 || [touch2 identity] != identity2)
      {
         printf("SNRotationGestureRecognizer: inconsistency in touch IDs\n");

         if (_state == SNGestureRecognizerStatePossible)
            [self changeState: SNGestureRecognizerStateFailed];
         else
            [self changeState: SNGestureRecognizerStateCancelled];

         return;
      }

      endAngle = [self angleFrom: [touch1 locationInWindow] 
                              to: [touch2 locationInWindow]];

      endTimestamp = [event timestamp];
      currentCentroid = [self centroidOfTouchesInWindow: touchSet];

      if ([touches count] == 1) // one of two fingers lifts up
      {
         if (_state == SNGestureRecognizerStatePossible)
         {
            // do nothing; state remains possible
            endAngle = 0;
            endTimestamp = 0;
         }
         else //stateBegan or stateChanged
         {
            // don't change state to Cancelled; change to Ended instead so client code can query rotation/velocity info?
            //[self changeState: SNGestureRecognizerStateCancelled];
            rotation = [self rotationFrom: currentAngle to: endAngle];
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
            rotation = [self rotationFrom: initialAngle to: endAngle];
            if (rotation < minimumRotation && rotation > -1*minimumRotation)
            {
               // Fingers have not moved enough to be considered a rotation
               [self changeState: SNGestureRecognizerStateFailed];
            }
            else
            {
               [self changeState: SNGestureRecognizerStateEnded];
            }
            return;
         }

         rotation = [self rotationFrom: currentAngle to: endAngle];
         [self changeState: SNGestureRecognizerStateEnded];
      }
   }

}

- (void)touchesCancelled:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesCancelled:touches withEvent:event];

}


- (void) setMinimumRotation: (float)minRotation
{
   minimumRotation = minRotation;
}

- (float) rotation
{
   return rotation;
}

/*
 * Returns the current velocity of rotation, expressed in radians per second.
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
- (float) velocity
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
         return [self rotationFrom: previousAngle to: endAngle]/time_diff;
      }
   }

   time_diff = currentTimestamp - previousTimestamp;
   return [self rotationFrom: previousAngle to: currentAngle]/time_diff;
}

/* Returns angle between two points, expressed in radians
 *
 *            PI/2
 *    3PI/4    |     PI/4
 *        \    |    /
 *          \  |  /
 *            \|/
 *  PI ------------------ 0
 *            /|\
 *          /  |  \
 *        /    |    \
 *   -3PI/4    |    -PI/4
 *           -PI/2
 *
 */
- (float) angleFrom: (NSPoint) p1 to: (NSPoint) p2
{
   float deltaX = p2.x - p1.x;
   float deltaY = p2.y - p1.y;
   return atan2(deltaY, deltaX);
}

/*
 * Returns the rotation between two angles, expressed in radians
 * Clockwise rotation         -- negative radian
 * Counter clockwise rotation -- positive radian
 * Absolute value of rotation should never be larger than PI
 */
- (float) rotationFrom: (float) angle1 to: (float) angle2
{
   float diff = angle2 - angle1;

   if (diff > PI)
   {
      return diff - 2*PI;
   }
   else if (diff < -1*PI)
   {
      return diff + 2*PI;
   }
   else
   {
      return diff;
   }
}

@end
