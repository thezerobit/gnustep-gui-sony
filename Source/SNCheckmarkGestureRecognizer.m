#include <AppKit/SNCheckmarkGestureRecognizer.h>

@implementation SNCheckmarkGestureRecognizer

- (void)reset
{
    [super reset];
    midPoint = NSZeroPoint;
    strokeDown = NO;
    strokeUp = NO;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(NSEvent*)event
{
   [super touchesBegan:touches withEvent:event];

    if ([touches count] != 1) 
    {
        [self changeState: SNGestureRecognizerStateFailed];
        return;
    }

    //cachedPoint = [_view firstTouchLocationInView];
    cachedPoint = [_hitTestedView firstTouchLocationInView];
    //printf("(%f, %f)\n", cachedPoint.x, cachedPoint.y);
}

- (void)touchesMoved:(NSSet*)touches withEvent:(NSEvent*)event
{
    printf("SNGestureRecognizer: touchesMoved\n");
    [super touchesMoved:touches withEvent:event];
    if (_state == SNGestureRecognizerStateFailed) return;

    //NSPoint nowPoint = [_view firstTouchLocationInView];
    NSPoint nowPoint = [_hitTestedView firstTouchLocationInView];
    NSPoint prevPoint = cachedPoint;
    cachedPoint = nowPoint;
    //printf("(%f, %f)\n", nowPoint.x, nowPoint.y);

    if (!strokeUp) 
    {
        // on downstroke, x increases and y decreases
        if (nowPoint.x >= prevPoint.x && nowPoint.y <= prevPoint.y) 
        {
            midPoint = nowPoint;
            strokeDown = YES;
            
        } 
        // upstroke has increasing x value and increasing y value and must 
        // follow after downstroke
        else if (strokeDown && nowPoint.x >= prevPoint.x && nowPoint.y >= prevPoint.y) 
        {
            strokeUp = YES;
        } 
        else 
        {
            [self changeState: SNGestureRecognizerStateFailed];
        }
    }

    // If we've seen a checkmark so far, any stroke not in upper right direction
    // invalidates the checkmark
    if ((_state == SNGestureRecognizerStatePossible) && strokeUp) 
    {
        if (!(nowPoint.x >= prevPoint.x && nowPoint.y >= prevPoint.y))
        {
           [self changeState: SNGestureRecognizerStateFailed];
        }
    }
}

- (void)touchesEnded:(NSSet*)touches withEvent:(NSEvent*)event
{
    [super touchesEnded:touches withEvent:event];

    if ((_state == SNGestureRecognizerStatePossible) && strokeUp) 
    {
        [self changeState: SNGestureRecognizerStateRecognized];
    }
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(NSEvent*)event
{
    [super touchesCancelled:touches withEvent:event];
    midPoint = NSZeroPoint;
    strokeDown = NO;
    strokeUp = NO;
    [self changeState: SNGestureRecognizerStateFailed];
}

- (NSPoint) midpointInView:(NSView *)view;
{
   if (view == _hitTestedView)
      return midPoint;
   else if (view == nil) // window base coordinates
      return [_hitTestedView convertPoint: midPoint fromView: nil];
   else
      return [view convertPoint: midPoint fromView: _hitTestedView];
}

@end
