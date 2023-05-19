//
//  ORSyncFlowCard.m
//  Orooso
//
//  Created by Rodrigo Sieiro on 04/12/2012.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import "ORSFCardTwitterURL.h"
#import "ORTwitterUserRelationship.h"
#import "SORelativeDateTransformer.h"
#import "ORImage.h"
#import "ORSFTwitterURL.h"
#import "NSString+ORString.h"
#import "STTweetLabel.h"
#import "ORTHLViewController.h"
#import "GTMNSString+HTML.h"

@interface ORSFCardTwitterURL ()

@property (nonatomic, strong) ORTweet *tweet;

@end

@implementation ORSFCardTwitterURL

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        NSArray *arrayOfViews = [[NSBundle mainBundle] loadNibNamed:@"ORSFCardTwitterURL" owner:self options:nil];
        if ([arrayOfViews count] < 1) return nil;
        self = [arrayOfViews objectAtIndex:0];
    }

    return self;
}

- (void)configureItem
{
//    self.loadingView.alpha = 0.0f;
    self.imgMain.alpha = 0.0f;
    self.imgMain.image = nil;
	self.imgTwitterAvatar.image = nil;
	self.lblDomain.text = @"";
	self.lblRetweetCount.text = @"";
	self.lblTwitterScreenName.text = @"";
	self.lblTwitterUserName.text = @"";

    [self updatePageTitle:@""];
    [self configureForTweet:((ORSFTweet*)self.item)];
    
    UIImage *image = self.item.mainImage;
    if (image) {
        [self item:self.item imageLoaded:image local:YES];
    }
}

#pragma mark - ORSFItemDelegate Methods

- (void)item:(ORSFItem *)item avatarLoaded:(UIImage *)image local:(BOOL)local
{
    if (item == self.item) {
        self.imgTwitterAvatar.image = image;
        self.imgTwitterAvatar.hidden = NO;
    } else {
        NSLog(@"Card changed before avatar delegate response: %@ -> %@", item.itemID, self.item.itemID);
    }
}

- (void)item:(ORSFItem *)item imageLoaded:(UIImage *)image local:(BOOL)local
{
    if (item == self.item) {
		// Adjust and align to top portion of image if the image is tall (avoid cutting off people's heads)
        self.imgMain.image = image;
        
        if (!local) {
            [UIView animateWithDuration:0.5f delay:0.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
                self.imgMain.alpha = 1.0f;
//                self.loadingView.alpha = 0.0f;
                [self hideTextAnimated:NO];
            } completion:nil];
        } else {
            self.imgMain.alpha = 1.0f;
//            self.loadingView.alpha = 0.0f;
            [self hideTextAnimated:NO];
        }
        
        [self updatePageTitle:self.lblPageTitle.text];
    } else {
        NSLog(@"Card changed before image return: %@ -> %@", item.itemID, self.item.itemID);
    }
}

- (void)itemImageIsLoading:(ORSFItem *)item
{
    if (item == self.item) {
//        [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
//            self.loadingView.alpha = 1.0f;
//        } completion:nil];
    } else {
        NSLog(@"Card changed before image load: %@ -> %@", item.itemID, self.item.itemID);
    }
}

- (void)itemImageFailedToLoad:(ORSFItem *)item
{
    if (item == self.item) {
//        [UIView animateWithDuration:0.2f delay:0.0f options:UIViewAnimationOptionAllowUserInteraction animations:^{
//            self.loadingView.alpha = 0.0f;
//        } completion:nil];
    } else {
        NSLog(@"Card changed before image fail: %@ -> %@", item.itemID, self.item.itemID);
    }
}

- (void)itemDetailURLResolved:(ORSFItem *)item
{
    if (item != self.item) {
        NSLog(@"Card changed before detail resolved: %@ -> %@", item.itemID, self.item.itemID);
    } else {
		[self populateResolvedUrlFieldsForOrUrl:item.detailURL];

        if (item.detailURL.imageURL) {
            item.imageURL = item.detailURL.imageURL;
            UIImage *img = item.mainImage;
            if (img) [self item:self.item imageLoaded:img local:YES];
        }
	}
}

- (void)itemDetailURLFailedToResolve:(ORSFItem *)item
{
    if (item != self.item) {
        NSLog(@"Card changed before detail resolved: %@ -> %@", item.itemID, self.item.itemID);
    } else {
		[self populateResolvedUrlFieldsForOrUrl:item.detailURL];
	}
}

//  TWITTER
//================================================================================================================
#pragma mark - TWITTER

- (void)configureForTweet:(ORSFTweet *)tweet
{
    NSString *avatarURL;
	self.tweet = tweet.tweet;
    
    if (tweet.tweet.isRetweet) {
        self.lblTwitterUserName.text = tweet.tweet.retweetUser.name;
        self.lblTwitterScreenName.text = [NSString stringWithFormat:@"@%@", tweet.tweet.retweetUser.screenName];
        avatarURL = tweet.tweet.retweetUser.profilePicUrl_normal;
    } else {
        self.lblTwitterUserName.text = tweet.tweet.user.name;
        self.lblTwitterScreenName.text = [NSString stringWithFormat:@"@%@", tweet.tweet.user.screenName];
        avatarURL = tweet.tweet.user.profilePicUrl_normal;
    }

	self.lblRetweetCount.text = [NSString stringWithFormat:@"%d", (int)tweet.scoreBlendedNormalized];
	
	if (tweet.detailURL.isResolved)
		[self populateResolvedUrlFieldsForOrUrl:tweet.detailURL];
	else {
		[self setDomainLabel:tweet.detailURL.finalURL.host];
        [self updatePageTitle:@"...loading"];
        [self.item setDetailURL:tweet.detailURL resolve:YES];
	}
    
    if (avatarURL) {
        NSURL *url = [NSURL URLWithString:avatarURL];
        __weak ORSFCardTwitterURL *weakSelf = self;
        __weak ORTweet *weakTweet = tweet.tweet;
        
        [[ORCachedEngine sharedInstance] imageAtURL:url size:self.imgTwitterAvatar.frame.size completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
            if (weakSelf.tweet == weakTweet) {
                weakSelf.imgTwitterAvatar.image = image;
            }
        }];
    }
}

- (void)setDomainLabel:(NSString*)domain
{
    if (!domain) {
        self.lblDomain.text = domain;
    } else {
        NSMutableString *mString = [NSMutableString stringWithString:domain];
        [mString replaceOccurrencesOfString:@"www." withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, mString.length)];
        self.lblDomain.text = mString;
    }
}

- (void)populateResolvedUrlFieldsForOrUrl:(ORURL*)url
{
	[self setDomainLabel:url.finalURL.host];
    
    if (url.type == ORURLTypeYoutube && [url.pageTitle isEqualToString:@"(Video)"]) {
        [YouTubeEngine fetchVideoById:url.customData cb:^(NSError *error, NSArray *items) {
            if (items && items.count > 0) {
                ORYouTubeVideo *video = items[0];
                url.pageTitle = video.title;
                url.pageDescription = video.videoDescription;
                url.isResolved = YES;
                [self updatePageTitle:[url.pageTitle gtm_stringByStrippingHTML]];
            }
        }];
    }
    
    if (!url.pageTitle) {
        switch (url.type) {
            case ORURLTypeYoutube: {
                [self updatePageTitle:@"(Video)"];
                break;
            }
            case ORURLTypeImage:
            case ORURLTypeInstagram:
            case ORURLTypeTwitpic:
            case ORURLTypeTwitterMedia:
            case ORURLTypeYfrog: {
                [self updatePageTitle:@"(Image)"];
                break;
            }
            default: {
                [self updatePageTitle:@"(Untitled)"];
                break;
            }
        }
    } else {
        [self updatePageTitle:[url.pageTitle gtm_stringByStrippingHTML]];
    }
}

- (void)updatePageTitle:(NSString *)text
{
    self.lblPageTitle.text = text;
    
    CGRect frame = self.lblPageTitle.frame;
    frame.size.width = self.frame.size.width - 16.0f;
    if (self.imgMain.image) frame.size.width -= (self.imgMain.frame.size.width + 4.0f);
    self.lblPageTitle.frame = frame;
    
    [self.lblPageTitle sizeToFit];
}

- (void)setRemovePosition:(float)position
{
    if (position < 0) position = 0;
    if (position > 100.0f) position = 100.0f;
    
    CGRect frame = self.viewCellContent.frame;
    frame.origin.x = position;
    self.viewCellContent.frame = frame;
}

- (void)finishRemoveDraggingWithSuccess:(BOOL)success
{
    CGRect frame = self.viewCellContent.frame;

    if (!success) {
        frame.origin.x = 0.0f;
    } else {
        frame.origin.x = 100.0f;
    }

    [UIView animateWithDuration:0.2f animations:^{
        self.viewCellContent.frame = frame;
    }];
}

- (IBAction)btnRemove_TouchUpInside:(id)sender
{
    [self finishRemoveDraggingWithSuccess:NO];
    [self.parent removeCurrentItem];
}

- (IBAction)btnRetweet_TouchUpInside:(id)sender {
	[ShareEngine shareURL:self.item.detailURL.originalURL.absoluteString andTitle:self.lblPageTitle.text andImage:self.imgMain.image andHostView:RVC andShareFrom:@"card" viaTwitterScreenName:self.tweet.user.screenName];
	[self finishRemoveDraggingWithSuccess:NO]; // close the card
}

- (IBAction)btnMentionCount_TouchUpInside:(id)sender {
    UIAlertView* alert =
	[[UIAlertView alloc] initWithTitle: @""
							   message: [NSString stringWithFormat:@"%@ retweets of this link", self.lblRetweetCount.text]
							  delegate: self
					 cancelButtonTitle: @"OK"
					 otherButtonTitles: nil];
    [alert show];
}

@end
