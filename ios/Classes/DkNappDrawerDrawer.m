/**
 * Module developed by Napp ApS
 * www.napp.dk
 * Mads Møller
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#define USE_TI_UINAVIGATIONWINDOW

#import "DkNappDrawerDrawer.h"
#import "DkNappDrawerDrawerProxy.h"
#import "TiUINavigationWindowProxy.h"
#import "TiUtils.h"
#import "TiViewController.h"
#import "TiUINavigationWindowInternal.h"
#import <TitaniumKit/TiApp.h>



UIViewController *ControllerForViewProxy(TiViewProxy *proxy);

UIViewController *ControllerForViewProxy(TiViewProxy *proxy)
{
  [[proxy view] setAutoresizingMask:UIViewAutoresizingNone];

  //make the proper resize !
  TiThreadPerformOnMainThread(^{
    [proxy windowWillOpen];
    [proxy reposition];
    [proxy windowDidOpen];
  },
      YES);
  return [[TiViewController alloc] initWithViewProxy:proxy];
}

UINavigationController *NavigationControllerForViewProxy(TiUINavigationWindowProxy *proxy)
{
  return [proxy controller];
}

@implementation DkNappDrawerDrawer

#pragma mark - Accessibility

- (id)accessibilityElement
{
  return controllerView_;
}

- (NSArray *)accessibleElements

{
  if (_accessibleElements != nil) {
    [_accessibleElements removeAllObjects];
  } else {
    _accessibleElements = [[NSMutableArray alloc] init];
  }

  if ([[self isLeftWindowOpen:nil] intValue]) {
    [_accessibleElements addObject:leftView_];
  } else if ([[self isRightWindowOpen:nil] intValue]) {
    [_accessibleElements addObject:rightView_];
  }
  [_accessibleElements addObject:controllerView_];

  return _accessibleElements;
}

/* The container itself is not accessible, so MultiFacetedView should return NO in isAccessiblityElement. */
- (BOOL)isAccessibilityElement
{
  return NO;
}

/* The following methods are implementations of UIAccessibilityContainer protocol methods. */
- (NSInteger)accessibilityElementCount
{
  return [[self accessibleElements] count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
  return [[self accessibleElements] objectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
  return [[self accessibleElements] indexOfObject:element];
}

#pragma mark - Init

- (MMDrawerController *)controller
{
  if (controller == nil) {

    // Check in centerWindow is a UINavigationController
    BOOL useNavController = NO;
    if ([[[[self.proxy valueForUndefinedKey:@"centerWindow"] class] description] isEqualToString:@"TiUINavigationWindowProxy"]) {
      useNavController = YES;
    }

    // navController or TiWindow ?
    UIViewController *centerWindow = useNavController ? NavigationControllerForViewProxy([self.proxy valueForUndefinedKey:@"centerWindow"]) : ControllerForViewProxy([self.proxy valueForUndefinedKey:@"centerWindow"]);

    TiViewProxy *leftWindow = [self.proxy valueForUndefinedKey:@"leftWindow"];
    TiViewProxy *rightWindow = [self.proxy valueForUndefinedKey:@"rightWindow"];
    __weak __typeof__(self) weakSelf = self;

    if (leftWindow != nil) {

      BOOL leftIsNav = NO;
      if ([[[leftWindow class] description] isEqualToString:@"TiUINavigationWindowProxy"]) {
          leftIsNav = YES;
      }

        UIViewController *leftController = leftIsNav ? NavigationControllerForViewProxy([self.proxy valueForUndefinedKey:@"leftWindow"]) : ControllerForViewProxy([self.proxy valueForUndefinedKey:@"leftWindow"]);

        
//      TiViewController *leftController = leftIsNav ? NavigationControllerForViewProxy(leftWindow) : ControllerForViewProxy(leftWindow);

      //both left and right
      if (rightWindow != nil) {

        BOOL rightIsNav = NO;
        if ([[[rightWindow class] description] isEqualToString:@"TiUINavigationWindowProxy"]) {
            rightIsNav = YES;
        }

//        TiViewController *rightController = rightIsNav ? NavigationControllerForViewProxy(rightWindow) : ControllerForViewProxy(rightWindow);

          UIViewController *rightController = rightIsNav ? NavigationControllerForViewProxy([self.proxy valueForUndefinedKey:@"rightWindow"]) : ControllerForViewProxy([self.proxy valueForUndefinedKey:@"rightWindow"]);
          
          
        TiUINavigationWindowProxy *centerProxy = [self.proxy valueForUndefinedKey:@"centerWindow"];

        TiThreadPerformOnMainThread(^{
          [centerProxy windowWillOpen];
          [centerProxy windowDidOpen];
        },
            YES);

        controller = [[CustomMMDrawerController alloc] initWithCenterViewController:centerWindow
                                                           leftDrawerViewController:leftController
                                                          rightDrawerViewController:rightController];
        //left only
      } else {

        TiUINavigationWindowProxy *centerProxy = [self.proxy valueForUndefinedKey:@"centerWindow"];

        TiThreadPerformOnMainThread(^{
          [centerProxy windowWillOpen];
          [centerProxy windowDidOpen];
        },
            YES);

        controller = [[CustomMMDrawerController alloc] initWithCenterViewController:centerWindow
                                                           leftDrawerViewController:leftController];
      }
      //right only
    } else if (rightWindow != nil) {

      BOOL rightIsNav = NO;
      if ([[[rightWindow class] description] isEqualToString:@"TiUINavigationWindowProxy"]) {
          rightIsNav = YES;
      }

//      TiViewController *rightController = rightIsNav ? NavigationControllerForViewProxy(rightWindow) : ControllerForViewProxy(rightWindow);

        UIViewController *rightController = rightIsNav ? NavigationControllerForViewProxy([self.proxy valueForUndefinedKey:@"rightWindow"]) : ControllerForViewProxy([self.proxy valueForUndefinedKey:@"rightWindow"]);
        
      TiUINavigationWindowProxy *centerProxy = [self.proxy valueForUndefinedKey:@"centerWindow"];

      TiThreadPerformOnMainThread(^{
        [centerProxy windowWillOpen];
        [centerProxy windowDidOpen];
      },
          YES);

      controller = [[CustomMMDrawerController alloc] initWithCenterViewController:centerWindow
                                                        rightDrawerViewController:rightController];

      //error
    } else {
      NSLog(@"[ERROR][DkNappDrawerDrawer] No windows assigned");
      return nil;
    }
    
      
    // SET PROPERTIES at init
    if ([self.proxy valueForUndefinedKey:@"openDrawerGestureMode"] != nil) {
      [self setOpenDrawerGestureMode_:[self.proxy valueForUndefinedKey:@"openDrawerGestureMode"]];
    }

    if ([self.proxy valueForUndefinedKey:@"closeDrawerGestureMode"] != nil) {
      [self setCloseDrawerGestureMode_:[self.proxy valueForUndefinedKey:@"closeDrawerGestureMode"]];
    }

    if ([self.proxy valueForUndefinedKey:@"leftDrawerWidth"] != nil) {
      [self setLeftDrawerWidth_:[self.proxy valueForUndefinedKey:@"leftDrawerWidth"]];
    }

    if ([self.proxy valueForUndefinedKey:@"rightDrawerWidth"] != nil) {
      [self setRightDrawerWidth_:[self.proxy valueForUndefinedKey:@"rightDrawerWidth"]];
    }

    if ([self.proxy valueForUndefinedKey:@"centerHiddenInteractionMode"] != nil) {
      [self setCenterHiddenInteractionMode_:[self.proxy valueForUndefinedKey:@"centerHiddenInteractionMode"]];
    }

    if ([self.proxy valueForUndefinedKey:@"showShadow"] != nil) {
      [self setShowShadow_:[self.proxy valueForUndefinedKey:@"showShadow"]];
    }

    if ([self.proxy valueForUndefinedKey:@"animationMode"] != nil) {
      [self setAnimationMode_:[self.proxy valueForUndefinedKey:@"animationMode"]];
    }

    if ([self.proxy valueForUndefinedKey:@"animationVelocity"] != nil) {
      [self setAnimationVelocity_:[self.proxy valueForUndefinedKey:@"animationVelocity"]];
    }

    if ([self.proxy valueForUndefinedKey:@"shouldStretchDrawer"] != nil) {
      [self setShouldStretchDrawer_:[self.proxy valueForUndefinedKey:@"shouldStretchDrawer"]];
    }

    if ([self.proxy valueForUndefinedKey:@"showStatusBarView"] != nil) {
      [self setShowsStatusBarBackgroundView_:[self.proxy valueForUndefinedKey:@"showStatusBarView"]];
    }

    if ([self.proxy valueForUndefinedKey:@"statusBarStyle"] != nil) {
      [self setStatusBarStyle_:[self.proxy valueForUndefinedKey:@"statusBarStyle"]];
    }

    // open/close window
    [controller setWindowAppearanceCallback:^(NSString *state) {
      __typeof__(self) strongSelf = weakSelf;

      if ([state isEqualToString:@"open"]) {
          
        [[strongSelf proxy] fireEvent:@"windowDidOpen"];
          
          
      } else if ([state isEqualToString:@"close"]) {
          if ([TiUtils boolValue:[[strongSelf proxy] valueForUndefinedKey:@"autoCloseWindows"] def:YES]) {
              [[strongSelf proxy] fireEvent:@"windowDidClose"];
          }
 
      }

      [strongSelf _fireStateEventForCurrentState];
    }];

    [controller willMoveToParentViewController:TiApp.controller.topPresentedController];

    // set frame bounds & add it
    controllerView_ = [controller view];
    [controllerView_ setFrame:[self bounds]];
    [self addSubview:controllerView_];

    [TiApp.controller.topPresentedController addChildViewController:controller];

    leftView_ = leftWindow.view;
    rightView_ = rightWindow.view;
    centerView_ = centerWindow.view;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationDidChange:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
  }
  return controller;
}

- (void)orientationDidChange:(NSNotification *)note
{
  if ([self.controller.centerViewController isKindOfClass:[UINavigationController class]]) {
    UINavigationController *navCon = (UINavigationController *)self.controller.centerViewController;
    UINavigationBar *bar = navCon.navigationBar;

     // [navCon prefersStatusBarHidden];
      
    bar.frame = CGRectMake(0, 0, self.controller.view.bounds.size.width, 64);
  }
}

- (void)frameSizeChanged:(CGRect)frame bounds:(CGRect)bounds
{
  [[[self controller] view] setFrame:bounds];
  [super frameSizeChanged:frame bounds:bounds];
}

#pragma mark - Properties

- (void)setCenterWindow_:(id)args
{
  ENSURE_UI_THREAD(setCenterWindow_, args);
  BOOL useNavController = NO;
  if ([[[args class] description] isEqualToString:@"TiUINavigationWindowProxy"]) {
    useNavController = YES;
  }
  UIViewController *centerWindow = useNavController ? NavigationControllerForViewProxy([self.proxy valueForUndefinedKey:@"centerWindow"]) : ControllerForViewProxy([self.proxy valueForUndefinedKey:@"centerWindow"]);
  if (useNavController) {
      TiUINavigationWindowProxy *centerProxy = [self.proxy valueForUndefinedKey:@"centerWindow"];

    if (controller != nil) {
      [centerProxy windowWillOpen];
      [centerProxy windowDidOpen];
    }
  }

  [controller setCenterViewController:centerWindow];

  // Cleanup
  if (useNavController) {
    if (navProxy != nil) {
      if ([TiUtils boolValue:[[self proxy] valueForUndefinedKey:@"autoCloseWindows"] def:YES]) {
          [navProxy windowWillClose];
          [navProxy windowDidClose];
      }
    }
    // Save new proxy
    navProxy = [self.proxy valueForUndefinedKey:@"centerWindow"];
  }
}

- (void)setLeftWindow_:(id)args
{
  ENSURE_UI_THREAD(setLeftWindow_, args);
  if ([TiUtils boolValue:args] == 0) {
    [controller setLeftDrawerViewController:nil];
  } else {
    [controller setLeftDrawerViewController:ControllerForViewProxy(args)];
  }
}

- (void)setRightWindow_:(id)args
{
  ENSURE_UI_THREAD(setRightWindow_, args);
  if ([TiUtils boolValue:args] == 0) {
    [controller setRightDrawerViewController:nil];
  } else {
    [controller setRightDrawerViewController:ControllerForViewProxy(args)];
  }
}

- (void)setLeftDrawerWidth_:(id)args
{
  ENSURE_UI_THREAD(setLeftDrawerWidth_, args);
  //ENSURE_SINGLE_ARG(args, NSNumber);
  if ([args respondsToSelector:@selector(objectForKey:)]) {
    [controller setMaximumLeftDrawerWidth:[TiUtils floatValue:@"width" properties:args] animated:[TiUtils boolValue:@"animated" properties:args def:NO] completion:nil];
  } else {
    [controller setMaximumLeftDrawerWidth:[TiUtils floatValue:args]];
  }
}

- (void)setRightDrawerWidth_:(id)args
{
  ENSURE_UI_THREAD(setRightDrawerWidth_, args);
  // ENSURE_SINGLE_ARG(args, NSNumber);
  if ([args respondsToSelector:@selector(objectForKey:)]) {
    [controller setMaximumRightDrawerWidth:[TiUtils floatValue:@"width" properties:args] animated:[TiUtils boolValue:@"animated" properties:args def:NO] completion:nil];
  } else {
    [controller setMaximumRightDrawerWidth:[TiUtils floatValue:args]];
  }
}

- (void)setCloseDrawerGestureMode_:(id)args
{
  ENSURE_UI_THREAD(setCloseDrawerGestureMode_, args);
  ENSURE_SINGLE_ARG(args, NSNumber);
  [controller setCloseDrawerGestureModeMask:[TiUtils intValue:args]];
}

- (void)setOpenDrawerGestureMode_:(id)args
{
  ENSURE_UI_THREAD(setOpenDrawerGestureMode_, args);
  ENSURE_SINGLE_ARG(args, NSNumber);
  [controller setOpenDrawerGestureModeMask:[TiUtils intValue:args]];
}

- (void)setCenterHiddenInteractionMode_:(id)args
{
  ENSURE_UI_THREAD(setCenterHiddenInteractionMode_, args);
  ENSURE_SINGLE_ARG(args, NSNumber);
  [controller setCenterHiddenInteractionMode:[TiUtils intValue:args]];
}

- (void)setAnimationVelocity_:(id)args
{
  ENSURE_UI_THREAD(setAnimationVelocity_, args);
  ENSURE_SINGLE_ARG(args, NSNumber);
  [controller setAnimationVelocity:[TiUtils floatValue:args]];
}

- (void)setShowShadow_:(id)args
{
  ENSURE_UI_THREAD(setShowShadow_, args);
  ENSURE_SINGLE_ARG(args, NSNumber);
  [controller setShowsShadow:[TiUtils boolValue:args]];
}

- (void)setShouldStretchDrawer_:(id)args
{
  ENSURE_UI_THREAD(setShouldStretchDrawer_, args);
  ENSURE_SINGLE_ARG(args, NSNumber);
  [controller setShouldStretchDrawer:[TiUtils boolValue:args]];
}

- (void)setShowsStatusBarBackgroundView_:(id)args
{
  ENSURE_UI_THREAD(setShowsStatusBarBackgroundView_, args);
  ENSURE_SINGLE_ARG(args, NSNumber);
  [controller setShowsStatusBarBackgroundView:[TiUtils boolValue:args]];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
  return [controller preferredStatusBarStyle];
}

- (UIViewController *)childViewControllerForStatusBarStyle
{
  return nil;
}


- (void)setStatusBarStyle_:(NSNumber *)style
{
  ENSURE_UI_THREAD(setStatusBarStyle_, style);    
    
    controller.navigationController.navigationBar.barStyle = [style intValue];
    
//  [[UIApplication sharedApplication] setStatusBarStyle:[style intValue]];
}

- (void)setAnimationMode_:(id)args
{
  ENSURE_UI_THREAD(setAnimationMode_, args);
  int mode = [TiUtils intValue:args];
  switch (mode) {
  case 1:
    [controller setDrawerVisualStateBlock:[NappDrawerVisualState slideAndScaleVisualStateBlock]];
    break;
  case 2:
    [controller setDrawerVisualStateBlock:[NappDrawerVisualState slideVisualStateBlock]];
    break;
  case 3:
    [controller setDrawerVisualStateBlock:[NappDrawerVisualState noneVisualStateBlock]];
    break;
  case 4:
    [controller setDrawerVisualStateBlock:[NappDrawerVisualState parallax3VisualStateBlock]];
    break;
  case 5:
    [controller setDrawerVisualStateBlock:[NappDrawerVisualState parallax5VisualStateBlock]];
    break;
  case 6:
    [controller setDrawerVisualStateBlock:[NappDrawerVisualState parallax7VisualStateBlock]];
    break;
  case 7:
    [controller setDrawerVisualStateBlock:[NappDrawerVisualState fadeVisualStateBlock]];
    break;
  case 100:
    [controller setDrawerVisualStateBlock:[NappDrawerVisualState noneVisualStateBlock]];
  default:
    [controller setDrawerVisualStateBlock:[NappDrawerVisualState noneVisualStateBlock]];
    break;
  }
}



#pragma mark - API


//-(KrollPromise *)close:(id)args {
//
//    if ([self.proxy _hasListeners:@"close"]) {
//      [self.proxy  fireEvent:@"close"];
//    }
//
//
////    [(DkNappDrawerDrawer *)[self view] removeFromSuperview];
////
////    TiViewProxy *leftWinProxy = [self valueForUndefinedKey:@"leftWindow"];
////    TiViewProxy *rightWinProxy = [self valueForUndefinedKey:@"rightWindow"];
////    TiViewProxy *centerWinProxy = [self valueForUndefinedKey:@"centerWindow"];
////    [leftWinProxy windowDidClose];
////    [rightWinProxy windowDidClose];
////    [centerWinProxy windowDidClose];
////
////    [controller closeDrawerAnimated:NO completion:^(BOOL finished) {
////    }];
//
//}

- (void)toggleLeftWindow:(id)args
{
  ENSURE_UI_THREAD(toggleLeftWindow, args);
  [controller toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)toggleRightWindow:(id)args
{
  ENSURE_UI_THREAD(toggleRightWindow, args);
  [controller toggleDrawerSide:MMDrawerSideRight animated:YES completion:nil];
}

- (void)bounceLeftWindow:(id)args
{
  ENSURE_UI_THREAD(bounceLeftWindow, args);
  [controller bouncePreviewForDrawerSide:MMDrawerSideLeft completion:nil];
}

- (void)bounceRightWindow:(id)args
{
  ENSURE_UI_THREAD(bounceRightWindow, args);
  [controller bouncePreviewForDrawerSide:MMDrawerSideRight completion:nil];
}

- (NSNumber *)isAnyWindowOpen:(id)args
{
  return NUMBOOL(controller.openSide != MMDrawerSideNone);
}

- (NSNumber *)isLeftWindowOpen:(id)args
{
  return NUMBOOL(controller.openSide == MMDrawerSideLeft);
}

- (NSNumber *)isRightWindowOpen:(id)args
{
  return NUMBOOL(controller.openSide == MMDrawerSideRight);
}

#pragma mark - Events

// Little hack to propagate focus/blur events
- (void)_fireStateEventForCurrentState
{
  if ([[self controller] openSide] == MMDrawerSideNone) {
    if ([[self proxy] _hasListeners:@"centerWindowDidFocus"]) {
      [[self proxy] fireEvent:@"centerWindowDidFocus"];
    }
  } else {
    if ([[self proxy] _hasListeners:@"centerWindowDidBlur"]) {
      [[self proxy] fireEvent:@"centerWindowDidBlur"];
    }
  }
}
@end
