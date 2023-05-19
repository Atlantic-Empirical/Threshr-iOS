//
//  ORBackViewController.m
//  Threshr
//
//  Created by Rodrigo Sieiro on 02/08/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import "ORProfileViewController.h"
#import "ORModalViewDelegate.h"
#import "ORTHLViewController.h"

@interface ORProfileViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, assign) CGPoint startPosition;

@end

@implementation ORProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateLabels];
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
            [self.delegate viewController:self dismissedWithSuccess:success];
        }];
    }
}

#pragma mark - Custom Methods

- (void)updateLabels
{
    NSUInteger size = [ORCachedEngine sharedInstance].cacheSize;
    NSString *cacheSize;
    if (size >= 1024 * 1024) {
        cacheSize = [NSString stringWithFormat:@"%d MB", (int)(size / (1024 * 1024))];
    } else if (size >= 1024) {
        cacheSize = [NSString stringWithFormat:@"%d KB", (int)(size / 1024)];
    } else {
        cacheSize = [NSString stringWithFormat:@"%d bytes", size];
    }
    
    self.lblUsername.text = [NSString stringWithFormat:@"Signed in as @%@", TwitterEngine.screenName];
	
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"]; // example: 1.0.0
	NSNumber *buildNumber = [infoDict objectForKey:@"CFBundleVersion"]; // example: 42
	self.lblVersion.text = [NSString stringWithFormat:@"v%@.%@", appVersion, buildNumber];
	
}

- (void)btnDone_TouchUpInside:(id)sender
{
    [self viewDraggedWithSuccess:YES];
}

- (void)btnSignOut_TouchUpInside:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ORUserSignedOut" object:nil];
    [self viewDraggedWithSuccess:YES];
}

- (IBAction)btnResetHiding_TouchUpInside:(id)sender {
	[THLEngine unhideAll];
	[((ORTHLViewController*)RVC) refreshData:self];
    UIAlertView* alert =
	[[UIAlertView alloc] initWithTitle: @""
							   message: @"recently hidden articles have been unhidden"
							  delegate: self
					 cancelButtonTitle: @"OK"
					 otherButtonTitles: nil];
    [alert show];
}

- (IBAction)btnPortl_TouchUpInside:(id)sender {
	[[UIApplication sharedApplication] openURL: [NSURL URLWithString:@"http://itunes.com/app/portl"]];
}

@end
