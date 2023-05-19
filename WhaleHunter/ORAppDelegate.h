//
//  ORAppDelegate.h
//  WhaleHunter
//
//  Created by Rodrigo Sieiro on 25/07/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ORLoggingEngine.h"
#import "ORShareEngine.h"

static NSString * const kStatusBarTappedNotification = @"statusBarTappedNotification";

@class ORTHLViewController, ORTHLEngine;

@interface ORAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ORTHLViewController *rootViewController;
@property (strong, nonatomic) ORLoggingEngine *loggingEngine;
@property (strong, nonatomic) ORShareEngine *shareEngine;
@property (nonatomic, strong) ORTHLEngine *thl;
@property (nonatomic, assign) BOOL allowRotation;

- (void)forcePortrait;
- (void)unlockOrientation;

@end
