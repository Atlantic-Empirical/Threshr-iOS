//
//  ORShareEngine.h
//  Threshr
//
//  Created by Thomas Purnell-Fisher on 8/8/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORShareEngine : NSObject

- (void)shareURL:(NSString*)urlString andTitle:(NSString*)title andImage:(UIImage*)image andHostView:(UIViewController*)host andShareFrom:(NSString*)sharedFrom viaTwitterScreenName:(NSString*)twitterScreenName;
- (void)shareAppWithHostView:(UIViewController*)host;

@end
