/**
 * Module developed by Napp ApS
 * www.napp.dk
 * Mads Møller
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */
#define USE_TI_UINAVIGATIONWINDOW



#import "CustomMMDrawerController.h"
#import "NappDrawerVisualState.h"
#import "TiBase.h"
#import "TiUIView.h"
#import "TiUINavigationWindowProxy.h"
#import "TiWindowProxy.h"

#import <QuartzCore/QuartzCore.h>

@interface DkNappDrawerDrawer : TiUIView {
  @private
  CustomMMDrawerController *controller;
    TiUINavigationWindowProxy *navProxy;

  NSMutableArray *_accessibleElements;

  UIView *controllerView_;

  UIView *leftView_;
  UIView *rightView_;
  UIView *centerView_;
}

- (CustomMMDrawerController *)controller;

// Public APIs

- (void)toggleLeftWindow:(id)args;
- (void)toggleRightWindow:(id)args;
- (void)bounceLeftWindow:(id)args;
- (void)bounceRightWindow:(id)args;
- (NSNumber *)isAnyWindowOpen:(id)args;
- (NSNumber *)isLeftWindowOpen:(id)args;
- (NSNumber *)isRightWindowOpen:(id)args;
- (void)close:(id)args;

@end
