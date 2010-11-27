#import <AppKit/SNGestureRecognizer.h>

@interface SNCheckmarkGestureRecognizer : SNGestureRecognizer {
  BOOL strokeDown;
  BOOL strokeUp;
  NSPoint midPoint;
  NSPoint cachedPoint;
}

- (NSPoint) midpointInView:(NSView *)view;

@end
