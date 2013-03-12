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
    [TestFlight takeOff:@"73c60e40d91cd2e993c0c3415b7be729_MTk2OTQ2MjAxMy0wMy0xMSAxMTo1NTowMS42NTI1MjM"];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.loginSplashViewController = [[LoginSplashViewController alloc] initWithNibName:@"LoginSplashViewController_iPhone" bundle:nil];
        self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController_iPhone" bundle:nil];
    } else {
        self.loginSplashViewController = [[LoginSplashViewController alloc] initWithNibName:@"LoginSplashViewController_iPhone" bundle:nil];
        self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController_iPad" bundle:nil];
    }
    [self showLoginView];
    [self.window makeKeyAndVisible];
    return YES;
}

-(void)showLoginView {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMainView) name:kIRCCloudBacklogCompletedNotification object:nil];
    self.window.rootViewController = self.loginSplashViewController;
}

-(void)showMainView {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kIRCCloudBacklogCompletedNotification object:nil];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:self.mainViewController];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[NetworkConnection sharedInstance] disconnect];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSString *session = [[NSUserDefaults standardUserDefaults] stringForKey:@"session"];
    if([NetworkConnection sharedInstance].state == kIRCCloudStateDisconnected && session != nil && [session length] > 0)
        [[NetworkConnection sharedInstance] connect];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NetworkConnection sharedInstance] disconnect];
}

@end
