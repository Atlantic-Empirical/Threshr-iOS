//
//  ORSyncFlowCard.h
//  Orooso
//
//  Created by Rodrigo Sieiro on 04/12/2012.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import "ORSyncFlowCard.h"

@interface ORSFCardTwitterURL : ORSyncFlowCard

@property (nonatomic, strong) IBOutlet UILabel *debugLabel;
@property (nonatomic, weak) IBOutlet UIImageView *imgTwitterAvatar;
@property (weak, nonatomic) IBOutlet UILabel *lblPageTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblDomain;
@property (weak, nonatomic) IBOutlet UILabel *lblTwitterUserName;
@property (weak, nonatomic) IBOutlet UILabel *lblTwitterScreenName;
@property (weak, nonatomic) IBOutlet UILabel *lblRetweetCount;
@property (weak, nonatomic) IBOutlet UIView *viewCellContent;
@property (weak, nonatomic) IBOutlet UIButton *btnRemove;
@property (weak, nonatomic) ORTHLViewController *parent;
@property (weak, nonatomic) IBOutlet UIButton *btnRetweet;
@property (weak, nonatomic) IBOutlet UIButton *btnMentionCount;

- (IBAction)btnRemove_TouchUpInside:(id)sender;
- (IBAction)btnRetweet_TouchUpInside:(id)sender;
- (IBAction)btnMentionCount_TouchUpInside:(id)sender;

- (void)setRemovePosition:(float)position;
- (void)finishRemoveDraggingWithSuccess:(BOOL)success;

@end
