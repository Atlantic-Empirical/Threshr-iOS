//
//  ORTHLViewController.h
//  WhaleHunter
//
//  Created by Rodrigo Sieiro on 25/07/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ORTHLViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ORTwitterEngineDelegate>

@property (weak, nonatomic) IBOutlet UIView *viewContent;
@property (weak, nonatomic) IBOutlet UIView *viewSquare;
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (weak, nonatomic) IBOutlet UILabel *lblTitleBlack;
@property (weak, nonatomic) IBOutlet UILabel *lblHeadline;
@property (weak, nonatomic) IBOutlet UILabel *lblActivity;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *aiLoading;
@property (nonatomic, weak) IBOutlet UIButton *btnProfile;
@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UIPanGestureRecognizer *swipeLeft;
@property (nonatomic, weak) IBOutlet UIPanGestureRecognizer *swipeRight;
@property (weak, nonatomic) IBOutlet UIButton *btnWomCallToAction;
@property (weak, nonatomic) IBOutlet UIView *viewHeader;

- (IBAction)btnProfile_TouchUpInside:(id)sender;
- (IBAction)swipeLeftSelector:(UIPanGestureRecognizer *)sender;
- (IBAction)swipeRightSelector:(UIPanGestureRecognizer *)sender;
- (IBAction)btnWomCallToAction_TouchUpInside:(id)sender;

@property (nonatomic, assign) BOOL hasRefreshed;

- (void)refreshData:(id)sender;
- (void)removeCurrentItem;
- (void)forceSignOut;
- (void)loadTwitterData;

@end
