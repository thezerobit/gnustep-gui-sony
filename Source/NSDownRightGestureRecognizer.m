#include <AppKit/NSDownRightGestureRecognizer.h>

@implementation NSDownRightGestureRecognizer

- (void)reset
{
    [super reset];
    initialPoint = NSZeroPoint;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesBegan:touches withEvent:event];

    if ([touches count] != 1) 
    {
        [self changeState: NSGestureRecognizerStateFailed];
        return;
    }

    initialPoint = [_view firstTouchLocationInView];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(NSEvent*)event
{
    [super touchesMoved:touches withEvent:event];
    if (_state == NSGestureRecognizerStateFailed) return;

    NSPoint nowPoint = [_view firstTouchLocationInView];

    // on downstroke, x increases and y decreases
    if (nowPoint.x >= initialPoint.x && nowPoint.y <= initialPoint.y) 
    {
       if ([self distanceFrom: nowPoint to: initialPoint] >= 50)     
          [self changeState: NSGestureRecognizerStateRecognized];  
    } 
    else 
    {
       [self changeState: NSGestureRecognizerStateFailed];
    }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(NSEvent*)event
{
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(NSEvent*)event
{
    [super touchesCancelled:touches withEvent:event];
    initialPoint = NSZeroPoint;
    [self changeState: NSGestureRecognizerStateFailed];
}

- (float) distanceFrom: (NSPoint) p1 to: (NSPoint) p2
{
   float x = p2.x - p1.x;
   float y = p2.y - p1.y;
   return sqrt(x*x + y*y);
}

@end
