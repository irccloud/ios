//
//  AppDelegate.m
//  IRCCloud
//
//  Created by Sam Steele on 2/19/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import "AppDelegate.h"
#import "NetworkConnection.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [TestFlight takeOff:@""];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.loginSplashViewController = [[LoginSplashViewController alloc] initWithNibName:@"LoginSplashViewController_iPhone" bundle:nil];
        self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController_iPhone" bundle:nil];
    } else {
        self.loginSplashViewController = [[LoginSplashViewController alloc] initWithNibName:@"LoginSplashViewController_iPad" bundle:nil];
        self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController_iPad" bundle:nil];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMainView) name:kIRCCloudBacklogCompletedNotification object:nil];
    self.window.rootViewController = self.loginSplashViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

-(void)showLoginView {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMainView) name:kIRCCloudBacklogCompletedNotification object:nil];
        self.window.rootViewController = self.loginSplashViewController;
    }];
}

-(void)showMainView {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kIRCCloudBacklogCompletedNotification object:nil];
        self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.mainViewController];
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    _disconnectTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:[NetworkConnection sharedInstance] selector:@selector(disconnect) userInfo:nil repeats:NO];
    [self.window.rootViewController viewWillDisappear:NO];
    __block UIBackgroundTaskIdentifier background_task;
    background_task = [application beginBackgroundTaskWithExpirationHandler: ^ {
        [_disconnectTimer invalidate];
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

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self applicationWillResignActive:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self applicationDidBecomeActive:application];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [_disconnectTimer invalidate];
    [self.window.rootViewController viewWillAppear:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NetworkConnection sharedInstance] disconnect];
}

@end
