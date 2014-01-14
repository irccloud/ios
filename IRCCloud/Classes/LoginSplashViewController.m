//
//  LoginSplashViewController.m
//
//  Copyright (C) 2013 IRCCloud, Ltd.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.


#import <QuartzCore/QuartzCore.h>
#import "LoginSplashViewController.h"
#import "UIColor+IRCCloud.h"

@implementation LoginSplashViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _conn = [NetworkConnection sharedInstance];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.frame = [UIScreen mainScreen].applicationFrame;
    username.background = password.background = [[UIImage imageNamed:@"textbg"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14)];
    username.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, username.frame.size.height)];
    username.leftViewMode = UITextFieldViewModeAlways;
    username.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, username.frame.size.height)];
    username.rightViewMode = UITextFieldViewModeAlways;
    password.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, password.frame.size.height)];
    password.leftViewMode = UITextFieldViewModeAlways;
    password.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, password.frame.size.height)];
    password.rightViewMode = UITextFieldViewModeAlways;
    [login setBackgroundImage:[[UIImage imageNamed:@"sendbg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14)] forState:UIControlStateNormal];
    [login setBackgroundImage:[[UIImage imageNamed:@"sendbg"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14)] forState:UIControlStateDisabled];
    [login setTitleColor:[UIColor selectedBlueColor] forState:UIControlStateNormal];
    [login setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [login setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    login.titleLabel.shadowOffset = CGSizeMake(0, 1);
    [login.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:14.0]];
    login.adjustsImageWhenDisabled = YES;
    login.adjustsImageWhenHighlighted = NO;
    login.enabled = NO;
    
#ifdef BRAND_NAME
    [version setText:[NSString stringWithFormat:@"Version %@-%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey], BRAND_NAME]];
#else
    [version setText:[NSString stringWithFormat:@"Version %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString*)kCFBundleVersionKey]]];
#endif
}

-(void)flyaway {
    if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        logo.transform = CGAffineTransformMakeTranslation(0, -(logo.frame.origin.y + logo.frame.size.height));
        loadingView.transform = CGAffineTransformMakeTranslation(0, self.view.frame.size.height - loadingView.frame.origin.y);
    } else {
        logo.transform = CGAffineTransformMakeTranslation(-(logo.frame.origin.x + logo.frame.size.width), 0);
        loadingView.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width - loadingView.frame.origin.x, 0);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    activity.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated {
    logo.transform = CGAffineTransformIdentity;
    loadingView.transform = CGAffineTransformIdentity;
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateConnecting:)
                                                 name:kIRCCloudConnectivityNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleEvent:)
                                                 name:kIRCCloudEventNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogStarted:)
                                                 name:kIRCCloudBacklogStartedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backlogProgress:)
                                                 name:kIRCCloudBacklogProgressNotification object:nil];

    NSString *session = [[NSUserDefaults standardUserDefaults] stringForKey:@"session"];
    if(session != nil && [session length] > 0) {
        if(_conn.state == kIRCCloudStateDisconnected) {
            loginView.alpha = 0;
            loadingView.alpha = 1;
            progress.hidden = YES;
            progress.progress = 0;
            [activity startAnimating];
            activity.hidden = NO;
            [status setText:@"Connecting"];
            [_conn connect];
        }
    } else {
        password.text = @"";
        loadingView.alpha = 0;
        loginView.alpha = 1;
    }
}

-(void)viewDidAppear:(BOOL)animated {
    self.view.frame = [UIScreen mainScreen].applicationFrame;
}

-(void)handleEvent:(NSNotification *)notification {
    kIRCEvent event = [[notification.userInfo objectForKey:kIRCCloudEventKey] intValue];
    IRCCloudJSONObject *o = nil;
    
    switch(event) {
        case kIRCEventFailureMsg:
            o = notification.object;
            if([[o objectForKey:@"message"] isEqualToString:@"auth"]) {
                [_conn disconnect];
                [_conn performSelectorOnMainThread:@selector(logout) withObject:nil waitUntilDone:YES];
                [activity stopAnimating];
                loginView.alpha = 1;
                loadingView.alpha = 0;
            } else if([[o objectForKey:@"message"] isEqualToString:@"set_shard"]) {
                [[NSUserDefaults standardUserDefaults] setObject:[o objectForKey:@"cookie"] forKey:@"session"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                progress.hidden = YES;
                progress.progress = 0;
                [activity startAnimating];
                activity.hidden = NO;
                [status setText:@"Connecting"];
                [_conn connect];
            } else if([[o objectForKey:@"message"] isEqualToString:@"temp_unavailable"]) {
                error.text = @"Your account is temporarily unavailable";
                error.hidden = NO;
                CGRect frame = error.frame;
                frame.size.height = [error.text sizeWithFont:error.font constrainedToSize:CGSizeMake(frame.size.width,INT_MAX) lineBreakMode:error.lineBreakMode].height;
                error.frame = frame;
                [_conn disconnect];
                _conn.idleInterval = 30;
                [self updateConnecting:nil];
                [_conn performSelectorOnMainThread:@selector(scheduleIdleTimer) withObject:nil waitUntilDone:NO];
            } else {
                error.text = [o objectForKey:@"message"];
                error.hidden = NO;
                CGRect frame = error.frame;
                frame.size.height = [error.text sizeWithFont:error.font constrainedToSize:CGSizeMake(frame.size.width,INT_MAX) lineBreakMode:error.lineBreakMode].height;
                error.frame = frame;
                [_conn disconnect];
                [_conn fail];
                [self updateConnecting:nil];
                [_conn performSelectorOnMainThread:@selector(scheduleIdleTimer) withObject:nil waitUntilDone:NO];
            }
            break;
        default:
            break;
    }
}

-(void)updateConnecting:(NSNotification *)notification {
    if(_conn.state == kIRCCloudStateConnecting || [_conn reachable] == kIRCCloudUnknown) {
        if(loadingView.alpha > 0)
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Connecting");
        [status setText:@"Connecting"];
        activity.hidden = NO;
        [activity startAnimating];
        progress.progress = 0;
        progress.hidden = YES;
        error.text = nil;
    } else if(_conn.state == kIRCCloudStateDisconnected) {
        if(_conn.reconnectTimestamp > 0) {
            int seconds = (int)(_conn.reconnectTimestamp - [[NSDate date] timeIntervalSince1970]) + 1;
            [status setText:[NSString stringWithFormat:@"Reconnecting in %i second%@", seconds, (seconds == 1)?@"":@"s"]];
            activity.hidden = NO;
            [activity startAnimating];
            progress.progress = 0;
            progress.hidden = YES;
            [self performSelector:@selector(updateConnecting:) withObject:nil afterDelay:1];
        } else {
            if(loadingView.alpha > 0)
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Disconnected");
            if([_conn reachable])
                [status setText:@"Disconnected"];
            else
                [status setText:@"Offline"];
            activity.hidden = YES;
            progress.progress = 0;
            progress.hidden = YES;
        }
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    [username resignFirstResponder];
    [password resignFirstResponder];
}

-(void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)backlogStarted:(NSNotification *)notification {
#ifdef DEBUG
    NSLog(@"This is a debug build, skipping APNs registration");
#else
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
#endif
    [status setText:@"Loading"];
    activity.hidden = YES;
    progress.progress = 0;
    progress.hidden = NO;
}

-(void)backlogProgress:(NSNotification *)notification {
    [progress setProgress:[notification.object floatValue] animated:YES];
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.view.frame = [UIScreen mainScreen].applicationFrame;
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            logo.frame = CGRectMake(92, 36, 138, 138);
            loadingView.frame = loginView.frame = CGRectMake(0, 200, 320, 160);
        } else {
            logo.frame = CGRectMake(26, 76, 138, 138);
            loadingView.frame = CGRectMake(160, 100, 320, 160);
            loginView.frame = CGRectMake(160, 70, 320, 160);
        }
    } else {
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            logo.frame = CGRectMake(249, 118, 276, 276);
            loadingView.frame = loginView.frame = CGRectMake(78, 392, 612, 160);
            version.frame = CGRectMake(0, 984, 768, 20);
        } else {
            logo.frame = CGRectMake(128, 240, 276, 276);
            loadingView.frame = CGRectMake(392, 344, 612, 160);
            loginView.frame = CGRectMake(392, 302, 612, 160);
            version.frame = CGRectMake(0, 728, 1024, 20);
        }
    }
}

-(void)keyboardWillShow:(NSNotification*)notification {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            logo.frame = CGRectMake(112, 16, 96, 96);
            loadingView.frame = loginView.frame = CGRectMake(0, 112, 320, 160);
        } else {
            logo.frame = CGRectMake(52, 24, 96, 96);
            loadingView.frame = loginView.frame = CGRectMake(160, 0, 320, 160);
        }
    } else {
        if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            logo.frame = CGRectMake(128, 246-180, 256, 256);
            loadingView.frame = loginView.frame = CGRectMake(392, 302-180, 612, 144);
        }
    }
    [UIView commitAnimations];
}

-(void)keyboardWillBeHidden:(NSNotification*)notification {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
            logo.frame = CGRectMake(96, 36, 128, 128);
            loadingView.frame = loginView.frame = CGRectMake(0, 200, 320, 160);
        } else {
            logo.frame = CGRectMake(36, 76, 128, 128);
            loadingView.frame = loginView.frame = CGRectMake(160, 70, 320, 160);
        }
    } else {
        if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        } else {
            logo.frame = CGRectMake(128, 246, 256, 256);
            loadingView.frame = CGRectMake(392, 344, 612, 160);
            loginView.frame = CGRectMake(392, 302, 612, 160);
        }
    }
    [UIView commitAnimations];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)loginButtonPressed:(id)sender {
    [username resignFirstResponder];
    [password resignFirstResponder];
    [UIView beginAnimations:nil context:nil];
    loginView.alpha = 0;
    loadingView.alpha = 1;
    [UIView commitAnimations];
    [status setText:@"Signing in"];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Signing in");
    progress.hidden = YES;
    progress.progress = 0;
    [activity startAnimating];
    activity.hidden = NO;
    error.text = nil;
    error.hidden = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *result = [[NetworkConnection sharedInstance] login:[username text] password:[password text]];
        if([[result objectForKey:@"success"] intValue] == 1) {
            [[NSUserDefaults standardUserDefaults] setObject:[result objectForKey:@"session"] forKey:@"session"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [status setText:@"Connecting"];
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Connecting");
            [_conn connect];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView beginAnimations:nil context:nil];
                loginView.alpha = 1;
                loadingView.alpha = 0;
                [UIView commitAnimations];
                NSString *message = @"Unable to login to IRCCloud.  Please check your username and password, and try again shortly.";
                if([[result objectForKey:@"message"] isEqualToString:@"auth"]
                   || [[result objectForKey:@"message"] isEqualToString:@"email"]
                   || [[result objectForKey:@"message"] isEqualToString:@"password"]
                   || [[result objectForKey:@"message"] isEqualToString:@"legacy_account"])
                    message = @"Incorrect username or password.  Please try again.";
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
            });
        }
    });
}

-(IBAction)textFieldChanged:(id)sender {
    login.enabled = (username.text.length > 0 && password.text.length > 0);
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == username)
        [password becomeFirstResponder];
    else
        [self loginButtonPressed:textField];
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

@end
