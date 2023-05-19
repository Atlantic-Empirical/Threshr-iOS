//
//  ORSFCardStats.h
//  Threshr
//
//  Created by Rodrigo Sieiro on 16/08/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORSFCardStats : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel *lblContent;
@property (nonatomic, strong) ORSFItem *item;

@end
