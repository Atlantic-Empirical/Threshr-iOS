//
//  ORActivityProvider.h
//  Threshr
//
//  Created by Rodrigo Sieiro on 07/08/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORActivityProvider : NSObject <UIActivityItemSource>

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *twitterScreenName;
@property (nonatomic, assign) BOOL hasImage;
@property (nonatomic, assign) NSUInteger length;
@property (nonatomic, assign) BOOL forWordOfMouth;

- (id)initWithTitle:(NSString *)title url:(NSString *)url andTwitterScreenName:(NSString*)twitterScreenName;

@end
