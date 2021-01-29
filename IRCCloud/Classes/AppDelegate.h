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
#import <UserNotifications/UserNotifications.h>
#import "LoginSplashViewController.h"
#import "MainViewController.h"
#import "ECSlidingViewController.h"
#import "NetworkConnection.h"
#import "URLHandler.h"
#import "SplashViewController.h"

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSURLSessionDataDelegate, UNUserNotificationCenterDelegate> {
    NetworkConnection *_conn;
    URLHandler *_urlHandler;
    id _backlogCompletedObserver;
    id _backlogFailedObserver;
    id _IRCEventObserver;
    void (^imageUploadCompletionHandler)(void);
    BOOL _movedToBackground;
    __block UIBackgroundTaskIdentifier _background_task;
    void (^_fetchHandler)(UIBackgroundFetchResult);
    void (^_refreshHandler)(UIBackgroundFetchResult);
    NSMutableSet *_activeScenes;
}

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) LoginSplashViewController *loginSplashViewController;
@property (strong, nonatomic) MainViewController *mainViewController;
@property (strong, nonatomic) ECSlidingViewController *slideViewController;
@property (strong, nonatomic) SplashViewController *splashViewController;

@property BOOL movedToBackground;

-(void)showLoginView;
-(void)showMainView:(BOOL)animated;
-(void)showConnectionView;
-(void)launchURL:(NSURL *)url;
-(void)addScene:(id)scene;
-(void)removeScene:(id)scene;
-(void)setActiveScene:(UIWindow *)window;
-(UIScene *)sceneForWindow:(UIWindow *)window;
-(void)closeWindow:(UIWindow *)window;
@end

@interface SceneDelegate : NSObject <UIWindowSceneDelegate> {
    AppDelegate *_appDelegate;
    UIScene *_scene;
}
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UIScene *scene;

@property (strong, nonatomic) LoginSplashViewController *loginSplashViewController;
@property (strong, nonatomic) MainViewController *mainViewController;
@property (strong, nonatomic) ECSlidingViewController *slideViewController;
@property (strong, nonatomic) SplashViewController *splashViewController;
@end
