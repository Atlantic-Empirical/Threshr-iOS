//
//  ORSyncFlowCard.m
//  Orooso
//
//  Created by Rodrigo Sieiro on 04/12/2012.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORSyncFlowCard.h"
#import "ORTwitterUserRelationship.h"
#import "ORImage.h"

@implementation ORSyncFlowCard

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    return self;
}

- (void)setItem:(ORSFItem *)item
{
    if (_item && _item != item) [_item cancelPendingOperations];

    _item = item;
    _item.delegate = self;
    
    self.imgMain.image = nil;
    self.imgType.image = nil;
    
    [self configureItem];
}

- (void)showText:(BOOL)animated
{
    // Do nothing by default
}

- (void)hideTextAnimated:(BOOL)animated
{
    // Do nothing by default
}

- (void)configureItem
{
    NSAssert(1 == 0, @"This method should be overriden");
}

//- (void)presentSecondaryLongPressAffordance:(BOOL)showIt
//{
//	if (showIt) {
//		
//		self.imgLongPressSecondaryAffordance.alpha = 0.0f;
//		self.imgLongPressSecondaryAffordance.hidden = NO;
//		[UIView animateWithDuration:0.2f delay:0.0f
//							options:UIViewAnimationOptionAllowUserInteraction
//						 animations:^{
//							 self.imgLongPressSecondaryAffordance.alpha = 1.0f;
//						 } completion:^(BOOL finished) {
//							 //
//						 }];
//	} else {
//		[UIView animateWithDuration:0.2f delay:0.0f
//							options:UIViewAnimationOptionAllowUserInteraction
//						 animations:^{
//							 self.imgLongPressSecondaryAffordance.alpha = 0.0f;
//						 } completion:^(BOOL finished) {
//							 self.imgLongPressSecondaryAffordance.hidden = YES;
//						 }];
//	}
//}

#pragma mark - ORSFItemDelegate Methods

- (void)item:(ORSFItem *)item avatarLoaded:(UIImage *)image local:(BOOL)local
{
    NSAssert(1 == 0, @"This method should be overriden");
}

- (void)item:(ORSFItem *)item imageLoaded:(UIImage *)image local:(BOOL)local
{
    NSAssert(1 == 0, @"This method should be overriden");
}

- (void)itemImageIsLoading:(ORSFItem *)item
{
    NSAssert(1 == 0, @"This method should be overriden");
}

- (void)itemImageFailedToLoad:(ORSFItem *)item
{
    NSAssert(1 == 0, @"This method should be overriden");
}

- (void)itemDetailURLResolved:(ORSFItem *)item
{
    NSAssert(1 == 0, @"This method should be overriden");
}

@end
