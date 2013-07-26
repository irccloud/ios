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

#import "AppDelegate.h"
#import "NetworkConnection.h"
#import "ImageViewController.h"
#import "EditConnectionViewController.h"
#import "UIColor+IRCCloud.h"
#import "config.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    if(TESTFLIGHT_KEY)
        [TestFlight takeOff:TESTFLIGHT_KEY];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.loginSplashViewController = [[LoginSplashViewController alloc] initWithNibName:@"LoginSplashViewController_iPhone" bundle:nil];
        self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController_iPhone" bundle:nil];
        self.slideViewController = [[ECSlidingViewController alloc] init];
        self.slideViewController.view.backgroundColor = [UIColor backgroundBlueColor];
        self.slideViewController.topViewController = [[UINavigationController alloc] initWithRootViewController:self.mainViewController];
        self.slideViewController.topViewController.view.backgroundColor = [UIColor navBarColor];
    } else {
        self.loginSplashViewController = [[LoginSplashViewController alloc] initWithNibName:@"LoginSplashViewController_iPad" bundle:nil];
        self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController_iPad" bundle:nil];
        self.slideViewController = [[ECSlidingViewController alloc] init];
        self.slideViewController.view.backgroundColor = [UIColor backgroundBlueColor];
        self.slideViewController.topViewController = [[UINavigationController alloc] initWithRootViewController:self.mainViewController];
        self.slideViewController.topViewController.view.backgroundColor = [UIColor navBarColor];
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
    if(![url.scheme isEqualToString:@"irccloud"])
        [self launchURL:url];
    return YES;
}

- (void)launchURL:(NSURL *)url {
    if([url.scheme hasPrefix:@"irc"]) {
        [self.mainViewController launchURL:[NSURL URLWithString:[url.description stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
    } else {
        if(!_openInChromeController)
            _openInChromeController = [[OpenInChromeController alloc] init];
        NSString *l = [url.path lowercaseString];
        if([l hasSuffix:@"jpg"] || [l hasSuffix:@"png"] || [l hasSuffix:@"gif"]) {
            [self showImage:url];
        } else if(!([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [_openInChromeController openInChrome:url
                                         withCallbackURL:[NSURL URLWithString:@"irccloud://"]
                                            createNewTab:NO]))
            [[UIApplication sharedApplication] openURL:url];
    }
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken {
    [[NSUserDefaults standardUserDefaults] setObject:devToken forKey:@"APNs"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *result = [[NetworkConnection sharedInstance] registerAPNs:devToken];
        NSLog(@"Registration result: %@", result);
    });
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    TFLog(@"Error in APNs registration. Error: %@", err);
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMainView) name:kIRCCloudBacklogCompletedNotification object:nil];
        self.window.rootViewController = self.loginSplashViewController;
    }];
}

-(void)showImage:(NSURL *)url {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.window.rootViewController = [[ImageViewController alloc] initWithURL:url];
    }];
}

-(void)showMainView {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        if([[ServersDataSource sharedInstance] count]) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:kIRCCloudBacklogCompletedNotification object:nil];
            self.window.rootViewController = self.slideViewController;
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
    [NetworkConnection sharedInstance].background = YES;
    [_disconnectTimer invalidate];
    _disconnectTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:[NetworkConnection sharedInstance] selector:@selector(disconnect) userInfo:nil repeats:NO];
    if([self.window.rootViewController isKindOfClass:[ECSlidingViewController class]]) {
        ECSlidingViewController *evc = (ECSlidingViewController *)self.window.rootViewController;
        [evc.topViewController viewWillDisappear:NO];
    } else {
        [self.window.rootViewController viewWillDisappear:NO];
    }
    __block UIBackgroundTaskIdentifier background_task;
    background_task = [application beginBackgroundTaskWithExpirationHandler: ^ {
        [_disconnectTimer performSelectorOnMainThread:@selector(invalidate) withObject:nil waitUntilDone:YES];
        [[NetworkConnection sharedInstance] disconnect];
        [NSThread sleepForTimeInterval:5];
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    }];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:35];
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    });
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [NetworkConnection sharedInstance].background = NO;
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
    [[NetworkConnection sharedInstance] disconnect];
}

@end
