//
//  ORTweetCell.h
//  Threshr
//
//  Created by Rodrigo Sieiro on 30/07/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <UIKit/UIKit.h>

@class STTweetLabel, ORTweetsViewController;

@interface ORTweetCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *imgTwitterAvatar;
@property (nonatomic, weak) IBOutlet UILabel *lblTwitterUserName;
@property (nonatomic, weak) IBOutlet UILabel *lblTwitterScreenName;
@property (nonatomic, weak) IBOutlet UILabel *lblStatus;
@property (nonatomic, weak) IBOutlet UIView *viewTweetContent;
@property (nonatomic, weak) IBOutlet UIView *viewRetweetedBy;
@property (nonatomic, weak) IBOutlet UILabel *lblRetweetedBy;
@property (nonatomic, weak) IBOutlet UIButton *btnReply;
@property (nonatomic, weak) IBOutlet UIButton *btnRetweet;
@property (nonatomic, weak) IBOutlet UIButton *btnFav;
@property (weak, nonatomic) IBOutlet UILabel *lblDate;

@property (nonatomic, weak) ORTweetsViewController *parent;
@property (nonatomic, strong) STTweetLabel *tweetLabel;
@property (nonatomic, strong) ORTweet *tweet;

- (IBAction)btnReply_TouchUpInside:(id)sender;
- (IBAction)btnRetweet_TouchUpInside:(id)sender;
- (IBAction)btnFav_TouchUpInside:(id)sender;

- (void)showStatus:(NSString *)status completion:(void(^)(void))completion;

@end
