#include "AppKit/SNTouch.h"
#include "AppKit/NSView.h"

@implementation SNTouch

+ (SNTouch*) touchWithIdentity: (NSUInteger)iden
                         phase: (SNTouchPhase)pha
                        window: (NSWindow*)win
                          view: (NSView*)vi
              locationInWindow: (NSPoint)loc
{
  SNTouch *t;

  t = (SNTouch*)NSAllocateObject(self, 0, NSDefaultMallocZone());
  //if (self != eventClass)
  //  e = [e init];
  AUTORELEASE(t);

  t->identity = iden;
  t->phase = pha;
  t->locationInWindow = loc;
  t->window = RETAIN(win);
  t->view = RETAIN(vi);

  return t;
}

+ (SNTouch*) touchWithIdentity: (NSUInteger)iden
                         phase: (SNTouchPhase)pha
                        window: (NSWindow*)win
              locationInWindow: (NSPoint)loc
{
  SNTouch *t;

  t = (SNTouch*)NSAllocateObject(self, 0, NSDefaultMallocZone());
  //if (self != eventClass)
  //  e = [e init];
  AUTORELEASE(t);

  t->identity = iden;
  t->phase = pha;
  t->locationInWindow = loc;
  t->window = RETAIN(win);

  return t;
}

+ (SNTouch*) touchWithIdentity: (NSUInteger)iden
                         phase: (SNTouchPhase)pha
                      tapCount: (unsigned int)tap
                  windowNumber: (int)windowNum 
              locationInWindow: (NSPoint)loc;
{
  SNTouch *t;

  t = (SNTouch*)NSAllocateObject(self, 0, NSDefaultMallocZone());
  //if (self != eventClass)
  //  e = [e init];
  AUTORELEASE(t);

  t->identity = iden;
  t->phase = pha;
  t->tapCount = tap;
  t->locationInWindow = loc;
  t->window = RETAIN(GSWindowWithNumber(windowNum));

  return t;
}

- (void)dealloc
{
   //printf("SNTouch dealloc1\n");
   RELEASE(window); 
   //printf("SNTouch dealloc2\n");
   RELEASE(view);
   [super dealloc];
}
//- (double)timestamp;
- (NSUInteger)identity
{
  return identity;
}

- (NSUInteger)phase 
{
  return phase;
}
//- (int)info;
- (unsigned int)tapCount
{
  return tapCount;
}
//- (BOOL)isTap;
//- (BOOL)isWarped;
- (id)window
{
  return window;
}

- (id)view
{
  return view;
}

- (void)setView: (NSView*) v
{
  AUTORELEASE(view);
  view = RETAIN(v);
}
//- (struct CGPoint)locationInView:(id)fp8;

/**
 * Returns the window location for which this event was generated (in the
 * base coordinate system of the window).
 */
- (NSPoint) locationInWindow
{
  return locationInWindow;
}

- (NSPoint) locationInView
{
  return [view convertPoint: locationInWindow fromView: nil];
}

//- (struct CGPoint)previousLocationInView:(id)fp8;



@end
