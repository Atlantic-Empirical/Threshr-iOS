//
//  ORTweetCell.m
//  Threshr
//
//  Created by Rodrigo Sieiro on 30/07/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import "ORTweetCell.h"
#import "STTweetLabel.h"
#import "ORTweetsViewController.h"

@implementation ORTweetCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"ORTweetCell" owner:self options:nil];
        if ([arrayOfViews count] < 1) return nil;
        self = [arrayOfViews objectAtIndex:0];
        
        if (self) {
            self.tweetLabel = [[STTweetLabel alloc] initWithFrame:self.viewTweetContent.bounds];
            self.tweetLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.tweetLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:15.0f]];
            [self.tweetLabel setTextColor:[UIColor whiteColor]];
            [self.viewTweetContent addSubview:self.tweetLabel];
        }
    }
    
    return self;
}

- (void)setTweet:(ORTweet *)tweet
{
    if (tweet == _tweet) return;
    _tweet = tweet;
    
    self.lblStatus.alpha = 0.0f;
	self.lblTwitterUserName.text = tweet.user.name;
	self.lblTwitterScreenName.text = [NSString stringWithFormat:@"@%@", tweet.user.screenName];
    self.tweetLabel.text = tweet.text;
    self.imgTwitterAvatar.image = nil;
    
    if (tweet.isRetweet) {
        self.lblRetweetedBy.text = [NSString stringWithFormat:@"Retweeted by @%@", tweet.retweetUser.screenName];
        self.viewRetweetedBy.hidden = NO;
    } else {
        self.viewRetweetedBy.hidden = YES;
    }
    
    [self.btnRetweet setTitle:(tweet.retweetedByMe ? @"unretweet" : @"retweet") forState:UIControlStateNormal];
    [self.btnFav setTitle:(tweet.favoritedByMe ? @"unfav" : @"fav") forState:UIControlStateNormal];
    
    STLinkCallbackBlock callbackBlock = ^(STLinkActionType actionType, NSString *link) {
        NSURL *url;
        
        switch (actionType) {
            case STLinkActionTypeAccount: {
                url = [NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/%@",
                                            [link stringByReplacingOccurrencesOfString:@"@" withString:@""]]];
                break;
            }
            case STLinkActionTypeHashtag: {
                url = [NSURL URLWithString:[NSString stringWithFormat:@"https://twitter.com/search?q=%@&src=hash",
                                            [link stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
                break;
            }
            case STLinkActionTypeWebsite: {
                url = [NSURL URLWithString:link];
                break;
            }
        }
        
        if (url) [self.parent navigateToURL:url];
    };
    
    [self.tweetLabel setText:tweet.text];
    [self.tweetLabel setCallbackBlock:callbackBlock];
    
    if (tweet.user.profilePicUrl_normal) {
        NSURL *url = [NSURL URLWithString:tweet.user.profilePicUrl_normal];
        __weak ORTweetCell *weakSelf = self;
        __weak ORTweet *weakTweet = tweet;
        
        [[ORCachedEngine sharedInstance] imageAtURL:url size:self.imgTwitterAvatar.frame.size completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
            if (weakSelf.tweet == weakTweet) {
                weakSelf.imgTwitterAvatar.image = image;
            }
        }];
    }
	
	// DATE / TIME
    NSString *myDateString;
    NSDate *tweetDate = (tweet.retweetedAt) ? tweet.retweetedAt : tweet.createdAt;
	SORelativeDateTransformer *rdt = [[SORelativeDateTransformer alloc] init];
	NSTimeInterval interval = [[[NSDate alloc] init] timeIntervalSinceDate:tweetDate];
	if (interval > (60*60*24)){
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
		[dateFormatter setLocale:locale];
		[dateFormatter setDateFormat:@"dd' 'MMM' 'yy"];
		myDateString = [dateFormatter stringFromDate:tweetDate];
	} else {
		myDateString = [rdt transformedValue:tweetDate];
	}
	self.lblDate.text = myDateString;

}

- (void)btnReply_TouchUpInside:(id)sender
{
    [self.parent replyForCell:self];
}

- (void)btnRetweet_TouchUpInside:(id)sender
{
    if (self.tweet.retweetedByMe) {
        [TwitterEngine destroyId:self.tweet.myRetweetID completion:^(NSError *error, ORTweet *tweet) {
            if (error) NSLog(@"Unretweet Error: %@", error);

            self.tweet.myRetweetID = 0;
            self.tweet.retweetedByMe = NO;
            
            [self showStatus:@"unretweeted!" completion:^{
                [self.btnRetweet setTitle:(tweet.retweetedByMe ? @"unretweet" : @"retweet") forState:UIControlStateNormal];
            }];
        }];
    } else {
        [TwitterEngine retweetId:self.tweet.tweetID completion:^(NSError *error, ORTweet *tweet) {
            if (error) NSLog(@"Retweet Error: %@", error);

            self.tweet.myRetweetID = (tweet.isRetweet) ? tweet.retweetID : tweet.tweetID;
            self.tweet.retweetedByMe = YES;
            
            [self showStatus:@"retweeted!" completion:^{
                [self.btnRetweet setTitle:(tweet.retweetedByMe ? @"unretweet" : @"retweet") forState:UIControlStateNormal];
            }];
        }];
    }
}

- (void)btnFav_TouchUpInside:(id)sender
{
    if (self.tweet.favoritedByMe) {
        [TwitterEngine unfavoriteId:self.tweet.tweetID completion:^(NSError *error, ORTweet *tweet) {
            if (error) NSLog(@"Unfav Error: %@", error);
            
            self.tweet.favoritedByMe = NO;
            
            [self showStatus:@"unfavorited!" completion:^{
                [self.btnFav setTitle:(tweet.favoritedByMe ? @"unfav" : @"fav") forState:UIControlStateNormal];
            }];
        }];
    } else {
        [TwitterEngine favoriteId:self.tweet.tweetID completion:^(NSError *error, ORTweet *tweet) {
            if (error) NSLog(@"Fav Error: %@", error);
            
            self.tweet.favoritedByMe = YES;
            
            [self showStatus:@"favorited!" completion:^{
                [self.btnFav setTitle:(tweet.favoritedByMe ? @"unfav" : @"fav") forState:UIControlStateNormal];
            }];
        }];
    }
}

- (void)showStatus:(NSString *)status completion:(void(^)(void))completion
{
    self.lblStatus.text = status;
    [ORTweetCell cancelPreviousPerformRequestsWithTarget:self];
    
    [UIView animateWithDuration:0.3f animations:^{
        self.lblStatus.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [self performSelector:@selector(hideStatus) withObject:nil afterDelay:1.5f];
        if (completion) completion();
    }];
}

- (void)hideStatus
{
    [UIView animateWithDuration:0.3f animations:^{
        self.lblStatus.alpha = 0.0f;
    }];
}

@end
