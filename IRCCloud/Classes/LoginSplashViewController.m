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
#import "SamlLoginViewController.h"
@import Firebase;

@implementation LoginSplashViewController

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return ![touch.view isKindOfClass:[UIControl class]];
}

-(UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (@available(iOS 13, *)) {
        self.view.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    self->_kbSize = CGSizeZero;

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

    for(UILabel *l in resetPasswordHint.subviews) {
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
    
    self.view.frame = [UIScreen mainScreen].bounds;
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
    name.background = [UIImage imageNamed:@"login_top_input"];
    username.background = [UIImage imageNamed:@"login_top_input"];
    password.background = [UIImage imageNamed:@"login_bottom_input"];
    host.background = [UIImage imageNamed:@"login_only_input"];

    [self transitionToSize:self.view.bounds.size];
}

-(void)hideLoginView {
    loginView.alpha = 0;
    loadingView.alpha = 1;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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
    enterpriseHint.text = @"Enterprise Edition";
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
    [self transitionToSize:self.view.bounds.size];
    if(self->_accessLink && IRCCLOUD_HOST.length) {
        self->_gotCredentialsFromPasswordManager = YES;
        [self _loginWithAccessLink];
#ifndef ENTERPRISE
    } else {
        [self performSelector:@selector(_promptForSWC) withObject:nil afterDelay:0.1];
#endif
    }
}

-(void)_promptForSWC {
#if !TARGET_OS_MACCATALYST
    if (@available(macCatalyst 14.0, *)) {
        if(username.text.length == 0 && !_gotCredentialsFromPasswordManager && !_accessLink) {
            SecRequestSharedWebCredential(NULL, NULL, ^(CFArrayRef credentials, CFErrorRef error) {
                if (error != NULL) {
                    CLS_LOG(@"Unable to request shared web credentials: %@", error);
                    return;
                }
                
                if (CFArrayGetCount(credentials) > 0) {
                    self->_gotCredentialsFromPasswordManager = YES;
                    NSDictionary *credentialsDict = CFArrayGetValueAtIndex(credentials, 0);
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        [self->username setText:[credentialsDict objectForKey:(__bridge id)(kSecAttrAccount)]];
                        [self->password setText:[credentialsDict objectForKey:(__bridge id)(kSecSharedPassword)]];
                        [self loginHintPressed:nil];
                        [self loginButtonPressed:nil];
                    }];
                }
            });
        }
    }
#endif
}

-(void)_loginWithAccessLink {
    if([self->_accessLink.scheme hasPrefix:@"irccloud"] && [self->_accessLink.host isEqualToString:@"chat"] && [self->_accessLink.path isEqualToString:@"/access-link"])
                self->_accessLink = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@/%@%@?%@&format=json", IRCCLOUD_HOST, _accessLink.host, _accessLink.path, _accessLink.query]];

    loginView.alpha = 0;
    loadingView.alpha = 1;
    [status setText:@"Signing in"];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, status.text);
    [activity startAnimating];
    activity.hidden = NO;
    [[NetworkConnection sharedInstance] login:self->_accessLink handler:^(IRCCloudJSONObject *result) {
        self->_accessLink = nil;
        if([[result objectForKey:@"success"] intValue] == 1) {
            if([result objectForKey:@"websocket_path"])
                IRCCLOUD_PATH = [result objectForKey:@"websocket_path"];
            [NetworkConnection sharedInstance].session = [result objectForKey:@"session"];
            [[NSUserDefaults standardUserDefaults] setObject:IRCCLOUD_PATH forKey:@"path"];
            [[NSUserDefaults standardUserDefaults] synchronize];
            if([result objectForKey:@"api_host"])
                [[NetworkConnection sharedInstance] updateAPIHost:[result objectForKey:@"api_host"]];
#ifdef ENTERPRISE
            NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
            NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
            [d setObject:IRCCLOUD_HOST forKey:@"host"];
            [d setObject:IRCCLOUD_PATH forKey:@"path"];
            [d synchronize];
            self->loginHint.alpha = 0;
            self->signupHint.alpha = 0;
            self->enterpriseHint.alpha = 0;
            self->forgotPasswordLogin.alpha = 0;
            self->forgotPasswordSignup.alpha = 0;
            [((AppDelegate *)([UIApplication sharedApplication].delegate)) showMainView:YES];
        } else {
            [UIView beginAnimations:nil context:nil];
            self->loginView.alpha = 1;
            self->loadingView.alpha = 0;
            [UIView commitAnimations];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Login Failed" message:@"Invalid access link" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self transitionToSize:self.view.bounds.size];
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
    if(name.alpha)
        offset = 1;
    
    if(self->_authURL)
        offset = -2;
    
    if(name.alpha > 0)
        username.background = [UIImage imageNamed:@"login_mid_input"];
    else if(sendAccessLink.alpha > 0)
        username.background = [UIImage imageNamed:@"login_only_input"];
    else
        username.background = [UIImage imageNamed:@"login_top_input"];

    if(sendAccessLink.alpha) {
        usernameYOffset.constant = 16 + 26;
    } else {
        usernameYOffset.constant = 16 + (offset * 39);
    }

    passwordYOffset.constant = 16 + ((offset + 1) * 39);
    nextYOffset.constant = 16 + 39 + 32;
    loginYOffset.constant = signupYOffset.constant = 16 + ((offset + 2) * 39) + 15;
    sendAccessLinkYOffset.constant = 16 + 81;
    
    OnePassword.hidden = self->_authURL || (login.alpha != 1 && signup.alpha != 1) || ![[OnePasswordExtension sharedExtension] isAppExtensionAvailable];
}

-(UIImageView *)logo {
    return logo;
}

-(void)transitionToSize:(CGSize)size {
    if(self->_kbSize.height && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.view.window.backgroundColor = [UIColor colorWithRed:68.0/255.0 green:128.0/255.0 blue:250.0/255.0 alpha:1];
        loadingViewYOffset.constant = loginViewYOffset.constant = logo.frame.origin.y + logo.frame.size.height + 16;
    } else {
        self.view.window.backgroundColor = [UIColor colorWithRed:11.0/255.0 green:46.0/255.0 blue:96.0/255.0 alpha:1];
        loginViewYOffset.constant = 160;
        loadingViewYOffset.constant = 120;
        loginViewYOffset.constant += self.view.window.safeAreaInsets.top;
        loadingViewYOffset.constant += self.view.window.safeAreaInsets.top;
    }
    
    [self _updateFieldPositions];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self transitionToSize:size];
        [self.view layoutIfNeeded];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];
}

-(void)keyboardWillShow:(NSNotification*)notification {
    if (@available(iOS 13.0, *)) {
        if([NSProcessInfo processInfo].macCatalystApp) {
            return;
        }
    }
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    self->_kbSize = [self.view convertRect:[[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] toView:nil].size;
    [self transitionToSize:self.view.bounds.size];
    [self.view layoutIfNeeded];
    [UIView commitAnimations];
}

-(void)keyboardWillBeHidden:(NSNotification*)notification {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationBeginsFromCurrentState:YES];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    self->_kbSize = CGSizeZero;
    [self transitionToSize:self.view.bounds.size];
    [self.view layoutIfNeeded];
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
    resetPasswordHint.alpha = 1;
    TOSHint.alpha = 0;
    forgotPasswordLogin.alpha = 0;
    forgotPasswordSignup.alpha = 0;
    notAProblem.alpha = 0;
    sendAccessLink.alpha = 0;
    enterEmailAddressHint.alpha = 0;
    [self transitionToSize:self.view.bounds.size];
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
    resetPasswordHint.alpha = 0;
    TOSHint.alpha = 1;
    forgotPasswordLogin.alpha = 0;
    forgotPasswordSignup.alpha = 0;
    notAProblem.alpha = 0;
    sendAccessLink.alpha = 0;
    enterEmailAddressHint.alpha = 0;
    [self transitionToSize:self.view.bounds.size];
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
    resetPasswordHint.alpha = 0;
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
    _requestingReset = NO;
    [sendAccessLink setTitle:@"Request access link" forState:UIControlStateNormal];
    [enterEmailAddressHint setText:@"Just enter the email address you signed up with and we'll send you a link to log straight in."];
}

-(void)resetPasswordHintPressed:(id)sender {
    [self forgotPasswordHintPressed:sender];
    _requestingReset = YES;
    [sendAccessLink setTitle:@"Request password reset" forState:UIControlStateNormal];
    [enterEmailAddressHint setText:@"Just enter the email address you signed up with and we'll send you a link to reset your password."];
}

-(void)_accessLinkRequestFailed {
    [UIView beginAnimations:nil context:nil];
    self->loginView.alpha = 1;
    self->loadingView.alpha = 0;
    [UIView commitAnimations];
    [self->activity stopAnimating];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Request Failed" message:self->_requestingReset?@"Unable to request a password reset.  Please try again later.":@"Unable to request an access link.  Please try again later." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(IBAction)sendAccessLinkButtonPressed:(id)sender {
    [username resignFirstResponder];
    [UIView beginAnimations:nil context:nil];
    loginView.alpha = 0;
    loadingView.alpha = 1;
    [UIView commitAnimations];
    [status setText:self->_requestingReset?@"Requesting Password Reset":@"Requesting Access Link"];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, status.text);
    [activity startAnimating];
    activity.hidden = NO;
    NSString *user = [username.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    [[NetworkConnection sharedInstance] requestAuthTokenWithHandler:^(IRCCloudJSONObject *result) {
        if([[result objectForKey:@"success"] intValue] == 1) {
            if(self->_requestingReset) {
                [[NetworkConnection sharedInstance] requestPasswordReset:user token:[result objectForKey:@"token"] handler:^(IRCCloudJSONObject *result) {
                    if([[result objectForKey:@"success"] intValue] == 1) {
                        [UIView beginAnimations:nil context:nil];
                        self->loginView.alpha = 1;
                        self->loadingView.alpha = 0;
                        [UIView commitAnimations];
                        [self->activity stopAnimating];
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Email Sent" message:@"We've sent you a password reset link.  Check your email and follow the instructions to sign in." preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                        [self loginHintPressed:nil];
                    } else {
                        [self _accessLinkRequestFailed];
                    }
                }];
            } else {
                [[NetworkConnection sharedInstance] requestAccessLink:user token:[result objectForKey:@"token"] handler:^(IRCCloudJSONObject *result) {
                    if([[result objectForKey:@"success"] intValue] == 1) {
                        [UIView beginAnimations:nil context:nil];
                        self->loginView.alpha = 1;
                        self->loadingView.alpha = 0;
                        [UIView commitAnimations];
                        [self->activity stopAnimating];
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Email Sent" message:@"We've sent you an access link.  Check your email and follow the instructions to sign in." preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:alert animated:YES completion:nil];
                        [self loginHintPressed:nil];
                    } else {
                        [self _accessLinkRequestFailed];
                    }
                }];
            }
        } else {
            [self _accessLinkRequestFailed];
        }
    }];
}

-(IBAction)onePasswordButtonPressed:(id)sender {
    self->_gotCredentialsFromPasswordManager = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        if(self->login.alpha) {
#ifdef ENTERPRISE
            NSString *url = [NSString stringWithFormat:@"https://%@", host.text];
#else
            NSString *url = @"https://www.irccloud.com";
#endif
            [[OnePasswordExtension sharedExtension] findLoginForURLString:url forViewController:self sender:sender completion:^(NSDictionary *loginDict, NSError *error) {
                if (!loginDict) {
                    if (error.code != AppExtensionErrorCodeCancelledByUser) {
                        CLS_LOG(@"Error invoking 1Password App Extension for find login: %@", error);
                    }
                    return;
                }
                
                self->loginView.alpha = 0;
                if([loginDict[AppExtensionUsernameKey] length])
                    self->username.text = loginDict[AppExtensionUsernameKey];
                self->password.text = loginDict[AppExtensionPasswordKey];
                self->enterpriseHint.alpha = 0;
                self->host.alpha = 0;
                self->hostHint.alpha = 0;
                self->next.alpha = 0;
                self->enterpriseLearnMore.alpha = 0;
                self->username.alpha = 1;
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
                                              AppExtensionUsernameKey: self->username.text ? : @"",
                                              AppExtensionPasswordKey: self->password.text ? : @"",
                                              AppExtensionSectionTitleKey: @"IRCCloud",
                                              AppExtensionFieldsKey: @{
                                                      @"Name" : self->name.text ? : @""
                                                      }
                                              };
            
            [[OnePasswordExtension sharedExtension] storeLoginForURLString:url loginDetails:newLoginDetails passwordGenerationOptions:nil forViewController:self sender:sender completion:^(NSDictionary *loginDict, NSError *error) {
                
                if (!loginDict) {
                    if (error.code != AppExtensionErrorCodeCancelledByUser) {
                        CLS_LOG(@"Failed to use 1Password App Extension to save a new Login: %@", error);
                    }
                    return;
                }
                if(((NSString *)loginDict[AppExtensionReturnedFieldsKey][@"Name"]).length)
                    self->name.text = (NSString *)(loginDict[AppExtensionReturnedFieldsKey][@"Name"]);
                if([loginDict[AppExtensionUsernameKey] length])
                    self->username.text = loginDict[AppExtensionUsernameKey];
                self->password.text = loginDict[AppExtensionPasswordKey] ? : @"";
                
                self->enterpriseHint.alpha = 0;
                self->host.alpha = 0;
                self->hostHint.alpha = 0;
                self->next.alpha = 0;
                self->enterpriseLearnMore.alpha = 0;
                self->username.alpha = 1;
                [self signupHintPressed:nil];
            }];
        }
    });
}

-(IBAction)TOSHintPressed:(id)sender {
#ifndef EXTENSION
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://www.irccloud.com/terms"] options:@{UIApplicationOpenURLOptionUniversalLinksOnly:@NO} completionHandler:nil];
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
    [[NetworkConnection sharedInstance] requestConfigurationWithHandler:^(IRCCloudJSONObject *result) {
        if(result) {
            IRCCLOUD_HOST = [result objectForKey:@"api_host"];
            [self _stripIRCCloudHost];
            if([[result objectForKey:@"enterprise"] isKindOfClass:[NSDictionary class]]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->enterpriseHint.text = [[result objectForKey:@"enterprise"] objectForKey:@"fullname"];
                });
            }
            if(![[result objectForKey:@"auth_mechanism"] isEqualToString:@"internal"])
                self->signupHint.enabled = YES;
            
            if([[result objectForKey:@"auth_mechanism"] isEqualToString:@"saml"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->login setTitle:[NSString stringWithFormat:@"Login with %@", [result objectForKey:@"saml_provider"]] forState:UIControlStateNormal];
                    self->login.enabled = YES;
                });
                self->_authURL = [NSString stringWithFormat:@"https://%@/saml/auth", IRCCLOUD_HOST];
                self->signupHint.enabled = NO;
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self->login setTitle:@"Login" forState:UIControlStateNormal];
                    self->login.enabled = NO;
                });
                self->_authURL = nil;
            }
        } else {
            IRCCLOUD_HOST = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Connection Failed" message:@"Please check your host and try again shortly, or contact your system administrator for assistance." preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self->_accessLink && IRCCLOUD_HOST.length) {
                [self _loginWithAccessLink];
            } else {
                if(IRCCLOUD_HOST.length) {
                    self->enterpriseHint.alpha = 0;
                    self->host.alpha = 0;
                    self->hostHint.alpha = 0;
                    self->next.alpha = 0;
                    self->enterpriseLearnMore.alpha = 0;
                    
                    if(!self->_authURL) {
                        self->username.alpha = 1;
                        self->password.alpha = 1;
                        self->forgotPasswordHint.alpha = 1;
                        self->resetPasswordHint.alpha = 1;
                    }
                    if(self->signupHint.enabled)
                        self->signupHint.alpha = 1;
                    else
                        self->enterpriseHint.alpha = 1;
                    self->login.alpha = 1;
                    [self transitionToSize:self.view.bounds.size];
                }
                [UIView beginAnimations:nil context:nil];
                self->loginView.alpha = 1;
                self->loadingView.alpha = 0;
                [UIView commitAnimations];
            }
        });
    }];
}

-(IBAction)enterpriseLearnMorePressed:(id)sender {
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"irccloud://"]]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"irccloud://"] options:@{UIApplicationOpenURLOptionUniversalLinksOnly:@NO} completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms://itunes.apple.com/app/irccloud/id672699103"] options:@{UIApplicationOpenURLOptionUniversalLinksOnly:@NO} completionHandler:nil];
    }
}

-(IBAction)hideKeyboard:(id)sender {
    [self.view endEditing:YES];
}

-(IBAction)loginButtonPressed:(id)sender {
    if(self->_authURL) {
        SamlLoginViewController *c = [[SamlLoginViewController alloc] initWithURL:self->_authURL];
        c.navigationItem.title = login.titleLabel.text;
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:c] animated:YES completion:nil];
        return;
    }
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
    NSString *user = [username.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    NSString *pass = password.text;
    NSString *realname = [name.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    CGFloat nameAlpha = name.alpha;
    
#ifndef ENTERPRISE
    IRCCLOUD_HOST = @"api.irccloud.com";
#endif
    [[NetworkConnection sharedInstance] requestConfigurationWithHandler:^(IRCCloudJSONObject *config) {
        if(!config) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView beginAnimations:nil context:nil];
                self->loginView.alpha = 1;
                self->loadingView.alpha = 0;
                [UIView commitAnimations];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Communication Error" message:@"Unable to fetch configuration. Please try again shortly." preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                [alert addAction:[UIAlertAction actionWithTitle:@"Send Feedback" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [[NetworkConnection sharedInstance] sendFeedbackReport:self];
                }]];
                [self presentViewController:alert animated:YES completion:nil];
            });
            return;
        }
        [[NetworkConnection sharedInstance] updateAPIHost:[config objectForKey:@"api_host"]];
        
        [[NetworkConnection sharedInstance] requestAuthTokenWithHandler:^(IRCCloudJSONObject *result) {
            if([[result objectForKey:@"success"] intValue] == 1) {
                IRCCloudAPIResultHandler handler = ^(IRCCloudJSONObject *result) {
                    if([[result objectForKey:@"success"] intValue] == 1) {
                        if([result objectForKey:@"websocket_path"])
                            IRCCLOUD_PATH = [result objectForKey:@"websocket_path"];
                        [NetworkConnection sharedInstance].session = [result objectForKey:@"session"];
                        [[NSUserDefaults standardUserDefaults] setObject:IRCCLOUD_PATH forKey:@"path"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        if([result objectForKey:@"api_host"])
                            [[NetworkConnection sharedInstance] updateAPIHost:[result objectForKey:@"api_host"]];
#ifdef ENTERPRISE
                        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
                        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
                        [d setObject:IRCCLOUD_HOST forKey:@"host"];
                        [d setObject:IRCCLOUD_PATH forKey:@"path"];
                        [d synchronize];
#ifndef ENTERPRISE
                        if(!self->_gotCredentialsFromPasswordManager) {
                            if (@available(macCatalyst 14.0, *)) {
                                SecAddSharedWebCredential((CFStringRef)@"www.irccloud.com", (__bridge CFStringRef)user, (__bridge CFStringRef)pass, ^(CFErrorRef error) {
                                    if (error != NULL) {
                                        CLS_LOG(@"Unable to save shared credentials: %@", error);
                                        return;
                                    }
                                });
                            }
                        }
#endif
                        self->loginHint.alpha = 0;
                        self->signupHint.alpha = 0;
                        self->enterpriseHint.alpha = 0;
                        self->forgotPasswordLogin.alpha = 0;
                        self->forgotPasswordSignup.alpha = 0;
                        [((AppDelegate *)([UIApplication sharedApplication].delegate)) showMainView:YES];
                    } else {
                        CLS_LOG(@"Failure: %@", result);
                        [UIView beginAnimations:nil context:nil];
                        self->loginView.alpha = 1;
                        self->loadingView.alpha = 0;
                        [UIView commitAnimations];
                        NSString *message = self->name.alpha?@"Invalid email address or password. Please try again.":@"Unable to login to IRCCloud.  Please check your username and password, and try again shortly.";
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
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:self->name.alpha?@"Sign Up Failed":@"Login Failed" message:message preferredStyle:UIAlertControllerStyleAlert];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                        [alert addAction:[UIAlertAction actionWithTitle:@"Send Feedback" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                            [[NetworkConnection sharedInstance] sendFeedbackReport:self];
                        }]];
                        [self presentViewController:alert animated:YES completion:nil];
                    }
                };
                
                if(nameAlpha)
                    [[NetworkConnection sharedInstance] signup:user password:pass realname:realname token:[result objectForKey:@"token"] handler:handler];
                else
                    [[NetworkConnection sharedInstance] login:user password:pass token:[result objectForKey:@"token"] handler:handler];
            } else {
                CLS_LOG(@"Failure: %@", result);
                [UIView beginAnimations:nil context:nil];
                self->loginView.alpha = 1;
                self->loadingView.alpha = 0;
                [UIView commitAnimations];
                NSString *message = @"Unable to communicate with the IRCCloud servers.  Please try again shortly.";
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Login Failed" message:message preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
                [alert addAction:[UIAlertAction actionWithTitle:@"Send Feedback" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [[NetworkConnection sharedInstance] sendFeedbackReport:self];
                }]];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
    }];
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
    else if(textField == name)
        [username becomeFirstResponder];
    else if(textField == host)
        [self nextButtonPressed:host];
    else
        [self loginButtonPressed:textField];
    return YES;
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskPortrait:UIInterfaceOrientationMaskAll;
}

-(void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
