//
//  ORShareEngine.m
//  Threshr
//
//  Created by Thomas Purnell-Fisher on 8/8/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import "ORShareEngine.h"
#import "ORActivityProvider.h"

@implementation ORShareEngine

- (void)shareURL:(NSString*)urlString andTitle:(NSString*)title andImage:(UIImage*)image andHostView:(UIViewController*)host andShareFrom:(NSString*)sharedFrom viaTwitterScreenName:(NSString*)twitterScreenName
{
    ORActivityProvider *item = [[ORActivityProvider alloc] initWithTitle:title url:urlString andTwitterScreenName:twitterScreenName];
	item.hasImage = (image != nil);
	NSArray *activityItems;
	
	if (image) {
		activityItems = @[item, image];
	} else {
		activityItems = @[item];
	}
	
	UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
	activityController.excludedActivityTypes = @[UIActivityTypeAirDrop, UIActivityTypeAssignToContact];

	[activityController setCompletionHandler:^(NSString *activityType, BOOL completed) {
		if (completed) {
			[LoggingEngine addLogItemAtLocation:sharedFrom andEvent:@"ItemShared" withParams:@{@"account": TwitterEngine.screenName, @"service": activityType}];
		}
	}];
	
	[LoggingEngine.gAnalytics sendView:@"Share"];
	
	[host presentViewController:activityController animated:YES completion:nil];
}

- (void)shareAppWithHostView:(UIViewController*)host;
{
    ORActivityProvider *item = [[ORActivityProvider alloc] initWithTitle:@"Check out this app" url:@"http://appstore.com/threshr" andTwitterScreenName:nil];
	NSArray *activityItems = @[item];
	item.forWordOfMouth = YES;
	UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
	[activityController setCompletionHandler:^(NSString *activityType, BOOL completed) {
		if (completed) {
			[LoggingEngine addLogItemAtLocation:@"word-of-mouth" andEvent:@"ItemShared" withParams:@{@"account": TwitterEngine.screenName, @"service": activityType}];
		}
	}];
	[LoggingEngine.gAnalytics sendView:@"Share"];
	[host presentViewController:activityController animated:YES completion:nil];
}

@end
