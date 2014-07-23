//
//  SplashViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 7/22/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NetworkConnection.h"

@interface SplashViewController : UIViewController {
    IBOutlet UILabel *status;
    IBOutlet UILabel *error;
    IBOutlet UIProgressView *progress;
    IBOutlet UIActivityIndicatorView *activity;
    
    NetworkConnection *_conn;
}

@end
