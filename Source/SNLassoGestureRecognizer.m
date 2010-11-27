#include <AppKit/SNLassoGestureRecognizer.h>
#include <math.h>

#define PI           3.141593


@implementation SNLassoGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action
{
   self = [super initWithTarget:target action:action];

   if (self)
   {
      vertices = [[NSMutableArray alloc] initWithCapacity: 32];
      initialPoint  = NSZeroPoint;
      currentPoint  = NSZeroPoint;
      previousPoint = NSZeroPoint;

      // Default property values
      granularity = 12; // pixels
      maxEndToBeginDistance  = 4096;     // pixels
      minRotation = PI/4; // 45 degrees
      /***
      rotationBeganThreshold = PI/6;     // 30 degrees
      minTotalRotation       = 1.375*PI; // 270 degrees
      maxTotalRotation       = 2.5*PI;   // 450 degrees
      rotationStepCeiling    = PI/2;     // 90 degrees
      rotationStepFloor      = PI/6;     // 30 degrees
      ***/

      currentTangent = previousTangent = 2*PI;
      //currentRotation = previousRotation = 2*PI;
      totalRotation    = 0;
      //currentStepFloor = 0;
      maxX = maxY = minX = minY = 0;

      winding = 0;
      //rotationDirection = Undecided;
      minRotationReached = NO;
   }

   return self;
}

- (void)reset
{
   [super reset];

   [vertices removeAllObjects];
   initialPoint  = NSZeroPoint;
   currentPoint  = NSZeroPoint;
   previousPoint = NSZeroPoint;

   currentTangent = previousTangent = 2*PI;
   //currentRotation = previousRotation = 2*PI;
   totalRotation    = 0;
   //currentStepFloor = 0;
   maxX = maxY = minX = minY = 0;

   winding = 0;
   //rotationDirection = Undecided;
   minRotationReached = NO;
}

- (NSPoint)locationInView:(NSView *)view
{
   if (view)
      return [view convertPoint: currentPoint fromView: nil];
   else
      return currentPoint;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesBegan:touches withEvent:event];

   // only allows single touch
   //if ([_view touchCount] != 1 || [touches count] != 1)
   if ([_hitTestedView touchCount] != 1 || [touches count] != 1)
   {
      printf("SNLassoGestureRecognizer: only one touch allowed\n");
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }

   initialPoint = [[touches anyObject] locationInWindow];
   currentPoint = initialPoint;
   NSValue *point = [NSValue valueWithPoint: currentPoint];
   [vertices addObject: point];
   //printf("initial point = (%f, %f)\n", initialPoint.x, initialPoint.y);

   maxX = minX = currentPoint.x;
   maxY = minY = currentPoint.y;

}

- (void)touchesMoved:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesMoved:touches withEvent:event];

   // not a valid circle if we have more than 1 finger
   //if ([_view touchCount] != 1 || [touches count] != 1)
   if ([_hitTestedView touchCount] != 1 || [touches count] != 1)
   {
      printf("SNLassoGestureRecognizer: more than 2 fingers in view\n");
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }

   previousPoint = currentPoint;
   NSPoint tempPoint = [[touches anyObject] locationInWindow];

   //if (tempPoint.x == currentPoint.x || tempPoint.y == currentPoint.y)
   //{
   //   return;
   //}

   //if ([self distanceFrom: previousPoint to: tempPoint] < granularity)
   if (tempPoint.x - previousPoint.x < granularity  &&
       tempPoint.x - previousPoint.x > -granularity &&
       tempPoint.y - previousPoint.y < granularity  &&
       tempPoint.y - previousPoint.y > -granularity)
   {
      // Skip -- too close to previous point
      return;
   }

   currentPoint = tempPoint;
   NSValue *point = [NSValue valueWithPoint: currentPoint];
   [vertices addObject: point];
   //printf("current point = (%f, %f)\n", currentPoint.x, currentPoint.y);

   // keep track of enclosing rectangle
   if (currentPoint.x > maxX)
      maxX = currentPoint.x;
   else if (currentPoint.x < minX)
      minX = currentPoint.x;
   if (currentPoint.y > maxY)
      maxY = currentPoint.y;
   else if (currentPoint.y < minY)
      minY = currentPoint.y;

   if (!minRotationReached)
   {
      previousTangent = currentTangent;
      currentTangent = [self angleFrom: previousPoint to: currentPoint];

      if (previousTangent <= PI) //previous tangent exists
      {
         totalRotation += [self rotationFrom: previousTangent to: currentTangent];
         printf("totalRotation = %f\n", totalRotation * 180 / 3.141593);

         if (fabs(totalRotation) >= minRotation)
            minRotationReached = YES;
      }
   }

   /******* CHANGED ALGORITHM...
   previousTangent = currentTangent;
   currentTangent = [self angleFrom: previousPoint to: currentPoint];
   //printf("currentTangent = %f\n", currentTangent * 180 / 3.141593);

   
   if (previousTangent <= PI) //previous tangent exists
   {
      previousRotation = currentRotation;
      currentRotation = [self rotationFrom: previousTangent to: currentTangent];
      //printf("currentRotation = %f\n", currentRotation * 180 / 3.141593);

      ////////////////
      // For each new tangent (and hence rotation) we calculate, we do two tests:
      // 1. The rotation between the previous and the current tangents must be less than the step ceiling value.
      //    This is to prevent acute angles, and gestures like "dragging along a straight line and going backward 
      //    immediately without forming an angle".
      // 2. The total rotation must be greater than the step floor value, which only increases over time.
      //    This is to prevent a change of rotation direction during the gesture, which would result in a concave
      //    polygon. We only want to deal with convex polygons here. Theoretically, this can be enforced by
      //    ensuring each rotation is positive for a counter-clockwise gesture, and negative for a clockwise
      //    gesture. In reality, however, this would fail almost every circle gesture attempt, as rotation values
      //    calculated by pixels tend to fluctuate between positive and negative somewhat, so we want to allow minor 
      //    fluctuation by using a buffer floor value.
      /////////////////

      if (currentRotation > rotationStepCeiling || currentRotation < -1*rotationStepCeiling)
      {
         printf("NSCircleGestureRecognizer: bad circle\n");
         [self changeState: SNGestureRecognizerStateFailed];
         return;
      }

      totalRotation += currentRotation;

      if (rotationDirection == Undecided)
      {
         if (totalRotation >= rotationBeganThreshold)
         {
            rotationDirection = CounterClockwise;
            currentStepFloor = totalRotation - rotationStepFloor;
         }
         else if (totalRotation <= -1*rotationBeganThreshold)
         {
            rotationDirection = Clockwise;
            currentStepFloor = totalRotation + rotationStepFloor;
         }
      }
      else if (rotationDirection == CounterClockwise)
      {
         if (totalRotation < currentStepFloor)
         {
            printf("NSCircleGestureRecognizer: rotation inconsistency\n");
            [self changeState: SNGestureRecognizerStateFailed];
            return;
         }

         float newFloor = totalRotation - rotationStepFloor;
         if (newFloor > currentStepFloor)
         {
            currentStepFloor = newFloor;
         }
      }
      else //Clockwise
      {
         if (totalRotation > currentStepFloor)
         {
            printf("NSCircleGestureRecognizer: rotation inconsistency\n");
            [self changeState: SNGestureRecognizerStateFailed];
            return;
         }

         float newFloor = totalRotation + rotationStepFloor;
         if (newFloor < currentStepFloor)
         {
            currentStepFloor = newFloor;
         }
      }

      printf("totalRotation = %f\n", totalRotation * 180 / 3.141593);

      if (totalRotation > maxTotalRotation || totalRotation < -1*maxTotalRotation)
      {
         printf("NSCircleGestureRecognizer: above max rotation\n");
         [self changeState: SNGestureRecognizerStateFailed];
         return;
      }

   }
   *******/

}

- (void)touchesEnded:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesEnded:touches withEvent:event];

   // not a valid circle if we have more than 1 finger
   //if ([_view touchCount] != 1 || [touches count] != 1)
   if ([_hitTestedView touchCount] != 1 || [touches count] != 1)
   {
      printf("SNLassoGestureRecognizer: more than 2 fingers in view\n");
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }

   NSPoint endPoint = [[touches anyObject] locationInWindow];

   if (endPoint.x != currentPoint.x || endPoint.y != currentPoint.y)
   {
      NSValue *point = [NSValue valueWithPoint: endPoint];
      [vertices addObject: point];

      // keep track of enclosing rectangle
      if (endPoint.x > maxX)
         maxX = endPoint.x;
      else if (endPoint.x < minX)
         minX = endPoint.x;
      if (endPoint.y > maxY)
         maxY = endPoint.y;
      else if (endPoint.y < minY)
         minY = endPoint.y;
   }

   /***
   if (totalRotation < minTotalRotation && totalRotation > -1*minTotalRotation)
   {
      printf("NSCircleGestureRecognizer: below min rotation\n");
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }
   ***/

   if ([vertices count] < 3)
   {
      printf("SNLassoGestureRecognizer: need at least 3 points to be a polygon\n");
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }

   if (!minRotationReached)
   {
      printf("SNLassoGestureRecognizer: I haven't observed enough rotation\n");
      [self changeState: SNGestureRecognizerStateFailed];
      return;
   }

   // End point shouldn't be too far from beginning point
   if ([self distanceFrom: endPoint to: initialPoint] <= maxEndToBeginDistance)
   {
      printf("vertices size = %i\n", [vertices count]);
      [self changeState: SNGestureRecognizerStateRecognized];
   }
   else
   {
      printf("SNLassoGestureRecognizer: end point too far from begin point\n");
      [self changeState: SNGestureRecognizerStateFailed];
   }

}

- (void)touchesCancelled:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesCancelled:touches withEvent:event];

}




- (void) setGranularity: (float) aGranularity
{
   granularity = aGranularity;
}

- (void) setMaxEndToBeginDistance: (float) distance
{
   maxEndToBeginDistance = distance;
}

- (void) setMinRotation: (float) rotation
{
   minRotation = rotation;
}

- (float) windingNumber
{
   return winding;
}

/***
- (float) rotation
{
   return totalRotation;
}

- (RotationDirection) direction
{
   return rotationDirection;
}

- (void) setRotationBeganThreshold: (float) rotation
{
   rotationBeganThreshold = rotation;
}

- (void) setMinTotalRotation: (float) minRotation
{
   minTotalRotation = minRotation;
}

- (void) setMaxTotalRotation: (float) maxRotation
{
   maxTotalRotation = maxRotation;
}
***/

- (float) distanceFrom: (NSPoint) p1 to: (NSPoint) p2
{
   float x = p2.x - p1.x;
   float y = p2.y - p1.y;
   return sqrt(x*x + y*y);
}

/* 
 * Returns angle between two points, expressed in radians
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

/* 
 * Returns whether or not a given point is inside the lasso.
 * This is a "Point in Polygon" problem, and we solve it by the
 * "winding number algorithm".
 *
 * We first translate all vertices of lasso by -p to make it the
 * new origin. Then, we traverse all verticies to see how many times
 * the polygon winds around the point, using the "Axis Crossing 
 * Method". If the winding number is 0, then the point is not inside
 * the polygon. Otherwise, the point is.
 *
 * Note: This algorithm works for convex/concave/complex polygons.
 * Detailed algorithm can be found here:
 * http://www.engr.colostate.edu/~dga/dga/papers/point_in_polygon.pdf
 *
 *            _____        __
 *      |    /   __\      |  \
 *      |   /   /   point |  | 
 *      |  |    \  *     /   | 
 *      |  |     \______/  __|
 *      |   \             /
 *      |    \__         /
 *      |       \______/
 *   ----------------------- 
 *      |
 *
 *
 *   ---> translate polygon by -p
 * 
 *
 *                 |
 *        II       |       I
 *            _____|       __
 *           /   __|      |  \
 *          /   /  |point |  | 
 *    -----|----\--*-----/---|--- 
 *         |     \_|____/  __|
 *          \      |      /
 *      III  \__   |     /  IV
 *              \__|___/
 *                 |
 *                 |
 * 
 *
 */
- (BOOL) pointInLasso: (NSPoint) point inView: (NSView *) view;
{
   NSPoint pointInWindow;

   // convert to window-based coordinate first, if necessary
   if (view)
      pointInWindow = [view convertPoint: point toView: nil];
   else
      pointInWindow = point;

   if (pointInWindow.x > maxX || pointInWindow.x < minX ||
       pointInWindow.y > maxY || pointInWindow.y < minY)
   {
      // point is not even in enclosing rectangle
      return NO;
   }

   /***
   NSEnumerator *enumerator = [vertices objectEnumerator];
   NSValue *value;
   NSPoint vertex;
   NSPoint translatedVertex;
   BOOL quadrant_I = NO, quadrant_II = NO, quadrant_III = NO, quadrant_IV = NO;
   
   while ((value = [enumerator nextObject]))
   {
      vertex = [value pointValue];
      printf("vertex = (%f, %f)\n", vertex.x, vertex.y);
      translatedVertex = NSMakePoint(vertex.x - pointInWindow.x, vertex.y - pointInWindow.y);

      if (translatedVertex.x > 0 && translatedVertex.y > 0)
         quadrant_I = YES;
      else if (translatedVertex.x < 0 && translatedVertex.y > 0)
         quadrant_II = YES;
      else if (translatedVertex.x < 0 && translatedVertex.y < 0)
         quadrant_III = YES;
      else if (translatedVertex.x > 0 && translatedVertex.y < 0)
         quadrant_IV = YES;

      if (quadrant_I && quadrant_II && quadrant_III && quadrant_IV)
         return YES;
   }
   ***/

   NSEnumerator *enumerator = [vertices objectEnumerator];
   NSValue *value1;
   NSValue *value2;
   NSPoint vertex1, vertex2;
   NSPoint initialVertex, translatedVertex1, translatedVertex2;

   value1 = [enumerator nextObject];
   value2 = [enumerator nextObject];
   vertex1 = [value1 pointValue];
   translatedVertex1 = NSMakePoint(vertex1.x - pointInWindow.x, vertex1.y - pointInWindow.y);
   initialVertex = translatedVertex1;

   winding = 0;
   do
   {
      vertex2 = [value2 pointValue];
      translatedVertex2 = NSMakePoint(vertex2.x - pointInWindow.x, vertex2.y - pointInWindow.y);

      winding += [self calculateWindingNumberFrom: translatedVertex1
                                               to: translatedVertex2];

      translatedVertex1 = translatedVertex2;
   }
   while ((value2 = [enumerator nextObject]));

   // last vertex to first vertex
   winding += [self calculateWindingNumberFrom: translatedVertex2
                                            to: initialVertex];

   if (winding == 0) 
      return NO;
   else 
      return YES;
}

- (float) calculateWindingNumberFrom: (NSPoint) v1 to: (NSPoint) v2
{
   float intersect;
   float x1, y1, x2, y2;
   x1 = v1.x;
   y1 = v1.y;
   x2 = v2.x;
   y2 = v2.y;

   if (y1 == 0 && y2 == 0)
   {
      // both v1 v2 are on x-axis, winding number unchanged
      return 0;
   }
   else if (y1 * y2 < 0) // line v1 -> v2 crosses x-axis
   {
      intersect = x1 + (y1*(x2-x1))/(y1-y2); // x-coordinate of intersection of line v1 -> v2 and x-axis
      if (intersect > 0) // line v1 -> v2 crosses positive x-axis
      {
         if (y1 < 0)  //counter-clockwise
            return 1;
         else         //clockwise
            return -1;
      }
   }
   else if (y1 == 0 && x1 > 0) // v1 on positive x-axis
   {
      if (y2 > 0) 
         return 0.5;
      else 
         return -0.5;
   }
   else if (y2 == 0 && x2 > 0) // v2 on positive x-axis
   {
      if (y1 < 0) 
         return 0.5;
      else 
         return -0.5;
   }

   return 0;
}

- (void)dealloc
{
   RELEASE(vertices);
   [super dealloc];
}

@end
