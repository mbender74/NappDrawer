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

#import "CustomMMDrawerController.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

static CGFloat const CustomMMDrawerDefaultBounceDistance = 50.0f;
static CGFloat const CustomMMDrawerSlidingProgressThreshold = 0.001f;

@implementation CustomMMDrawerController

- (void)viewDidLoad
{
  [super viewDidLoad];

  for (UIGestureRecognizer *gestureRecognizer in self.view.gestureRecognizers) {
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
      [gestureRecognizer addTarget:self action:@selector(slidingPanGestureUpdated:)];
    }
  }
}

- (void)openDrawerSide:(MMDrawerSide)drawerSide animated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
  [self startSlidingUpdatesForDrawerSide:drawerSide];

  [super openDrawerSide:drawerSide
               animated:animated
             completion:^(BOOL finished) {
               if (finished) {
                 [self notifyWindowAppearanceState:@"open"];
               }

               [self finishSlidingUpdates];

               if (completion) {
                 completion(finished);
               }
             }];
}

- (void)closeDrawerAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
  [self startSlidingUpdatesForDrawerSide:[self currentSlidingSide]];

  [super closeDrawerAnimated:animated
                  completion:^(BOOL finished) {
                    if (finished) {
                      [self notifyWindowAppearanceState:@"close"];
                    }

                    [self finishSlidingUpdates];

                    if (completion) {
                      completion(finished);
                    }
                  }];
}

- (void)bouncePreviewForDrawerSide:(MMDrawerSide)drawerSide completion:(void (^)(BOOL finished))completion
{
  [self bouncePreviewForDrawerSide:drawerSide distance:CustomMMDrawerDefaultBounceDistance completion:completion];
}

- (void)bouncePreviewForDrawerSide:(MMDrawerSide)drawerSide distance:(CGFloat)distance completion:(void (^)(BOOL finished))completion
{
  [self startSlidingUpdatesForDrawerSide:drawerSide];

  [super bouncePreviewForDrawerSide:drawerSide
                            distance:distance
                          completion:^(BOOL finished) {
                            [self finishSlidingUpdates];

                            if (completion) {
                              completion(finished);
                            }
                          }];
}

- (void)setWindowAppearanceCallback:(void (^)(NSString *))callback
{
  _callback = [callback copy];
}

// G11: Callback aufräumen um retain cycles zu vermeiden
- (void)clearWindowAppearanceCallback
{
  _callback = nil;
  [super setGestureCompletionBlock:nil];
}

- (void)setSlidingCallback:(void (^)(CGFloat progress, MMDrawerSide drawerSide))callback
{
  _slidingCallback = [callback copy];
  _lastSlidingProgress = -1.0f;
  _lastSlidingSide = MMDrawerSideNone;
}

- (void)clearSlidingCallback
{
  _slidingCallback = nil;
  [_slidingDisplayLink invalidate];
  _slidingDisplayLink = nil;
  _lastSlidingProgress = -1.0f;
  _lastSlidingSide = MMDrawerSideNone;
}

- (void)notifyWindowAppearanceState:(NSString *)state
{
  if (_callback) {
    _callback(state);
  }
}

- (void)slidingPanGestureUpdated:(UIPanGestureRecognizer *)panGesture
{
  if (!_slidingCallback) {
    return;
  }

  switch (panGesture.state) {
  case UIGestureRecognizerStateBegan:
  case UIGestureRecognizerStateChanged:
    [self startSlidingUpdatesForDrawerSide:[self currentSlidingSide]];
    [self sampleSlidingPosition];
    break;
  case UIGestureRecognizerStateEnded:
  case UIGestureRecognizerStateCancelled:
  case UIGestureRecognizerStateFailed:
    [self sampleSlidingPosition];
    break;
  default:
    break;
  }
}

- (void)startSlidingUpdatesForDrawerSide:(MMDrawerSide)drawerSide
{
  if (!_slidingCallback) {
    return;
  }

  if ((drawerSide == MMDrawerSideLeft && self.maximumLeftDrawerWidth <= 0.0f) ||
      (drawerSide == MMDrawerSideRight && self.maximumRightDrawerWidth <= 0.0f) ||
      drawerSide == MMDrawerSideNone) {
    return;
  }

  if (drawerSide != MMDrawerSideNone) {
    _lastSlidingSide = drawerSide;
  }

  if (!_slidingDisplayLink) {
    _slidingDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(sampleSlidingPosition)];
    [_slidingDisplayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
  }

  _slidingDisplayLink.paused = NO;
  [self sampleSlidingPosition];
}

- (void)finishSlidingUpdates
{
  [self sampleSlidingPosition];
  [_slidingDisplayLink invalidate];
  _slidingDisplayLink = nil;
}

- (void)sampleSlidingPosition
{
  if (!_slidingCallback) {
    return;
  }

  CGFloat progress = 0.0f;
  MMDrawerSide drawerSide = [self currentSlidingSideWithProgress:&progress];

  if (drawerSide == MMDrawerSideNone && _lastSlidingSide != MMDrawerSideNone) {
    drawerSide = _lastSlidingSide;
  }

  if (drawerSide == MMDrawerSideNone) {
    return;
  }

  BOOL sideChanged = drawerSide != _lastSlidingSide;
  BOOL progressChanged = fabs(progress - _lastSlidingProgress) >= CustomMMDrawerSlidingProgressThreshold;

  if (sideChanged || progressChanged) {
    _lastSlidingSide = drawerSide;
    _lastSlidingProgress = progress;
    _slidingCallback(progress, drawerSide);
  }
}

- (MMDrawerSide)currentSlidingSide
{
  CGFloat progress = 0.0f;
  MMDrawerSide drawerSide = [self currentSlidingSideWithProgress:&progress];

  if (drawerSide == MMDrawerSideNone) {
    drawerSide = self.openSide;
  }

  if (drawerSide == MMDrawerSideNone) {
    drawerSide = _lastSlidingSide;
  }

  return drawerSide;
}

- (MMDrawerSide)currentSlidingSideWithProgress:(CGFloat *)progress
{
  UIView *centerContainerView = self.centerViewController.view.superview;

  if (!centerContainerView) {
    if (progress) {
      *progress = 0.0f;
    }
    return MMDrawerSideNone;
  }

  CALayer *layer = centerContainerView.layer.presentationLayer ?: centerContainerView.layer;
  CGFloat offset = CGRectGetMinX(layer.frame);

  if (offset > 0.0f && self.maximumLeftDrawerWidth > 0.0f) {
    if (progress) {
      *progress = MIN(MAX(offset / self.maximumLeftDrawerWidth, 0.0f), 1.0f);
    }
    return MMDrawerSideLeft;
  }

  if (offset < 0.0f && self.maximumRightDrawerWidth > 0.0f) {
    if (progress) {
      *progress = MIN(MAX(fabs(offset) / self.maximumRightDrawerWidth, 0.0f), 1.0f);
    }
    return MMDrawerSideRight;
  }

  if (progress) {
    *progress = 0.0f;
  }

  return MMDrawerSideNone;
}

@end
