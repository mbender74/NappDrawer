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

@implementation CustomMMDrawerController

- (void)openDrawerSide:(MMDrawerSide)drawerSide animated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
  [super openDrawerSide:drawerSide
               animated:animated
             completion:^(BOOL finished) {
               if (finished) {
                   self->_callback(@"open");
               }
             }];
}

- (void)closeDrawerAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion
{
  [super closeDrawerAnimated:animated
                  completion:^(BOOL finished) {
                    if (finished) {
                        self->_callback(@"close");
                    }
                  }];
}

- (void)setWindowAppearanceCallback:(void (^)(NSString *))callback
{
  _callback = [callback copy];

  __weak __typeof__(self) weakSelf = self;

  // add callback for the gestures
  [super setGestureCompletionBlock:^(MMDrawerController *controller, UIGestureRecognizer *gesture) {
    __typeof__(self) strongSelf = weakSelf;

    if (controller.openSide == MMDrawerSideNone) {
      strongSelf->_callback(@"close");
    } else {
      strongSelf->_callback(@"open");
    }
  }];
}



//-(void)setWindowAppearanceCallback:(void(^)(NSString*))callback
// {
//     _callback = [callback copy];
//
//     // add callback for the gestures
//     [super setGestureCompletionBlock:^(MMDrawerController *controller, UIGestureRecognizer *gesture) {
//         if(controller.openSide == MMDrawerSideNone){
//             self->_callback(@"close");
//         } else {
//             self->_callback(@"open");
//         }
//     }];
// }




@end
