//
//  vcSFWebView.m
//  Orooso
//
//  Created by Thomas Purnell-Fisher on 7/19/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ORWebView.h"
#import "ORWebsite.h"
#import "ORSyncFlowCard.h"
#import	"ORSFTwitterURL.h"
#import "STTweetLabel.h"
#import "ORTweetsViewController.h"
#import "NSString+ORString.h"
#import "ORModalViewDelegate.h"
#import "GTMNSString+HTML.h"
#import "ORActivityProvider.h"

@interface ORWebView () <ORModalViewDelegate, UIGestureRecognizerDelegate>

@property (assign, nonatomic) int hotlinkIndex;
@property (strong, nonatomic) ORTweetsViewController *tweetsView;
@property (nonatomic, assign) CGPoint startPosition;
@property (nonatomic, strong) NSURL *oAuthURL;
@property (nonatomic, assign) CGFloat lastOffset;

@property (nonatomic, strong) UIView *blackView;
@property (nonatomic, strong) UIImageView *screenShot;
@property (nonatomic, assign) BOOL isLoadingCurrentItem;

@end

@implementation ORWebView

//  LIFE CYCLE
//================================================================================================================
#pragma mark - LIFE CYCLE

- (void)dealloc
{
    [self unregisterForNotifications];
    
    self.wvMain.delegate = nil;
    [self.wvMain stopLoading];
	self.wvMain = nil;
}

- (id)initWithSFItem:(ORSFTwitterURL *)item
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.currentItem = item;
    
    return self;
}

- (id)initForOAuthWithURL:(NSURL *)url
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.oAuthURL = url;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self registerForNotifications];
    
    self.btnBack.enabled = NO;
    self.btnBack.hidden = YES;
	
	self.viewSpinnerHost.layer.cornerRadius = 5.0f;
    
    if (self.currentItem) [self loadCurrentItem];
    if (self.oAuthURL) [self loadOAuthURL];
	
	self.wvMain.scrollView.delegate = self;
	self.wvMain.scrollView.contentInset = UIEdgeInsetsMake(self.viewHeader.bounds.size.height, 0, 0, 0);
	self.wvMain.scrollView.scrollIndicatorInsets = self.wvMain.scrollView.contentInset;
}

//  GETTERS
//================================================================================================================
#pragma mark - GETTERS

- (NSString*)pageTitle
{
	NSString *str = [self.wvMain stringByEvaluatingJavaScriptFromString:@"document.title"];
	if ([str containsString:@"Instagram"]) return @"Instagram";
	return str;
}

//  NAVIGATION
//================================================================================================================
#pragma mark - NAVIGATION

- (void)loadCurrentItem
{
    NSString *targetUrl = self.currentItem.detailURL.finalURL.absoluteString;
    
    if (!targetUrl || [targetUrl isEqualToString:@"about:blank"]) {
        return;
    }

    [self.aiPageLoading startAnimating];
	[UIView animateWithDuration:0.3f animations:^{
		self.viewSpinnerHost.alpha = 1.0f;
	}];
	
	if ([targetUrl containsString:@"www.nytimes"]) {
		targetUrl = [targetUrl stringByReplacingOccurrencesOfString:@"www.nytimes" withString:@"mobile.nytimes"];
	}
    
	// WV will choke if there's no scheme
	if (![targetUrl hasPrefix:@"http"]) targetUrl = [NSString stringWithFormat:@"http://%@", targetUrl];
	
    NSURL *url = [NSURL URLWithString:targetUrl];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    
    self.isLoadingCurrentItem = YES;
    [self.wvMain loadRequest:requestObj];
}

- (void)loadOAuthURL
{
    self.swipeLeft.enabled = NO;
    self.swipeRight.enabled = NO;
    self.viewFooter.hidden = YES;
    
    CGRect frame = self.viewWebViewParent.frame;
    frame.size.height += self.viewFooter.frame.size.height;
    self.viewWebViewParent.frame = frame;
    
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:self.oAuthURL];
    [self.wvMain loadRequest:requestObj];
}

- (IBAction)btnBack_TouchUpInside:(id)sender
{
	if (self.wvMain.canGoBack) [self.wvMain goBack];
}

//  WEBVIEW DELEGATE
//================================================================================================================
#pragma mark - WEBVIEW DELEGATE

- (void)handleYTError:(NSUInteger)errorCode
{
    NSLog(@"YouTube Error: %d", errorCode);
    
    if (errorCode == 101 || errorCode == 150) {
        // Restricted Video
        NSURL *url = self.wvMain.request.mainDocumentURL;
        NSString *videoID = url.pathComponents.lastObject;
        
        if (videoID) {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@", videoID]];
            NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
            [self.wvMain loadRequest:requestObj];
        }
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL *url = request.URL;
    
    if (self.oAuthURL) {
        NSString *urlString = [NSString stringWithFormat:@"%@://%@%@", request.URL.scheme, request.URL.host, request.URL.path];
        
        if ([urlString isEqualToString:TwitterEngine.callbackURL]) {
            if ([url.query hasPrefix:@"denied"]) {
                if (TwitterEngine) [TwitterEngine cancelAuthentication];
            } else {
                if (TwitterEngine) [TwitterEngine resumeAuthenticationFlowWithURL:url];
            }

            CGRect frame = self.view.frame;
            frame.origin.x = frame.size.width;
            
            [self.delegate viewController:self willDismissWithDuration:0.3f];
            
            [UIView animateWithDuration:0.3f animations:^{
                self.view.frame = frame;
            } completion:^(BOOL finished) {
				[self willMoveToParentViewController:nil];
                [self.view removeFromSuperview];
				[self removeFromParentViewController];
                [self.delegate viewController:self dismissedWithSuccess:YES];
            }];
            
            return NO;
        }
    }
    
    // Handle YT javascript callbacks
    if ([url.scheme isEqualToString:@"ytplayer"]) {
        NSUInteger code = [[url.path stringByReplacingOccurrencesOfString:@"/" withString:@""] integerValue];
        
        if ([url.host isEqualToString:@"player_error"]) {
            [self handleYTError:code];
        }
        
        return NO;
    }
    
	return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (self.isLoadingCurrentItem) {
        self.isLoadingCurrentItem = NO;
        
        if (!self.currentItem.detailURL.isResolved && !self.currentItem.detailURL.isResolving) {
            self.currentItem.detailURL.pageTitle = self.pageTitle;
            self.currentItem.detailURL.isResolved = YES;
            
            [[ORApiEngine sharedInstance] submitURL:self.currentItem.detailURL cb:^(NSError *error, BOOL result) {
                if (error) NSLog(@"Error: %@", error);
                if (result) NSLog(@"URL submitted to server");
            }];
            
            if ([self.delegate respondsToSelector:@selector(refreshParent)]) {
                [self.delegate refreshParent];
            }
        }
    }
    
	[UIView animateWithDuration:0.3f animations:^{
		self.viewSpinnerHost.alpha = 0.0f;
        self.wvMain.alpha = 1.0f;
	} completion:^(BOOL finished) {
        [self.aiPageLoading stopAnimating];
    }];
    
    self.btnBack.enabled = (webView.canGoBack);
	self.btnBack.hidden = !webView.canGoBack;
    
    NSURL *url = webView.request.mainDocumentURL;
	
	self.lblHeader.text = [url.host stringByReplacingOccurrencesOfString:@"www." withString:@""];
	
    if ([url.host hasSuffix:@"youtube.com"]) {
        NSString *ytAPI = @"\
        function onYouTubePlayerReady(vph5) \
        { \
        if (alreadyCalled) return; \
        alreadyCalled = true; \
        vph5.addEventListener(\"onError\", \"ytError\"); \
        } \
        function objcCallback(url) \
        { \
        var iframe = document.createElement(\"IFRAME\"); \
        iframe.setAttribute(\"src\", url); \
        document.documentElement.appendChild(iframe); \
        iframe.parentNode.removeChild(iframe); \
        iframe = null; \
        } \
        \
        function ytError(errorCode) \
        { \
        objcCallback(\"ytplayer://player_error/\" + errorCode); \
        } \
        \
        var alreadyCalled = false; \
        ";
        [webView stringByEvaluatingJavaScriptFromString:ytAPI];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    // Blank page error, should be ignored
    if (error.code == -999) return;

	[UIView animateWithDuration:0.3f animations:^{
		self.viewSpinnerHost.alpha = 0.0f;
        self.wvMain.alpha = 1.0f;
	} completion:^(BOOL finished) {
        [self.aiPageLoading stopAnimating];
    }];
    
    DLog(@"Error (UIWebView): %@", [error localizedDescription]);
}

#pragma mark - WV Scrolling

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	CGFloat offset = scrollView.contentOffset.y + scrollView.contentInset.top;
	CGFloat delta = offset - self.lastOffset;

	CGRect frame = self.viewHeader.frame;
	CGFloat maxY = 0;

	if (delta > 0) {
		frame.origin.y -= delta;
	} else {
		frame.origin.y -= (delta / 2.0f);
	}

	if (offset < 64.0f && frame.origin.y < -frame.size.height + (64.0f - offset)) frame.origin.y = -frame.size.height + (64.0f - offset);
	if (frame.origin.y < -(frame.size.height - 20.0f)) frame.origin.y = -(frame.size.height - 20.0f);
	if (frame.origin.y > maxY) frame.origin.y = maxY;

	if (frame.origin.y < 0) {
		CGFloat alpha = (CGRectGetMaxY(frame) - 20.0f) / 44.0f;
		self.lblHeader.alpha = alpha;
		self.btnDone.alpha = alpha;
	} else {
		self.lblHeader.alpha = 1.0f;
		self.btnDone.alpha = 1.0f;
	}

	self.viewHeader.frame = frame;
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

#pragma mark - Swipe!

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
        CGPoint v = [self.swipeRight velocityInView:self.view];
        if (v.x < 0 && fabsf(v.x) > fabsf(v.y)) return YES; // Only left
        return NO;
    }
    
    return YES;
}

- (IBAction)swipeLeftSelector:(UIPanGestureRecognizer *)sender
{
    CGPoint position = [sender locationInView:self.view];
    
    switch (sender.state) {
        case UIGestureRecognizerStateBegan: {
            self.startPosition = position;
            [self initializeTweetsview];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            float deltaX = position.x - self.startPosition.x;
            [self setTweetsViewPosition:deltaX];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            float deltaX = position.x - self.startPosition.x;
            CGPoint v = [sender velocityInView:self.view.superview];
            [self tweetsViewDraggedWithSuccess:(fabsf(deltaX) > (self.view.bounds.size.width / 2) || v.x < -150.0f)];
            break;
        }
        default:
            [self tweetsViewDraggedWithSuccess:NO];
            break;
    }
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
            [self.delegate viewController:self dismissedWithSuccess:NO];
        }];
    }
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
    
    if (self.tweetsView) [self.view bringSubviewToFront:self.tweetsView.view];
}

- (void)initializeTweetsview
{
    if (!self.screenShot) [self initializeBackground];
    if (self.tweetsView) return;
    
	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
    
    self.tweetsView = [[ORTweetsViewController alloc] initWithTweets:[self.currentItem.tweets array]];
    self.tweetsView.delegate = self;
    self.tweetsView.view.frame = frame;
	[self addChildViewController:self.tweetsView];
    [self.view addSubview:self.tweetsView.view];
	[self.tweetsView didMoveToParentViewController:self];
}

- (void)setTweetsViewPosition:(float)position
{
    if (position > 0) position = 0;
    
	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width + position;
    
    self.tweetsView.view.frame = frame;
    
    CGFloat factor = 1.0f - (fabsf(position) / frame.size.width);
    [self viewController:self.tweetsView movedWithFactor:factor];
}

- (void)tweetsViewDraggedWithSuccess:(BOOL)success
{
    if (!success) {
        CGRect frame = self.tweetsView.view.frame;
        frame.origin.x = self.view.bounds.size.width;
        
        [UIView animateWithDuration:0.1f animations:^{
            self.tweetsView.view.frame = frame;
            self.screenShot.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
            self.screenShot.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [self.screenShot removeFromSuperview];
            [self.blackView removeFromSuperview];
            self.screenShot = nil;
            self.blackView = nil;
        }];
    } else {
        [self initializeTweetsview];
        self.swipeRight.enabled = NO;
        self.swipeLeft.enabled = NO;
        
        [UIView animateWithDuration:0.3f animations:^{
            self.tweetsView.view.frame = self.view.bounds;
            self.screenShot.transform = CGAffineTransformMakeScale(MINIMUM_SCALE, MINIMUM_SCALE);
            self.screenShot.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [LoggingEngine.gAnalytics sendView:@"Who"];
        }];
    }
}

- (IBAction)btnDone_TouchUpInside:(id)sender
{
    [self viewDraggedWithSuccess:YES];
}

- (IBAction)btnWho_TouchUpInside:(id)sender
{
    [self tweetsViewDraggedWithSuccess:YES];
}

- (IBAction)btnShare_TouchUpInside:(id)sender
{
    NSString *currentURL = (self.wvMain.canGoBack) ? self.wvMain.request.mainDocumentURL.absoluteString : self.currentItem.detailURL.finalURL.absoluteString;
    NSString *pageTitle = (self.wvMain.canGoBack || !self.currentItem.detailURL.pageTitle) ? self.pageTitle : self.currentItem.detailURL.pageTitle;
    if ([pageTitle isEqualToString:@""]) pageTitle = nil;

    if (!self.wvMain.canGoBack && self.currentItem.imageURL) {
        [[ORCachedEngine sharedInstance] imageAtURL:self.currentItem.imageURL completion:^(NSError *error, MKNetworkOperation *op, UIImage *image, BOOL cached) {
			[ShareEngine shareURL:currentURL andTitle:[pageTitle gtm_stringByStrippingHTML] andImage:image andHostView:self andShareFrom:@"webview" viaTwitterScreenName:self.currentItem.tweet.user.screenName];
            [LoggingEngine.gAnalytics sendView:@"Share"];
        }];
    } else {
		[ShareEngine shareURL:currentURL andTitle:[pageTitle gtm_stringByStrippingHTML] andImage:nil andHostView:self andShareFrom:@"webview" viaTwitterScreenName:self.currentItem.tweet.user.screenName];
        [LoggingEngine.gAnalytics sendView:@"Share"];
    }
}

- (void)navigateToURL:(NSURL *)url
{
    [self.aiPageLoading startAnimating];
	[UIView animateWithDuration:0.3f animations:^{
		self.viewSpinnerHost.alpha = 1.0f;
	}];
    
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.wvMain loadRequest:requestObj];
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
    self.tweetsView = nil;
    self.swipeLeft.enabled = YES;
    self.swipeRight.enabled = YES;
    
    [LoggingEngine.gAnalytics sendView:@"Webview"];
}

- (void)fullscreenStarted:(NSNotification *)notification
{
    [AppDelegate unlockOrientation];
}

- (void)fullscreenFinished:(NSNotification *)notification
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [AppDelegate forcePortrait];
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullscreenStarted:) name:@"UIMoviePlayerControllerDidEnterFullscreenNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullscreenFinished:) name:@"UIMoviePlayerControllerDidExitFullscreenNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarTapped:) name:kStatusBarTappedNotification object:nil];
}

- (void)unregisterForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)statusBarTapped:(NSNotification *)n
{
	[self.wvMain.scrollView setContentOffset:CGPointMake(0, -64.0f) animated:YES];
}

@end
