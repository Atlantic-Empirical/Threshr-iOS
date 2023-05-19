//
//  ORTweetsViewController.m
//  Threshr
//
//  Created by Rodrigo Sieiro on 30/07/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import "ORTweetsViewController.h"
#import "ORModalViewDelegate.h"
#import "ORReplyViewController.h"
#import "ORTweetCell.h"

@interface ORTweetsViewController () <ORModalViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSArray *tweets;
@property (nonatomic, strong) ORReplyViewController *replyView;
@property (nonatomic, strong) ORTweetCell *currentCell;
@property (nonatomic, assign) CGPoint startPosition;

@property (nonatomic, strong) UIView *blackView;
@property (nonatomic, strong) UIImageView *screenShot;

@end

@implementation ORTweetsViewController

static NSString *cardIdentifier = @"ORTweetCell";

- (id)initWithTweets:(NSArray *)tweets
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.tweets = tweets;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.collectionView registerClass:[ORTweetCell class] forCellWithReuseIdentifier:cardIdentifier];
}

#pragma mark - UICollectionView Data Source / Delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.tweets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	ORTweet *tweet = self.tweets[indexPath.row];
    ORTweetCell *cell = (ORTweetCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cardIdentifier forIndexPath:indexPath];
    cell.parent = self;
    if (tweet) cell.tweet = tweet;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Deselect it first
    [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
}

#pragma mark - Swipe!

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.swipeRight) {
        CGPoint v = [self.swipeRight velocityInView:self.view];
        if (v.x > 0 && fabsf(v.x) > fabsf(v.y)) return YES; // Only right
        return NO;
    }
    
    return YES;
}

- (IBAction)swipeRightSelector:(UIPanGestureRecognizer *)sender
{
    CGPoint position = [sender locationInView:self.view.superview];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            self.startPosition = position;
            break;
        }
        case UIGestureRecognizerStateChanged: {
            float deltaX = position.x - self.startPosition.x;
            [self setViewPosition:deltaX];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            float deltaX = position.x - self.startPosition.x;
            CGPoint v = [sender velocityInView:self.view.superview];
            [self viewDraggedWithSuccess:(deltaX > (self.view.bounds.size.width / 2) || v.x > 150.0f)];
            break;
        }
        default:
            [self viewDraggedWithSuccess:NO];
            break;
    }
}

- (void)setViewPosition:(float)position
{
    if (position < 0) position = 0;
    
    CGRect frame = self.view.frame;
    frame.origin.x = position;
    self.view.frame = frame;
    
    CGFloat factor = fabsf(position) / frame.size.width;
    [self.delegate viewController:self movedWithFactor:factor];
}

- (void)viewDraggedWithSuccess:(BOOL)success
{
    if (!success) {
        CGRect frame = self.view.frame;
        frame.origin.x = 0;
        
        [UIView animateWithDuration:0.1f animations:^{
            self.view.frame = frame;
        }];
    } else {
        [self.view endEditing:YES];
        CGRect frame = self.view.frame;
        frame.origin.x = self.view.superview.bounds.size.width;

        [self.delegate viewController:self willDismissWithDuration:0.3f];
        
        [UIView animateWithDuration:0.3f animations:^{
            self.view.frame = frame;
        } completion:^(BOOL finished) {
			[self willMoveToParentViewController:nil];
            [self.view removeFromSuperview];
			[self removeFromParentViewController];
            [self.delegate viewController:self dismissedWithSuccess:YES];
        }];
    }
}

#pragma mark - Custom Methods

- (IBAction)btnDone_TouchUpInside:(id)sender
{
    [self viewDraggedWithSuccess:YES];
}

- (void)initializeBackground
{
    if (self.screenShot) {
        [self.screenShot removeFromSuperview];
        self.screenShot = nil;
    }
    
    if (self.blackView) {
        [self.blackView removeFromSuperview];
        self.blackView = nil;
    }
    
    UIImage *image = [ORUtility imageFromView:self.view];
    
    self.blackView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.blackView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.blackView];
    
    self.screenShot = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.screenShot.image = image;
    [self.view addSubview:self.screenShot];
    
    if (self.replyView) [self.view bringSubviewToFront:self.replyView.view];
}

- (void)replyForCell:(ORTweetCell *)cell
{
    self.currentCell = cell;
    
    [self initializeBackground];
    
    self.replyView = [[ORReplyViewController alloc] initWithTweet:self.currentCell.tweet];
    self.replyView.delegate = self;
    
	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
	self.replyView.view.frame = frame;

	[self addChildViewController:self.replyView];
	[self.view addSubview:self.replyView.view];
	[self.replyView didMoveToParentViewController:self];
    self.swipeRight.enabled = NO;
	
	[UIView animateWithDuration:0.3f animations:^{
		self.replyView.view.frame = self.view.bounds;
        self.screenShot.transform = CGAffineTransformMakeScale(MINIMUM_SCALE, MINIMUM_SCALE);
        self.screenShot.alpha = 0.0f;
	} completion:^(BOOL finished) {
        [LoggingEngine.gAnalytics sendView:@"Reply"];
    }];
}

- (void)navigateToURL:(NSURL *)url
{
    if ([self.delegate respondsToSelector:@selector(navigateToURL:)]) [self.delegate navigateToURL:url];
    [self viewDraggedWithSuccess:YES];
}

- (void)viewController:(UIViewController *)viewController movedWithFactor:(CGFloat)factor
{
    self.screenShot.alpha = factor;
    
    CGFloat transformFactor = MINIMUM_SCALE + ((1.0f - MINIMUM_SCALE) * factor);
    CGAffineTransform transform = CGAffineTransformMakeScale(transformFactor, transformFactor);
    self.screenShot.transform = transform;
}

- (void)viewController:(UIViewController *)viewController willDismissWithDuration:(CGFloat)duration
{
    [UIView animateWithDuration:duration animations:^{
        self.screenShot.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
        self.screenShot.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [self.screenShot removeFromSuperview];
        [self.blackView removeFromSuperview];
        self.screenShot = nil;
        self.blackView = nil;
    }];
}

- (void)viewController:(UIViewController *)viewController dismissedWithSuccess:(BOOL)success
{
    self.replyView = nil;
    self.swipeRight.enabled = YES;
    
    if (success) {
        [self.currentCell showStatus:@"replied!" completion:^{
            self.currentCell = nil;
        }];
    }
    
    [LoggingEngine.gAnalytics sendView:@"Who"];
}

@end
