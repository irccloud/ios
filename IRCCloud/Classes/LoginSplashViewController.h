//
//  LoginSplashViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 2/19/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkConnection.h"

@interface LoginSplashViewController : UIViewController {
    IBOutlet UIImageView *logo;
    IBOutlet UILabel *version;
    
    IBOutlet UIView *loginView;
    IBOutlet UITextField *username;
    IBOutlet UITextField *password;
    
    IBOutlet UIView *loadingView;
    IBOutlet UILabel *status;
    IBOutlet UILabel *error;
    IBOutlet UIProgressView *progress;
    IBOutlet UIActivityIndicatorView *activity;
    
    NetworkConnection *_conn;
}
-(IBAction)loginButtonPressed:(id)sender;
@end
