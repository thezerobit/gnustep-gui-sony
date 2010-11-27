#include "AppKit/SNGestureRecognizer.h"

@implementation LastTouch
@end

@implementation SNGestureRecognizer

// Initializing a gesture recognizer
- (id)initWithTarget:(id)target action:(SEL)action
{
   self = [super init];

   if (self)
   {
      _target = target;
      _action = action;

      _enabled = YES;
      _cancelsTouchesInView = YES;
      _delaysTouchesBegan = NO;
      _delaysTouchesEnded = YES;
      _hasBegun = NO;
   }

   return self;
}

// Adding and removing targets and actions
/***
- (void)addTarget:(id)targetaction:(SEL)action
{
}

- (void)removeTarget:(id)targetaction:(SEL)action
{
}
***/

// Getting the touches and location of a gesture
- (NSPoint)locationInView:(NSView *)view
{
   // Subclasses should override this
   return NSZeroPoint;
}

/***
- (NSPoint)locationOfTouch:(NSUInteger)touchIndex inView:(NSView *)view
{
}

- (NSUInteger)numberOfTouches
{
}
***/

// Setting and getting the recognizer's state and view
- (int)state
{
   return _state;
}

- (void)changeState:(SNGestureRecognizerState)aState
{
   _state = aState;

   if (_state == SNGestureRecognizerStateRecognized ||
       _state == SNGestureRecognizerStateBegan ||
       _state == SNGestureRecognizerStateChanged)
   {
      if ([_timer isValid])
      {
         [_timer invalidate];
         [_timer release];
         _timer = nil;
      }

      [self tryToSendAction]; // This method may call notifySuccess
   }
   else if (_state == SNGestureRecognizerStateFailed ||
            _state == SNGestureRecognizerStateCancelled)
   {
      if ([_timer isValid])
      {
         [_timer invalidate];
         [_timer release];
         _timer = nil;
      }

      [self notifyFailure];
   }
}

- (id)view
{
   return _view;
}

- (void)setView:(NSView*)aView
{
   if (aView != _view)
   {
      AUTORELEASE(_view);
      _view = RETAIN(aView);
   }
}

- (id)hitTestedView
{
   return _hitTestedView;
}

- (BOOL)enabled
{
   return _enabled;
}

- (void)setEnabled:(BOOL)aValue
{
   _enabled = aValue;
}

- (BOOL)hasBegun
{
   return _hasBegun;
}

// Cancelling and delaying touches
- (BOOL)cancelsTouchesInView
{
   return _cancelsTouchesInView;
}

- (BOOL)delaysTouchesBegan
{
   return _delaysTouchesBegan;
}

- (BOOL)delaysTouchesEnded
{
   return _delaysTouchesEnded;
}


// Specifying dependencies between gesture recognizers
- (void)requireGestureRecognizerToFail:(SNGestureRecognizer *)otherGestureRecognizer
{
   [self addObstacle: otherGestureRecognizer];
   [otherGestureRecognizer addVulture: self];
}

- (void)addObstacle:(SNGestureRecognizer *)otherGestureRecognizer
{
   if (_obstacles == nil)
   {
      _obstacles = [[NSMutableSet alloc] initWithCapacity: 1];
   }

   if (_currentObstacles == nil)
   {
      _currentObstacles = [[NSMutableSet alloc] initWithCapacity: 1];
   }

   [_obstacles addObject: otherGestureRecognizer];
   [_currentObstacles addObject: otherGestureRecognizer];
}

- (void)removeObstacle:(SNGestureRecognizer *)otherGestureRecognizer
{
    [_currentObstacles removeObject: otherGestureRecognizer];
}

- (void)addVulture:(SNGestureRecognizer *)otherGestureRecognizer
{
   if (_vultures == nil)
   {
      _vultures = [[NSMutableSet alloc] initWithCapacity: 1];
   }

   [_vultures addObject: otherGestureRecognizer];
}

- (void)tryToSendAction
{
   NSEnumerator *enumerator = [_obstacles objectEnumerator];
   SNGestureRecognizer *recognizer;

   /**
   while ((recognizer = [enumerator nextObject]))
   {
      if ([recognizer state] != SNGestureRecognizerStateFailed)
         return;
   }
   **/

   if ([_currentObstacles count] != 0) return;

   if (_target && _action)
   {
      printf("=== %s SENDING ACTION ===\n", [[self description] cString]);
      [NSApp sendAction: _action to: _target from: self];
      _actionSent = YES;
      [self notifySuccess];

      // In case this is a delayed action firing
      // E.g. action fired by timer or recognizer previously blocked by obstacles
      if ([_view touchCount] == 0)
      {
         [self reset];
      }
   }
}

- (void)notifyFailure
{
   NSEnumerator *enumerator = [_vultures objectEnumerator];
   SNGestureRecognizer *recognizer;

   while ((recognizer = [enumerator nextObject]))
   {
      //[recognizer removeObstacle: self];
      if ([recognizer state] == SNGestureRecognizerStateRecognized ||
          [recognizer state] == SNGestureRecognizerStateBegan ||
          [recognizer state] == SNGestureRecognizerStateChanged)
      {
         [recognizer removeObstacle: self];
         [recognizer tryToSendAction];
      }
   }
}

- (void)notifySuccess
{
   NSEnumerator *enumerator = [_vultures objectEnumerator];
   SNGestureRecognizer *recognizer;

   while ((recognizer = [enumerator nextObject]))
   {
      [recognizer changeState: SNGestureRecognizerStateFailed];
      [recognizer notifyFailure];
   }
}

// Methods for subclasses
- (void)reset
{
   // If state is possible when last finger is lifted, it means gesture has failed
   // Notify failure before unwinding state to possible
   if (_state == SNGestureRecognizerStatePossible)
   {
      //_state = SNGestureRecognizerStateFailed;
      //[self notifyFailure];
      [self changeState: SNGestureRecognizerStateFailed];
   }

   //_state = SNGestureRecognizerStatePossible;
   [self changeState: SNGestureRecognizerStatePossible];
   _actionSent = NO;

   [_currentObstacles removeAllObjects];
   [_currentObstacles initWithSet: _obstacles];
   _hasBegun = NO;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(NSEvent*)event
{
   _hitTestedView = [[touches anyObject] view];
   _hasBegun = YES;
}

- (void)touchesMoved:(NSSet*)touches withEvent:(NSEvent*)event
{
}

- (void)touchesEnded:(NSSet*)touches withEvent:(NSEvent*)event
{
}

- (void)touchesCancelled:(NSSet*)touches withEvent:(NSEvent*)event
{
   [self changeState: SNGestureRecognizerStateFailed];
}

- (NSPoint) centroidOfTouchesInWindow: (NSSet*)touches
{
   NSEnumerator *enumerator = [touches objectEnumerator];
   SNTouch *theTouch;
   NSPoint touchLocation;
   float x = 0.0, y = 0.0;

   while ((theTouch = [enumerator nextObject]))
   {
      touchLocation = [theTouch locationInWindow];
      x += touchLocation.x;
      y += touchLocation.y;
   }

   return NSMakePoint(x/[touches count], y/[touches count]);
}

- (void)dealloc
{
   //printf("SNGestureRecognizer dealloc1\n");
   RELEASE(_view);
   RELEASE(_obstacles);
   RELEASE(_currentObstacles);
   RELEASE(_vultures);
   [super dealloc];
}

@end
