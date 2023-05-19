//
//  ORSFCardStats.m
//  Threshr
//
//  Created by Rodrigo Sieiro on 16/08/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import "ORSFCardStats.h"

@implementation ORSFCardStats

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"ORSFCardStats" owner:self options:nil];
        if ([arrayOfViews count] < 1) return nil;
        self = [arrayOfViews objectAtIndex:0];
    }
    
    return self;
}

- (void)setItem:(ORSFItem *)item
{
    _item = item;
    self.lblContent.text = item.content;
}

@end
