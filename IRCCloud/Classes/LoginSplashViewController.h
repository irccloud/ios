//
//  LoginSplashViewController.h
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


#import <UIKit/UIKit.h>

@interface LoginSplashViewController : UIViewController<UITextFieldDelegate, UIGestureRecognizerDelegate> {
    IBOutlet UIImageView *logo;
    IBOutlet UILabel *IRC;
    IBOutlet UILabel *Cloud;
    IBOutlet UILabel *version;
    
    IBOutlet UIView *loginView;
    IBOutlet UITextField *name;
    IBOutlet UITextField *username;
    IBOutlet UITextField *password;
    IBOutlet UITextField *host;
    IBOutlet UIButton *login;
    IBOutlet UIButton *signup;
    IBOutlet UIButton *next;
    IBOutlet UIButton *sendAccessLink;
    
    IBOutlet UIView *loadingView;
    IBOutlet UILabel *status;
    IBOutlet UIActivityIndicatorView *activity;
    
    IBOutlet UIControl *signupHint;
    IBOutlet UIControl *loginHint;
    IBOutlet UIControl *forgotPasswordHint;
    IBOutlet UIControl *TOSHint;
    IBOutlet UIControl *enterpriseLearnMore;
    IBOutlet UIControl *forgotPasswordLogin;
    IBOutlet UIControl *forgotPasswordSignup;
    
    IBOutlet UILabel *enterpriseHint;
    IBOutlet UILabel *hostHint;
    IBOutlet UILabel *enterEmailAddressHint;
    IBOutlet UIView *notAProblem;
    
    IBOutlet UIButton *OnePassword;
    
    CGSize _kbSize;
    NSURL *_accessLink;
    NSString *_impression;
    BOOL _gotCredentialsFromPasswordManager;
}
@property NSURL *accessLink;
@property (nonatomic) NSString *impression;
-(IBAction)loginButtonPressed:(id)sender;
-(IBAction)signupButtonPressed:(id)sender;
-(IBAction)textFieldChanged:(id)sender;
-(IBAction)loginHintPressed:(id)sender;
-(IBAction)signupHintPressed:(id)sender;
-(IBAction)forgotPasswordHintPressed:(id)sender;
-(IBAction)TOSHintPressed:(id)sender;
-(IBAction)nextButtonPressed:(id)sender;
-(IBAction)enterpriseLearnMorePressed:(id)sender;
-(IBAction)sendAccessLinkButtonPressed:(id)sender;
-(IBAction)hideKeyboard:(id)sender;
-(void)hideLoginView;
-(UIImageView *)logo;
-(IBAction)onePasswordButtonPressed:(id)sender;
@end
