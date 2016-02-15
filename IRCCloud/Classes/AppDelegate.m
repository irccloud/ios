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

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <AdSupport/AdSupport.h>
#import "AppDelegate.h"
#import "NetworkConnection.h"
#import "EditConnectionViewController.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"
#import "config.h"
#import "URLHandler.h"
#import "UIDevice+UIDevice_iPhone6Hax.h"

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSURL *caches = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
    [[NSFileManager defaultManager] removeItemAtURL:caches error:nil];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"bgTimeout":@(30), @"autoCaps":@(YES), @"host":IRCCLOUD_HOST, @"saveToCameraRoll":@(YES), @"photoSize":@(1024), @"notificationSound":@(YES), @"tabletMode":@(YES), @"imageService":@"IRCCloud", @"uploadsAvailable":@(NO)}];
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"fontSize":@([UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody].pointSize * 0.8)}];
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
    
    [ColorFormatter loadFonts];
    [UIColor setTheme:[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]];
    [[EventsDataSource sharedInstance] reformat];
    
    if(IRCCLOUD_HOST.length < 1)
        [NetworkConnection sharedInstance].session = nil;
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
#ifdef ENTERPRISE
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
        [d setObject:IRCCLOUD_HOST forKey:@"host"];
        [d setObject:IRCCLOUD_PATH forKey:@"path"];
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"photoSize"] forKey:@"photoSize"];
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"cacheVersion"] forKey:@"cacheVersion"];
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"uploadsAvailable"] forKey:@"uploadsAvailable"];
        [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"imageService"] forKey:@"imageService"];
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
    [Fabric with:@[CrashlyticsKit]];
#endif
    
    self.loginSplashViewController = [[LoginSplashViewController alloc] initWithNibName:@"LoginSplashViewController" bundle:nil];
    self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    self.slideViewController = [[ECSlidingViewController alloc] init];
    self.slideViewController.view.backgroundColor = [UIColor blackColor];
    self.slideViewController.topViewController = [[UINavigationController alloc] initWithNavigationBarClass:[NavBarHax class] toolbarClass:nil];
    [((UINavigationController *)self.slideViewController.topViewController) setViewControllers:@[self.mainViewController]];
    self.slideViewController.topViewController.view.backgroundColor = [UIColor blackColor];
    if(launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        self.mainViewController.bidToOpen = [[[[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] objectForKey:@"d"] objectAtIndex:1] intValue];
        self.mainViewController.eidToOpen = [[[[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] objectForKey:@"d"] objectAtIndex:2] doubleValue];
    }

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor colorWithRed:11.0/255.0 green:46.0/255.0 blue:96.0/255.0 alpha:1];
    self.window.rootViewController = [[UIViewController alloc] init];
    
    _animationView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    _animationView.backgroundColor = [UIColor colorWithRed:0.043 green:0.18 blue:0.376 alpha:1];
    
    _logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"login_logo"]];
    [_logo sizeToFit];
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 8)
        _logo.center = CGPointMake(self.window.center.y, 39);
    else
        _logo.center = CGPointMake(self.window.center.x, 39);

    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 8) {
        if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
            _animationView.transform = self.window.rootViewController.view.transform;
            if([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
                _animationView.frame = CGRectMake(20,0,_animationView.frame.size.height,_animationView.frame.size.width);
            else
                _animationView.frame = CGRectMake(0,0,_animationView.frame.size.height,_animationView.frame.size.width);
        }
    }
    CGRect frame = _animationView.frame;
    frame.origin.y -= [UIApplication sharedApplication].statusBarFrame.size.height;
    frame.size.height += [UIApplication sharedApplication].statusBarFrame.size.height;
    _animationView.frame = frame;
    
    frame = _logo.frame;
    frame.origin.y += [UIApplication sharedApplication].statusBarFrame.size.height;
    _logo.frame = frame;

    [_animationView addSubview:_logo];
    [self.window addSubview:_animationView];
    [self.window makeKeyAndVisible];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _conn = [NetworkConnection sharedInstance];
        [self.mainViewController loadView];
        [self.mainViewController viewDidLoad];
        NSString *session = [NetworkConnection sharedInstance].session;
        if(session != nil && [session length] > 0 && IRCCLOUD_HOST.length > 0) {
            //Store the session in the keychain again to update the access policy
            [NetworkConnection sharedInstance].session = session;
            [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
            self.window.backgroundColor = [UIColor textareaBackgroundColor];
            self.window.rootViewController = self.slideViewController;
        } else {
            self.window.rootViewController = self.loginSplashViewController;
        }
        
        [self.window addSubview:_animationView];
        
        if([NetworkConnection sharedInstance].session.length) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
            [animation setFromValue:@(_logo.layer.position.x)];
            [animation setToValue:@(_animationView.bounds.size.width + _logo.bounds.size.width)];
            [animation setDuration:0.4];
            [animation setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:.8 :-.3 :.8 :-.3]];
            animation.removedOnCompletion = NO;
            animation.fillMode = kCAFillModeForwards;
            [_logo.layer addAnimation:animation forKey:nil];
        } else {
            self.loginSplashViewController.logo.hidden = YES;
            
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position.x"];
            [animation setFromValue:@(_logo.layer.position.x)];
            [animation setToValue:@(self.loginSplashViewController.logo.layer.position.x)];
            [animation setDuration:0.4];
            [animation setTimingFunction:[CAMediaTimingFunction functionWithControlPoints:.17 :.89 :.32 :1.28]];
            animation.removedOnCompletion = NO;
            animation.fillMode = kCAFillModeForwards;
            [_logo.layer addAnimation:animation forKey:nil];
        }
        
        [UIView animateWithDuration:0.25 delay:0.25 options:0 animations:^{
            _animationView.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            self.loginSplashViewController.logo.hidden = NO;
            [_animationView removeFromSuperview];
            _animationView = nil;
        }];
    }];
    
    return YES;
}

-(BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler {
    CLS_LOG(@"Continuing activity type: %@", userActivity.activityType);
#ifdef ENTERPRISE
    if([userActivity.activityType isEqualToString:@"com.irccloud.enterprise.buffer"])
#else
    if([userActivity.activityType isEqualToString:@"com.irccloud.buffer"])
#endif
    {
        if([userActivity.userInfo objectForKey:@"bid"]) {
            self.mainViewController.bidToOpen = [[userActivity.userInfo objectForKey:@"bid"] intValue];
            self.mainViewController.eidToOpen = 0;
            self.mainViewController.incomingDraft = [userActivity.userInfo objectForKey:@"draft"];
            CLS_LOG(@"Opening BID from handoff: %i", self.mainViewController.bidToOpen);
            [self.mainViewController bufferSelected:[[userActivity.userInfo objectForKey:@"bid"] intValue]];
            return YES;
        }
    } else if([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        if([userActivity.webpageURL.host isEqualToString:@"www.irccloud.com"]) {
            if([userActivity.webpageURL.path isEqualToString:@"/chat/access-link"]) {
                CLS_LOG(@"Opening access-link from handoff");
                NSString *url = [[userActivity.webpageURL.absoluteString stringByReplacingOccurrencesOfString:@"https://www.irccloud.com/" withString:@"irccloud://"] stringByReplacingOccurrencesOfString:@"&mobile=1" withString:@""];
                [[NetworkConnection sharedInstance] logout];
                self.loginSplashViewController.accessLink = [NSURL URLWithString:url];
                self.window.backgroundColor = [UIColor colorWithRed:11.0/255.0 green:46.0/255.0 blue:96.0/255.0 alpha:1];
                self.loginSplashViewController.view.alpha = 1;
                if(self.window.rootViewController == self.loginSplashViewController)
                    [self.loginSplashViewController viewWillAppear:YES];
                else
                    self.window.rootViewController = self.loginSplashViewController;
            } else if([userActivity.webpageURL.path hasPrefix:@"/verify-email/"]) {
                CLS_LOG(@"Opening verify-email from handoff");
                [[[NSURLSession sharedSession] dataTaskWithURL:userActivity.webpageURL completionHandler:
                  ^(NSData *data, NSURLResponse *response, NSError *error) {
                      [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                          if([(NSHTTPURLResponse *)response statusCode] == 200) {
                              UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Email Confirmed" message:@"Your email address was successfully confirmed" preferredStyle:UIAlertControllerStyleAlert];
                              [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil]];
                              [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                          } else {
                              UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Email Confirmation Failed" message:@"Unable to confirm your email address.  Please try again shortly." preferredStyle:UIAlertControllerStyleAlert];
                              [alert addAction:[UIAlertAction actionWithTitle:@"Send Again" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                  [[NetworkConnection sharedInstance] resendVerifyEmail];
                                  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmation Sent" message:@"You should shortly receive an email with a link to confirm your address." preferredStyle:UIAlertControllerStyleAlert];
                                  [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil]];
                                  [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                              }]];
                              [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil]];
                              [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                          }
                      }];
                }] resume];
            } else if([userActivity.webpageURL.path isEqualToString:@"/"] && [userActivity.webpageURL.fragment hasPrefix:@"!/"]) {
                NSString *url = [userActivity.webpageURL.absoluteString stringByReplacingOccurrencesOfString:@"https://www.irccloud.com/#!/" withString:@"irc://"];
                if([url hasPrefix:@"irc://ircs://"])
                    url = [url substringFromIndex:6];
                CLS_LOG(@"Opening URL from handoff: %@", url);
                [self.mainViewController launchURL:[NSURL URLWithString:url]];
            } else if([userActivity.webpageURL.path isEqualToString:@"/invite"]) {
                [self launchURL:[NSURL URLWithString:[userActivity.webpageURL.absoluteString stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
            } else {
                [[UIApplication sharedApplication] openURL:userActivity.webpageURL];
                return NO;
            }
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if([url.scheme hasPrefix:@"irccloud"]) {
        if([url.host isEqualToString:@"chat"] && [url.path isEqualToString:@"/access-link"]) {
            [[NetworkConnection sharedInstance] logout];
            self.loginSplashViewController.accessLink = url;
            self.window.backgroundColor = [UIColor colorWithRed:11.0/255.0 green:46.0/255.0 blue:96.0/255.0 alpha:1];
            self.loginSplashViewController.view.alpha = 1;
            if(self.window.rootViewController == self.loginSplashViewController)
                [self.loginSplashViewController viewWillAppear:YES];
            else
                self.window.rootViewController = self.loginSplashViewController;
        } else if([url.host isEqualToString:@"referral"]) {
            [self performSelectorInBackground:@selector(_sendImpression:) withObject:url];
        } else {
            return NO;
        }
    } else {
        [self launchURL:url];
    }
    return YES;
}

-(void)_sendImpression:(NSURL *)url {
    NSDictionary *d = [[NetworkConnection sharedInstance] impression:[[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString] referrer:[url.absoluteString substringFromIndex:url.scheme.length + url.host.length + 4]];
    if([[d objectForKey:@"success"] intValue]) {
        self.loginSplashViewController.impression = [d objectForKey:@"id"];
    }
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
    NSData *oldToken = [[NSUserDefaults standardUserDefaults] objectForKey:@"APNs"];
    if(oldToken && ![devToken isEqualToData:oldToken]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CLS_LOG(@"Unregistering old APNs token");
            NSDictionary *result = [_conn unregisterAPNs:oldToken session:_conn.session];
            NSLog(@"Unregistration result: %@", result);
        });
    }
    [[NSUserDefaults standardUserDefaults] setObject:devToken forKey:@"APNs"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *result = [_conn registerAPNs:devToken];
        NSLog(@"Registration result: %@", result);
    });
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)err {
    CLS_LOG(@"Error in APNs registration. Error: %@", err);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if(_movedToBackground && application.applicationState != UIApplicationStateActive) {
        if([userInfo objectForKey:@"d"]) {
            self.mainViewController.bidToOpen = [[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue];
            self.mainViewController.eidToOpen = [[[userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue];
            CLS_LOG(@"Opening BID from notification: %i", self.mainViewController.bidToOpen);
            [self.mainViewController bufferSelected:[[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue]];
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))handler {
    
    if([userInfo objectForKey:@"d"]) {
        int cid = [[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue];
        int bid = [[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue];
        NSTimeInterval eid = [[[userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue];
        
        if(application.applicationState == UIApplicationStateBackground && (!_conn || (_conn.state != kIRCCloudStateConnected && _conn.state != kIRCCloudStateConnecting))) {
            [[NotificationsDataSource sharedInstance] notify:nil cid:cid bid:bid eid:eid];
        }
        
        if(_movedToBackground && application.applicationState == UIApplicationStateInactive) {
            self.mainViewController.bidToOpen = bid;
            self.mainViewController.eidToOpen = eid;
            CLS_LOG(@"Opening BID from notification: %i", self.mainViewController.bidToOpen);
            [self.mainViewController bufferSelected:bid];
        } else if(application.applicationState == UIApplicationStateBackground && (!_conn || (_conn.state != kIRCCloudStateConnected && _conn.state != kIRCCloudStateConnecting))) {
            if(_backlogCompletedObserver) {
                [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
                _backlogCompletedObserver = nil;
            }
            if(_backlogFailedObserver) {
                [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
                _backlogFailedObserver = nil;
            }
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            
            _backlogCompletedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogCompletedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
                if([n.object bid] == bid) {
                    if(_backlogCompletedObserver) {
                        [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
                        _backlogCompletedObserver = nil;
                    }
                    if(_backlogFailedObserver) {
                        [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
                        _backlogFailedObserver = nil;
                    }
                    [self.mainViewController refresh];
                    NSLog(@"Backlog download completed for bid%i", bid);
                    [[NotificationsDataSource sharedInstance] updateBadgeCount];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [[NetworkConnection sharedInstance] serialize];
                        handler(UIBackgroundFetchResultNewData);
                    });
                }
            }];
            _backlogFailedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogFailedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
                if([n.object bid] == bid) {
                    if(_backlogCompletedObserver) {
                        [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
                        _backlogCompletedObserver = nil;
                    }
                    if(_backlogFailedObserver) {
                        [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
                        _backlogFailedObserver = nil;
                    }
                    [self.mainViewController refresh];
                    NSLog(@"Backlog download failed for bid%i", bid);
                    [[NotificationsDataSource sharedInstance] updateBadgeCount];
                    handler(UIBackgroundFetchResultFailed);
                }
            }];

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSLog(@"Preloading backlog for bid%i from notification", bid);
                [[NetworkConnection sharedInstance] requestBacklogForBuffer:bid server:cid];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[NetworkConnection sharedInstance] serialize];
                });
            });
        } else {
            handler(UIBackgroundFetchResultNoData);
        }
    } else if ([userInfo objectForKey:@"hb"] && application.applicationState == UIApplicationStateBackground) {
        for(NSString *key in [userInfo objectForKey:@"hb"]) {
            NSDictionary *bids = [[userInfo objectForKey:@"hb"] objectForKey:key];
            for(NSString *bid in bids.allKeys) {
                NSTimeInterval eid = [[bids objectForKey:bid] doubleValue];
                [[BuffersDataSource sharedInstance] updateLastSeenEID:eid buffer:bid.intValue];
                [[NotificationsDataSource sharedInstance] removeNotificationsForBID:bid.intValue olderThan:eid];
            }
        }
        [[NotificationsDataSource sharedInstance] updateBadgeCount];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NetworkConnection sharedInstance] serialize];
            handler(UIBackgroundFetchResultNoData);
        });
    } else {
        handler(UIBackgroundFetchResultNoData);
    }
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    NSTimeInterval highestEid = [NetworkConnection sharedInstance].highestEID;
    if([NetworkConnection sharedInstance].state != kIRCCloudStateConnected && [NetworkConnection sharedInstance].state != kIRCCloudStateConnecting) {
        if(_backlogCompletedObserver) {
            [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
            _backlogCompletedObserver = nil;
        }
        if(_backlogFailedObserver) {
            [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
            _backlogFailedObserver = nil;
        }
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        _backlogCompletedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogCompletedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
            if(_backlogCompletedObserver) {
                [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
                _backlogCompletedObserver = nil;
            }
            if(_backlogFailedObserver) {
                [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
                _backlogFailedObserver = nil;
            }
            [self.mainViewController refresh];
            [[NotificationsDataSource sharedInstance] updateBadgeCount];
            _refreshHandler = nil;
            if(highestEid < [NetworkConnection sharedInstance].highestEID) {
                completionHandler(UIBackgroundFetchResultNewData);
            } else {
                completionHandler(UIBackgroundFetchResultNoData);
            }
            
            if(application.applicationState != UIApplicationStateActive && _background_task == UIBackgroundTaskInvalid && [NetworkConnection sharedInstance].notifier) {
                CLS_LOG(@"Backlog download completed for background refresh, disconnecting websocket");
                [[NetworkConnection sharedInstance] disconnect];
            } else {
                CLS_LOG(@"Backlog download completed for background refresh, upgrading websocket");
                [NetworkConnection sharedInstance].notifier = NO;
            }
        }];
        _backlogFailedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogFailedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
            if(_backlogCompletedObserver) {
                [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
                _backlogCompletedObserver = nil;
            }
            if(_backlogFailedObserver) {
                [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
                _backlogFailedObserver = nil;
            }
            if([NetworkConnection sharedInstance].notifier) {
                CLS_LOG(@"Backlog download failed for background refresh, disconnecting websocket");
                [[NetworkConnection sharedInstance] disconnect];
            }
            [self.mainViewController refresh];
            _refreshHandler = nil;
            completionHandler(UIBackgroundFetchResultFailed);
        }];
        [[NetworkConnection sharedInstance] connect:YES];
        if(_refreshHandler)
            _refreshHandler(UIBackgroundFetchResultNoData);
        
        _refreshHandler = completionHandler;
        [self performSelector:@selector(_complete) withObject:nil afterDelay:[UIApplication sharedApplication].backgroundTimeRemaining - 5];
    } else {
        completionHandler(UIBackgroundFetchResultNoData);
        _refreshHandler = nil;
    }
}

-(void)_complete {
    if(_refreshHandler) {
        [self.mainViewController refresh];
        CLS_LOG(@"Refresh took too long, giving up");
        if([NetworkConnection sharedInstance].notifier) {
            [[NetworkConnection sharedInstance] disconnect];
        }
        _refreshHandler(UIBackgroundFetchResultNewData);
        _refreshHandler = nil;
    }
}

-(void)showLoginView {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.window.backgroundColor = [UIColor colorWithRed:11.0/255.0 green:46.0/255.0 blue:96.0/255.0 alpha:1];
        self.loginSplashViewController.view.alpha = 1;
        self.window.rootViewController = self.loginSplashViewController;
#ifndef ENTERPRISE
        [self.loginSplashViewController loginHintPressed:nil];
#endif
    }];
}

-(void)showMainView {
    [self showMainView:YES];
}

-(void)showMainView:(BOOL)animated {
    if(animated) {
        if([NetworkConnection sharedInstance].session.length && [NetworkConnection sharedInstance].state != kIRCCloudStateConnected)
            [[NetworkConnection sharedInstance] connect:NO];

        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [UIApplication sharedApplication].statusBarHidden = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad;
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
                    self.window.backgroundColor = [UIColor textareaBackgroundColor];
                }];
            }
        }];
    } else if(self.window.rootViewController != self.slideViewController) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [UIApplication sharedApplication].statusBarHidden = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad;
            self.slideViewController.view.alpha = 1;
            [self.window.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            self.window.rootViewController = self.slideViewController;
            self.window.backgroundColor = [UIColor textareaBackgroundColor];
        }];
    }
}

-(void)showConnectionView {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped]];
    }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    _conn = [NetworkConnection sharedInstance];
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
        }
    }];
    _background_task = background_task;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for(Buffer *b in [[BuffersDataSource sharedInstance] getBuffers]) {
            if(!b.scrolledUp && [[EventsDataSource sharedInstance] highlightStateForBuffer:b.bid lastSeenEid:b.last_seen_eid type:b.type] == 0)
                [[EventsDataSource sharedInstance] pruneEventsForBuffer:b.bid maxSize:100];
        }
        [_conn serialize];
        [NSThread sleepForTimeInterval:[UIApplication sharedApplication].backgroundTimeRemaining - 60];
        if(background_task == _background_task) {
            _background_task = UIBackgroundTaskInvalid;
            if([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
                CLS_LOG(@"Background task timed out, disconnecting websocket");
                [[NetworkConnection sharedInstance] performSelectorOnMainThread:@selector(disconnect) withObject:nil waitUntilDone:NO];
                [[NetworkConnection sharedInstance] serialize];
                [NetworkConnection sync];
            }
            [application endBackgroundTask: background_task];
        }
    });
    if(self.window.rootViewController != _slideViewController && [ServersDataSource sharedInstance].count) {
        [self showMainView:NO];
        self.window.backgroundColor = [UIColor blackColor];
    }
    [[NotificationsDataSource sharedInstance] updateBadgeCount];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    _conn = [NetworkConnection sharedInstance];
    if(_backlogCompletedObserver) {
        NSLog(@"Backlog completed observer was registered, removing");
        [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
        _backlogCompletedObserver = nil;
    }
    if(_backlogFailedObserver) {
        NSLog(@"Backlog failed observer was registered, removing");
        [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
        _backlogFailedObserver = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(_conn.reconnectTimestamp == 0)
        _conn.reconnectTimestamp = -1;
    
    if(_conn.session.length && _conn.state != kIRCCloudStateConnected && _conn.state != kIRCCloudStateConnecting)
        [_conn connect:NO];
    else if(_conn.notifier)
        _conn.notifier = NO;
    
    if(_movedToBackground) {
        _movedToBackground = NO;
        if([ColorFormatter shouldClearFontCache]) {
            [ColorFormatter clearFontCache];
            [[EventsDataSource sharedInstance] clearFormattingCache];
            [ColorFormatter loadFonts];
        }
        _conn.reconnectTimestamp = -1;
        if([self.window.rootViewController isKindOfClass:[ECSlidingViewController class]]) {
            ECSlidingViewController *evc = (ECSlidingViewController *)self.window.rootViewController;
            [evc.topViewController viewWillAppear:NO];
        } else {
            [self.window.rootViewController viewWillAppear:NO];
        }
        if(_background_task != UIBackgroundTaskInvalid) {
            [application endBackgroundTask:_background_task];
            _background_task = UIBackgroundTaskInvalid;
        }
    }
    [[NotificationsDataSource sharedInstance] clear];
    [[NotificationsDataSource sharedInstance] updateBadgeCount];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    CLS_LOG(@"Application terminating, disconnecting websocket");
    [_conn disconnect];
    [_conn serialize];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    NSURLSessionConfiguration *config;
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 8) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        config = [NSURLSessionConfiguration backgroundSessionConfiguration:identifier];
#pragma GCC diagnostic pop
    } else {
        config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
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
    _conn = [NetworkConnection sharedInstance];
    NSData *response = [NSData dataWithContentsOfURL:location];
    if(session.configuration.identifier && [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
#ifdef ENTERPRISE
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
        NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
        NSMutableDictionary *uploadtasks = [[d dictionaryForKey:@"uploadtasks"] mutableCopy];
        NSDictionary *dict = [uploadtasks objectForKey:session.configuration.identifier];
        [uploadtasks removeObjectForKey:session.configuration.identifier];
        [d setObject:uploadtasks forKey:@"uploadtasks"];
        [d synchronize];
        
        NSDictionary *r = [[[SBJsonParser alloc] init] objectWithData:response];
        if(!r) {
            CLS_LOG(@"Invalid JSON response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        } else if([[r objectForKey:@"success"] intValue] == 1) {
            if([[dict objectForKey:@"service"] isEqualToString:@"irccloud"]) {
                _IRCEventObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudEventNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
                    Buffer *b = nil;
                    IRCCloudJSONObject *o = nil;
                    kIRCEvent event = [[n.userInfo objectForKey:kIRCCloudEventKey] intValue];
                    switch(event) {
                        case kIRCEventSuccess:
                            o = n.object;
                            if(_finalizeUploadReqid && [[o objectForKey:@"_reqid"] intValue] == _finalizeUploadReqid) {
                                CLS_LOG(@"IRCCloud upload successful");
                                b = [[BuffersDataSource sharedInstance] getBuffer:[[dict objectForKey:@"bid"] intValue]];
                                if(b) {
                                    NSString *msg = [dict objectForKey:@"msg"];
                                    if(msg.length)
                                        msg = [msg stringByAppendingString:@" "];
                                    else
                                        msg = @"";
                                    msg = [msg stringByAppendingFormat:@"%@", [[o objectForKey:@"file"] objectForKey:@"url"]];
                                    [[NetworkConnection sharedInstance] say:msg to:b.name cid:b.cid];
                                    [self.mainViewController fileUploadDidFinish];
                                    [[NSNotificationCenter defaultCenter] removeObserver:_IRCEventObserver];
                                    UILocalNotification *alert = [[UILocalNotification alloc] init];
                                    alert.fireDate = [NSDate date];
                                    alert.userInfo = @{@"d":@[@(b.cid), @(b.bid), @(-1)]};
                                    [[UIApplication sharedApplication] scheduleLocalNotification:alert];
                                    AudioServicesPlaySystemSound(1001);
                                    if(imageUploadCompletionHandler)
                                        imageUploadCompletionHandler();
                                    if([UIApplication sharedApplication].applicationState != UIApplicationStateActive && _background_task == UIBackgroundTaskInvalid) {
                                        CLS_LOG(@"background transfer session successfully completed, disconnecting websocket");
                                        [_conn disconnect];
                                    }
                                }
                            }
                            break;
                        case kIRCEventFailureMsg:
                            o = n.object;
                            if(_finalizeUploadReqid && [[o objectForKey:@"_reqid"] intValue] == _finalizeUploadReqid) {
                                CLS_LOG(@"IRCCloud upload failed");
                                [self.mainViewController fileUploadDidFail];
                                [[NSNotificationCenter defaultCenter] removeObserver:_IRCEventObserver];
                                UILocalNotification *alert = [[UILocalNotification alloc] init];
                                alert.fireDate = [NSDate date];
                                alert.alertBody = @"Unable to share image. Please try again shortly.";
                                [[UIApplication sharedApplication] scheduleLocalNotification:alert];
                                if(imageUploadCompletionHandler)
                                    imageUploadCompletionHandler();
                                if([UIApplication sharedApplication].applicationState != UIApplicationStateActive && _background_task == UIBackgroundTaskInvalid) {
                                    CLS_LOG(@"background transfer session failed, disconnecting websocket");
                                    [_conn disconnect];
                                }
                            }
                            break;
                        default:
                            break;
                    }
                }];
                
                if(_conn.state != kIRCCloudStateConnected) {
                    [[NSNotificationCenter defaultCenter] removeObserver:self];
                    _backlogCompletedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogCompletedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
                        [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
                        [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
                        NSLog(@"Finalizing IRCCloud upload");
                        _finalizeUploadReqid = [[NetworkConnection sharedInstance] finalizeUpload:[r objectForKey:@"id"] filename:[dict objectForKey:@"filename"] originalFilename:[dict objectForKey:@"original_filename"]];
                    }];
                    _backlogFailedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogFailedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
                        [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
                        [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
                        if([UIApplication sharedApplication].applicationState != UIApplicationStateActive && _background_task == UIBackgroundTaskInvalid) {
                            CLS_LOG(@"Backlog failed during background transfer callback, disconnecting websocket");
                            [_conn disconnect];
                        }
                    }];
                    CLS_LOG(@"Connecting websocket for background transfer callback");
                    [_conn connect:YES];
                } else {
                    CLS_LOG(@"Finalizing IRCCloud upload");
                    _finalizeUploadReqid = [[NetworkConnection sharedInstance] finalizeUpload:[r objectForKey:@"id"] filename:[dict objectForKey:@"filename"] originalFilename:[dict objectForKey:@"original_filename"]];
                }
            } else if([[dict objectForKey:@"service"] isEqualToString:@"imgur"]) {
                NSString *link = [[[r objectForKey:@"data"] objectForKey:@"link"] stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
                
                if([dict objectForKey:@"msg"]) {
                    if(_conn.state != kIRCCloudStateConnected) {
                        [[NSNotificationCenter defaultCenter] removeObserver:self];
                        _backlogCompletedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogCompletedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
                            [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
                            Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[dict objectForKey:@"bid"] intValue]];
                            [_conn say:[NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"msg"],link] to:b.name cid:b.cid];
                            UILocalNotification *alert = [[UILocalNotification alloc] init];
                            alert.fireDate = [NSDate date];
                            alert.userInfo = @{@"d":@[@(b.cid), @(b.bid), @(-1)]};
                            [[UIApplication sharedApplication] scheduleLocalNotification:alert];
                            AudioServicesPlaySystemSound(1001);
                            if(imageUploadCompletionHandler)
                                imageUploadCompletionHandler();
                            if([UIApplication sharedApplication].applicationState != UIApplicationStateActive && _background_task == UIBackgroundTaskInvalid) {
                                CLS_LOG(@"Backlog completed during background transfer callback, disconnecting websocket");
                                [_conn disconnect];
                            }
                        }];
                        _backlogFailedObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kIRCCloudBacklogFailedNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *n) {
                            [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
                            UILocalNotification *alert = [[UILocalNotification alloc] init];
                            alert.fireDate = [NSDate date];
                            alert.alertBody = @"Unable to share image. Please try again shortly.";
                            [[UIApplication sharedApplication] scheduleLocalNotification:alert];
                            if(imageUploadCompletionHandler)
                                imageUploadCompletionHandler();
                            if([UIApplication sharedApplication].applicationState != UIApplicationStateActive && _background_task == UIBackgroundTaskInvalid) {
                                CLS_LOG(@"Backlog failed during background transfer callback, disconnecting websocket");
                                [_conn disconnect];
                            }
                        }];
                        [_conn connect:YES];
                    } else {
                        Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[dict objectForKey:@"bid"] intValue]];
                        [_conn say:[NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"msg"],link] to:b.name cid:b.cid];
                        UILocalNotification *alert = [[UILocalNotification alloc] init];
                        alert.fireDate = [NSDate date];
                        alert.userInfo = @{@"d":@[@(b.cid), @(b.bid), @(-1)]};
                        [[UIApplication sharedApplication] scheduleLocalNotification:alert];
                        AudioServicesPlaySystemSound(1001);
                        if(imageUploadCompletionHandler)
                            imageUploadCompletionHandler();
                    }
                } else {
                    if([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
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
                        [[UIApplication sharedApplication] scheduleLocalNotification:alert];
                    }
                    if(imageUploadCompletionHandler)
                        imageUploadCompletionHandler();
                }
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if(error) {
        CLS_LOG(@"Download error: %@", error);
        UILocalNotification *alert = [[UILocalNotification alloc] init];
        alert.fireDate = [NSDate date];
        alert.alertBody = @"Unable to share image. Please try again shortly.";
        alert.soundName = @"a.caf";
        [[UIApplication sharedApplication] scheduleLocalNotification:alert];
    }
    [session finishTasksAndInvalidate];
}

@end
