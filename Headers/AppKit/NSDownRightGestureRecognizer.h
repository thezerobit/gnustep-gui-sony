#import <AppKit/NSGestureRecognizer.h>

@interface NSDownRightGestureRecognizer : NSGestureRecognizer {
  NSPoint initialPoint;
}

- (float) distanceFrom: (NSPoint) p1 to: (NSPoint) p2;
@end
