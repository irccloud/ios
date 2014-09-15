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
    NSLog(@"Application finished launching: %@", launchOptions);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"bgTimeout":@(30), @"autoCaps":@(YES), @"host":IRCCLOUD_HOST, @"saveToCameraRoll":@(YES), @"photoSize":@(1024)}];
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
#ifdef ENTERPRISE
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
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
    self.window.backgroundColor = [UIColor colorWithRed:11.0/255.0 green:46.0/255.0 blue:96.0/255.0 alpha:1];
    self.loginSplashViewController = [[LoginSplashViewController alloc] initWithNibName:@"LoginSplashViewController" bundle:nil];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController_iPhone" bundle:nil];
        self.slideViewController = [[ECSlidingViewController alloc] init];
        self.slideViewController.view.backgroundColor = [UIColor blackColor];
        self.slideViewController.topViewController = [[UINavigationController alloc] initWithNavigationBarClass:[NavBarHax class] toolbarClass:nil];
        [((UINavigationController *)self.slideViewController.topViewController) setViewControllers:@[self.mainViewController]];
        self.slideViewController.topViewController.view.backgroundColor = [UIColor blackColor];
    } else {
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
    NSString *session = [NetworkConnection sharedInstance].session;
    if(session != nil && [session length] > 0) {
        [self.mainViewController loadView];
        [self.mainViewController viewDidLoad];
        [[NetworkConnection sharedInstance] connect:NO];
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
            [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
            self.window.backgroundColor = [UIColor whiteColor];
        }
        self.window.rootViewController = self.slideViewController;
    } else {
        self.window.rootViewController = self.loginSplashViewController;
    }
    [self.window makeKeyAndVisible];
    
    NSLog(@"Animating from default.png");
    
    UIView *animationView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    animationView.backgroundColor = [UIColor colorWithRed:0.043 green:0.18 blue:0.376 alpha:1];
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 8) {
        animationView.transform = self.window.rootViewController.view.transform;
        if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
            animationView.frame = CGRectMake(20,0,animationView.frame.size.height,animationView.frame.size.width);
        else
            animationView.frame = CGRectMake(0,0,animationView.frame.size.height,animationView.frame.size.width);
    }
    
    UIImageView *logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"login_logo"]];
    [logo sizeToFit];
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 8)
        logo.center = CGPointMake(self.window.center.y, 39);
    else
        logo.center = CGPointMake(self.window.center.x, 39);
    [animationView addSubview:logo];
    [self.window addSubview:animationView];

    if([NetworkConnection sharedInstance].session.length) {
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
        [animation setFromValue:@(logo.layer.position.x)];
        [animation setToValue:@(animationView.bounds.size.width)];
        [animation setDuration:0.5];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:.6 :-.28 :.73 :.05]];
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        [logo.layer addAnimation:animation forKey:nil];
        
        [UIView animateWithDuration:0.5 animations:^{
            animationView.alpha = 0;
        } completion:^(BOOL finished) {
            [animationView removeFromSuperview];
        }];
    } else {
        self.loginSplashViewController.logo.hidden = YES;
        
        CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
        [animation setFromValue:@(logo.layer.position.x)];
        [animation setToValue:@(self.loginSplashViewController.logo.layer.position.x)];
        [animation setDuration:0.5];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:.17 :.89 :.32 :1.28]];
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        [logo.layer addAnimation:animation forKey:nil];
        
        [UIView animateWithDuration:0.5 animations:^{
            animationView.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            self.loginSplashViewController.logo.hidden = NO;
            [animationView removeFromSuperview];
        }];
    }
    
    NSLog(@"Launch complete");
    return YES;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSLog(@"Incoming URL: %@", url);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if([url.scheme hasPrefix:@"irccloud"]) {
        if([url.host isEqualToString:@"chat"] && [url.path isEqualToString:@"/access-link"]) {
            [_conn logout];
            self.loginSplashViewController.accessLink = url;
            self.window.backgroundColor = [UIColor colorWithRed:11.0/255.0 green:46.0/255.0 blue:96.0/255.0 alpha:1];
            self.loginSplashViewController.view.alpha = 1;
            if(self.window.rootViewController == self.loginSplashViewController)
                [self.loginSplashViewController viewWillAppear:YES];
            else
                self.window.rootViewController = self.loginSplashViewController;
        }
    } else {
        [self launchURL:url];
    }
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
    if(_movedToBackground && application.applicationState != UIApplicationStateActive) {
        if([userInfo objectForKey:@"d"]) {
            self.mainViewController.bidToOpen = [[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue];
            self.mainViewController.eidToOpen = [[[userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue];
            NSLog(@"Opening BID from notification: %i", self.mainViewController.bidToOpen);
            [self.mainViewController bufferSelected:[[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue]];
        }
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSLog(@"Perform background fetch");
    NSTimeInterval highestEid = [EventsDataSource sharedInstance].highestEid;
    if(_conn.state != kIRCCloudStateConnected && _conn.state != kIRCCloudStateConnecting) {
        CLS_LOG(@"Fetching backlog in the background");
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        _backlogCompletedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogCompletedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
            CLS_LOG(@"Backlog complete");
            [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
            [self.mainViewController refresh];
            if(highestEid < [EventsDataSource sharedInstance].highestEid) {
                CLS_LOG(@"Got new events");
                completionHandler(UIBackgroundFetchResultNewData);
            } else {
                CLS_LOG(@"No new events");
                completionHandler(UIBackgroundFetchResultNoData);
            }
            
            if(application.applicationState != UIApplicationStateActive && _background_task == UIBackgroundTaskInvalid)
                [_conn disconnect];
            else
                _conn.notifier = NO;
        }];
        _backlogFailedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogFailedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
            CLS_LOG(@"Backlog failed");
            [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
            [_conn disconnect];
            completionHandler(UIBackgroundFetchResultFailed);
        }];
        [_conn connect:YES];
    } else {
        CLS_LOG(@"Background fetch requested but we're still connected");
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

-(void)showLoginView {
    NSLog(@"Show Login View");
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.window.backgroundColor = [UIColor colorWithRed:11.0/255.0 green:46.0/255.0 blue:96.0/255.0 alpha:1];
        self.loginSplashViewController.view.alpha = 1;
        self.window.rootViewController = self.loginSplashViewController;
    }];
}

-(void)showMainView {
    [self showMainView:YES];
}

-(void)showMainView:(BOOL)animated {
    if(animated) {
        NSLog(@"Show main view with fade animation");
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [UIApplication sharedApplication].statusBarHidden = NO;
        self.slideViewController.view.alpha = 1;
        if(self.window.rootViewController != self.slideViewController) {
            BOOL fromLoginView = (self.window.rootViewController == self.loginSplashViewController);
            UIView *v = self.window.rootViewController.view;
            self.window.rootViewController = self.slideViewController;
            [self.window insertSubview:v aboveSubview:self.window.rootViewController.view];
            if(fromLoginView)
                [self.loginSplashViewController hideLoginView];
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
    }];
    } else if(self.window.rootViewController != self.slideViewController) {
        NSLog(@"Show main view without animation");
        [UIApplication sharedApplication].statusBarHidden = NO;
        self.slideViewController.view.alpha = 1;
        [self.window.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        self.window.rootViewController = self.slideViewController;
#ifdef __IPHONE_7_0
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
            self.window.backgroundColor = [UIColor whiteColor];
#endif
    }
}

-(void)showConnectionView {
    NSLog(@"Show edit connection view");
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped]];
    }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    _movedToBackground = YES;
    _conn.failCount = 0;
    _conn.reconnectTimestamp = 0;
    [_conn cancelIdleTimer];
    if([self.window.rootViewController isKindOfClass:[ECSlidingViewController class]]) {
        ECSlidingViewController *evc = (ECSlidingViewController *)self.window.rootViewController;
        [evc.topViewController viewWillDisappear:NO];
    } else {
        [self.window.rootViewController viewWillDisappear:NO];
    }
    
    __block UIBackgroundTaskIdentifier background_task = [application beginBackgroundTaskWithExpirationHandler: ^ {
        if(background_task == _background_task) {
            if([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
                CLS_LOG(@"Background task expired, disconnecting websocket");
                [_conn performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:YES];
                [_conn serialize];
                [NetworkConnection sync];
            }
            _background_task = UIBackgroundTaskInvalid;
        } else {
            NSLog(@"Stale background task expired");
        }
    }];
    _background_task = background_task;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffers]) {
            if(!b.scrolledUp && [[EventsDataSource sharedInstance] highlightStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type] == 0)
                [[EventsDataSource sharedInstance] pruneEventsForBuffer:b.bid maxSize:100];
        }
        [_conn serialize];
        NSLog(@"Sleeping for %f", [UIApplication sharedApplication].backgroundTimeRemaining - 30);
        [NSThread sleepForTimeInterval:[UIApplication sharedApplication].backgroundTimeRemaining - 30];
        NSLog(@"Finished sleeping");
        if(background_task == _background_task) {
            _background_task = UIBackgroundTaskInvalid;
            if([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
                CLS_LOG(@"Background task finished, disconnecting websocket");
                [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:NO];
                [[NetworkConnection sharedInstance] serialize];
                [NetworkConnection sync];
            }
            [application endBackgroundTask: background_task];
        } else {
            NSLog(@"Stale background task finished");
        }
    });
    if(self.window.rootViewController != _slideViewController && [ServersDataSource sharedInstance].count) {
        [self showMainView:NO];
        self.window.backgroundColor = [UIColor blackColor];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(_movedToBackground) {
        _movedToBackground = NO;
        [ColorFormatter clearFontCache];
        [[EventsDataSource sharedInstance] clearFormattingCache];
        _conn.reconnectTimestamp = -1;
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7) {
            [UIApplication sharedApplication].applicationIconBadgeNumber = 1;
            [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
        } else {
            [_conn updateBadgeCount];
        }
        if([self.window.rootViewController isKindOfClass:[ECSlidingViewController class]]) {
            ECSlidingViewController *evc = (ECSlidingViewController *)self.window.rootViewController;
            [evc.topViewController viewWillAppear:NO];
        } else {
            [self.window.rootViewController viewWillAppear:NO];
        }
        if(_background_task != UIBackgroundTaskInvalid) {
            NSLog(@"App resumed, cancelling background task");
            [application endBackgroundTask:_background_task];
            _background_task = UIBackgroundTaskInvalid;
        }
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [_conn disconnect];
    [_conn serialize];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
#ifdef ENTERPRISE
        config.sharedContainerIdentifier = @"group.com.irccloud.enterprise.share";
#else
        config.sharedContainerIdentifier = @"group.com.irccloud.share";
#endif
    }
    config.HTTPCookieStorage = nil;
    config.URLCache = nil;
    config.requestCachePolicy = NSURLCacheStorageNotAllowed;
    config.discretionary = NO;
    [[NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]] finishTasksAndInvalidate];
    imageUploadCompletionHandler = completionHandler;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    NSLog(@"Downloaded to: %@", location);
    NSData *response = [NSData dataWithContentsOfURL:location];
    if(session.configuration.identifier && [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
#ifdef ENTERPRISE
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
        NSMutableDictionary *uploadtasks = [[d dictionaryForKey:@"uploadtasks"] mutableCopy];
        NSDictionary *dict = [uploadtasks objectForKey:session.configuration.identifier];
        NSLog(@"Upload completed in the background: %@", dict);
        [uploadtasks removeObjectForKey:session.configuration.identifier];
        [d setObject:uploadtasks forKey:@"uploadtasks"];
        [d synchronize];
        
        NSDictionary *r = [[[SBJsonParser alloc] init] objectWithData:response];
        if(!r) {
            NSLog(@"IMGUR: Invalid JSON response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        } else if([[r objectForKey:@"success"] intValue] == 1) {
            NSString *link = [[[r objectForKey:@"data"] objectForKey:@"link"] stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
            
            if([dict objectForKey:@"msg"]) {
                if(_conn.state != kIRCCloudStateConnected) {
                    CLS_LOG(@"Sending message in the background");
                    [[NSNotificationCenter defaultCenter] removeObserver:self];
                    _backlogCompletedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogCompletedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
                        CLS_LOG(@"Backlog complete");
                        [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
                        Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[dict objectForKey:@"bid"] intValue]];
                        [_conn say:[NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"msg"],link] to:b.name cid:b.cid];
                        CLS_LOG(@"Message sent");
                        UILocalNotification *alert = [[UILocalNotification alloc] init];
                        alert.fireDate = [NSDate date];
                        alert.userInfo = @{@"d":@[@(b.cid), @(b.bid), @(-1)]};
                        alert.soundName = @"a.caf";
                        [[UIApplication sharedApplication] scheduleLocalNotification:alert];
                        imageUploadCompletionHandler();
                        if([UIApplication sharedApplication].applicationState != UIApplicationStateActive && _background_task == UIBackgroundTaskInvalid)
                            [_conn disconnect];
                    }];
                    _backlogFailedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogFailedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
                        CLS_LOG(@"Backlog failed");
                        [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
                        [_conn disconnect];
                        UILocalNotification *alert = [[UILocalNotification alloc] init];
                        alert.fireDate = [NSDate date];
                        alert.alertBody = @"Unable to share image. Please try again shortly.";
                        alert.soundName = @"a.caf";
                        [[UIApplication sharedApplication] scheduleLocalNotification:alert];
                        imageUploadCompletionHandler();
                        if([UIApplication sharedApplication].applicationState != UIApplicationStateActive && _background_task == UIBackgroundTaskInvalid)
                            [_conn disconnect];
                    }];
                    [_conn connect:YES];
                } else {
                    CLS_LOG(@"Sending message");
                    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[dict objectForKey:@"bid"] intValue]];
                    [_conn say:[NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"msg"],link] to:b.name cid:b.cid];
                    CLS_LOG(@"Message sent");
                    UILocalNotification *alert = [[UILocalNotification alloc] init];
                    alert.fireDate = [NSDate date];
                    alert.userInfo = @{@"d":@[@(b.cid), @(b.bid), @(-1)]};
                    alert.soundName = @"a.caf";
                    [[UIApplication sharedApplication] scheduleLocalNotification:alert];
                    imageUploadCompletionHandler();
                }
            } else {
                CLS_LOG(@"Setting link as draft");
                Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[dict objectForKey:@"bid"] intValue]];
                if(b) {
                    if(b.draft.length)
                        b.draft = [b.draft stringByAppendingFormat:@" %@",link];
                    else
                        b.draft = link;
                }
                UILocalNotification *alert = [[UILocalNotification alloc] init];
                alert.fireDate = [NSDate date];
                alert.alertBody = @"Your image has been uploaded and is ready to send";
                alert.userInfo = @{@"d":@[@(b.cid), @(b.bid), @(-1)]};
                alert.soundName = @"a.caf";
                [[UIApplication sharedApplication] scheduleLocalNotification:alert];
                imageUploadCompletionHandler();
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error) {
        NSLog(@"Download error: %@", error);
        UILocalNotification *alert = [[UILocalNotification alloc] init];
        alert.fireDate = [NSDate date];
        alert.alertBody = @"Unable to share image. Please try again shortly.";
        alert.soundName = @"a.caf";
        [[UIApplication sharedApplication] scheduleLocalNotification:alert];
    }
    [session finishTasksAndInvalidate];
}

@end
