//
//  AppDelegate.m
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

#import <HockeySDK/HockeySDK.h>
#import <Crashlytics/Crashlytics.h>
#import "AppDelegate.h"
#import "NetworkConnection.h"
#import "ImageViewController.h"
#import "EditConnectionViewController.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"
#import "config.h"

//From: http://stackoverflow.com/a/19313559
@interface NavBarHax : UINavigationBar

@property (nonatomic, assign) BOOL changingUserInteraction;
@property (nonatomic, assign) BOOL userInteractionChangedBySystem;

@end

@implementation NavBarHax

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.userInteractionChangedBySystem && self.userInteractionEnabled == NO) {
        return [super hitTest:point withEvent:event];
    }
    
    if ([self pointInside:point withEvent:event]) {
        self.changingUserInteraction = YES;
        self.userInteractionEnabled = YES;
        self.changingUserInteraction = NO;
    } else {
        self.changingUserInteraction = YES;
        self.userInteractionEnabled = NO;
        self.changingUserInteraction = NO;
    }
    
    return [super hitTest:point withEvent:event];
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    if (!self.changingUserInteraction) {
        self.userInteractionChangedBySystem = YES;
    } else {
        self.userInteractionChangedBySystem = NO;
    }
    
    [super setUserInteractionEnabled:userInteractionEnabled];
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _conn = [NetworkConnection sharedInstance];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"bgTimeout":@(30), @"autoCaps":@(YES), @"host":@"www.irccloud.com"}];
#ifdef ENTERPRISE
#ifdef HOCKEYAPP_TOKEN_ENTERPRISE
    if(@HOCKEYAPP_TOKEN_ENTERPRISE.length) {
        [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@HOCKEYAPP_TOKEN_ENTERPRISE];
        [[BITHockeyManager sharedHockeyManager] setDisableCrashManager:YES];
        [[BITHockeyManager sharedHockeyManager] setDisableFeedbackManager:YES];
        [[BITHockeyManager sharedHockeyManager] startManager];
        if(![BITHockeyManager sharedHockeyManager].isAppStoreEnvironment)
            [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    }
#endif
#else
#ifdef HOCKEYAPP_TOKEN
    if(@HOCKEYAPP_TOKEN.length) {
        [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@HOCKEYAPP_TOKEN];
        [[BITHockeyManager sharedHockeyManager] setDisableCrashManager:YES];
        [[BITHockeyManager sharedHockeyManager] setDisableFeedbackManager:YES];
        [[BITHockeyManager sharedHockeyManager] startManager];
        if(![BITHockeyManager sharedHockeyManager].isAppStoreEnvironment)
             [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    }
#endif
#endif
#ifdef CRASHLYTICS_TOKEN
    [Crashlytics startWithAPIKey:@CRASHLYTICS_TOKEN];
#endif
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.loginSplashViewController = [[LoginSplashViewController alloc] initWithNibName:@"LoginSplashViewController_iPhone" bundle:nil];
        self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController_iPhone" bundle:nil];
        self.slideViewController = [[ECSlidingViewController alloc] init];
        self.slideViewController.view.backgroundColor = [UIColor blackColor];
        self.slideViewController.topViewController = [[UINavigationController alloc] initWithNavigationBarClass:[NavBarHax class] toolbarClass:nil];
        [((UINavigationController *)self.slideViewController.topViewController) setViewControllers:@[self.mainViewController]];
        self.slideViewController.topViewController.view.backgroundColor = [UIColor blackColor];
    } else {
        self.loginSplashViewController = [[LoginSplashViewController alloc] initWithNibName:@"LoginSplashViewController_iPad" bundle:nil];
        self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController_iPad" bundle:nil];
        self.slideViewController = [[ECSlidingViewController alloc] init];
        self.slideViewController.view.backgroundColor = [UIColor blackColor];
        self.slideViewController.topViewController = [[UINavigationController alloc] initWithNavigationBarClass:[NavBarHax class] toolbarClass:nil];
        [((UINavigationController *)self.slideViewController.topViewController) setViewControllers:@[self.mainViewController]];
        self.slideViewController.topViewController.view.backgroundColor = [UIColor blackColor];
    }
    if(launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        self.mainViewController.bidToOpen = [[[[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] objectForKey:@"d"] objectAtIndex:1] intValue];
        self.mainViewController.eidToOpen = [[[[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] objectForKey:@"d"] objectAtIndex:2] doubleValue];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMainView) name:kIRCCloudBacklogCompletedNotification object:nil];
    self.window.rootViewController = self.loginSplashViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if(![url.scheme hasPrefix:@"irccloud"])
        [self launchURL:url];
    return YES;
}

- (void)launchURL:(NSURL *)url {
    if(self.window.rootViewController.presentedViewController)
       [self.window.rootViewController dismissModalViewControllerAnimated:NO];
    NSString *l = [url.path lowercaseString];
    if([url.scheme hasPrefix:@"irc"]) {
        [self.mainViewController launchURL:[NSURL URLWithString:[url.description stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
    } else if([l hasSuffix:@"jpg"] || [l hasSuffix:@"png"] || [l hasSuffix:@"gif"] ||
              ([[url.host lowercaseString] isEqualToString:@"imgur.com"] && [url.path rangeOfString:@"/a/"].location == NSNotFound) ||
              ([[url.host lowercaseString] hasSuffix:@"flickr.com"] && [[url.path lowercaseString] hasPrefix:@"/photos/"]) ||
              (([[url.host lowercaseString] isEqualToString:@"instagram.com"] || [[url.host lowercaseString] isEqualToString:@"instagr.am"]) && [[url.path lowercaseString] hasPrefix:@"/p/"]) ||
              (([[url.host lowercaseString] isEqualToString:@"droplr.com"] || [[url.host lowercaseString] isEqualToString:@"d.pr"]) && [[url.path lowercaseString] hasPrefix:@"/i/"]) ||
              ([url.host.lowercaseString isEqualToString:@"cl.ly"] && url.path.length && ![url.path.lowercaseString isEqualToString:@"/robots.txt"] && ![url.path.lowercaseString isEqualToString:@"/image"])) {
        [self showImage:url];
    } else {
        if(!_openInChromeController)
            _openInChromeController = [[OpenInChromeController alloc] init];
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"useChrome"] || ![_openInChromeController isChromeInstalled]) {
            if(!([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [_openInChromeController openInChrome:url
                                             withCallbackURL:[NSURL URLWithString:
#ifdef ENTERPRISE
                                                              @"irccloud-enterprise://"
#else
                                                              @"irccloud://"
#endif
                                                              ]
                                                createNewTab:NO]))
                [[UIApplication sharedApplication] openURL:url];
        } else {
            _pendingURL = url;
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Choose A Browser" message:@"Would you prefer to open links in Safari or Chrome?" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Chrome", @"Safari", nil];
            [alert show];
        }
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [[NSUserDefaults standardUserDefaults] setObject:@(buttonIndex == 0) forKey:@"useChrome"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self launchURL:_pendingURL];
    _pendingURL = nil;
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    if(![devToken isEqualToData:[[NSUserDefaults standardUserDefaults] objectForKey:@"APNs"]]) {
        [[NSUserDefaults standardUserDefaults] setObject:devToken forKey:@"APNs"];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSDictionary *result = [_conn registerAPNs:devToken];
            NSLog(@"Registration result: %@", result);
        });
    }
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    CLS_LOG(@"Error in APNs registration. Error: %@", err);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if(_disconnectTimer) {
        self.mainViewController.bidToOpen = [[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue];
        self.mainViewController.eidToOpen = [[[userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue];
        [self.mainViewController bufferSelected:[[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue]];
    }
}

-(void)showLoginView {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.window.backgroundColor = [UIColor blackColor];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMainView) name:kIRCCloudBacklogCompletedNotification object:nil];
        self.loginSplashViewController.view.alpha = 1;
        self.window.rootViewController = self.loginSplashViewController;
    }];
}

-(void)showImage:(NSURL *)url {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.window.backgroundColor = [UIColor blackColor];
        self.window.rootViewController = [[ImageViewController alloc] initWithURL:url];
        [self.window insertSubview:self.slideViewController.view aboveSubview:self.window.rootViewController.view];
        [UIView animateWithDuration:0.5f animations:^{
            self.slideViewController.view.alpha = 0;
        } completion:^(BOOL finished){
            [self.slideViewController.view removeFromSuperview];
#ifdef __IPHONE_7_0
            if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
                [UIApplication sharedApplication].statusBarHidden = YES;
#endif
        }];
    }];
}

-(void)showMainView {
    [self showMainView:YES];
}

-(void)showMainView:(BOOL)animated {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [UIApplication sharedApplication].statusBarHidden = NO;
        if([[ServersDataSource sharedInstance] count]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kIRCCloudBacklogCompletedNotification object:nil];
            self.slideViewController.view.alpha = 1;
            if(animated) {
                if(self.window.rootViewController == self.loginSplashViewController) {
                    self.window.rootViewController = self.slideViewController;
                    [self.window insertSubview:self.loginSplashViewController.view aboveSubview:self.slideViewController.view];
                    CGAffineTransform transform = self.slideViewController.view.transform;
                    self.slideViewController.view.transform = CGAffineTransformScale(transform, 0.01, 0.01);
                    [UIView animateWithDuration:0.5f animations:^{
                        self.loginSplashViewController.view.alpha = 0;
                        [self.loginSplashViewController flyaway];
                        self.slideViewController.view.transform = transform;
                    } completion:^(BOOL finished){
                        [self.loginSplashViewController.view removeFromSuperview];
#ifdef __IPHONE_7_0
                        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
                            self.window.backgroundColor = [UIColor whiteColor];
#endif
                    }];
                } else if(self.window.rootViewController != self.slideViewController) {
                    UIView *v = self.window.rootViewController.view;
                    self.window.rootViewController = self.slideViewController;
                    [self.window insertSubview:v aboveSubview:self.window.rootViewController.view];
                    [UIView animateWithDuration:0.5f animations:^{
                        v.alpha = 0;
                    } completion:^(BOOL finished){
                        [v removeFromSuperview];
#ifdef __IPHONE_7_0
                        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
                            self.window.backgroundColor = [UIColor whiteColor];
#endif
                    }];
                }
            } else if(self.window.rootViewController != self.slideViewController) {
                [self.window.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                self.window.rootViewController = self.slideViewController;
            }
        } else {
            [self showConnectionView];
        }
    }];
}

-(void)showConnectionView {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped]];
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    _conn.background = YES;
    [_disconnectTimer invalidate];
    _disconnectTimer = [NSTimer scheduledTimerWithTimeInterval:[[[NSUserDefaults standardUserDefaults] objectForKey:@"bgTimeout"] intValue] target:_conn selector:@selector(disconnect) userInfo:nil repeats:NO];
    if([self.window.rootViewController isKindOfClass:[ECSlidingViewController class]]) {
        ECSlidingViewController *evc = (ECSlidingViewController *)self.window.rootViewController;
        [evc.topViewController viewWillDisappear:NO];
    } else {
        [self.window.rootViewController viewWillDisappear:NO];
    }
    __block UIBackgroundTaskIdentifier background_task;
    background_task = [application beginBackgroundTaskWithExpirationHandler: ^ {
        [_disconnectTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
        [_conn disconnect];
        [NSThread sleepForTimeInterval:5];
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffers]) {
            if(!b.scrolledUp && [[EventsDataSource sharedInstance] highlightStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type] == 0)
                [[EventsDataSource sharedInstance] pruneEventsForBuffer:b.bid];
        }
        [NSThread sleepForTimeInterval:[[[NSUserDefaults standardUserDefaults] objectForKey:@"bgTimeout"] intValue] + 5];
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    });
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [ColorFormatter clearFontCache];
    [[EventsDataSource sharedInstance] clearFormattingCache];
    if(_conn.reconnectTimestamp == 0)
        _conn.reconnectTimestamp = -1;
    _conn.background = NO;
    application.applicationIconBadgeNumber = 1;
    application.applicationIconBadgeNumber = 0;
    [application cancelAllLocalNotifications];
    [_disconnectTimer invalidate];
    _disconnectTimer = nil;
    if([self.window.rootViewController isKindOfClass:[ECSlidingViewController class]]) {
        ECSlidingViewController *evc = (ECSlidingViewController *)self.window.rootViewController;
        [evc.topViewController viewWillAppear:NO];
    } else {
        [self.window.rootViewController viewWillAppear:NO];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [_conn disconnect];
}

@end
