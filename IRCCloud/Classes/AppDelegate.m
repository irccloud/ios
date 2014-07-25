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

#import <Crashlytics/Crashlytics.h>
#import "AppDelegate.h"
#import "NetworkConnection.h"
#import "EditConnectionViewController.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"
#import "config.h"
#import "URLHandler.h"

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
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"bgTimeout":@(30), @"autoCaps":@(YES), @"host":@"api.irccloud.com", @"saveToCameraRoll":@(YES), @"photoSize":@(1024)}];
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"host"] isEqualToString:@"www.irccloud.com"]) {
        CLS_LOG(@"Migrating host");
        [[NSUserDefaults standardUserDefaults] setObject:@"api.irccloud.com" forKey:@"host"];
    }
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"path"]) {
        IRCCLOUD_HOST = [[NSUserDefaults standardUserDefaults] objectForKey:@"host"];
        IRCCLOUD_PATH = [[NSUserDefaults standardUserDefaults] objectForKey:@"path"];
    } else if([[[NSUserDefaults standardUserDefaults] objectForKey:@"host"] isEqualToString:@"api.irccloud.com"]) {
        NSString *session = [NetworkConnection sharedInstance].session;
        if(session.length) {
            CLS_LOG(@"Migrating path from session cookie");
            IRCCLOUD_PATH = [NSString stringWithFormat:@"/websocket/%c", [session characterAtIndex:0]];
            [[NSUserDefaults standardUserDefaults] setObject:IRCCLOUD_PATH forKey:@"path"];
        }
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
        [d setObject:IRCCLOUD_HOST forKey:@"host"];
        [d setObject:IRCCLOUD_PATH forKey:@"path"];
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"photoSize"] forKey:@"photoSize"];
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_access_token"])
            [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_access_token"] forKey:@"imgur_access_token"];
        else
            [d removeObjectForKey:@"imgur_access_token"];
        if([[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_refresh_token"])
            [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_refresh_token"] forKey:@"imgur_refresh_token"];
        else
            [d removeObjectForKey:@"imgur_refresh_token"];
        [d synchronize];
    }
#ifdef CRASHLYTICS_TOKEN
    [Crashlytics startWithAPIKey:@CRASHLYTICS_TOKEN];
#endif
    _conn = [NetworkConnection sharedInstance];
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
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
        [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    if(![url.scheme hasPrefix:@"irccloud"])
        [self launchURL:url];
    return YES;
}

- (void)launchURL:(NSURL *)url {
    if (!_urlHandler) {
        _urlHandler = [[URLHandler alloc] init];
#ifdef ENTERPRISE
        _urlHandler.appCallbackURL = [NSURL URLWithString:@"irccloud-enterprise://"];
#else
        _urlHandler.appCallbackURL = [NSURL URLWithString:@"irccloud://"];
#endif
        
    }
    [_urlHandler launchURL:url];
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
    if(_conn.background && application.applicationState != UIApplicationStateActive) {
        self.mainViewController.bidToOpen = [[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue];
        self.mainViewController.eidToOpen = [[[userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue];
        [self.mainViewController bufferSelected:[[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue]];
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    if(_conn.state != kIRCCloudStateConnected) {
        CLSLog(@"Fetching backlog in the background");
        _backlogCompletedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogCompletedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
            CLSLog(@"Backlog complete");
            [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
            [_conn disconnect];
            _conn.background = YES;
            completionHandler(UIBackgroundFetchResultNewData);
        }];
        _backlogFailedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogFailedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
            CLSLog(@"Backlog failed");
            [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
            [_conn disconnect];
            _conn.background = YES;
            completionHandler(UIBackgroundFetchResultFailed);
        }];
        _conn.background = NO;
        [_conn connect];
    } else {
        NSLog(@"Background fetch requested but we're still connected");
        completionHandler(UIBackgroundFetchResultNoData);
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

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"Entering background");
    _conn.background = YES;
    _conn.failCount = 0;
    _conn.reconnectTimestamp = -1;
    if(_conn.state == kIRCCloudStateDisconnected)
        [_conn cancelIdleTimer];
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
                [[EventsDataSource sharedInstance] pruneEventsForBuffer:b.bid maxSize:100];
        }
        [NSThread sleepForTimeInterval:[[[NSUserDefaults standardUserDefaults] objectForKey:@"bgTimeout"] intValue] + 5];
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    });
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if(_conn.background) {
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
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [_conn disconnect];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    //TODO: When this starts working, implement posting after the app was suspended
    NSLog(@"Background URL session finished: %@", identifier);
    
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
        NSDictionary *uploadtasks = [d dictionaryForKey:@"uploadtasks"];
        NSLog(@"%@", uploadtasks);
    }
    
    completionHandler();
}

@end
