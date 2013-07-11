//
//  AppDelegate.h
//  IRCCloud
//
//  Created by Sam Steele on 2/19/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginSplashViewController.h"
#import "MainViewController.h"
#import "ECSlidingViewController.h"
#import "OpenInChromeController.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    NSTimer *_disconnectTimer;
    OpenInChromeController *_openInChromeController;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) LoginSplashViewController *loginSplashViewController;
@property (strong, nonatomic) MainViewController *mainViewController;
@property (strong, nonatomic) ECSlidingViewController *slideViewController;

-(void)showImage:(NSURL *)url;
-(void)showLoginView;
-(void)showMainView;
-(void)showConnectionView;
-(void)launchURL:(NSURL *)url;
@end
