//
//  ORTHLViewController.m
//  WhaleHunter
//
//  Created by Rodrigo Sieiro on 25/07/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <Accounts/Accounts.h>
#import "ORTHLViewController.h"
#import "ORModalViewDelegate.h"
#import "ORSFCardTwitterURL.h"
#import "ORSFCardStats.h"
#import "ORWebView.h"
#import "ORProfileViewController.h"
#import "ORAccountPickerViewController.h"
#import "ORCallToAction.h"

@interface ORTHLViewController () <UIAlertViewDelegate, ORModalViewDelegate, UIGestureRecognizerDelegate, ORTHLEngineDelegate>

@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) ORWebView *webView;
@property (nonatomic, strong) ORProfileViewController *profileView;
@property (nonatomic, strong) ORAccountPickerViewController *accountPicker;
@property (nonatomic, strong) NSIndexPath *currentIP;
@property (nonatomic, strong) ORSFCardTwitterURL *currentCell;
@property (nonatomic, assign) CGPoint startPosition;
@property (nonatomic, assign) BOOL isRemoving;
@property (nonatomic, assign) CGFloat lastOffset;
@property (nonatomic, strong) ORCallToAction *c2a;

@property (nonatomic, strong) UIView *blackView;
@property (nonatomic, strong) UIImageView *screenShot;
@property (nonatomic, assign) BOOL hasData;

@end

@implementation ORTHLViewController

static NSString *cardIdentifier = @"ORSFCardTwitterURL";
static NSString *statsIdentifier = @"ORSFCardStats";

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarTapped:) name:kStatusBarTappedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(forceSignOut) name:@"ORUserSignedOut" object:nil];

    TwitterEngine.delegate = self;
	self.viewSquare.layer.cornerRadius = 10.0f;
    
    self.hasRefreshed = NO;
    AppDelegate.thl = [[ORTHLEngine alloc] initWithDelegate:self];
    
    [self.collectionView registerClass:[ORSFCardTwitterURL class] forCellWithReuseIdentifier:cardIdentifier];
    [self.collectionView registerClass:[ORSFCardStats class] forCellWithReuseIdentifier:statsIdentifier];

    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refreshData:) forControlEvents:UIControlEventValueChanged];
    [self.collectionView addSubview:self.refreshControl];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([prefs stringForKey:@"accessToken"] && [prefs stringForKey:@"tokenSecret"]) {
        [TwitterEngine setAccessToken:[prefs stringForKey:@"accessToken"] secret:[prefs stringForKey:@"tokenSecret"]];
        TwitterEngine.userId = [prefs stringForKey:@"userId"];
        TwitterEngine.screenName = [prefs stringForKey:@"screenName"];
        TwitterEngine.userName = [prefs stringForKey:@"userName"];
    }
    
	[LoggingEngine.gAnalytics sendView:@"Home"];

	self.collectionView.contentInset = UIEdgeInsetsMake(self.view.bounds.size.height, 0, 0, 0);
	self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;

	if (TwitterEngine.isAuthenticated) {
		[LoggingEngine addLogItemAtLocation:@"THL" andEvent:@"Loaded" withParams:@{@"account": TwitterEngine.screenName}];
		[self loadTwitterData];
	}
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    if (!TwitterEngine.isAuthenticated) [self showAccountPicker];
}

#pragma mark - Signed-out state

- (void)showAccountPicker
{
	[THLEngine reset];
	self.hasData = NO;

	self.collectionView.contentInset = UIEdgeInsetsMake(self.view.bounds.size.height, 0, 0, 0);
	self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;

	CGRect frame = self.viewHeader.frame;
	frame.origin.y = 0;
	self.viewHeader.frame = frame;

	if (self.accountPicker) {
		[self.accountPicker willMoveToParentViewController:nil];
		[self.accountPicker.view removeFromSuperview];
		[self.accountPicker removeFromParentViewController];
		self.accountPicker = nil;
	}

	self.accountPicker = [[ORAccountPickerViewController alloc] initWithNibName:nil bundle:nil];
	self.accountPicker.delegate = self;
	self.accountPicker.view.frame = CGRectMake(0, 188.0f, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 188.0f);;
	[self addChildViewController:self.accountPicker];

	if (self.profileView) {
		[self.viewContent insertSubview:self.accountPicker.view belowSubview:self.profileView.view];
	} else {
		[self.viewContent addSubview:self.accountPicker.view];
	}

	[self.accountPicker didMoveToParentViewController:self];

	if (self.screenShot) {
		self.screenShot.hidden = YES;
		self.blackView.hidden = YES;
	}

	[self.accountPicker checkDeviceAccounts];

	TwitterEngine.delegate = self.accountPicker;
}

#pragma mark - UICollectionView Data Source / Delegate

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return THLEngine.displayedItems.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(collectionView.frame.size.width, 180.0f);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	ORSFTwitterURL *item = THLEngine.displayedItems[indexPath.row];
    if (!item) NSLog(@"Item is nil, weird things might happen (%@)", indexPath);
    
    if ([item.itemID isEqualToString:@"_stats_"]) {
        ORSFCardStats *cell = (ORSFCardStats *)[collectionView dequeueReusableCellWithReuseIdentifier:statsIdentifier forIndexPath:indexPath];
        if (item) cell.item = item;
        return cell;
    } else {
        ORSFCardTwitterURL *cell = (ORSFCardTwitterURL *)[collectionView dequeueReusableCellWithReuseIdentifier:cardIdentifier forIndexPath:indexPath];
        if (item) cell.item = item;
        cell.parent = self;
        return cell;
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Deselect it first
    [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    if (self.isRemoving) {
        self.isRemoving = NO;
        return;
    }

    ORSFTwitterURL *item = THLEngine.displayedItems[indexPath.row];
    if (item.firstOldItem) return;
	if (!item.detailURL) return;
    
    self.currentIP = indexPath;
    self.currentCell = (ORSFCardTwitterURL *)[collectionView cellForItemAtIndexPath:indexPath];
    
    [self webViewDraggedWithSuccess:YES];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.isRemoving) self.isRemoving = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	CGFloat offset = scrollView.contentOffset.y + scrollView.contentInset.top;
	CGFloat delta = offset - self.lastOffset;

	CGRect frame = self.viewHeader.frame;
	CGRect labelFrame = self.lblTitle.frame;
	CGRect blackLabelFrame = self.lblTitleBlack.frame;
	CGRect btnFrame = self.btnProfile.frame;
	CGFloat maxY = (self.hasData) ? 64.0f - frame.size.height : 0;

	frame.origin.y -= delta;
	if (offset < 64.0f && frame.origin.y < -frame.size.height + (64.0f - offset)) frame.origin.y = -frame.size.height + (64.0f - offset);
	if (frame.origin.y < -(frame.size.height - 20.0f)) frame.origin.y = -(frame.size.height - 20.0f);
	if (frame.origin.y > maxY) frame.origin.y = maxY;

	if (frame.origin.y < 0) {
		if (CGRectGetMaxY(frame) < 64.0f) {
			CGFloat alpha = (CGRectGetMaxY(frame) - 20.0f) / 44.0f;
			self.lblTitle.alpha = alpha;
			self.btnProfile.alpha = alpha;
			self.lblTitleBlack.alpha = 0;
			self.lblHeadline.alpha = 0;
			self.aiLoading.alpha = 0;
			self.lblActivity.alpha = 0;

			labelFrame.origin.y = CGRectGetHeight(frame) - labelFrame.size.height;
			btnFrame.origin.y = CGRectGetHeight(frame) - btnFrame.size.height;
		} else {
			CGFloat alpha = (CGRectGetMaxY(frame) - 64.0f) / (CGRectGetHeight(frame) - 64.0f);
			self.lblTitle.alpha = 1.0f - alpha;
			self.btnProfile.alpha = 1.0f;
			self.lblTitleBlack.alpha = alpha;
			self.lblHeadline.alpha = alpha;
			self.aiLoading.alpha = alpha;
			self.lblActivity.alpha = alpha;

			labelFrame.origin.y = 20.0f - frame.origin.y;
			btnFrame.origin.y = 20.0f - frame.origin.y;
		}
	} else {
		self.lblTitle.alpha = 1.0f;
		self.btnProfile.alpha = 1.0f;
		self.lblTitleBlack.alpha = 1.0f;
		self.lblHeadline.alpha = 1.0f;
		self.aiLoading.alpha = 1.0f;
		self.lblActivity.alpha = 1.0f;

		labelFrame.origin.y = 20.0f;
		btnFrame.origin.y = 20.0f;
	}

//	if (labelFrame.origin.y > 90.0f) {
//		blackLabelFrame.origin.y = labelFrame.origin.y;
//		self.lblTitleBlack.frame = blackLabelFrame;
//	} else if (blackLabelFrame.origin.y < 90.0f) {
//		blackLabelFrame.origin.y = 90.0f;
//		self.lblTitleBlack.frame = blackLabelFrame;
//	}

	self.viewHeader.frame = frame;
	self.lblTitle.frame = labelFrame;
	self.btnProfile.frame = btnFrame;
	self.lastOffset = offset;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	if (!decelerate) [self scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	CGFloat maxY = CGRectGetMaxY(self.viewHeader.frame);

	if (maxY > 20.0f && maxY < 64.0f) {
		if (maxY < 42.0f) {
			CGPoint point = scrollView.contentOffset;
			point.y += (maxY - 20.0f);
			[scrollView setContentOffset:point animated:YES];
		} else {
			CGPoint point = scrollView.contentOffset;
			point.y -= (64.0f - maxY);
			[scrollView setContentOffset:point animated:YES];
		}
	}
}

#pragma mark - Twitter Engine Delegate

- (void)twitterEngine:(ORTwitterEngine *)engine newTweet:(ORTweet *)tweet
{
    NSLog(@"New streaming tweet, this shouldn't happen");
}

- (void)twitterEngine:(ORTwitterEngine *)engine statusUpdate:(NSString *)message
{
    NSLog(@"Twitter: %@", message);
}

- (void)twitterEngine:(ORTwitterEngine *)engine needsToOpenURL:(NSURL *)url
{
}

#pragma mark - Swipe!

- (void)setIsRemoving:(BOOL)isRemoving
{
    _isRemoving = isRemoving;
    
    if (isRemoving) {
        self.swipeLeft.enabled = NO;
        self.swipeRight.enabled = NO;
    } else {
        self.swipeLeft.enabled = YES;
        self.swipeRight.enabled = YES;
        if (self.currentCell) [self.currentCell finishRemoveDraggingWithSuccess:NO];
        self.currentIP = nil;
        self.currentCell = nil;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == self.swipeRight) {
        CGPoint v = [self.swipeRight velocityInView:self.view];
        if (v.x > 0 && fabsf(v.x) > fabsf(v.y)) return YES; // Only right
        return NO;
    } else if (gestureRecognizer == self.swipeLeft) {
        CGPoint v = [self.swipeLeft velocityInView:self.view];
        if (v.x < 0 && fabsf(v.x) > fabsf(v.y)) return YES; // Only left
        return NO;
    }
    
    return YES;
}

- (IBAction)swipeLeftSelector:(UIPanGestureRecognizer *)sender
{
    CGPoint position = [sender locationInView:self.collectionView];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            self.startPosition = position;
            self.currentIP = [self.collectionView indexPathForItemAtPoint:position];
            self.currentCell = (ORSFCardTwitterURL *)[self.collectionView cellForItemAtIndexPath:self.currentIP];
            [self initializeWebview];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            float deltaX = position.x - self.startPosition.x;
            [self setWebViewPosition:deltaX];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            float deltaX = position.x - self.startPosition.x;
            CGPoint v = [sender velocityInView:self.view.superview];
            [self webViewDraggedWithSuccess:(fabsf(deltaX) > (self.view.bounds.size.width / 2) || v.x < -150.0f)];
            self.currentCell = nil;
            self.currentIP = nil;
            break;
        }
        default:
            [self webViewDraggedWithSuccess:NO];
            self.currentCell = nil;
            self.currentIP = nil;
            break;
    }
}

- (IBAction)swipeRightSelector:(UIPanGestureRecognizer *)sender
{
    CGPoint position = [sender locationInView:self.collectionView];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            self.startPosition = position;
            self.currentIP = [self.collectionView indexPathForItemAtPoint:position];
            self.currentCell = (ORSFCardTwitterURL *)[self.collectionView cellForItemAtIndexPath:self.currentIP];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            float deltaX = position.x - self.startPosition.x;
            [self.currentCell setRemovePosition:deltaX];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            float deltaX = position.x - self.startPosition.x;
            CGPoint v = [sender velocityInView:self.view.superview];
            BOOL success = (fabsf(deltaX) > (100.0f / 2) || v.x > 150.0f);
            [self.currentCell finishRemoveDraggingWithSuccess:success];
            self.isRemoving = success;
            break;
        }
        default:
            [self.currentCell finishRemoveDraggingWithSuccess:NO];
            self.isRemoving = NO;
            break;
    }
}

- (IBAction)btnWomCallToAction_TouchUpInside:(id)sender
{
	[ShareEngine shareAppWithHostView:self];
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
    
    self.collectionView.scrollEnabled = NO;
    UIImage *image = [ORUtility imageFromView:self.viewContent];
    
    self.blackView = [[UIView alloc] initWithFrame:self.viewContent.bounds];
    self.blackView.backgroundColor = [UIColor blackColor];
    [self.viewContent addSubview:self.blackView];
    
    self.screenShot = [[UIImageView alloc] initWithFrame:self.viewContent.bounds];
    self.screenShot.image = image;
    [self.viewContent addSubview:self.screenShot];
    
    if (self.webView) [self.viewContent bringSubviewToFront:self.webView.view];
}

- (void)initializeWebview
{
    ORSFTwitterURL *item = (ORSFTwitterURL *)self.currentCell.item;
    
    if (self.webView) {
        if (self.webView.currentItem == item) {
            if (!self.screenShot) [self initializeBackground];
            return;
        }

		[self.webView willMoveToParentViewController:nil];
        [self.webView.view removeFromSuperview];
		[self.webView removeFromParentViewController];

        self.webView = nil;
    }
    
    [self initializeBackground];
    
	CGRect frame = self.viewContent.bounds;
	frame.origin.x = frame.size.width;

    self.webView = [[ORWebView alloc] initWithSFItem:item];
    self.webView.delegate = self;
    self.webView.view.frame = frame;
	[self addChildViewController:self.webView];
    [self.viewContent addSubview:self.webView.view];
	[self.webView didMoveToParentViewController:self];
}

- (void)setWebViewPosition:(float)position
{
    if (position > 0) position = 0;
    
	CGRect frame = self.viewContent.bounds;
	frame.origin.x = frame.size.width + position;
    self.webView.view.frame = frame;
    
    CGFloat factor = 1.0f - (fabsf(position) / frame.size.width);
    [self viewController:self.webView movedWithFactor:factor];
}

- (void)webViewDraggedWithSuccess:(BOOL)success
{
    if (!success) {
        CGRect frame = self.webView.view.frame;
        frame.origin.x = self.viewContent.bounds.size.width;
        
        [UIView animateWithDuration:0.1f animations:^{
            self.webView.view.frame = frame;
            self.screenShot.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
            self.screenShot.alpha = 1.0f;
        } completion:^(BOOL finished) {
            self.collectionView.scrollEnabled = YES;
            [self.screenShot removeFromSuperview];
            [self.blackView removeFromSuperview];
            self.screenShot = nil;
            self.blackView = nil;
        }];
    } else {
        [self initializeWebview];
        self.swipeRight.enabled = NO;
        self.swipeLeft.enabled = NO;
        
        [UIView animateWithDuration:0.3f animations:^{
            self.webView.view.frame = self.viewContent.bounds;
            self.screenShot.transform = CGAffineTransformMakeScale(MINIMUM_SCALE, MINIMUM_SCALE);
            self.screenShot.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [LoggingEngine.gAnalytics sendView:@"Webview"];
        }];
    }
}

#pragma mark - Custom Methods

- (void)removeCurrentItem
{
    if (self.currentCell) {
        self.currentCell = nil;

        if (self.currentIP) {
            [THLEngine removeItemAtIndex:self.currentIP.row];
            [self.collectionView deleteItemsAtIndexPaths:@[self.currentIP]];
        }
    }
    
    self.isRemoving = NO;
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
        self.collectionView.scrollEnabled = YES;
        [self.screenShot removeFromSuperview];
        [self.blackView removeFromSuperview];
        self.screenShot = nil;
        self.blackView = nil;
    }];
}

- (void)viewController:(UIViewController *)viewController dismissedWithSuccess:(BOOL)success
{
    [LoggingEngine.gAnalytics sendView:@"Home"];
    
    self.webView = nil;
    self.profileView = nil;
	self.accountPicker = nil;
    self.swipeLeft.enabled = YES;
    self.swipeRight.enabled = YES;
}

- (void)refreshParent
{
    [self.collectionView reloadData];
}

- (void)loadTwitterData
{
	[self.aiLoading startAnimating];
    [THLEngine start];
}

- (void)refreshData:(id)sender
{
	[self.accountPicker checkDeviceAccounts];
    [THLEngine reload];
}

- (void)forceSignOut
{
    if (!TwitterEngine.isAuthenticated) return;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs removeObjectForKey:@"accessToken"];
    [prefs removeObjectForKey:@"tokenSecret"];
    [prefs removeObjectForKey:@"userId"];
    [prefs removeObjectForKey:@"screenName"];
    [prefs removeObjectForKey:@"userName"];
    [prefs synchronize];
    
    [THLEngine reset];
    [self.collectionView reloadData];
    [TwitterEngine resetOAuthToken];
    
    [self showAccountPicker];
}

- (void)btnProfile_TouchUpInside:(id)sender
{
	if (!TwitterEngine.isAuthenticated) return;

    [self initializeBackground];
    
	CGRect frame = self.viewContent.bounds;
	frame.origin.x = frame.size.width;
    
    self.profileView = [[ORProfileViewController alloc] initWithNibName:nil bundle:nil];
    self.profileView.view.frame = frame;
    self.profileView.delegate = self;
    [self.viewContent addSubview:self.profileView.view];
    
    self.swipeRight.enabled = NO;
    self.swipeLeft.enabled = NO;
    
    [UIView animateWithDuration:0.3f animations:^{
        self.profileView.view.frame = self.viewContent.bounds;
        self.screenShot.transform = CGAffineTransformMakeScale(MINIMUM_SCALE, MINIMUM_SCALE);
        self.screenShot.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [LoggingEngine.gAnalytics sendView:@"Profile"];
    }];
}

- (IBAction)statusBarTapped:(NSNotification *)n
{
	if (!TwitterEngine.isAuthenticated) return;
	[self.collectionView setContentOffset:CGPointMake(0, -64.0f) animated:YES];
}

#pragma mark - ORTHLEngineDelegate

- (void)thlItemsRefreshed:(NSUInteger)count
{
    self.hasRefreshed = YES;
    if (self.refreshControl.isRefreshing) [self.refreshControl endRefreshing];

	if (!self.hasData) {
		self.hasData = YES;

		[UIView animateWithDuration:1.0f animations:^{
			self.collectionView.contentInset = UIEdgeInsetsMake(64.0f, 0, 0, 0);
			self.collectionView.scrollIndicatorInsets = self.collectionView.contentInset;
			[self.collectionView reloadData];
			self.collectionView.contentOffset = CGPointMake(0, -64.0f);
		} completion:^(BOOL finished) {
			[self.aiLoading stopAnimating];
		}];
	} else {
		[self.collectionView reloadData];
	}
}

- (void)thlItemsUpdated:(NSUInteger)count
{
    // No new items, exit early
    if (count == 0) return;
    
    NSUInteger start = THLEngine.displayedItems.count - count;
    NSMutableArray *ips = [NSMutableArray arrayWithCapacity:count];
    
    for (int i = start; i < (start + count); i++) {
        [ips addObject:[NSIndexPath indexPathForItem:i inSection:0]];
    }
    
    [self.collectionView insertItemsAtIndexPaths:ips];
}

- (void)thlRefreshFailed
{
    // Do nothing
}

#pragma mark - CALL TO ACTION

- (void)presentWordOfMouthModal
{
	if (!self.c2a) {
		self.c2a = [[ORCallToAction alloc] initWithNibName:@"ORCallToAction" bundle:nil];
		self.c2a.view.frame = self.viewContent.bounds;
		self.c2a.view.alpha = 0.0f;
		[self.viewContent addSubview:self.c2a.view];
	}
	[UIView animateWithDuration:0.3f animations:^{
		self.c2a.view.alpha = 1.0f;
	} completion:^(BOOL finished) {
		//
	}];
}

@end
