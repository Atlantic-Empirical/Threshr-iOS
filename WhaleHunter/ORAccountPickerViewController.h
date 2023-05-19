//
//  ORAccountPickerViewController.h
//  Threshr
//
//  Created by Thomas Purnell-Fisher on 8/11/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ORModalViewDelegate;

@interface ORAccountPickerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, ORTwitterEngineDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tblAccountList;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *aiLoading;
@property (nonatomic, weak) IBOutlet UILabel *lblTitle;
@property (nonatomic, weak) IBOutlet UILabel *lblNoAccounts;
@property (nonatomic, weak) IBOutlet UIButton *btnRetry;
@property (nonatomic, weak) id <ORModalViewDelegate> delegate;

- (IBAction)btnOtherTwitterAccount_TouchUpInside:(id)sender;
- (IBAction)btnRetry_TouchUpInside:(id)sender;

- (void)checkDeviceAccounts;

@end
