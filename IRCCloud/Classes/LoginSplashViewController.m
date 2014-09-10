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

@implementation LoginSplashViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _conn = [NetworkConnection sharedInstance];
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
    
    UIFont *lato = [UIFont fontWithName:@"Lato" size:38];
    IRC.font = lato;
    [IRC sizeToFit];
    Cloud.font = lato;
    [Cloud sizeToFit];
#ifdef ENTERPRISE
    Cloud.textColor = IRC.textColor;
    IRC.textColor = [UIColor whiteColor];
#endif
    
    lato = [UIFont fontWithName:@"Lato" size:16];
    enterpriseHint.font = lato;
    
    for(UILabel *l in signupHint.subviews) {
        l.font = lato;
        [l sizeToFit];
        lato = [UIFont fontWithName:@"Lato" size:18];
    }

    lato = [UIFont fontWithName:@"Lato" size:16];
    for(UILabel *l in loginHint.subviews) {
        l.font = lato;
        [l sizeToFit];
        lato = [UIFont fontWithName:@"Lato" size:18];
    }
    
    ((UILabel *)(forgotPasswordLogin.subviews.firstObject)).font = lato;
    ((UILabel *)(forgotPasswordSignup.subviews.firstObject)).font = lato;
    lato = [UIFont fontWithName:@"Lato" size:15];
    ((UILabel *)(notAProblem.subviews.firstObject)).font = lato;
    lato = [UIFont fontWithName:@"Lato-LightItalic" size:15];
    ((UILabel *)(notAProblem.subviews.lastObject)).font = lato;
    lato = [UIFont fontWithName:@"Lato" size:13];
    enterEmailAddressHint.font = lato;
    
    lato = [UIFont fontWithName:@"Lato" size:14];
    for(UILabel *l in forgotPasswordHint.subviews) {
        l.font = lato;
        [l sizeToFit];
    }

    for(UILabel *l in TOSHint.subviews) {
        l.font = lato;
        [l sizeToFit];
    }

    for(UILabel *l in enterpriseLearnMore.subviews) {
        l.font = lato;
        [l sizeToFit];
    }
    
    lato = [UIFont fontWithName:@"Lato-LightItalic" size:13];
    hostHint.font = lato;
    
    lato = [UIFont fontWithName:@"Lato" size:16];
    
    self.view.frame = [UIScreen mainScreen].applicationFrame;
    username.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, username.frame.size.height)];
    username.leftViewMode = UITextFieldViewModeAlways;
    username.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, username.frame.size.height)];
    username.rightViewMode = UITextFieldViewModeAlways;
    username.font = lato;
#ifdef ENTERPRISE
    username.placeholder = @"Email or Username";
#endif
    password.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, password.frame.size.height)];
    password.leftViewMode = UITextFieldViewModeAlways;
    password.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, password.frame.size.height)];
    password.rightViewMode = UITextFieldViewModeAlways;
    password.font = lato;
    host.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, host.frame.size.height)];
    host.leftViewMode = UITextFieldViewModeAlways;
    host.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, host.frame.size.height)];
    host.rightViewMode = UITextFieldViewModeAlways;
    host.font = lato;
    name.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, name.frame.size.height)];
    name.leftViewMode = UITextFieldViewModeAlways;
    name.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 9, name.frame.size.height)];
    name.rightViewMode = UITextFieldViewModeAlways;
    name.font = lato;
    
    lato = [UIFont fontWithName:@"Lato" size:17];
    login.titleLabel.font = lato;
    login.enabled = NO;
    signup.titleLabel.font = lato;
    signup.enabled = NO;
    next.titleLabel.font = lato;
    next.enabled = NO;
    sendAccessLink.titleLabel.font = lato;
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


-(void)flyaway {
    if(UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        logo.transform = CGAffineTransformMakeTranslation(0, -(logo.frame.origin.y + logo.frame.size.height));
        IRC.transform = CGAffineTransformMakeTranslation(0, -(IRC.frame.origin.y + IRC.frame.size.height));
        Cloud.transform = CGAffineTransformMakeTranslation(0, -(Cloud.frame.origin.y + Cloud.frame.size.height));
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
    IRC.transform = CGAffineTransformIdentity;
    Cloud.transform = CGAffineTransformIdentity;
    loadingView.transform = CGAffineTransformIdentity;
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
    if(username.text.length) {
        loginHint.alpha = 0;
        signupHint.alpha = 1;
        signup.alpha = 0;
        login.alpha = 1;
        name.alpha = 0;
    } else {
        loginHint.alpha = 1;
        signupHint.alpha = 0;
        signup.alpha = 1;
        login.alpha = 0;
        name.alpha = 1;
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
    if(_accessLink && IRCCLOUD_HOST.length) {
        [self _loginWithAccessLink];
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
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView beginAnimations:nil context:nil];
                loginView.alpha = 1;
                loadingView.alpha = 0;
                [UIView commitAnimations];
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Login Failed" message:@"Invalid access link" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                [alert show];
            });
        }
    });
}

-(void)viewDidAppear:(BOOL)animated {
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
}

-(void)viewWillDisappear:(BOOL)animated {
    [username resignFirstResponder];
    [password resignFirstResponder];
    [host resignFirstResponder];
}

-(void)viewDidDisappear:(BOOL)animated {
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
        loadingView.frame = loginView.frame = CGRectMake(0, 0, 320, self.view.bounds.size.height);
    } else {
        self.view.window.backgroundColor = [UIColor colorWithRed:11.0/255.0 green:46.0/255.0 blue:96.0/255.0 alpha:1];
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
        
        loginView.frame = CGRectMake(0, 119, width, height - 119);
        loadingView.frame = CGRectMake(0, 78, width, height - 78);
        version.frame = CGRectMake(0, height - 20 - _kbSize.height, width, 20);
        
        forgotPasswordLogin.frame = CGRectMake(logo.frame.origin.x + 17, 70, 65, 32);
        forgotPasswordSignup.frame = CGRectMake(logo.frame.origin.x + 141, 70, 65, 32);
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
    [UIView beginAnimations:nil context:NULL];
    name.alpha = 0;
    login.alpha = 1;
    password.alpha = 1;
    signup.alpha = 0;
    loginHint.alpha = 0;
    signupHint.alpha = 1;
    forgotPasswordHint.alpha = 1;
    TOSHint.alpha = 0;
    forgotPasswordLogin.alpha = 0;
    forgotPasswordSignup.alpha = 0;
    notAProblem.alpha = 0;
    sendAccessLink.alpha = 0;
    enterEmailAddressHint.alpha = 0;
    [self willAnimateRotationToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
    [UIView commitAnimations];
    [self textFieldChanged:name];
}

-(IBAction)signupHintPressed:(id)sender {
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
    [UIView commitAnimations];
    [self textFieldChanged:username];
}

-(IBAction)forgotPasswordHintPressed:(id)sender {
    [UIView beginAnimations:nil context:NULL];
    login.alpha = 0;
    password.alpha = 0;
    signupHint.alpha = 0;
    forgotPasswordHint.alpha = 0;
    
    forgotPasswordLogin.alpha = 1;
    forgotPasswordSignup.alpha = 1;
    notAProblem.alpha = 1;
    sendAccessLink.alpha = 1;
    enterEmailAddressHint.alpha = 1;
    [self _updateFieldPositions];
    [UIView commitAnimations];
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
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Password Reset Failed" message:@"Unable to request a password reset.  Please try again later." delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            [alert show];
        });
    });
}


-(IBAction)TOSHintPressed:(id)sender {
#ifndef EXTENSION
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.irccloud.com/terms"]];
#endif
}

-(IBAction)nextButtonPressed:(id)sender {
    IRCCLOUD_HOST = host.text;
    if([IRCCLOUD_HOST hasPrefix:@"http://"])
        IRCCLOUD_HOST = [IRCCLOUD_HOST substringFromIndex:7];
    if([IRCCLOUD_HOST hasPrefix:@"https://"])
        IRCCLOUD_HOST = [IRCCLOUD_HOST substringFromIndex:8];
    if([IRCCLOUD_HOST hasSuffix:@"/"])
        IRCCLOUD_HOST = [IRCCLOUD_HOST substringToIndex:IRCCLOUD_HOST.length - 1];
    
    if(_accessLink) {
        [self _loginWithAccessLink];
    } else {
        [UIView beginAnimations:nil context:NULL];
    }

    enterpriseHint.alpha = 0;
    host.alpha = 0;
    hostHint.alpha = 0;
    next.alpha = 0;
    enterpriseLearnMore.alpha = 0;
    
    username.alpha = 1;
    password.alpha = 1;
    signupHint.alpha = 1;
    login.alpha = 1;
    forgotPasswordHint.alpha = 1;
    
    if(!_accessLink) {
        [UIView commitAnimations];
        
        [host resignFirstResponder];
    }
}

-(IBAction)enterpriseLearnMorePressed:(id)sender {
    
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

-(NSUInteger)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskPortrait:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return orientation == UIInterfaceOrientationPortrait || [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPhone;
}

@end
