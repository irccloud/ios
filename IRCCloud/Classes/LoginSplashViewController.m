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
#import "AppDelegate.h"
#import "OnePasswordExtension.h"
#import "UIDevice+UIDevice_iPhone6Hax.h"

@implementation LoginSplashViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _kbSize = CGSizeZero;
    }
    return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return ![touch.view isKindOfClass:[UIControl class]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
    tap.delegate = self;
    tap.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tap];
    
    UISwipeGestureRecognizer *swipe =[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard:)];
    swipe.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipe];
    
    UIFont *sourceSansPro = [UIFont fontWithName:@"SourceSansPro-Regular" size:38];
    IRC.font = sourceSansPro;
    [IRC sizeToFit];
    Cloud.font = sourceSansPro;
    [Cloud sizeToFit];
#ifdef ENTERPRISE
    Cloud.textColor = IRC.textColor;
    IRC.textColor = [UIColor whiteColor];
#endif
    
    sourceSansPro = [UIFont fontWithName:@"SourceSansPro-Regular" size:16];
    enterpriseHint.font = sourceSansPro;
    
    for(UILabel *l in signupHint.subviews) {
        l.font = sourceSansPro;
        [l sizeToFit];
        sourceSansPro = [UIFont fontWithName:@"SourceSansPro-Regular" size:18];
    }

    sourceSansPro = [UIFont fontWithName:@"SourceSansPro-Regular" size:16];
    for(UILabel *l in loginHint.subviews) {
        l.font = sourceSansPro;
        [l sizeToFit];
        sourceSansPro = [UIFont fontWithName:@"SourceSansPro-Regular" size:18];
    }
    
    ((UILabel *)(forgotPasswordLogin.subviews.firstObject)).font = sourceSansPro;
    ((UILabel *)(forgotPasswordSignup.subviews.firstObject)).font = sourceSansPro;
    sourceSansPro = [UIFont fontWithName:@"SourceSansPro-Regular" size:15];
    ((UILabel *)(notAProblem.subviews.firstObject)).font = sourceSansPro;
    sourceSansPro = [UIFont fontWithName:@"SourceSansPro-LightIt" size:15];
    ((UILabel *)(notAProblem.subviews.lastObject)).font = sourceSansPro;
    sourceSansPro = [UIFont fontWithName:@"SourceSansPro-Regular" size:13];
    enterEmailAddressHint.font = sourceSansPro;
    
    sourceSansPro = [UIFont fontWithName:@"SourceSansPro-Regular" size:14];
    for(UILabel *l in forgotPasswordHint.subviews) {
        l.font = sourceSansPro;
        [l sizeToFit];
    }

    for(UILabel *l in TOSHint.subviews) {
        l.font = sourceSansPro;
        [l sizeToFit];
    }

    for(UILabel *l in enterpriseLearnMore.subviews) {
        l.font = sourceSansPro;
        [l sizeToFit];
    }
    
    sourceSansPro = [UIFont fontWithName:@"SourceSansPro-LightIt" size:13];
    hostHint.font = sourceSansPro;
    
    sourceSansPro = [UIFont fontWithName:@"SourceSansPro-Regular" size:16];
    
    self.view.frame = [UIScreen mainScreen].applicationFrame;
    username.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, username.frame.size.height)];
    username.leftViewMode = UITextFieldViewModeAlways;
    username.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, username.frame.size.height)];
    username.rightViewMode = UITextFieldViewModeAlways;
    username.font = sourceSansPro;
#ifdef ENTERPRISE
    username.placeholder = @"Email or Username";
#endif
    password.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, password.frame.size.height)];
    password.leftViewMode = UITextFieldViewModeAlways;
    password.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, password.frame.size.height)];
    password.rightViewMode = UITextFieldViewModeAlways;
    password.font = sourceSansPro;
    host.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, host.frame.size.height)];
    host.leftViewMode = UITextFieldViewModeAlways;
    host.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, host.frame.size.height)];
    host.rightViewMode = UITextFieldViewModeAlways;
    host.font = sourceSansPro;
    name.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, name.frame.size.height)];
    name.leftViewMode = UITextFieldViewModeAlways;
    name.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, name.frame.size.height)];
    name.rightViewMode = UITextFieldViewModeAlways;
    name.font = sourceSansPro;
    
    sourceSansPro = [UIFont fontWithName:@"SourceSansPro-Regular" size:17];
    login.titleLabel.font = sourceSansPro;
    login.enabled = NO;
    signup.titleLabel.font = sourceSansPro;
    signup.enabled = NO;
    next.titleLabel.font = sourceSansPro;
    next.enabled = NO;
    sendAccessLink.titleLabel.font = sourceSansPro;
    sendAccessLink.enabled = NO;
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

-(void)hideLoginView {
    loginView.alpha = 0;
    loadingView.alpha = 1;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    password.text = @"";
    loadingView.alpha = 0;
    loginView.alpha = 1;
    if(sendAccessLink.alpha) {
        [self forgotPasswordHintPressed:nil];
    } else if(username.text.length && !name.text.length) {
        [self loginHintPressed:nil];
    } else {
        [self signupHintPressed:nil];
    }
#ifdef ENTERPRISE
    host.alpha = 1;
    username.alpha = 0;
    password.alpha = 0;
    name.alpha = 0;
    enterpriseHint.alpha = 1;
    loginHint.alpha = 0;
    signupHint.alpha = 0;
    login.alpha = 0;
    signup.alpha = 0;
    next.alpha = 1;
    TOSHint.alpha = 0;
    forgotPasswordHint.alpha = 0;
    enterpriseLearnMore.alpha = 1;
    hostHint.alpha = 1;
#endif
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
    if(_accessLink && IRCCLOUD_HOST.length) {
        _gotCredentialsFromPasswordManager = YES;
        [self _loginWithAccessLink];
#ifndef ENTERPRISE
    } else if ([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
        [self performSelector:@selector(_promptForSWC) withObject:nil afterDelay:0.1];
#endif
    }
}

-(void)_promptForSWC {
    if(username.text.length == 0 && !_gotCredentialsFromPasswordManager && !_accessLink) {
        loginView.alpha = 0;
        SecRequestSharedWebCredential(NULL, NULL, ^(CFArrayRef credentials, CFErrorRef error) {
            if (error != NULL) {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    loginView.alpha = 1;
                }];
                NSLog(@"Unable to request shared web credentials: %@", error);
                return;
            }
            
            if (CFArrayGetCount(credentials) > 0) {
                _gotCredentialsFromPasswordManager = YES;
                NSDictionary *credentialsDict = CFArrayGetValueAtIndex(credentials, 0);
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [username setText:[credentialsDict objectForKey:(__bridge id)(kSecAttrAccount)]];
                    [password setText:[credentialsDict objectForKey:(__bridge id)(kSecSharedPassword)]];
                    [self loginHintPressed:nil];
                    [self loginButtonPressed:nil];
                }];
            } else {
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    loginView.alpha = 1;
                }];
            }
        });
    }
}

-(void)_loginWithAccessLink {
    if([_accessLink.scheme hasPrefix:@"irccloud"] && [_accessLink.host isEqualToString:@"chat"] && [_accessLink.path isEqualToString:@"/access-link"])
                _accessLink = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@%@?%@&format=json", IRCCLOUD_HOST, _accessLink.host, _accessLink.path, _accessLink.query]];

    loginView.alpha = 0;
    loadingView.alpha = 1;
    [status setText:@"Signing in"];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, status.text);
    [activity startAnimating];
    activity.hidden = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *result = [[NetworkConnection sharedInstance] login:_accessLink];
        _accessLink = nil;
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
            loginHint.alpha = 0;
            signupHint.alpha = 0;
            enterpriseHint.alpha = 0;
            forgotPasswordLogin.alpha = 0;
            forgotPasswordSignup.alpha = 0;
            [((AppDelegate *)([UIApplication sharedApplication].delegate)) showMainView:YES];
#ifndef ENTERPRISE
            [Answers logLoginWithMethod:@"access-link" success:@YES customAttributes:nil];
#endif
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView beginAnimations:nil context:nil];
                loginView.alpha = 1;
                loadingView.alpha = 0;
                [UIView commitAnimations];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"Invalid access link" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
            });
#ifndef ENTERPRISE
            [Answers logLoginWithMethod:@"access-link" success:@NO customAttributes:nil];
#endif
        }
    });
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [username resignFirstResponder];
    [password resignFirstResponder];
    [host resignFirstResponder];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)_updateFieldPositions {
    int offset = 0;
    float left = (loginView.bounds.size.width - 288) / 2;
    if(name.alpha)
        offset = 1;
    
    if(name.alpha > 0)
        username.background = [UIImage imageNamed:@"login_mid_input"];
    else if(sendAccessLink.alpha > 0)
        username.background = [UIImage imageNamed:@"login_only_input"];
    else
        username.background = [UIImage imageNamed:@"login_top_input"];
    
    if(sendAccessLink.alpha) {
        username.frame = CGRectMake(left, 16 + 26, 288, 39);
    } else {
        username.frame = CGRectMake(left, 16 + (offset * 39), 288, 39);
    }

    name.frame = CGRectMake(left, 16, 288, 39);
    host.frame = CGRectMake(left, 16, 288, 39);
    password.frame = CGRectMake(left, 16 + ((offset + 1) * 39), 288, 38);
    OnePassword.frame = CGRectMake(password.frame.origin.x + password.frame.size.width - 48, password.frame.origin.y, 48, password.frame.size.height);
    hostHint.frame = CGRectMake(left, 16 + 39, 288, 32);
    next.frame = CGRectMake(left, 16 + 39 + 32, 288, 40);
    login.frame = signup.frame = CGRectMake(left, 16 + ((offset + 2) * 39) + 15, 288, 40);
    status.frame = CGRectMake(left + 16, 16, loginView.bounds.size.width - left*2 - 32, 21);
    activity.center = status.center;
    CGRect frame = activity.frame;
    frame.origin.y += 24;
    activity.frame = frame;
    sendAccessLink.frame = CGRectMake(left, 16 + 81, 288, 40);
    enterEmailAddressHint.frame = CGRectMake(left, 16 + 80 + 50, 288, 40);
    
    OnePassword.hidden = (login.alpha != 1 && signup.alpha != 1) || ![[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
    
    float w = 0.0f;
    for(UIView *v in notAProblem.subviews) {
        [v sizeToFit];
        v.frame = CGRectMake(w, 0, v.bounds.size.width, 20);
        w += v.bounds.size.width + 2;
    }
    w -= 2;
    notAProblem.frame = CGRectMake(left, 16 - 5, w, 20);
    
    w = 0.0f;
    for(UIView *v in forgotPasswordHint.subviews) {
        v.frame = CGRectMake(w, 0, v.bounds.size.width, 32);
        w += v.bounds.size.width + 2;
    }
    w -= 2;
    forgotPasswordHint.frame = CGRectMake(loginView.bounds.size.width / 2.0f - w / 2.0f, login.frame.origin.y + login.frame.size.height + 2, w, 32);
    
    w = 0.0f;
    for(UIView *v in TOSHint.subviews) {
        v.frame = CGRectMake(w, 0, v.bounds.size.width, 32);
        w += v.bounds.size.width + 2;
    }
    w -= 2;
    TOSHint.frame = CGRectMake(loginView.bounds.size.width / 2.0f - w / 2.0f, login.frame.origin.y + login.frame.size.height + 2, w, 32);
    
    w = 0.0f;
    for(UIView *v in enterpriseLearnMore.subviews) {
        v.frame = CGRectMake(w, 0, v.bounds.size.width, 32);
        w += v.bounds.size.width + 2;
    }
    w -= 2;
    enterpriseLearnMore.frame = CGRectMake(loginView.bounds.size.width / 2.0f - w / 2.0f, next.frame.origin.y + next.frame.size.height + 2, w, 32);
}

-(UIImageView *)logo {
    return logo;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.view.frame = [UIScreen mainScreen].applicationFrame;
    float width = self.view.frame.size.width;
    float height = self.view.frame.size.height;
    if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation) && [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 8) {
        width = self.view.frame.size.height;
        height = self.view.frame.size.width;
    }
    
    if(_kbSize.height && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.view.window.backgroundColor = [UIColor colorWithRed:68.0/255.0 green:128.0/255.0 blue:250.0/255.0 alpha:1];
        loadingView.frame = loginView.frame = CGRectMake(0, 0, width, self.view.bounds.size.height);
    } else {
        self.view.window.backgroundColor = [UIColor colorWithRed:11.0/255.0 green:46.0/255.0 blue:96.0/255.0 alpha:1];
        loginView.frame = CGRectMake(0, 119, width, height - 119);
        loadingView.frame = CGRectMake(0, 78, width, height - 78);
        version.frame = CGRectMake(0, height - 20 - _kbSize.height, width, 20);
    }

    logo.frame = CGRectMake(width / 2 - 112, 15, 48, 48);
    IRC.frame = CGRectMake(logo.frame.origin.x + 48 + 14, 15, IRC.bounds.size.width, 48);
    Cloud.frame = CGRectMake(IRC.frame.origin.x + IRC.bounds.size.width, 15, Cloud.bounds.size.width, 48);
    float w = 0.0f;
    for(UIView *v in signupHint.subviews) {
        v.frame = CGRectMake(w, 0, v.bounds.size.width, 32);
        w += v.bounds.size.width + 8;
    }
    w -= 8;
    signupHint.frame = CGRectMake(width / 2.0f - w / 2.0f, 70, w, 32);
    
    w = 0.0f;
    for(UIView *v in loginHint.subviews) {
        v.frame = CGRectMake(w, 0, v.bounds.size.width, 32);
        w += v.bounds.size.width + 8;
    }
    w -= 8;
    loginHint.frame = CGRectMake(width / 2.0f - w / 2.0f, 70, w, 32);

    enterpriseHint.frame = CGRectMake(0, 70, width, 32);
    
    if(signupHint.enabled) {
        forgotPasswordLogin.frame = CGRectMake(logo.frame.origin.x + 17, 70, 65, 32);
        forgotPasswordSignup.frame = CGRectMake(logo.frame.origin.x + 141, 70, 65, 32);
    } else {
        forgotPasswordLogin.center = CGPointMake(width / 2, forgotPasswordLogin.center.y);
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
    [self loginButtonPressed:sender];
}

-(IBAction)loginHintPressed:(id)sender {
    if(sender)
        [UIView beginAnimations:nil context:NULL];
    name.alpha = 0;
    login.alpha = 1;
    password.alpha = 1;
    signup.alpha = 0;
    loginHint.alpha = 0;
    if(signupHint.enabled)
        signupHint.alpha = 1;
    else
        enterpriseHint.alpha = 1;
    forgotPasswordHint.alpha = 1;
    TOSHint.alpha = 0;
    forgotPasswordLogin.alpha = 0;
    forgotPasswordSignup.alpha = 0;
    notAProblem.alpha = 0;
    sendAccessLink.alpha = 0;
    enterEmailAddressHint.alpha = 0;
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
    if(sender)
        [UIView commitAnimations];
    [self textFieldChanged:name];
}

-(IBAction)signupHintPressed:(id)sender {
    if(sender)
        [UIView beginAnimations:nil context:NULL];
    name.alpha = 1;
    password.alpha = 1;
    login.alpha = 0;
    signup.alpha = 1;
    loginHint.alpha = 1;
    signupHint.alpha = 0;
    forgotPasswordHint.alpha = 0;
    TOSHint.alpha = 1;
    forgotPasswordLogin.alpha = 0;
    forgotPasswordSignup.alpha = 0;
    notAProblem.alpha = 0;
    sendAccessLink.alpha = 0;
    enterEmailAddressHint.alpha = 0;
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
    if(sender)
        [UIView commitAnimations];
    [self textFieldChanged:username];
}

-(IBAction)forgotPasswordHintPressed:(id)sender {
    if(sender)
        [UIView beginAnimations:nil context:NULL];
    login.alpha = 0;
    password.alpha = 0;
    signupHint.alpha = 0;
    forgotPasswordHint.alpha = 0;
    enterpriseHint.alpha = 0;
    
    forgotPasswordLogin.alpha = 1;
    if(signupHint.enabled)
        forgotPasswordSignup.alpha = 1;
    notAProblem.alpha = 1;
    sendAccessLink.alpha = 1;
    enterEmailAddressHint.alpha = 1;
    if(sender)
        [UIView commitAnimations];
    [self _updateFieldPositions];
}

-(IBAction)sendAccessLinkButtonPressed:(id)sender {
    [username resignFirstResponder];
    [UIView beginAnimations:nil context:nil];
    loginView.alpha = 0;
    loadingView.alpha = 1;
    [UIView commitAnimations];
    [status setText:@"Requesting Access Link"];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, status.text);
    [activity startAnimating];
    activity.hidden = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *result = [[NetworkConnection sharedInstance] requestAuthToken];
        if([[result objectForKey:@"success"] intValue] == 1) {
            result = [[NetworkConnection sharedInstance] requestPassword:[username text] token:[result objectForKey:@"token"]];
            if([[result objectForKey:@"success"] intValue] == 1) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIView beginAnimations:nil context:nil];
                    loginView.alpha = 1;
                    loadingView.alpha = 0;
                    [UIView commitAnimations];
                    [activity stopAnimating];
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Sent" message:@"We've sent you an access link.  Check your email and follow the instructions to sign in." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alert show];
                    [self loginHintPressed:nil];
                });
                return;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView beginAnimations:nil context:nil];
            loginView.alpha = 1;
            loadingView.alpha = 0;
            [UIView commitAnimations];
            [activity stopAnimating];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Request Failed" message:@"Unable to request an access link.  Please try again later." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        });
    });
}

-(IBAction)onePasswordButtonPressed:(id)sender {
    _gotCredentialsFromPasswordManager = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(login.alpha) {
#ifdef ENTERPRISE
            NSString *url = [NSString stringWithFormat:@"https://%@", host.text];
#else
            NSString *url = @"https://www.irccloud.com";
#endif
            [[OnePasswordExtension sharedExtension] findLoginForURLString:url forViewController:self sender:sender completion:^(NSDictionary *loginDict, NSError *error) {
                if (!loginDict) {
                    if (error.code != AppExtensionErrorCodeCancelledByUser) {
                        NSLog(@"Error invoking 1Password App Extension for find login: %@", error);
                    }
                    return;
                }
                
                loginView.alpha = 0;
                if([loginDict[AppExtensionUsernameKey] length])
                    username.text = loginDict[AppExtensionUsernameKey];
                password.text = loginDict[AppExtensionPasswordKey];
                enterpriseHint.alpha = 0;
                host.alpha = 0;
                hostHint.alpha = 0;
                next.alpha = 0;
                enterpriseLearnMore.alpha = 0;
                username.alpha = 1;
                [self loginHintPressed:nil];
                [self loginButtonPressed:nil];
            }];
        } else {
#ifdef ENTERPRISE
            NSString *url = [NSString stringWithFormat:@"https://%@", host.text];
#else
            NSString *url = @"https://www.irccloud.com";
#endif
            NSDictionary *newLoginDetails = @{
                                              AppExtensionTitleKey: @"IRCCloud",
                                              AppExtensionUsernameKey: username.text ? : @"",
                                              AppExtensionPasswordKey: password.text ? : @"",
                                              AppExtensionSectionTitleKey: @"IRCCloud",
                                              AppExtensionFieldsKey: @{
                                                      @"Name" : name.text ? : @""
                                                      }
                                              };
            
            [[OnePasswordExtension sharedExtension] storeLoginForURLString:url loginDetails:newLoginDetails passwordGenerationOptions:nil forViewController:self sender:sender completion:^(NSDictionary *loginDict, NSError *error) {
                
                if (!loginDict) {
                    if (error.code != AppExtensionErrorCodeCancelledByUser) {
                        NSLog(@"Failed to use 1Password App Extension to save a new Login: %@", error);
                    }
                    return;
                }
                if([loginDict[AppExtensionReturnedFieldsKey][@"Name"] length])
                    name.text = loginDict[AppExtensionReturnedFieldsKey][@"Name"];
                if([loginDict[AppExtensionUsernameKey] length])
                    username.text = loginDict[AppExtensionUsernameKey];
                password.text = loginDict[AppExtensionPasswordKey] ? : @"";
                
                enterpriseHint.alpha = 0;
                host.alpha = 0;
                hostHint.alpha = 0;
                next.alpha = 0;
                enterpriseLearnMore.alpha = 0;
                username.alpha = 1;
                [self signupHintPressed:nil];
            }];
        }
    });
}

-(IBAction)TOSHintPressed:(id)sender {
#ifndef EXTENSION
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.irccloud.com/terms"]];
#endif
}

-(void)_stripIRCCloudHost {
    if([IRCCLOUD_HOST hasPrefix:@"http://"])
        IRCCLOUD_HOST = [IRCCLOUD_HOST substringFromIndex:7];
    if([IRCCLOUD_HOST hasPrefix:@"https://"])
        IRCCLOUD_HOST = [IRCCLOUD_HOST substringFromIndex:8];
    if([IRCCLOUD_HOST hasSuffix:@"/"])
        IRCCLOUD_HOST = [IRCCLOUD_HOST substringToIndex:IRCCLOUD_HOST.length - 1];
}

-(IBAction)nextButtonPressed:(id)sender {
    IRCCLOUD_HOST = host.text;
    [self _stripIRCCloudHost];
    
    status.text = @"Connecting";
    [activity startAnimating];
    
    [host resignFirstResponder];
    [UIView beginAnimations:nil context:nil];
    loadingView.alpha = 1;
    loginView.alpha = 0;
    [UIView commitAnimations];
    
    activity.hidden = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *result = [[NetworkConnection sharedInstance] requestConfiguration];
        if(result) {
            if([[result objectForKey:@"enterprise"] isKindOfClass:[NSDictionary class]])
                enterpriseHint.text = [[result objectForKey:@"enterprise"] objectForKey:@"fullname"];
            if(![[result objectForKey:@"auth_mechanism"] isEqualToString:@"internal"])
                signupHint.enabled = NO;
        } else {
            IRCCLOUD_HOST = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Failed" message:@"Please check your host and try again shortly, or contact your system administrator for assistance."  delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(_accessLink && IRCCLOUD_HOST.length) {
                [self _loginWithAccessLink];
            } else {
                if(IRCCLOUD_HOST.length) {
                    enterpriseHint.alpha = 0;
                    host.alpha = 0;
                    hostHint.alpha = 0;
                    next.alpha = 0;
                    enterpriseLearnMore.alpha = 0;
                    
                    username.alpha = 1;
                    password.alpha = 1;
                    if(signupHint.enabled)
                        signupHint.alpha = 1;
                    else
                        enterpriseHint.alpha = 1;
                    login.alpha = 1;
                    forgotPasswordHint.alpha = 1;
                    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
                }
                [UIView beginAnimations:nil context:nil];
                loginView.alpha = 1;
                loadingView.alpha = 0;
                [UIView commitAnimations];
            }
        });
    });
}

-(IBAction)enterpriseLearnMorePressed:(id)sender {
    if(![[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"irccloud://"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.apple.com/app/irccloud/id672699103"]];
}

-(IBAction)hideKeyboard:(id)sender {
    [self.view endEditing:YES];
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
    [activity startAnimating];
    activity.hidden = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#ifndef ENTERPRISE
        IRCCLOUD_HOST = @"www.irccloud.com";
#endif
        NSDictionary *result = [[NetworkConnection sharedInstance] requestConfiguration];
        IRCCLOUD_HOST = [result objectForKey:@"api_host"];
        [self _stripIRCCloudHost];
        
        result = [[NetworkConnection sharedInstance] requestAuthToken];
        if([[result objectForKey:@"success"] intValue] == 1) {
            if(name.alpha)
                result = [[NetworkConnection sharedInstance] signup:[username text] password:[password text] realname:[name text] token:[result objectForKey:@"token"] impression:_impression];
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
#ifndef ENTERPRISE
                if(name.alpha) {
                    [Answers logSignUpWithMethod:@"email" success:@YES customAttributes:nil];
                } else {
                    [Answers logLoginWithMethod:@"email" success:@YES customAttributes:nil];
                }
                if(!_gotCredentialsFromPasswordManager && [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
                    SecAddSharedWebCredential((CFStringRef)@"www.irccloud.com", (__bridge CFStringRef)(username.text), (__bridge CFStringRef)(password.text), ^(CFErrorRef error) {
                        if (error != NULL) {
                            NSLog(@"Unable to save shared credentials: %@", error);
                            return;
                        }
                    });
                }
#endif
                loginHint.alpha = 0;
                signupHint.alpha = 0;
                enterpriseHint.alpha = 0;
                forgotPasswordLogin.alpha = 0;
                forgotPasswordSignup.alpha = 0;
                [((AppDelegate *)([UIApplication sharedApplication].delegate)) showMainView:YES];
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
                    if([[result objectForKey:@"message"] isEqualToString:@"password_error"])
                        message = @"Invalid password, please try again.";
                    if([[result objectForKey:@"message"] isEqualToString:@"banned"] || [[result objectForKey:@"message"] isEqualToString:@"ip_banned"])
                        message = @"Signup server unavailable, please try again later.";
                    if([[result objectForKey:@"message"] isEqualToString:@"bad_email"])
                        message = @"No signups allowed from that domain.";
                    if([[result objectForKey:@"message"] isEqualToString:@"tor_blocked"])
                        message = @"No signups allowed from TOR exit nodes";
                    if([[result objectForKey:@"message"] isEqualToString:@"signup_ip_blocked"])
                        message = @"Your IP address has been blacklisted.";
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:name.alpha?@"Sign Up Failed":@"Login Failed" message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    [alert show];
                });
#ifndef ENTERPRISE
                if(name.alpha) {
                    [Answers logSignUpWithMethod:@"email" success:@NO customAttributes:[result objectForKey:@"message"]?@{@"Failure": [result objectForKey:@"message"]}:nil];
                } else {
                    [Answers logLoginWithMethod:@"email" success:@NO customAttributes:[result objectForKey:@"message"]?@{@"Failure": [result objectForKey:@"message"]}:nil];
                }
#endif
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
    next.enabled = (host.text.length > 0);
    sendAccessLink.enabled = (username.text.length > 0);
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    if(textField == username)
        [password becomeFirstResponder];
    else
        [self loginButtonPressed:textField];
    return YES;
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskPortrait:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return orientation == UIInterfaceOrientationPortrait || [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPhone;
}

@end
