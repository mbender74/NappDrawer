/**
 * Module developed by Napp ApS
 * www.napp.dk
 * Mads Møller
 */

#import "DkNappDrawerProxy.h"
#import "DkNappDrawer.h"


@implementation DkNappDrawerProxy

- (instancetype)init
{
  self = [super init];
  if (self) {
    _viewClassName = @"DkNappDrawer";
  }
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Window Lifecycle

- (void)windowDidOpen
{
  DkNappDrawer *drawerView = (DkNappDrawer *)[self view];
  
  if (!drawerView || ![self.view superview]) {
    // View not yet attached to window — Titanium will call this again later.
    return;
  }

  [super windowDidOpen];
  [self reposition];
}


#pragma mark - Reposition (called from TiUIWindowProxy.windowDidOpen)

- (void)reposition
{
  // Ensure the drawer view is properly sized and positioned within its superview.
  CGRect frame = [[self.view superview] bounds];
  if (!CGRectEqualToRect(self.view.frame, frame)) {
    [UIView animateWithDuration:0.15 animations:^{
      self.view.frame = frame;
    } completion:nil];
  }
}


#pragma mark - Close

- (void)close:(id)args
{
  DkNappDrawer *drawerView = (DkNappDrawer *)[self view];
  
  // Remove the drawer's internal MMDrawerController before closing.
  if (drawerView && [drawerView respondsToSelector:@selector(controller)]) {
    CustomMMDrawerController *ctrl = [drawerView controller];
    
    if ([ctrl.view.superview isKindOfClass:[DkNappDrawer class]]) {
      [[ctrl view] removeFromSuperview];
    }
  }

  // Call the parent close — this fires windowDidClose on child proxies.
  [super close:args];
}


#pragma mark - API Methods

- (void)toggleLeftWindow:(id)args
{
  TiThreadPerformOnMainThread(^{
    DkNappDrawer *drawerView = (DkNappDrawer *)[self view];
    if ([drawerView respondsToSelector:@selector(toggleLeftWindow:)]) {
      [drawerView toggleLeftWindow:args];
    }
  }, NO);
}

- (void)toggleRightWindow:(id)args
{
  TiThreadPerformOnMainThread(^{
    DkNappDrawer *drawerView = (DkNappDrawer *)[self view];
    if ([drawerView respondsToSelector:@selector(toggleRightWindow:)]) {
      [drawerView toggleRightWindow:args];
    }
  }, NO);
}

- (void)bounceLeftWindow:(id)args
{
  TiThreadPerformOnMainThread(^{
    DkNappDrawer *drawerView = (DkNappDrawer *)[self view];
    if ([drawerView respondsToSelector:@selector(bounceLeftWindow:)]) {
      [drawerView bounceLeftWindow:args];
    }
  }, NO);
}

- (void)bounceRightWindow:(id)args
{
  TiThreadPerformOnMainThread(^{
    DkNappDrawer *drawerView = (DkNappDrawer *)[self view];
    if ([drawerView respondsToSelector:@selector(bounceRightWindow:)]) {
      [drawerView bounceRightWindow:args];
    }
  }, NO);
}

- (NSNumber *)isAnyWindowOpen:(id)args
{
  DkNappDrawer *drawerView = (DkNappDrawer *)[self view];
  if ([drawerView respondsToSelector:@selector(isAnyWindowOpen:)]) {
    return [drawerView isAnyWindowOpen:args];
  }
  return @(NO);
}

- (NSNumber *)isLeftWindowOpen:(id)args
{
  DkNappDrawer *drawerView = (DkNappDrawer *)[self view];
  if ([drawerView respondsToSelector:@selector(isLeftWindowOpen:)]) {
    return [drawerView isLeftWindowOpen:args];
  }
  return @(NO);
}

- (NSNumber *)isRightWindowOpen:(id)args
{
  DkNappDrawer *drawerView = (DkNappDrawer *)[self view];
  if ([drawerView respondsToSelector:@selector(isRightWindowOpen:)]) {
    return [drawerView isRightWindowOpen:args];
  }
  return @(NO);
}


#pragma mark - Status Bar

- (void)setStatusBarStyle_:(id)style
{
  // handled by DkNappDrawer.m via property setter
}

@end
