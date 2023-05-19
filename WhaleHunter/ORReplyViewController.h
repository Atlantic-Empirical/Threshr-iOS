//
//  ORReplyViewController.h
//  Threshr
//
//  Created by Rodrigo Sieiro on 30/07/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ORModalViewDelegate;

@interface ORReplyViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIView *viewBG;
@property (nonatomic, weak) IBOutlet UITextView *txtReply;
@property (nonatomic, weak) IBOutlet UIButton *btnSend;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiSending;
@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *swipeRight;
@property (weak) id <ORModalViewDelegate> delegate;

- (id)initWithTweet:(ORTweet *)tweet;
- (IBAction)btnDone_TouchUpInside:(id)sender;
- (IBAction)btnSend_TouchUpInside:(id)sender;
- (IBAction)swipeRightSelector:(UIPanGestureRecognizer *)sender;

@end
