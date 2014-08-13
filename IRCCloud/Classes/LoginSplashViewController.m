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
        _kbSize = CGSizeZero;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.frame = [UIScreen mainScreen].applicationFrame;
    username.background = password.background = host.background = name.background = [[UIImage imageNamed:@"textbg"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14)];
    username.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, username.frame.size.height)];
    username.leftViewMode = UITextFieldViewModeAlways;
    username.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, username.frame.size.height)];
    username.rightViewMode = UITextFieldViewModeAlways;
#ifdef ENTERPRISE
    username.placeholder = @"Email or Username";
#endif
    password.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, password.frame.size.height)];
    password.leftViewMode = UITextFieldViewModeAlways;
    password.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, password.frame.size.height)];
    password.rightViewMode = UITextFieldViewModeAlways;
    host.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, host.frame.size.height)];
    host.leftViewMode = UITextFieldViewModeAlways;
    host.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, host.frame.size.height)];
    host.rightViewMode = UITextFieldViewModeAlways;
    name.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, name.frame.size.height)];
    name.leftViewMode = UITextFieldViewModeAlways;
    name.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, name.frame.size.height)];
    name.rightViewMode = UITextFieldViewModeAlways;
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
    [signup setBackgroundImage:[[UIImage imageNamed:@"sendbg_active"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14)] forState:UIControlStateNormal];
    [signup setBackgroundImage:[[UIImage imageNamed:@"sendbg"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 14, 14, 14)] forState:UIControlStateDisabled];
    [signup setTitleColor:[UIColor selectedBlueColor] forState:UIControlStateNormal];
    [signup setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [signup setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
    signup.titleLabel.shadowOffset = CGSizeMake(0, 1);
    [signup.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:14.0]];
    signup.adjustsImageWhenDisabled = YES;
    signup.adjustsImageWhenHighlighted = NO;
    
#ifdef BRAND_NAME
    [version setText:[NSString stringWithFormat:@"Version %@-%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], @BRAND_NAME]];
#else
    [version setText:[NSString stringWithFormat:@"Version %@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];
#endif
    host.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"host"];
#ifdef ENTERPRISE
    if([host.text isEqualToString:@"api.irccloud.com"] || [host.text isEqualToString:@"www.irccloud.com"])
        host.text = nil;
#else
    host.hidden = YES;
#endif
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
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

    
    NSString *session = [NetworkConnection sharedInstance].session;
    if(session != nil && [session length] > 0) {
#ifndef EXTENSION
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
            [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
#endif
        if(_conn.state != kIRCCloudStateConnected) {
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
                [NetworkConnection sharedInstance].session = [o objectForKey:@"cookie"];
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
    [host resignFirstResponder];
}

-(void)viewDidDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)backlogStarted:(NSNotification *)notification {
#ifdef DEBUG
    NSLog(@"This is a debug build, skipping APNs registration");
#else
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert) categories:nil]];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    }
#endif
    [status setText:@"Loading"];
    activity.hidden = YES;
    progress.progress = 0;
    progress.hidden = NO;
}

-(void)backlogProgress:(NSNotification *)notification {
    [progress setProgress:[notification.object floatValue] animated:YES];
}

-(void)_updateFieldPositions {
    int offset = 0;
    if(name.alpha)
        offset = 1;
    
    int topoffset = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone || UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))?20:280;
    
    name.frame = CGRectMake(32, topoffset, loginView.bounds.size.width - 64, 30);
    username.frame = CGRectMake(32, topoffset + (offset * 38), loginView.bounds.size.width - 64, 30);
    password.frame = CGRectMake(32, topoffset + ((offset + 1) * 38), loginView.bounds.size.width - 64, 30);
    host.frame = CGRectMake(32, topoffset + ((offset + 2) * 38), loginView.bounds.size.width - 64, 30);
#ifdef ENTERPRISE
    offset++;
#endif
    if(name.alpha) {
        signup.frame = CGRectMake(32, topoffset + ((offset + 2) * 38), loginView.bounds.size.width - 64, 30);
    } else {
        if(_kbSize.height && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            login.frame = CGRectMake(32, topoffset + ((offset + 2) * 38), ((loginView.bounds.size.width - 64) / 2) - 2, 30);
            signup.frame = CGRectMake(32 + ((loginView.bounds.size.width - 64) / 2) + 2, topoffset + ((offset + 2) * 38), ((loginView.bounds.size.width - 64) / 2) - 2, 30);
        } else {
            login.frame = CGRectMake(32, topoffset + ((offset + 2) * 38), loginView.bounds.size.width - 64, 30);
            signup.frame = CGRectMake(32, topoffset + ((offset + 3) * 38), loginView.bounds.size.width - 64, 30);
        }
    }
    
    status.frame = CGRectMake(32, topoffset, loginView.bounds.size.width - 64, 21);
    progress.frame = CGRectMake(32, topoffset + 38, loginView.bounds.size.width - 64, 21);
    activity.center = progress.center;
    error.frame = CGRectMake(32, topoffset + 76, loginView.bounds.size.width - 64, 100);
    
    version.frame = CGRectMake(loginView.frame.origin.x, version.frame.origin.y, loginView.frame.size.width, version.frame.size.height);
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.view.frame = [UIScreen mainScreen].applicationFrame;
    if(_kbSize.height) {
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            int offset = 0;
            if(name.alpha)
                offset += 38;
            logo.frame = CGRectMake(124 + (offset / 2), 10, 72 - offset, 72 - offset);
            IRC.frame = CGRectMake(0, logo.frame.origin.y + logo.frame.size.height + 4, 154, 20);
            Cloud.frame = CGRectMake(154, logo.frame.origin.y + logo.frame.size.height + 4, 166, 20);
            loadingView.frame = loginView.frame = CGRectMake(0, 112 - offset, 320, self.view.bounds.size.height - 112 - offset);
        } else {
            if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                logo.frame = CGRectMake(256, 72, 256, 256);
                IRC.frame = CGRectMake(0, 340, 380, 40);
                Cloud.frame = CGRectMake(380, 340, 388, 40);
                loadingView.frame = loginView.frame = CGRectMake(0, 400, 768, self.view.bounds.size.height - 392);
                version.frame = CGRectMake(0, 984, 768, 20);
            } else {
                logo.frame = CGRectMake(72, 226 - _kbSize.height/2, 256, 256);
                IRC.frame = CGRectMake(0, 500 - _kbSize.height/2, 196, 40);
                Cloud.frame = CGRectMake(196, 500 - _kbSize.height/2, 206, 40);
                loadingView.frame = loginView.frame = CGRectMake(400, 0 - _kbSize.height/2, 624, self.view.bounds.size.height + _kbSize.height/2);
                version.frame = CGRectMake(0, 728, 1024, 20);
            }
        }
    } else {
        if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            logo.frame = CGRectMake(96, 24, 128, 128);
            IRC.frame = CGRectMake(0, 165, 154, 20);
            Cloud.frame = CGRectMake(154, 165, 166, 20);
            loadingView.frame = loginView.frame = CGRectMake(0, 200, 320, self.view.bounds.size.height - 200);
        } else {
            if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
                logo.frame = CGRectMake(256, 72, 256, 256);
                IRC.frame = CGRectMake(0, 340, 380, 40);
                Cloud.frame = CGRectMake(380, 340, 388, 40);
                loadingView.frame = loginView.frame = CGRectMake(0, 400, 768, self.view.bounds.size.height - 392);
                version.frame = CGRectMake(0, 984, 768, 20);
            } else {
                logo.frame = CGRectMake(72, 226, 256, 256);
                IRC.frame = CGRectMake(0, 500, 196, 40);
                Cloud.frame = CGRectMake(196, 500, 206, 40);
                loadingView.frame = loginView.frame = CGRectMake(400, 0, 624, self.view.bounds.size.height);
                version.frame = CGRectMake(0, 728, 1024, 20);
            }
        }
    }
    [self _updateFieldPositions];
}

-(void)keyboardWillShow:(NSNotification*)notification {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    _kbSize = [self.view convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:nil].size;
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
    [UIView commitAnimations];
}

-(void)keyboardWillBeHidden:(NSNotification*)notification {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    _kbSize = CGSizeZero;
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
    [UIView commitAnimations];
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)signupButtonPressed:(id)sender {
    if(name.alpha == 0) {
        [UIView beginAnimations:nil context:NULL];
        name.alpha = 1;
        login.alpha = 0;
        [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
        [UIView commitAnimations];
        [name becomeFirstResponder];
        [self textFieldChanged:name];
    } else {
        [self loginButtonPressed:sender];
    }
}

-(IBAction)loginButtonPressed:(id)sender {
    [username resignFirstResponder];
    [password resignFirstResponder];
    [UIView beginAnimations:nil context:nil];
    loginView.alpha = 0;
    loadingView.alpha = 1;
    [UIView commitAnimations];
    if(name.alpha)
        [status setText:@"Creating Account"];
    else
        [status setText:@"Signing in"];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, status.text);
    progress.hidden = YES;
    progress.progress = 0;
    [activity startAnimating];
    activity.hidden = NO;
    error.text = nil;
    error.hidden = YES;
#ifdef ENTERPRISE
    IRCCLOUD_HOST = host.text;
    if([IRCCLOUD_HOST hasPrefix:@"http://"])
        IRCCLOUD_HOST = [IRCCLOUD_HOST substringFromIndex:7];
    if([IRCCLOUD_HOST hasPrefix:@"https://"])
        IRCCLOUD_HOST = [IRCCLOUD_HOST substringFromIndex:8];
    if([IRCCLOUD_HOST hasSuffix:@"/"])
        IRCCLOUD_HOST = [IRCCLOUD_HOST substringToIndex:IRCCLOUD_HOST.length - 1];
#endif
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *result = [[NetworkConnection sharedInstance] requestAuthToken];
        if([[result objectForKey:@"success"] intValue] == 1) {
            if(name.alpha)
                result = [[NetworkConnection sharedInstance] signup:[username text] password:[password text] realname:[name text] token:[result objectForKey:@"token"]];
            else
                result = [[NetworkConnection sharedInstance] login:[username text] password:[password text] token:[result objectForKey:@"token"]];
            if([[result objectForKey:@"success"] intValue] == 1) {
                if([result objectForKey:@"websocket_host"])
                    IRCCLOUD_HOST = [result objectForKey:@"websocket_host"];
                if([result objectForKey:@"websocket_path"])
                    IRCCLOUD_PATH = [result objectForKey:@"websocket_path"];
                [NetworkConnection sharedInstance].session = [result objectForKey:@"session"];
                [[NSUserDefaults standardUserDefaults] setObject:IRCCLOUD_HOST forKey:@"host"];
                [[NSUserDefaults standardUserDefaults] setObject:IRCCLOUD_PATH forKey:@"path"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
#ifdef ENTERPRISE
                    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
                    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
                    [d setObject:IRCCLOUD_HOST forKey:@"host"];
                    [d setObject:IRCCLOUD_PATH forKey:@"path"];
                    [d synchronize];
                }
                [status setText:@"Connecting"];
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Connecting");
                [_conn connect];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIView beginAnimations:nil context:nil];
                    loginView.alpha = 1;
                    loadingView.alpha = 0;
                    [UIView commitAnimations];
                    NSString *message = name.alpha?@"Invalid email address or password. Please try again.":@"Unable to login to IRCCloud.  Please check your username and password, and try again shortly.";
                    if([[result objectForKey:@"message"] isEqualToString:@"auth"]
                       || [[result objectForKey:@"message"] isEqualToString:@"email"]
                       || [[result objectForKey:@"message"] isEqualToString:@"password"]
                       || [[result objectForKey:@"message"] isEqualToString:@"legacy_account"])
                        message = @"Incorrect username or password.  Please try again.";
                    if([[result objectForKey:@"message"] isEqualToString:@"realname"])
                        message = @"Please enter a valid name and try again.";
                    if([[result objectForKey:@"message"] isEqualToString:@"email_exists"])
                        message = @"This email address is already in use, please sign in or try another.";
                    if([[result objectForKey:@"message"] isEqualToString:@"rate_limited"])
                        message = @"Rate limited, please try again in a few minutes.";
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:name.alpha?@"Sign Up Failed":@"Login Failed" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alert show];
                });
            }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView beginAnimations:nil context:nil];
                loginView.alpha = 1;
                loadingView.alpha = 0;
                [UIView commitAnimations];
                NSString *message = @"Unable to communicate with the IRCCloud servers.  Please try again shortly.";
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
            });
        }
    });
}

-(IBAction)textFieldChanged:(id)sender {
    login.enabled = (username.text.length > 0 && password.text.length > 0);
    signup.enabled = (name.alpha == 0) || (username.text.length > 0 && password.text.length > 0 && name.text.length > 0);
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == username)
        [password becomeFirstResponder];
    else
        [self loginButtonPressed:textField];
    return YES;
}

-(NSUInteger)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskPortrait:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

@end
