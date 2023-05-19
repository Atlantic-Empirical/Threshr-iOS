//
//  ORActivityProvider.m
//  Threshr
//
//  Created by Rodrigo Sieiro on 07/08/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import "ORActivityProvider.h"

#define TWITTER_LIMIT 140
#define TWITTER_URL_LENGTH 23
#define TWITTER_MEDIA_LENGTH 32
#define VIA_FULL @"@threshr: http://appstore.com/threshr"
#define VIA_SMALL @"@threshr"
#define VIA_FACEBOOK @"#threshr: http://appstore.com/threshr"

@implementation ORActivityProvider

- (NSString*)viaTextSmall:(BOOL)small
{
	if ([TwitterEngine.userName isEqualToString:@"threshr"]) return @"";
	if (small) return VIA_SMALL;
	return VIA_FULL;
}

- (id)initWithTitle:(NSString *)title url:(NSString *)url andTwitterScreenName:(NSString*)twitterScreenName
{
    self = [super init];
    if (!self) return nil;
    
    self.title = title;
    self.url = url;
	self.twitterScreenName = twitterScreenName;
    
    return self;
}

- (NSUInteger)lengthWithTitle:(NSString *)title andVia:(NSString *)via
{
    // BUG: iOS Tweet composer counts "@Threshr" as an URL
    // So we need to count its chars as such
    NSUInteger length = 0;
	if (via && via.length > 0) length += [via length] + (TWITTER_URL_LENGTH - 8);
    if (title) length += [title length] + 1;
    if (self.url) length += TWITTER_URL_LENGTH + 1;
    if (self.hasImage) length += (TWITTER_MEDIA_LENGTH - 8);
	if (self.twitterScreenName) length += self.twitterScreenName.length + 6 + (TWITTER_URL_LENGTH - 8);
    return length;
}

- (NSString *)composedStringWithTitle:(NSString *)title url:(NSString *)url via:(NSString *)via
{
    // Original: [Title] [URL] via @Threshr for iOS: http://appstore.com/threshr [Image]
    
    NSMutableString *string = [NSMutableString stringWithCapacity:140];
    if (title) [string appendFormat:@"%@ ", title];
    if (url) [string appendFormat:@"%@ ", url];
    if (self.twitterScreenName) [string appendFormat:@"\nvia @%@", self.twitterScreenName];
    if (via && via.length > 0) [string appendFormat:@" & %@", via];

    return string;
}
	
- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
	if (self.forWordOfMouth) {
		return [self composedStringWithTitle:self.title url:self.url via:nil];
	} else {
		if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
			if ([self lengthWithTitle:self.title andVia:[self viaTextSmall:YES]] <= TWITTER_LIMIT) {
				// We're able to just shrink the "via" text
				// Result: [Title] [URL] via @Threshr [Image]
				return [self composedStringWithTitle:self.title url:self.url via:[self viaTextSmall:YES]];
			} else {
				// We have to shrink the title
				// Result: [Short Title](…) [URL] via @Threshr [Image]
				NSUInteger titleLength = (TWITTER_LIMIT - [self lengthWithTitle:nil andVia:[self viaTextSmall:YES]]) - 4;
				NSString *shortTitle = [NSString stringWithFormat:@"%@(…)", [self.title substringToIndex:titleLength - 1]];
				return [self composedStringWithTitle:shortTitle url:self.url via:[self viaTextSmall:YES]];
			}
		} else if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
			// Specific to Facebook
			return [self composedStringWithTitle:self.title url:self.url via:VIA_FACEBOOK];
		} else if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
			// Specific to Mail
			return [self composedStringWithTitle:self.title url:self.url via:[self viaTextSmall:NO]];
		}
		
		return [self composedStringWithTitle:self.title url:self.url via:[self viaTextSmall:NO]];
	}
	
	
	
//	if (self.forWordOfMouth) {
//		return [self composedStringWithTitle:self.title url:self.url via:nil];
//	} else {
//		if ([activityType isEqualToString:UIActivityTypePostToTwitter]) {
//			// Specific to Twitter
//			//        if ([self lengthWithTitle:self.title andVia:VIA_FULL] <= TWITTER_LIMIT) {
//			//            // Full string fits, just return it
//			//            // Result: [Title] [URL] via @Threshr for iOS: http://appstore.com/threshr [Image]
//			//            return [self composedStringWithTitle:self.title url:self.url via:VIA_FULL];
//			//        } else
//			if ([self lengthWithTitle:self.title andVia:VIA_SMALL] <= TWITTER_LIMIT) {
//				// We're able to just shrink the "via" text
//				// Result: [Title] [URL] via @Threshr [Image]
//				return [self composedStringWithTitle:self.title url:self.url via:VIA_SMALL];
//			} else {
//				// We have to shrink the title
//				// Result: [Short Title](…) [URL] via @Threshr [Image]
//				NSUInteger titleLength = (TWITTER_LIMIT - [self lengthWithTitle:nil andVia:VIA_SMALL]) - 4;
//				NSString *shortTitle = [NSString stringWithFormat:@"%@(…)", [self.title substringToIndex:titleLength - 1]];
//				return [self composedStringWithTitle:shortTitle url:self.url via:VIA_SMALL];
//			}
//		} else if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
//			// Specific to Facebook
//			return [self composedStringWithTitle:self.title url:self.url via:VIA_FULL];
//		} else if ([activityType isEqualToString:UIActivityTypePostToFacebook]) {
//			// Specific to Mail
//			return [self composedStringWithTitle:self.title url:self.url via:VIA_FULL];
//		}
//		
//		return [self composedStringWithTitle:self.title url:self.url via:VIA_FULL];
//	}
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    // Just return an empty string here
    return @"";
}

@end
