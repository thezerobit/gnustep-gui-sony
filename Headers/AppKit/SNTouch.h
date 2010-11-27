#include "Foundation/NSObject.h"
#include <Foundation/NSGeometry.h>
//#include "AppKit/NSWindow.h"
//#include "AppKit/NSView.h"

@class NSWindow;
@class NSView;

enum {
  SNTouchPhaseBegan        = 1U << 0,
  SNTouchPhaseMoved        = 1U << 1,
  SNTouchPhaseStationary   = 1U << 2,
  SNTouchPhaseEnded        = 1U << 3,
  SNTouchPhaseCancelled    = 1U << 4,

  SNTouchPhaseTouching     = SNTouchPhaseBegan | SNTouchPhaseMoved | SNTouchPhaseStationary,
  SNTouchPhaseAny          = 0xffffffffU

};
typedef NSUInteger SNTouchPhase;

@interface SNTouch : NSObject /*<NSCopying>*/
{
    //double _timestamp;
    @public NSUInteger identity;
    @public SNTouchPhase phase;
    @public unsigned int tapCount;
    NSWindow *window;
    NSView *view;
    @public NSPoint locationInWindow;
    
    //struct CGPoint _previousLocationInWindow;
    /**
    struct {
        unsigned int _firstTouchForView:1;
        unsigned int _isTap:1;
        unsigned int _isWarped:1;
    } _touchFlags;
    **/
}
 
+ (SNTouch*) touchWithIdentity: (NSUInteger)iden
                         phase: (SNTouchPhase) pha
                        window: (NSWindow*) win
                          view: (NSView*) vi
              locationInWindow: (NSPoint)loc;

+ (SNTouch*) touchWithIdentity: (NSUInteger)iden
                         phase: (SNTouchPhase) pha
                        window: (NSWindow*) win
              locationInWindow: (NSPoint)loc;

+ (SNTouch*) touchWithIdentity: (NSUInteger)iden
                         phase: (SNTouchPhase)pha
                      tapCount: (unsigned int)tap
                  windowNumber: (int)windowNum 
              locationInWindow: (NSPoint)loc;

- (void)dealloc;
//- (double)timestamp;
- (NSUInteger)identity;
- (NSUInteger)phase;
//- (int)info;
- (unsigned int)tapCount;
//- (BOOL)isTap;
//- (BOOL)isWarped;
- (id)window;
- (id)view;
- (void)setView: (NSView*) v;
//- (struct CGPoint)locationInView:(id)fp8;

- (NSPoint) locationInWindow;
- (NSPoint) locationInView;

//- (struct CGPoint)previousLocationInView:(id)fp8;
 
@end

