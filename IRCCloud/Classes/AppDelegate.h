//
//  AppDelegate.h
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
#import "LoginSplashViewController.h"
#import "MainViewController.h"
#import "ECSlidingViewController.h"
#import "NetworkConnection.h"
#import "URLHandler.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, NSURLSessionDataDelegate> {
    NetworkConnection *_conn;
    URLHandler *_urlHandler;
    id _backlogCompletedObserver;
    id _backlogFailedObserver;
    id _IRCEventObserver;
    int _finalizeUploadReqid;
    void (^imageUploadCompletionHandler)();
    BOOL _movedToBackground;
    __block UIBackgroundTaskIdentifier _background_task;
    UIView *_animationView;
    UIImageView *_logo;
    void (^_fetchHandler)(UIBackgroundFetchResult);
    void (^_refreshHandler)(UIBackgroundFetchResult);
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) LoginSplashViewController *loginSplashViewController;
@property (strong, nonatomic) MainViewController *mainViewController;
@property (strong, nonatomic) ECSlidingViewController *slideViewController;

-(void)showLoginView;
-(void)showMainView:(BOOL)animated;
-(void)showConnectionView;
-(void)launchURL:(NSURL *)url;
@end
