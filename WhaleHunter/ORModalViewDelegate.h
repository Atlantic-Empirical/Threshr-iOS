//
//  ORModalViewDelegate.h
//  Threshr
//
//  Created by Rodrigo Sieiro on 30/07/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ORModalViewDelegate <NSObject>

- (void)viewController:(UIViewController *)viewController dismissedWithSuccess:(BOOL)success;
- (void)viewController:(UIViewController *)viewController movedWithFactor:(CGFloat)factor;
- (void)viewController:(UIViewController *)viewController willDismissWithDuration:(CGFloat)duration;

@optional
- (void)navigateToURL:(NSURL *)url;
- (void)refreshParent;

@end
