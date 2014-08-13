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
#import "NetworkConnection.h"

@interface LoginSplashViewController : UIViewController<UITextFieldDelegate> {
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
    
    IBOutlet UIView *loadingView;
    IBOutlet UILabel *status;
    IBOutlet UILabel *error;
    IBOutlet UIProgressView *progress;
    IBOutlet UIActivityIndicatorView *activity;
    
    NetworkConnection *_conn;
    CGSize _kbSize;
}
-(void)flyaway;
-(IBAction)loginButtonPressed:(id)sender;
-(IBAction)signupButtonPressed:(id)sender;
-(IBAction)textFieldChanged:(id)sender;
@end
