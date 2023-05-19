//
//  ORAppDelegate.m
//  WhaleHunter
//
//  Created by Rodrigo Sieiro on 25/07/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <Crashlytics/Crashlytics.h>
#import "ORAppDelegate.h"
#import "ORTHLViewController.h"
#import "iRate.h"
#import "Flurry.h"

//565af010-20d8-4026-bcbf-a052c85cbc86

@implementation ORAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initialize Twitter with this app's keys
    ORTwitterEngine *twitter = [ORTwitterEngine sharedInstanceWithConsumerKey:@"6iCeBj0lNdDO9CPnuyiZzQ" andSecret:@"PQ7qcVyiWg0XzxxjVZGonchZrQIFWmQo1IGo4qrDiM"];
    NSLog(@"Twitter Engine Initiated: %@", twitter.consumerKey);
    
    ORApiEngine *apiEngine = [ORApiEngine sharedInstanceWithHostname:@"api.orooso.com" portNumber:80 useSSL:YES];
    apiEngine.currentAppCode = @"T";
    NSLog(@"API Engine Initiated: %@", apiEngine.baseURLString);
	
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	// Start all the Logging engines (and get a client id)
    self.loggingEngine = [ORLoggingEngine sharedInstance];
    [self.loggingEngine setupWithTestFlightId:@"a09d7e3a-c08d-4123-94bd-585460e410c9" andGoogleAnalyticsId:@"UA-37199973-3" andMixpanelId:@"4d9b91edd1a4b4d3aa5083b7e8829c99"];
    self.loggingEngine.company = @"Threshr";
    self.loggingEngine.device = @"iPhone";

	// Flurry
	[Flurry setCrashReportingEnabled:NO];
	[Flurry startSession:@"W249Q39SYCG2BJHJNKHV"];

	// Init Share Engine
	self.shareEngine = [[ORShareEngine alloc] init];
	
	// Configure iRate
	[iRate sharedInstance].onlyPromptIfLatestVersion = YES;
	[iRate sharedInstance].applicationName = @"Threshr";
	[iRate sharedInstance].remindPeriod = 7.0f;
	[iRate sharedInstance].daysUntilPrompt = 2;
	[iRate sharedInstance].usesUntilPrompt = 5;

	// Crashlytics
	[Crashlytics startWithAPIKey:@"5a11c8640615cf918918506da693d71a374cc45b"];
    
    self.allowRotation = NO;
    self.rootViewController = [[ORTHLViewController alloc] initWithNibName:nil bundle:nil];
    self.window.rootViewController = self.rootViewController;
    [self.window makeKeyAndVisible];
	
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [self.thl stopTimer];
	[[ORCachedEngine sharedInstance] cacheCleanup];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [self.rootViewController refreshData:nil];
    [self.thl startTimer];
    
    if (TwitterEngine.isAuthenticated) {
        [LoggingEngine addLogItemAtLocation:@"THL" andEvent:@"Resumed" withParams:@{@"account": TwitterEngine.screenName}];
    } else {
        [LoggingEngine addLogItemAtLocation:@"THL" andEvent:@"Resumed" withParams:nil];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (UIInterfaceOrientation)interfaceOrientation
{
    return self.rootViewController.interfaceOrientation;
}

- (NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    if (self.allowRotation) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (void)forcePortrait
{
    self.allowRotation = NO;
    
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
        UIViewController *vc = [[UIViewController alloc] init];
        UINavigationController* nc = [[UINavigationController alloc] initWithRootViewController:vc];
        [self.rootViewController presentViewController:nc animated:NO completion:nil];
        [self.rootViewController dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)unlockOrientation
{
    self.allowRotation = YES;
}

#pragma mark - Status bar touch tracking

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
	CGPoint location = [[[event allTouches] anyObject] locationInView:[self window]];
	CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;

	if (CGRectContainsPoint(statusBarFrame, location)) {
		[self statusBarTouchedAction];
	}
}

- (void)statusBarTouchedAction
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kStatusBarTappedNotification object:nil];
}

@end
