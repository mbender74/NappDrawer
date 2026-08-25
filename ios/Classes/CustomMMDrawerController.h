/**
 * Module developed by Napp ApS
 * www.napp.dk
 * Mads Møller
 *
 * CustomMMDrawerController - PR from Azwan b. Amit
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */

#import "MMDrawerController.h"

typedef void (^WindowAppearanceChangeBlock)(NSString *state);
typedef void (^DrawerSlidingBlock)(CGFloat progress, MMDrawerSide drawerSide);

@interface CustomMMDrawerController : MMDrawerController {
  WindowAppearanceChangeBlock _callback;
  DrawerSlidingBlock _slidingCallback;
  CADisplayLink *_slidingDisplayLink;
  CGFloat _lastSlidingProgress;
  MMDrawerSide _lastSlidingSide;
}

- (void)setWindowAppearanceCallback:(void (^)(NSString *))callback;
// G11: Callback beim Close aufräumen (retain cycle vermeiden)
- (void)clearWindowAppearanceCallback;
- (void)setSlidingCallback:(void (^)(CGFloat progress, MMDrawerSide drawerSide))callback;
- (void)clearSlidingCallback;

@end
