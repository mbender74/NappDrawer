/**
 * Module developed by Napp ApS
 * www.napp.dk
 * Mads Møller
 *
 * Appcelerator Titanium is Copyright (c) 2009-2010 by Appcelerator, Inc.
 * and licensed under the Apache Public License (version 2)
 */

#import "NappDrawerVisualState.h"
#import "MMDrawerVisualState.h"
#import <QuartzCore/QuartzCore.h>

@implementation NappDrawerVisualState

// G8: Redundante Visual State Methoden vereinfacht
// slideAndScale: eigen (unique to NappDrawer)
// slide, parallax3/5/7: delegiert an bundled MMDrawerVisualState
// none, fade: eigen (nicht im bundled MMDrawerVisualState vorhanden)

+ (MMDrawerControllerDrawerVisualStateBlock)slideAndScaleVisualStateBlock {
    MMDrawerControllerDrawerVisualStateBlock visualStateBlock = ^(MMDrawerController *drawerController, MMDrawerSide drawerSide, CGFloat percentVisible) {
        if (drawerSide == MMDrawerSideNone) return;

        CGFloat minScale = 0.90;
        CGFloat scale = minScale + (percentVisible * (1.0 - minScale));
        CATransform3D scaleTransform = CATransform3DMakeScale(scale, scale, scale);

        CGFloat maxDistance = 50;
        CGFloat distance = maxDistance * percentVisible;
        CATransform3D translateTransform;
        UIViewController *sideDrawerViewController;
        if (drawerSide == MMDrawerSideLeft) {
            sideDrawerViewController = drawerController.leftDrawerViewController;
            translateTransform = CATransform3DMakeTranslation((maxDistance - distance), 0.0, 0.0);
        } else if (drawerSide == MMDrawerSideRight) {
            sideDrawerViewController = drawerController.rightDrawerViewController;
            translateTransform = CATransform3DMakeTranslation(-(maxDistance - distance), 0.0, 0.0);
        }

        [sideDrawerViewController.view.layer setTransform:CATransform3DConcat(scaleTransform, translateTransform)];
        [sideDrawerViewController.view setAlpha:percentVisible];
    };
    return visualStateBlock;
}

+ (MMDrawerControllerDrawerVisualStateBlock)slideVisualStateBlock {
    return [MMDrawerVisualState slideVisualStateBlock];
}

+ (MMDrawerControllerDrawerVisualStateBlock)noneVisualStateBlock {
    MMDrawerControllerDrawerVisualStateBlock visualStateBlock = ^(MMDrawerController *drawerController, MMDrawerSide drawerSide, CGFloat percentVisible) {
        // No animation
    };
    return visualStateBlock;
}

+ (MMDrawerControllerDrawerVisualStateBlock)fadeVisualStateBlock {
    MMDrawerControllerDrawerVisualStateBlock visualStateBlock = ^(MMDrawerController *drawerController, MMDrawerSide drawerSide, CGFloat percentVisible) {
        if (drawerSide == MMDrawerSideNone) return;

        UIViewController *sideDrawerViewController;
        if (drawerSide == MMDrawerSideLeft) {
            sideDrawerViewController = drawerController.leftDrawerViewController;
        } else {
            sideDrawerViewController = drawerController.rightDrawerViewController;
        }
        [sideDrawerViewController.view setAlpha:percentVisible];
    };
    return visualStateBlock;
}

+ (MMDrawerControllerDrawerVisualStateBlock)parallax3VisualStateBlock {
    return [MMDrawerVisualState parallaxVisualStateBlockWithParallaxFactor:3.0];
}

+ (MMDrawerControllerDrawerVisualStateBlock)parallax5VisualStateBlock {
    return [MMDrawerVisualState parallaxVisualStateBlockWithParallaxFactor:5.0];
}

+ (MMDrawerControllerDrawerVisualStateBlock)parallax7VisualStateBlock {
    return [MMDrawerVisualState parallaxVisualStateBlockWithParallaxFactor:7.0];
}

@end
