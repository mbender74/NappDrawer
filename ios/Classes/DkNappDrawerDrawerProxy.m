/**
 * Module developed by Napp ApS
 * www.napp.dk
 * Mads Møller
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */

#import "DkNappDrawerDrawerProxy.h"
#import "DkNappDrawerDrawer.h"
#import "TiUtils.h"
#import <TitaniumKit/TiApp.h>

@implementation DkNappDrawerDrawerProxy

- (void)windowDidOpen
{
  DkNappDrawerDrawer *drawerView = (DkNappDrawerDrawer *)[self view];
  if (drawerView) {
    CustomMMDrawerController *ctrl = drawerView.controller;
    if (ctrl && ![ctrl.view.superview isKindOfClass:[DkNappDrawerDrawer class]]) {
      [ctrl.view removeFromSuperview];
      [drawerView addSubview:ctrl.view];
    }
  }
  [super windowDidOpen];
  [self reposition];
}

- (void)windowWillClose
{
  TiViewProxy *leftWinProxy = [self valueForUndefinedKey:@"leftWindow"];
  TiViewProxy *rightWinProxy = [self valueForUndefinedKey:@"rightWindow"];
  TiViewProxy *centerWinProxy = [self valueForUndefinedKey:@"centerWindow"];

  if (leftWinProxy) {
    [leftWinProxy windowWillClose];
  }
  if (rightWinProxy) {
    [rightWinProxy windowWillClose];
  }
  if (centerWinProxy) {
    [centerWinProxy windowWillClose];
  }
}

- (void)windowDidClose
{
  TiViewProxy *leftWinProxy = [self valueForUndefinedKey:@"leftWindow"];
  TiViewProxy *rightWinProxy = [self valueForUndefinedKey:@"rightWindow"];
  TiViewProxy *centerWinProxy = [self valueForUndefinedKey:@"centerWindow"];
  DkNappDrawerDrawer *drawerView = (DkNappDrawerDrawer *)[self view];

  // Call child windowDidClose first (detaches their views)
  if (leftWinProxy) {
    [leftWinProxy windowDidClose];
  }
  if (rightWinProxy) {
    [rightWinProxy windowDidClose];
  }
  if (centerWinProxy) {
    [centerWinProxy windowDidClose];
  }
  CustomMMDrawerController *ctrl = drawerView ? drawerView.controller : nil;

  TiThreadPerformOnMainThread(^{
    // Only call close: if not already closing (avoids "Window is already closing" warning)
    if (!closing) {
      [self close:nil];
    }

    // Remove the CustomMMDrawerController from parent hierarchy
    if (ctrl && ctrl.parentViewController) {
      [ctrl willMoveToParentViewController:nil];
      [ctrl removeFromParentViewController];

      if ([ctrl.view.superview isKindOfClass:[DkNappDrawerDrawer class]]) {
        [ctrl.view removeFromSuperview];
      }
    }

    // Remove child TiViewControllers from parent
    if (ctrl.centerViewController && ctrl.centerViewController.parentViewController) {
      [ctrl.centerViewController willMoveToParentViewController:nil];
      [ctrl.centerViewController removeFromParentViewController];
    }
    if (ctrl.leftDrawerViewController && ctrl.leftDrawerViewController.parentViewController) {
      [ctrl.leftDrawerViewController willMoveToParentViewController:nil];
      [ctrl.leftDrawerViewController removeFromParentViewController];
    }
    if (ctrl.rightDrawerViewController && ctrl.rightDrawerViewController.parentViewController) {
      [ctrl.rightDrawerViewController willMoveToParentViewController:nil];
      [ctrl.rightDrawerViewController removeFromParentViewController];
    }

    // Remove the drawer view itself from superview
    if (drawerView.superview) {
      [drawerView removeFromSuperview];
    }

    if ([self _hasListeners:@"close"]) {
      [self fireEvent:@"close"];
    }
  },
  YES);
}

- (CustomMMDrawerController *)_controller
{
  return [(DkNappDrawerDrawer *)[self view] controller];
}

- (instancetype)newView
{
  return [[DkNappDrawerDrawer alloc] init];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
  return [[self _controller] preferredStatusBarStyle];
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
  return nil;
}

// G10: Moderner Orientation Handler — viewWillTransitionToSize statt deprecated Notification
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
  [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
  DkNappDrawerDrawer *drawerView = (DkNappDrawerDrawer *)[self view];
  if (drawerView) {
    CustomMMDrawerController *ctrl = drawerView.controller;
    if (ctrl && [ctrl.centerViewController isKindOfClass:[UINavigationController class]]) {
      UINavigationController *navCon = (UINavigationController *)ctrl.centerViewController;
      UINavigationBar *bar = navCon.navigationBar;
      CGFloat barHeight = bar.bounds.size.height;
      [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        bar.frame = CGRectMake(0, 0, size.width, barHeight);
      } completion:nil];
    }
  }
}

#pragma API

- (void)setStatusBarStyle_:(NSNumber *)style
{
  ENSURE_UI_THREAD(setStatusBarStyle_, style);
  // barStyle ist ein @protected ivar von TiWindowProxy, direkt zugreifbar in Unterklassen
  barStyle = (UIStatusBarStyle)[style intValue];
  [[TiApp controller] performSelectorOnMainThread:@selector(updateStatusBar) withObject:nil waitUntilDone:NO];
}

- (void)toggleLeftWindow:(id)args
{
  TiThreadPerformOnMainThread(^{
    [(DkNappDrawerDrawer *)[self view] toggleLeftWindow:args];
  },
      NO);
}

- (void)toggleRightWindow:(id)args
{
  TiThreadPerformOnMainThread(^{
    [(DkNappDrawerDrawer *)[self view] toggleRightWindow:args];
  },
      NO);
}

- (void)bounceLeftWindow:(id)args
{
  TiThreadPerformOnMainThread(^{
    [(DkNappDrawerDrawer *)[self view] bounceLeftWindow:args];
  },
      NO);
}

- (void)bounceRightWindow:(id)args
{
  TiThreadPerformOnMainThread(^{
    [(DkNappDrawerDrawer *)[self view] bounceRightWindow:args];
  },
      NO);
}

- (NSNumber *)isAnyWindowOpen:(id)args
{
  return [(DkNappDrawerDrawer *)[self view] isAnyWindowOpen:args];
}

- (NSNumber *)isLeftWindowOpen:(id)args
{
  return [(DkNappDrawerDrawer *)[self view] isLeftWindowOpen:args];
}

- (NSNumber *)isRightWindowOpen:(id)args
{
  return [(DkNappDrawerDrawer *)[self view] isRightWindowOpen:args];
}

- (void)setBackGroundColor:(id)args
{
  [(DkNappDrawerDrawer *)[self view] setBackgroundColor:[[TiUtils colorValue:[self valueForUndefinedKey:@"backgroundColor"]] _color]];
}

@end