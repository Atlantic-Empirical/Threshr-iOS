//
//  ORAccountPickerViewController.m
//  Threshr
//
//  Created by Thomas Purnell-Fisher on 8/11/13.
//  Copyright (c) 2013 Orooso. All rights reserved.
//

#import "ORAccountPickerViewController.h"
#import "ORWebView.h"
#import "ORModalViewDelegate.h"
#import <Accounts/Accounts.h>
#import "ORTHLViewController.h"

@interface ORAccountPickerViewController () <ORModalViewDelegate>

@property (nonatomic, strong) NSArray *accounts;
@property (nonatomic, strong) ORWebView *webView;
@property (nonatomic, assign) BOOL isAuthenticating;

@end

@implementation ORAccountPickerViewController

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
	
	self.isAuthenticating = NO;
	self.tblAccountList.separatorStyle = UITableViewCellSeparatorStyleNone;

	[self checkDeviceAccounts];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self checkDeviceAccounts];
}

- (void)close
{
	[UIView animateWithDuration:0.25f animations:^{
		self.view.alpha = 0;
	} completion:^(BOOL finished) {
		[self willMoveToParentViewController:nil];
		[self.view removeFromSuperview];
		[self removeFromParentViewController];
		[self.delegate viewController:self dismissedWithSuccess:YES];
	}];
}

#pragma mark - Table View Delegate

- (int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.accounts.count + 1;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *MyIdentifier = @"MyIdentifier";
	
	// Try to retrieve from the table view a now-unused cell with the given identifier.
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	
	// If no cell is available, create a new one using the given identifier.
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier];
	}
    
    if (indexPath.row >= self.accounts.count) {
        cell.textLabel.text = @"Pair Other Account";
    } else {
        ACAccount *account = self.accounts[indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"@%@", account.username];
    }

	cell.backgroundColor = [UIColor clearColor];
	cell.textLabel.textColor = [UIColor colorWithRed:56.0f/255.0f green:185.0f/255.0f blue:235.0f/255.0f alpha:1.0f];
	cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24.0f];
	   
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (self.isAuthenticating) return;
    
    if (indexPath.row >= self.accounts.count) {
        [self signInWithOAuthDialog];
    } else {
        ACAccount *account = self.accounts[indexPath.row];
        [self signInWithTwitterAccount:account];
    }
}

#pragma mark - Custom Methods

- (void)checkDeviceAccounts
{
	[self.aiLoading startAnimating];
	self.lblNoAccounts.alpha = 1.0f;
	self.lblNoAccounts.text = @"Loading device accounts...";
	self.aiLoading.alpha = 1.0f;
	self.tblAccountList.alpha = 0;
	self.lblTitle.alpha = 0;

    // Try to get the device accounts
	self.accounts = nil;
    [TwitterEngine existingAccountsWithCompletion:^(NSError *error, NSArray *items) {
		self.accounts = items;

		self.lblNoAccounts.alpha = 0;
		self.tblAccountList.alpha = 1.0f;
		self.lblTitle.alpha = 1.0f;
		self.aiLoading.alpha = 0;
		[self.aiLoading stopAnimating];

		[self.tblAccountList reloadData];
    }];
}

- (void)signInWithOAuthDialog
{
    self.isAuthenticating = YES;

	[self.aiLoading startAnimating];
	self.lblNoAccounts.alpha = 1.0f;
	self.lblNoAccounts.text = @"Fetching Twitter tokens...";
	self.aiLoading.alpha = 1.0f;
	self.tblAccountList.alpha = 0;
	self.lblTitle.alpha = 0;

    // Start Twitter authentication
    [TwitterEngine authenticateWithCompletion:^(NSError *error) {
        if (error) {
            NSLog(@"Error: %@", error);
            [self authFailedWithError:@"Twitter authentication was canceled or failed."];
        } else {
            // Save this account to the device
            ACAccountStore *accountStore = [[ACAccountStore alloc] init];
            ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
            ACAccount *account = [[ACAccount alloc] initWithAccountType:accountType];
            account.username = TwitterEngine.screenName;
            account.credential = [[ACAccountCredential alloc] initWithOAuthToken:TwitterEngine.token tokenSecret:TwitterEngine.tokenSecret];
            
            [accountStore saveAccount:account withCompletionHandler:^(BOOL success, NSError *error) {
                if (error) NSLog(@"Error: %@", error);
                if (success) NSLog(@"Account saved to iOS Device");
            }];
            
            [self twitterSignedInWithSource:@"OAuth"];
        }
    }];
}

- (void)authFailedWithError:(NSString *)error
{
	self.isAuthenticating = NO;
    self.lblNoAccounts.text = error;
	self.lblNoAccounts.alpha = 1.0f;
	self.aiLoading.alpha = 0;
	self.lblTitle.alpha = 0;
	self.tblAccountList.alpha = 0;
	[self.aiLoading stopAnimating];
}

- (void)twitterSignedInWithSource:(NSString *)source
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setObject:TwitterEngine.token forKey:@"accessToken"];
    [prefs setObject:TwitterEngine.tokenSecret forKey:@"tokenSecret"];
    [prefs setObject:TwitterEngine.userId forKey:@"userId"];
    [prefs setObject:TwitterEngine.screenName forKey:@"screenName"];
    [prefs setObject:TwitterEngine.userName forKey:@"userName"];
    [prefs synchronize];

    [LoggingEngine addLogItemAtLocation:@"THL" andEvent:@"AccountPaired" withParams:@{@"account": TwitterEngine.screenName, @"source": source}];
    NSLog(@"User is signed in (Twitter): %@ (%@)", TwitterEngine.userName, TwitterEngine.screenName);
    
	TwitterEngine.delegate = RVC;
    [RVC loadTwitterData];
    
    self.isAuthenticating = NO;
	[self close];
}

- (void)signInWithTwitterAccount:(ACAccount *)account
{
    self.isAuthenticating = YES;

	[self.aiLoading startAnimating];
	self.lblNoAccounts.alpha = 1.0f;
	self.lblNoAccounts.text = @"Fetching Twitter tokens...";
	self.aiLoading.alpha = 1.0f;
	self.tblAccountList.alpha = 0;
	self.lblTitle.alpha = 0;

    [TwitterEngine reverseAuthWithAccount:account completion:^(NSError *error) {
        if (error) {
            NSLog(@"Error (Twitter): %@", [error localizedDescription]);
			[self authFailedWithError:@"Unable to use the Twitter account paired with this device. Try re-pairing Twitter via system settings or select 'Pair Other Account'."];
        } else {
            [self twitterSignedInWithSource:@"iOS"];
        }
    }];
}

- (IBAction)btnOtherTwitterAccount_TouchUpInside:(id)sender
{
	[self signInWithOAuthDialog];
}

- (IBAction)btnRetry_TouchUpInside:(id)sender
{
	[self checkDeviceAccounts];
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
    if (self.webView) {
		[self.webView willMoveToParentViewController:nil];
        [self.webView.view removeFromSuperview];
		[self.webView removeFromParentViewController];
        self.webView = nil;
    }
    
	CGRect frame = self.parentViewController.view.bounds;
	frame.origin.x = frame.size.width;
    
    self.webView = [[ORWebView alloc] initForOAuthWithURL:url];
    self.webView.delegate = self;
    self.webView.view.frame = frame;

	[self.parentViewController addChildViewController:self.webView];
    [self.parentViewController.view addSubview:self.webView.view];
	[self.webView didMoveToParentViewController:self.parentViewController];
    
    frame.origin.x = 0.0f;
    [UIView animateWithDuration:0.3f animations:^{
        self.webView.view.frame = frame;
    } completion:^(BOOL finished) {
        [LoggingEngine.gAnalytics sendView:@"OAuth Dialog"];
    }];
}

#pragma mark - Modal View Delegate

- (void)viewController:(UIViewController *)viewController dismissedWithSuccess:(BOOL)success
{
    if (viewController == self.webView && self.isAuthenticating && !success) {
        NSLog(@"Authentication canceled");
        [self authFailedWithError:@"Twitter authentication was canceled or failed."];
    }
    
    self.webView = nil;
}

- (void)viewController:(UIViewController *)viewController movedWithFactor:(CGFloat)factor
{
	//
}

- (void)viewController:(UIViewController *)viewController willDismissWithDuration:(CGFloat)duration
{
	//
}

@end
