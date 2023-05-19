//
//  ORTweetsViewController.h
//  Threshr
//
//  Created by Rodrigo Sieiro on 30/07/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ORModalViewDelegate;
@class ORTweetCell;

@interface ORTweetsViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *btnDone;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *swipeRight;
@property (weak) id <ORModalViewDelegate> delegate;

- (id)initWithTweets:(NSArray *)tweets;
- (IBAction)btnDone_TouchUpInside:(id)sender;
- (IBAction)swipeRightSelector:(UIPanGestureRecognizer *)sender;
- (void)replyForCell:(ORTweetCell *)cell;
- (void)navigateToURL:(NSURL *)url;

@end
