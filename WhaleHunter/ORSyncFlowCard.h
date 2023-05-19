//
//  ORSyncFlowCard.h
//  Orooso
//
//  Created by Rodrigo Sieiro on 04/12/2012.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import "SORelativeDateTransformer.h"

@class ORSFItem;

@interface ORSyncFlowCard : UICollectionViewCell <ORSFItemDelegate>

@property (nonatomic, strong) ORSFItem *item;
@property (nonatomic, strong) SORelativeDateTransformer *rdt;

@property (nonatomic, weak) IBOutlet UIView *viewCard;
@property (nonatomic, weak) IBOutlet UIImageView *imgMain;
@property (nonatomic, weak) IBOutlet UIImageView *imgType;

- (void)configureItem;
- (void)showText:(BOOL)animated;
- (void)hideTextAnimated:(BOOL)animated;

@end
