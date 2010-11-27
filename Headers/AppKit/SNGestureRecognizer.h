#include "Foundation/NSObject.h"
#include <AppKit/AppKit.h>

//@class NSView, NSSet, NSEvent;

typedef enum {
  SNGestureRecognizerStatePossible,
  SNGestureRecognizerStateBegan,
  SNGestureRecognizerStateChanged,
  SNGestureRecognizerStateEnded,
  SNGestureRecognizerStateCancelled,
  SNGestureRecognizerStateFailed,
  SNGestureRecognizerStateRecognized = SNGestureRecognizerStateEnded
} SNGestureRecognizerState;

@interface LastTouch : NSObject {
   @public NSTimeInterval timestamp;
   @public NSPoint location;
   @public unsigned int tapCount;
}
@end

@interface SNGestureRecognizer : NSObject {
  id _target;
  SEL _action;

  /*
   * Note: _view and _hitTestedView may not point to the same view.
   * This is true when a view allows its next responder's GRs to analyze touches.
   * In that case, _view is the parent view and _hitTestedView is the child view
   */
  NSView* _view;          //view to which this GR is attached
  NSView* _hitTestedView; //the hit tested view
  int _state;

  //NSMutableArray* _delayedTouches;
  //NSEvent* _updateEvent;
  NSMutableSet* _obstacles; //recognizers I'm waiting to fail
  NSMutableSet* _currentObstacles;
  NSMutableSet* _vultures;  //recognizers waiting for me to fail
  //NSMutableSet* _friends;   //recognizers for simultaneous recognition?

  NSTimer *_timer;

  BOOL _enabled;
  BOOL _cancelsTouchesInView;
  BOOL _delaysTouchesBegan;
  BOOL _delaysTouchesEnded;
  BOOL _actionSent;
  BOOL _hasBegun;
}

// Initializing a gesture recognizer
- (id)initWithTarget:(id)target action:(SEL)action;

// Adding and removing targets and actions
//- (void)addTarget:(id)targetaction:(SEL)action;
//- (void)removeTarget:(id)targetaction:(SEL)action;

// Getting the touches and location of a gesture
- (NSPoint)locationInView:(NSView *)view;
//- (NSPoint)locationOfTouch:(NSUInteger)touchIndex inView:(NSView *)view;
//- (NSUInteger)numberOfTouches;

// Getting the recognizer's state and view
- (int)state;
- (void)changeState:(SNGestureRecognizerState)aState;
- (id)view;
- (void)setView:(NSView*)aView;
- (id)hitTestedView;
- (BOOL)enabled;
- (void)setEnabled:(BOOL)aValue;
- (BOOL)hasBegun;

// Cancelling and delaying touches
- (BOOL)cancelsTouchesInView;
- (BOOL)delaysTouchesBegan;
- (BOOL)delaysTouchesEnded;

// Specifying dependencies between gesture recognizers
- (void)requireGestureRecognizerToFail:(SNGestureRecognizer *)otherGestureRecognizer;
- (void)addObstacle:(SNGestureRecognizer *)otherGestureRecognizer;
- (void)removeObstacle:(SNGestureRecognizer *)otherGestureRecognizer;
- (void)addVulture:(SNGestureRecognizer *)otherGestureRecognizer;
- (void)tryToSendAction;
- (void)notifyFailure;
- (void)notifySuccess;

// Methods for subclasses
- (void)reset;
- (void)touchesBegan:(NSSet*)touches withEvent:(NSEvent*)event;
- (void)touchesMoved:(NSSet*)touches withEvent:(NSEvent*)event;
- (void)touchesEnded:(NSSet*)touches withEvent:(NSEvent*)event;
- (void)touchesCancelled:(NSSet*)touches withEvent:(NSEvent*)event;

// Common geometric calculations
- (NSPoint) centroidOfTouchesInWindow: (NSSet*)touches;

@end
