//
//  vcSFWebView.h
//  Orooso
//
//  Created by Thomas Purnell-Fisher on 7/19/12.
//  Copyright (c) 2012 Orooso, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ORSyncFlowCard, ORWebsite;

@protocol ORModalViewDelegate;

@interface ORWebView : UIViewController <UIWebViewDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UIView *viewSpinnerHost;
@property (nonatomic, weak) IBOutlet UIWebView *wvMain;
@property (nonatomic, weak) IBOutlet UIView *viewWebViewParent;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiPageLoading;
@property (nonatomic, weak) IBOutlet UIButton *btnBack;
@property (nonatomic, weak) IBOutlet UIButton *btnDone;
@property (nonatomic, weak) IBOutlet UIView *viewFooter;
@property (nonatomic, weak) IBOutlet UIButton *btnShare;
@property (nonatomic, weak) IBOutlet UIButton *btnWho;
@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *swipeLeft;
@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *swipeRight;
@property (weak, nonatomic) IBOutlet UIView *viewHeader;
@property (weak, nonatomic) IBOutlet UILabel *lblHeader;

@property (nonatomic, weak) id <ORModalViewDelegate> delegate;
@property (nonatomic, strong, readonly) NSString *pageTitle;
@property (strong, nonatomic) ORSFTwitterURL *currentItem;


- (id)initWithSFItem:(ORSFTwitterURL *)item;
- (id)initForOAuthWithURL:(NSURL *)url;

- (IBAction)btnBack_TouchUpInside:(id)sender;
- (IBAction)btnDone_TouchUpInside:(id)sender;
- (IBAction)btnShare_TouchUpInside:(id)sender;
- (IBAction)btnWho_TouchUpInside:(id)sender;
- (IBAction)swipeLeftSelector:(UIPanGestureRecognizer *)sender;
- (IBAction)swipeRightSelector:(UIPanGestureRecognizer *)sender;

@end
