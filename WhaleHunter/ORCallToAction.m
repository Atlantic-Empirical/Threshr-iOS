//
//  ORCallToAction.m
//  Threshr
//
//  Created by Thomas Purnell-Fisher on 8/15/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import "ORCallToAction.h"

@interface ORCallToAction ()

@end

@implementation ORCallToAction

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnShowLove_TouchUpInside:(id)sender {
	[ShareEngine shareAppWithHostView:self];
	[self close];
}

- (IBAction)btnNoLove_TouchUpInside:(id)sender {
	[self close];
}

- (IBAction)btnInfo_TouchUpInside:(id)sender {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
													message:@"You can choose to tell one person or everyone.\n\nUse email, Facebook, Twitter -- whatever way you want!"
												   delegate:nil
										  cancelButtonTitle:@"OK"
										  otherButtonTitles:nil];
	[alert show];
}

- (void)close
{
	[UIView animateWithDuration:0.3f animations:^{
		self.view.alpha = 0.0f;
	} completion:^(BOOL finished) {
		//
	}];
}

@end
