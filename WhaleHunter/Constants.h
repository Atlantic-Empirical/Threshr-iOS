//
//  Constants.h
//  WhaleHunter
//
//  Created by Rodrigo Sieiro on 25/07/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import "ORAppDelegate.h"

#ifndef WhaleHunter_Constants_h
#define WhaleHunter_Constants_h

#define AppDelegate ((ORAppDelegate *)[UIApplication sharedApplication].delegate)
#define RVC (ORTHLViewController*)(((ORAppDelegate *)[UIApplication sharedApplication].delegate).rootViewController)
#define ApiEngine [ORApiEngine sharedInstance]
#define TwitterEngine [ORTwitterEngine sharedInstance]
#define YouTubeEngine [ORYouTubeEngine sharedInstance]
#define LoggingEngine ((ORLoggingEngine*)((ORAppDelegate *)[UIApplication sharedApplication].delegate).loggingEngine)
#define ShareEngine ((ORShareEngine*)((ORAppDelegate *)[UIApplication sharedApplication].delegate).shareEngine)
#define THLEngine ((ORTHLEngine*)((ORAppDelegate *)[UIApplication sharedApplication].delegate).thl)

#define MINIMUM_SCALE 0.9f

// iOS Version
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#endif
