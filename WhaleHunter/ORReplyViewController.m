//
//  ORReplyViewController.m
//  Threshr
//
//  Created by Rodrigo Sieiro on 30/07/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import "ORReplyViewController.h"
#import "ORModalViewDelegate.h"

@interface ORReplyViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) ORTweet *tweet;
@property (nonatomic, assign) BOOL keyboardIsVisible;
@property (nonatomic, assign) CGRect preKeyboardFrame;
@property (nonatomic, assign) CGPoint startPosition;

@end

@implementation ORReplyViewController

- (id)initWithTweet:(ORTweet *)tweet
{
    self = [super initWithNibName:nil bundle:nil];
    if (!self) return nil;
    
    self.tweet = tweet;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self registerForNotifications];
    
    if (self.tweet.isRetweet) {
        self.txtReply.text = [NSString stringWithFormat:@"@%@ @%@ ", self.tweet.user.screenName, self.tweet.retweetUser.screenName];
    } else {
        self.txtReply.text = [NSString stringWithFormat:@"@%@ ", self.tweet.user.screenName];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.txtReply becomeFirstResponder];
}

- (void)dismissWithSuccess:(BOOL)success
{
	[self.view endEditing:YES];

    [self.delegate viewController:self willDismissWithDuration:0.3f];
	[UIView animateWithDuration:0.3f animations:^{
		CGRect frame = self.view.frame;
		frame.origin.x = self.view.superview.bounds.size.width;
		self.view.frame = frame;
	} completion:^(BOOL finished) {
		[self willMoveToParentViewController:nil];
		[self.view removeFromSuperview];
        [self deregisterForNotifications];
		[self removeFromParentViewController];
        [self.delegate viewController:self dismissedWithSuccess:success];
	}];
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
        [self dismissWithSuccess:NO];
    }
}

- (IBAction)btnDone_TouchUpInside:(id)sender
{
	[self dismissWithSuccess:NO];
}

- (IBAction)btnSend_TouchUpInside:(id)sender
{
    self.btnSend.hidden = YES;
    [self.aiSending startAnimating];
    
    __weak ORReplyViewController *weakSelf = self;
    
    [TwitterEngine postTweet:self.txtReply.text inReplyTo:self.tweet.tweetID completion:^(NSError *error) {
        if (error) NSLog(@"Error: %@", error);
        
        weakSelf.btnSend.hidden = NO;
        [weakSelf.aiSending stopAnimating];
        [weakSelf dismissWithSuccess:YES];
    }];
}

- (void)keyboardWillShow:(NSNotification *)notify
{
	if (self.keyboardIsVisible) return;
	self.keyboardIsVisible = YES;
	NSDictionary* keyboardInfo = [notify userInfo];
	NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
	CGRect keyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    CGRect frame = self.viewBG.frame;
    frame.size.height -= keyboardFrame.size.height;
    
	[UIView animateWithDuration:[animationDuration floatValue] delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
		self.viewBG.frame = frame;
	} completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notify
{
	if (!self.keyboardIsVisible) return;
	self.keyboardIsVisible = NO;

	NSDictionary* keyboardInfo = [notify userInfo];
	NSNumber *animationDuration = [keyboardInfo valueForKey:UIKeyboardAnimationDurationUserInfoKey];
	CGRect keyboardFrame = [[keyboardInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    CGRect frame = self.viewBG.frame;
    frame.size.height += keyboardFrame.size.height;
    
	[UIView animateWithDuration:[animationDuration floatValue] delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
		self.viewBG.frame = frame;
	} completion:nil];
}

- (void) registerForNotifications
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) deregisterForNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
