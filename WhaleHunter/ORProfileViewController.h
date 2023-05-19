//
//  ORBackViewController.h
//  Threshr
//
//  Created by Rodrigo Sieiro on 02/08/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ORModalViewDelegate;

@interface ORProfileViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *lblUsername;
@property (weak, nonatomic) IBOutlet UIPanGestureRecognizer *swipeRight;
@property (nonatomic, weak) id <ORModalViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *btnPortl;
@property (weak, nonatomic) IBOutlet UILabel *lblVersion;

- (IBAction)btnDone_TouchUpInside:(id)sender;
- (IBAction)btnSignOut_TouchUpInside:(id)sender;
- (IBAction)swipeRightSelector:(UIPanGestureRecognizer *)sender;
- (IBAction)btnResetHiding_TouchUpInside:(id)sender;
- (IBAction)btnPortl_TouchUpInside:(id)sender;

@end
