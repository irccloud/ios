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

#import <SafariServices/SafariServices.h>
#import <Fabric/Fabric.h>
#import <AdSupport/AdSupport.h>
#import <Intents/Intents.h>
#import "AppDelegate.h"
#import "NetworkConnection.h"
#import "EditConnectionViewController.h"
#import "UIColor+IRCCloud.h"
#import "ColorFormatter.h"
#import "config.h"
#import "URLHandler.h"
#import "UIDevice+UIDevice_iPhone6Hax.h"
#import "AvatarsDataSource.h"
#import "ImageCache.h"
#import "LogExportsTableViewController.h"
#import "ImageViewController.h"

#ifdef DEBUG
@implementation NSURLRequest(CertificateHack)
+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host {
    return YES;
}
@end
#endif

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
#ifndef DEBUG
#ifdef ENTERPRISE
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.enterprise.share"];
#else
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.share"];
#endif
    if(sharedcontainer) {
        NSURL *logfile = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:@"log.txt"];

        freopen([logfile.path cStringUsingEncoding:NSASCIIStringEncoding],"w+",stderr);
    }
#endif
#ifdef CRASHLYTICS_TOKEN
    [Fabric with:@[CrashlyticsKit]];
#endif
    if (@available(iOS 10, *)) {
        UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
        center.delegate = self;
        UNTextInputNotificationAction *replyAction = [UNTextInputNotificationAction actionWithIdentifier:@"reply" title:@"Reply" options:UNNotificationActionOptionAuthenticationRequired textInputButtonTitle:@"Send" textInputPlaceholder:@""];
        
        UNNotificationAction *joinAction = [UNNotificationAction actionWithIdentifier:@"join" title:@"Join" options:UNNotificationActionOptionForeground];
        UNNotificationAction *acceptAction = [UNNotificationAction actionWithIdentifier:@"accept" title:@"Accept" options:UNNotificationActionOptionNone];
        UNNotificationAction *retryAction = [UNNotificationAction actionWithIdentifier:@"retry" title:@"Retry" options:UNNotificationActionOptionNone];

        [center setNotificationCategories:[NSSet setWithObjects:
                                           [UNNotificationCategory categoryWithIdentifier:@"buffer_msg" actions:@[replyAction] intentIdentifiers:@[INSendMessageIntentIdentifier] options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"buffer_me_msg" actions:@[replyAction] intentIdentifiers:@[INSendMessageIntentIdentifier] options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"channel_invite" actions:@[joinAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"callerid" actions:@[acceptAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone],
                                           [UNNotificationCategory categoryWithIdentifier:@"retry" actions:@[retryAction] intentIdentifiers:@[] options:UNNotificationCategoryOptionNone],
                                           nil]];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    NSURL *caches = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:[[NSBundle mainBundle] bundleIdentifier]];
    [[NSFileManager defaultManager] removeItemAtURL:caches error:nil];
    
    if(@available(iOS 10, *)) {
#ifdef ENTERPRISE
        NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.enterprise.share"];
#else
        NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.share"];
#endif
        sharedcontainer = [sharedcontainer URLByAppendingPathComponent:@"attachments/"];
        [[NSFileManager defaultManager] removeItemAtURL:sharedcontainer error:nil];
    }
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{@"bgTimeout":@(30), @"autoCaps":@(YES), @"host":IRCCLOUD_HOST, @"saveToCameraRoll":@(YES), @"photoSize":@(1024), @"notificationSound":@(YES), @"tabletMode":@(YES), @"imageService":@"IRCCloud", @"uploadsAvailable":@(NO), @"browser":[SFSafariViewController class]?@"IRCCloud":@"Safari", @"warnBeforeLaunchingBrowser":@(NO), @"imageViewer":@(YES), @"videoViewer":@(YES), @"inlineWifiOnly":@(NO), @"iCloudLogs":@(NO), @"clearFormattingAfterSending":@(YES), @"backgroundUploads":@(YES)}];
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
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"useChrome"]) {
        CLS_LOG(@"Migrating browser setting");
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"])
            [[NSUserDefaults standardUserDefaults] setObject:@"Chrome" forKey:@"browser"];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"useChrome"];
    }
    
    _conn = [NetworkConnection sharedInstance];
#ifdef DEBUG
    if([[NSProcessInfo processInfo].arguments containsObject:@"-ui_testing"]) {
        [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
        
        IRCCLOUD_HOST = @"MOCK.HOST";
        IRCCLOUD_PATH = @"/";
        [NetworkConnection sharedInstance].mock = YES;
        if([[NSProcessInfo processInfo].arguments containsObject:@"-mono"])
            [NetworkConnection sharedInstance].userInfo = @{@"last_selected_bid":@(5), @"prefs":@"{\"font\":\"mono\"}"};
        else
            [NetworkConnection sharedInstance].userInfo = @{@"last_selected_bid":@(5)};
        
        [[ServersDataSource sharedInstance] clear];
        Server *s = [[Server alloc] init];
        s.cid = 1;
        s.name = @"Widgets Ltd.";
        s.hostname = @"irc.example.com";
        s.port = 6697;
        s.ssl = 1;
        s.status = @"connected_ready";
        s.fail_info = @{};
        [[ServersDataSource sharedInstance] addServer:s];
        
        [[BuffersDataSource sharedInstance] clear];
        Buffer *b = [[Buffer alloc] init];
        b.cid = 1;
        b.bid = 1;
        b.name = @"*";
        b.type = @"console";
        [[BuffersDataSource sharedInstance] addBuffer:b];
        b = [[Buffer alloc] init];
        b.cid = 1;
        b.bid = 2;
        b.name = @"#design";
        b.type = @"channel";
        [[BuffersDataSource sharedInstance] addBuffer:b];
        b = [[Buffer alloc] init];
        b.cid = 1;
        b.bid = 3;
        b.name = @"#engineering";
        b.type = @"channel";
        [[BuffersDataSource sharedInstance] addBuffer:b];
        b = [[Buffer alloc] init];
        b.cid = 1;
        b.bid = 4;
        b.name = @"#general";
        b.type = @"channel";
        [[BuffersDataSource sharedInstance] addBuffer:b];
        b = [[Buffer alloc] init];
        b.cid = 1;
        b.bid = 5;
        b.name = @"#numb3rs";
        b.type = @"channel";
        b.last_seen_eid = 1467301343923062.000000;
        [[BuffersDataSource sharedInstance] addBuffer:b];
        b = [[Buffer alloc] init];
        b.cid = 1;
        b.bid = 6;
        b.name = @"Charlie";
        b.type = @"conversation";
        [[BuffersDataSource sharedInstance] addBuffer:b];
        
        [[ChannelsDataSource sharedInstance] clear];
        Channel *c = [[Channel alloc] init];
        c.cid = 1;
        c.bid = 2;
        c.name = @"#design";
        [[ChannelsDataSource sharedInstance] addChannel:c];
        c = [[Channel alloc] init];
        c.cid = 1;
        c.bid = 3;
        c.name = @"#engineering";
        [[ChannelsDataSource sharedInstance] addChannel:c];
        c = [[Channel alloc] init];
        c.cid = 1;
        c.bid = 4;
        c.name = @"#general";
        [[ChannelsDataSource sharedInstance] addChannel:c];
        c = [[Channel alloc] init];
        c.cid = 1;
        c.bid = 5;
        c.name = @"#numb3rs";
        c.topic_text = @"Everything is numbers";
        [[ChannelsDataSource sharedInstance] addChannel:c];
        
        [[UsersDataSource sharedInstance] clear];
        User *u = [[User alloc] init];
        u.cid = 1;
        u.bid = 5;
        u.nick = @"Amita";
        u.hostmask = @"amita@ealing.irccloud.com";
        u.mode = @"o";
        [[UsersDataSource sharedInstance] addUser:u];
        u = [[User alloc] init];
        u.cid = 1;
        u.bid = 5;
        u.nick = @"Charlie";
        u.hostmask = @"charlie@brockwell.irccloud.com";
        u.mode = @"";
        [[UsersDataSource sharedInstance] addUser:u];
        u = [[User alloc] init];
        u.cid = 1;
        u.bid = 5;
        u.nick = @"Don";
        u.hostmask = @"don@highgate.irccloud.com";
        u.mode = @"";
        [[UsersDataSource sharedInstance] addUser:u];
        
        [[EventsDataSource sharedInstance] clear];
        EventsDataSource *events = [EventsDataSource sharedInstance];
        Event *e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467300962668479.000000; e.type = @"you_joined_channel"; e.from = nil; e.msg = nil; e.nick = @"Amita"; e.hostmask = @"amita@ealing.irccloud.com"; e.isSelf = 1;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467300962814164.000000; e.type = @"user_channel_mode"; e.from = @"IRCCloud"; e.msg = nil; e.nick = @"Amita"; e.targetMode = @"o"; e.chan = @"#numb3rs"; e.isSelf = 0; e.ops = @{@"add":@[@{@"mode":@"o", @"param":@"Amita"}]};
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467300963753806.000000; e.type = @"channel_mode_is"; e.from = @""; e.msg = [NSString stringWithFormat:@"Channel mode is: %c+n%c", BOLD, BOLD]; e.isSelf = 0;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467301058838532.000000; e.type = @"joined_channel"; e.from = nil; e.msg = nil; e.nick = @"Charlie"; e.hostmask = @"charlie@brockwell.irccloud.com"; e.isSelf = 0;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467301079726432.000000; e.type = @"buffer_msg"; e.from = @"Amita"; e.fromMode = @"o"; e.msg = @"I can try to decode it but it could take days"; e.isSelf = 1;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467301093741476.000000; e.type = @"buffer_msg"; e.from = @"Charlie"; e.msg = @"And still no sign of Felgenbaum trying to attack Augie's site"; e.isSelf = 0;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467301111415829.000000; e.type = @"buffer_msg"; e.from = @"Amita"; e.fromMode = @"o"; e.msg = @"No. And Tal Felgenbaum is easily as good a hacker as Augie."; e.isSelf = 1;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467301120089245.000000; e.type = @"joined_channel"; e.from = nil; e.msg = nil; e.nick = @"Don"; e.hostmask = @"don@highgate.irccloud.com"; e.isSelf = 0;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467301136888600.000000; e.type = @"buffer_msg"; e.from = @"Charlie"; e.msg = @"He's probably trying to decode the backdoor too"; e.isSelf = 0;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467301155906677.000000; e.type = @"buffer_msg"; e.from = @"Don"; e.msg = @"You know, what if he's not trying to hack Augie, he's just trying to find him?"; e.isSelf = 0;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467301177623729.000000; e.type = @"buffer_msg"; e.from = @"Amita"; e.fromMode = @"o"; e.msg = @"IRC! Internet Relay Chat. It's how hackers talk when they don't want to be overheard."; e.isSelf = 1;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467301275771476.000000; e.type = @"buffer_msg"; e.from = @"Charlie"; e.msg = @"It's a pretty primitive chat program."; e.isSelf = 0;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467301293025280.000000; e.type = @"buffer_msg"; e.from = @"Amita"; e.fromMode = @"o"; e.msg = @"Think of it like shipping channels in the ocean."; e.isSelf = 1;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467301302890124.000000; e.type = @"buffer_msg"; e.from = @"Amita"; e.fromMode = @"o"; e.msg = @"You can't see them until a boat cuts through the water leaving a wake."; e.isSelf = 1;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467301330768637.000000; e.type = @"buffer_msg"; e.from = @"Amita"; e.fromMode = @"o"; e.msg = @"If two boats meet in the middle of the ocean to swap illegal drugs, you have to catch them in real time, otherwise there's no evidence of a meeting left behind."; e.isSelf = 1;
        [events addEvent:e];
        e = [[Event alloc] init];
        e.cid = 1; e.bid = 5; e.eid = 1467301343923062.000000; e.type = @"buffer_msg"; e.from = @"Charlie"; e.msg = @"No names, no accounts, no records of exchange."; e.isSelf = 0;
        [events addEvent:e];

    }
#endif
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [ColorFormatter loadFonts];
    [UIColor setTheme:[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]];
    [self.mainViewController applyTheme];
    [[EventsDataSource sharedInstance] reformat];
    
    if(IRCCLOUD_HOST.length < 1)
    [NetworkConnection sharedInstance].session = nil;
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
    
    self.splashViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"SplashViewController"];
    if(@available(iOS 11, *))
        self.splashViewController.view.accessibilityIgnoresInvertColors = YES;
    self.window.rootViewController = self.splashViewController;
    self.loginSplashViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"LoginSplashViewController"];
    if(@available(iOS 11, *))
        self.loginSplashViewController.view.accessibilityIgnoresInvertColors = YES;
    self.mainViewController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"MainViewController"];
    self.slideViewController = [[ECSlidingViewController alloc] init];
    self.slideViewController.view.backgroundColor = [UIColor blackColor];
    self.slideViewController.topViewController = [[UINavigationController alloc] initWithNavigationBarClass:[NavBarHax class] toolbarClass:nil];
    [((UINavigationController *)self.slideViewController.topViewController) setViewControllers:@[self.mainViewController]];
    self.slideViewController.topViewController.view.backgroundColor = [UIColor blackColor];
    if(@available(iOS 11, *))
        self.slideViewController.view.accessibilityIgnoresInvertColors = YES;
    if(launchOptions && [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        self.mainViewController.bidToOpen = [[[[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] objectForKey:@"d"] objectAtIndex:1] intValue];
        self.mainViewController.eidToOpen = [[[[launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey] objectForKey:@"d"] objectAtIndex:2] doubleValue];
    }

    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];

    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        NSString *session = [NetworkConnection sharedInstance].session;
        if(session != nil && [session length] > 0 && IRCCLOUD_HOST.length > 0) {
            //Store the session in the keychain again to update the access policy
            [NetworkConnection sharedInstance].session = session;
            self.window.backgroundColor = [UIColor textareaBackgroundColor];
            self.window.rootViewController = self.slideViewController;
        } else {
            self.window.rootViewController = self.loginSplashViewController;
        }
        
#ifdef DEBUG
        if(![[NSProcessInfo processInfo].arguments containsObject:@"-ui_testing"]) {
#endif
            [self.window addSubview:self.splashViewController.view];
            
            if([NetworkConnection sharedInstance].session.length) {
                [self.splashViewController animate:nil];
            } else {
                self.loginSplashViewController.logo.hidden = YES;
                [self.splashViewController animate:self.loginSplashViewController.logo];
            }
            
            [UIView animateWithDuration:0.25 delay:0.25 options:0 animations:^{
                self.splashViewController.view.backgroundColor = [UIColor clearColor];
            } completion:^(BOOL finished) {
                self.loginSplashViewController.logo.hidden = NO;
                [self.splashViewController.view removeFromSuperview];
            }];
#ifdef DEBUG
        }
#endif
    }];
    
    [[ImageCache sharedInstance] performSelectorInBackground:@selector(prune) withObject:nil];
    
    return YES;
}
-(BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
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
            [self showMainView:YES];
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
                                  [[NetworkConnection sharedInstance] resendVerifyEmailWithHandler:^(IRCCloudJSONObject *result) {
                                      if([result objectForKey:@"success"]) {
                                          UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmation Sent" message:@"You should shortly receive an email with a link to confirm your address." preferredStyle:UIAlertControllerStyleAlert];
                                          [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil]];
                                          [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                                      } else {
                                          UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Confirmation Failed" message:[NSString stringWithFormat:@"Unable to send confirmation message: %@.  Please try again shortly.", [result objectForKey:@"message"]] preferredStyle:UIAlertControllerStyleAlert];
                                          [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:nil]];
                                          [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                                      }
                                  }];
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
            } else if([userActivity.webpageURL.path hasPrefix:@"/pastebin/"]) {
                [self launchURL:[NSURL URLWithString:[NSString stringWithFormat:@"irccloud-paste-https://%@%@",userActivity.webpageURL.host,userActivity.webpageURL.path]]];
            } else if([userActivity.webpageURL.path hasPrefix:@"/irc/"]) {
                int bid = [URLHandler URLtoBID:userActivity.webpageURL];
                if(bid) {
                    [self.mainViewController bufferSelected:bid];
                    [self showMainView:YES];
                }
            } else if([userActivity.webpageURL.path hasPrefix:@"/log-export/"]) {
                [self showMainView:YES];
                [self.mainViewController launchURL:userActivity.webpageURL];
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

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self application:application didReceiveRemoteNotification:[notification.userInfo objectForKey:@"userInfo"]];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    if([userInfo objectForKey:@"view_logs"]) {
        LogExportsTableViewController *lvc = [[LogExportsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        lvc.buffer = _mainViewController.buffer;
        lvc.server = [[ServersDataSource sharedInstance] getServer:_mainViewController.buffer.cid];
        UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:lvc];
        [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
        if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && ![[UIDevice currentDevice] isBigPhone])
            nc.modalPresentationStyle = UIModalPresentationFormSheet;
        else
            nc.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self showMainView:YES];
        [_mainViewController presentViewController:nc animated:YES completion:nil];
    } else {
        if([userInfo objectForKey:@"d"]) {
            self.mainViewController.bidToOpen = [[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue];
            self.mainViewController.eidToOpen = [[[userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue];
            CLS_LOG(@"Opening BID from notification: %i", self.mainViewController.bidToOpen);
            [UIColor setTheme:[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]];
            [self.mainViewController applyTheme];
            [self.mainViewController bufferSelected:[[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue]];
            [self showMainView:YES];
        }
    }
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))handler {
    if([userInfo objectForKey:@"d"]) {
        int cid = [[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue];
        int bid = [[[userInfo objectForKey:@"d"] objectAtIndex:1] intValue];
        NSTimeInterval eid = [[[userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue];
        
        if(application.applicationState == UIApplicationStateBackground && (!_conn || (_conn.state != kIRCCloudStateConnected && _conn.state != kIRCCloudStateConnecting))) {
            [[NotificationsDataSource sharedInstance] notify:nil category:nil cid:cid bid:bid eid:eid];
        }
        
        if(_movedToBackground && application.applicationState == UIApplicationStateInactive) {
            self.mainViewController.bidToOpen = bid;
            self.mainViewController.eidToOpen = eid;
            CLS_LOG(@"Opening BID from notification: %i", self.mainViewController.bidToOpen);
            [UIColor setTheme:[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]];
            [self.mainViewController applyTheme];
            [self.mainViewController bufferSelected:bid];
            [self showMainView:YES];
        } else if(application.applicationState == UIApplicationStateBackground && (!_conn || (_conn.state != kIRCCloudStateConnected && _conn.state != kIRCCloudStateConnecting))) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                CLS_LOG(@"Preloading backlog for bid%i from notification", bid);
                [[NetworkConnection sharedInstance] requestBacklogForBuffer:bid server:cid completion:^(BOOL success) {
                    [self.mainViewController refresh];
                    [[NotificationsDataSource sharedInstance] updateBadgeCount];
                    if(success) {
                        CLS_LOG(@"Backlog download completed for bid%i", bid);
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [[NetworkConnection sharedInstance] serialize];
                            handler(UIBackgroundFetchResultNewData);
                        });
                    } else {
                        CLS_LOG(@"Backlog download failed for bid%i", bid);
                        handler(UIBackgroundFetchResultFailed);
                    }
                }];
            });
        } else {
            handler(UIBackgroundFetchResultNoData);
        }
    } else if ([userInfo objectForKey:@"hb"] && application.applicationState == UIApplicationStateBackground) {
        CLS_LOG(@"APNS Heartbeat: %@", userInfo);
        for(NSString *key in [userInfo objectForKey:@"hb"]) {
            NSDictionary *bids = [[userInfo objectForKey:@"hb"] objectForKey:key];
            for(NSString *bid in bids.allKeys) {
                NSTimeInterval eid = [[bids objectForKey:bid] doubleValue];
                CLS_LOG(@"Setting bid %i last_seen_eid to %f", bid.intValue, eid);
                [[BuffersDataSource sharedInstance] updateLastSeenEID:eid buffer:bid.intValue];
                [[NotificationsDataSource sharedInstance] removeNotificationsForBID:bid.intValue olderThan:eid];
            }
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NetworkConnection sharedInstance] serialize];
            handler(UIBackgroundFetchResultNoData);
        });
    } else {
        handler(UIBackgroundFetchResultNoData);
    }
    [[NotificationsDataSource sharedInstance] updateBadgeCount];
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    if([notification.request.content.userInfo objectForKey:@"d"]) {
        int bid = [[[notification.request.content.userInfo objectForKey:@"d"] objectAtIndex:1] intValue];
        NSTimeInterval eid = [[[notification.request.content.userInfo objectForKey:@"d"] objectAtIndex:2] doubleValue];
        Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:bid];
        if(_mainViewController.buffer.bid != bid && eid > b.last_seen_eid) {
            completionHandler(UNNotificationPresentationOptionAlert + UNNotificationPresentationOptionSound);
            return;
        }
    } else if([notification.request.content.userInfo objectForKey:@"view_logs"]) {
        if([UIApplication sharedApplication].applicationState == UIApplicationStateActive && [_mainViewController.presentedViewController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)_mainViewController.presentedViewController).topViewController isKindOfClass:[LogExportsTableViewController class]])
            completionHandler(UNNotificationPresentationOptionNone);
        else
            completionHandler(UNNotificationPresentationOptionAlert + UNNotificationPresentationOptionSound);
    }
    completionHandler(UNNotificationPresentationOptionNone);
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    [UIColor setTheme:[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]];
    [self.mainViewController applyTheme];
    if([response isKindOfClass:[UNTextInputNotificationResponse class]]) {
        [self handleAction:response.actionIdentifier userInfo:response.notification.request.content.userInfo response:((UNTextInputNotificationResponse *)response).userText completionHandler:completionHandler];
    } else if([response.actionIdentifier isEqualToString:UNNotificationDefaultActionIdentifier]) {
        [self application:[UIApplication sharedApplication] didReceiveRemoteNotification:response.notification.request.content.userInfo];
        completionHandler();
    } else {
        [self handleAction:response.actionIdentifier userInfo:response.notification.request.content.userInfo response:nil completionHandler:completionHandler];
    }
}

-(void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler {
    [self handleAction:[notification.userInfo objectForKey:@"identifier"] userInfo:[notification.userInfo objectForKey:@"userInfo"] response:[[notification.userInfo objectForKey:@"responseInfo"] objectForKey:UIUserNotificationActionResponseTypedTextKey] completionHandler:completionHandler];
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler {
    [self handleAction:identifier userInfo:userInfo response:[responseInfo objectForKey:UIUserNotificationActionResponseTypedTextKey] completionHandler:completionHandler];
}

-(void)handleAction:(NSString *)identifier userInfo:(NSDictionary *)userInfo response:(NSString *)response completionHandler:(void (^)())completionHandler {
    NSDictionary *result;
    
    if([identifier isEqualToString:@"reply"]) {
        result = [[NetworkConnection sharedInstance] POSTsay:response
                                                          to:[[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:[[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-key"] hasSuffix:@"CH"]?2:0]
                                                 cid:[[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue]];
    } else if([identifier isEqualToString:@"join"]) {
        result = [[NetworkConnection sharedInstance] POSTsay:[NSString stringWithFormat:@"/join %@", [[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:1]]
                                                  to:@""
                                                 cid:[[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue]];
    } else if([identifier isEqualToString:@"accept"]) {
        result = [[NetworkConnection sharedInstance] POSTsay:[NSString stringWithFormat:@"/accept %@", [[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:0]]
                                                  to:@""
                                                 cid:[[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue]];
    }

    if([[result objectForKey:@"success"] intValue] == 1) {
        if([identifier isEqualToString:@"reply"]) {
            AudioServicesPlaySystemSound(1001);
        } else if([identifier isEqualToString:@"join"]) {
            Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:[[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:1] server:[[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue]];
            if(b) {
                [self.mainViewController bufferSelected:b.bid];
            } else {
                self.mainViewController.cidToOpen = [[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue];
                self.mainViewController.bufferToOpen = [[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:1];
            }
            [self showMainView:YES];
        }
    } else {
        CLS_LOG(@"Failed: %@ %@", identifier, result);
        UILocalNotification *alert = [[UILocalNotification alloc] init];
        alert.fireDate = [NSDate date];
        if([identifier isEqualToString:@"reply"]) {
            Buffer *b = [[BuffersDataSource sharedInstance] getBufferWithName:[[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:0] server:[[[userInfo objectForKey:@"d"] objectAtIndex:0] intValue]];
            if(b)
                b.draft = response;
            alert.alertBody = [NSString stringWithFormat:@"Failed to send message to %@", [[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:0]];
        } else if([identifier isEqualToString:@"join"]) {
            alert.alertBody = [NSString stringWithFormat:@"Failed to join %@", [[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:1]];
        } else if([identifier isEqualToString:@"accept"]) {
            alert.alertBody = [NSString stringWithFormat:@"Failed to add %@ to accept list", [[[[userInfo objectForKey:@"aps"] objectForKey:@"alert"] objectForKey:@"loc-args"] objectAtIndex:0]];
        }
        alert.soundName = @"a.caf";
        alert.category = @"retry";
        if(response)
            alert.userInfo = @{@"identifier":identifier, @"userInfo":userInfo, @"responseInfo":@{UIUserNotificationActionResponseTypedTextKey:response}, @"d":[userInfo objectForKey:@"d"]};
        else
            alert.userInfo = @{@"identifier":identifier, @"userInfo":userInfo, @"d":[userInfo objectForKey:@"d"]};
        [[UIApplication sharedApplication] scheduleLocalNotification:alert];
    }
    
    completionHandler();
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
    if([NetworkConnection sharedInstance].session.length) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [UIColor setTheme:[[NSUserDefaults standardUserDefaults] objectForKey:@"theme"]];
        [self.mainViewController applyTheme];
        if(animated) {
            if([NetworkConnection sharedInstance].state != kIRCCloudStateConnected)
                [[NetworkConnection sharedInstance] connect:NO];

            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [UIApplication sharedApplication].statusBarHidden = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad;
                self.slideViewController.view.alpha = 1;
                if(self.window.rootViewController != self.slideViewController) {
                    if([self.window.rootViewController isKindOfClass:ImageViewController.class])
                        self.mainViewController.ignoreVisibilityChanges = YES;
                    BOOL fromLoginView = (self.window.rootViewController == self.loginSplashViewController);
                    UIView *v = self.window.rootViewController.view;
                    self.window.rootViewController = self.slideViewController;
                    [self.window insertSubview:v aboveSubview:self.window.rootViewController.view];
                    self.mainViewController.ignoreVisibilityChanges = NO;
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
            if([self.window.rootViewController isKindOfClass:ImageViewController.class])
                self.mainViewController.ignoreVisibilityChanges = YES;
            [UIApplication sharedApplication].statusBarHidden = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && [UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad;
            self.slideViewController.view.alpha = 1;
            [self.window.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            self.window.rootViewController = self.slideViewController;
            self.window.backgroundColor = [UIColor textareaBackgroundColor];
            self.mainViewController.ignoreVisibilityChanges = NO;
        }
        }];
        if(self.slideViewController.presentedViewController)
            [self.slideViewController dismissViewControllerAnimated:animated completion:nil];
    }
}

-(void)showConnectionView {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[EditConnectionViewController alloc] initWithStyle:UITableViewStyleGrouped]];
    }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
#ifndef DEBUG
#ifdef ENTERPRISE
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.enterprise.share"];
#else
    NSURL *sharedcontainer = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:@"group.com.irccloud.share"];
#endif
    if(sharedcontainer) {
        NSURL *logfile = [[[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] objectAtIndex:0] URLByAppendingPathComponent:@"log.txt"];
        
        NSDate *yesterday = [NSDate dateWithTimeIntervalSinceNow:(-60*60*24)];
        NSDate *modificationDate = nil;
        [logfile getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:nil];

        if([yesterday compare:modificationDate] == NSOrderedDescending) {
            freopen([logfile.path cStringUsingEncoding:NSASCIIStringEncoding],"w+",stderr);
        }
    }
#endif
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
    [[ImageCache sharedInstance] clearFailedURLs];
    [[ImageCache sharedInstance] performSelectorInBackground:@selector(prune) withObject:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    _conn = [NetworkConnection sharedInstance];
    CLS_LOG(@"App became active, state: %i notifier: %i movedToBackground: %i", _conn.state, _conn.notifier, _movedToBackground);
    
    if(_backlogCompletedObserver) {
        CLS_LOG(@"Backlog completed observer was registered, removing");
        [[NSNotificationCenter defaultCenter] removeObserver:_backlogCompletedObserver];
        _backlogCompletedObserver = nil;
    }
    if(_backlogFailedObserver) {
        CLS_LOG(@"Backlog failed observer was registered, removing");
        [[NSNotificationCenter defaultCenter] removeObserver:_backlogFailedObserver];
        _backlogFailedObserver = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if(_conn.reconnectTimestamp == 0)
        _conn.reconnectTimestamp = -1;
    _conn.failCount = 0;
    _conn.reachabilityValid = NO;
    if(_conn.session.length && _conn.state != kIRCCloudStateConnected && _conn.state != kIRCCloudStateConnecting)
        [_conn connect:NO];
    else if(_conn.notifier)
        _conn.notifier = NO;
    
    if(_movedToBackground) {
        _movedToBackground = NO;
        if([ColorFormatter shouldClearFontCache]) {
            [ColorFormatter clearFontCache];
            [[EventsDataSource sharedInstance] clearFormattingCache];
            [[AvatarsDataSource sharedInstance] clear];
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
    
    if(@available(iOS 10, *)) {
    } else {
        [[NotificationsDataSource sharedInstance] clear];
    }
    [[NotificationsDataSource sharedInstance] updateBadgeCount];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    CLS_LOG(@"Application terminating, disconnecting websocket");
    [_conn disconnect];
    [_conn serialize];
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    NSURLSessionConfiguration *config;
    config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
#ifdef ENTERPRISE
    config.sharedContainerIdentifier = @"group.com.irccloud.enterprise.share";
#else
    config.sharedContainerIdentifier = @"group.com.irccloud.share";
#endif
    config.HTTPCookieStorage = nil;
    config.URLCache = nil;
    config.requestCachePolicy = NSURLCacheStorageNotAllowed;
    config.discretionary = NO;
    if([identifier hasPrefix:@"com.irccloud.logs."]) {
        LogExportsTableViewController *lvc;
        
        if([_mainViewController.presentedViewController isKindOfClass:[UINavigationController class]] && [((UINavigationController *)_mainViewController.presentedViewController).topViewController isKindOfClass:[LogExportsTableViewController class]])
            lvc = (LogExportsTableViewController *)(((UINavigationController *)_mainViewController.presentedViewController).topViewController);
        else
            lvc = [[LogExportsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        
        lvc.completionHandler = completionHandler;
        [[NSURLSession sessionWithConfiguration:config delegate:lvc delegateQueue:[NSOperationQueue mainQueue]] finishTasksAndInvalidate];
    } else if([identifier hasPrefix:@"com.irccloud.share."]) {
        [[NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]] finishTasksAndInvalidate];
        imageUploadCompletionHandler = completionHandler;
    } else {
        CLS_LOG(@"Unrecognized background task: %@", identifier);
        completionHandler();
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    _conn = [NetworkConnection sharedInstance];
    NSData *response = [NSData dataWithContentsOfURL:location];
    if(session.configuration.identifier) {
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
        
        NSDictionary *r = [NSJSONSerialization JSONObjectWithData:response options:kNilOptions error:nil];
        if(!r) {
            CLS_LOG(@"Invalid JSON response: %@", [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding]);
        } else if([[r objectForKey:@"success"] intValue] == 1) {
            if([[dict objectForKey:@"service"] isEqualToString:@"irccloud"]) {
                CLS_LOG(@"Finalizing IRCCloud upload");
                NSDictionary *o = [[NetworkConnection sharedInstance] finalizeUpload:[r objectForKey:@"id"] filename:[dict objectForKey:@"filename"] originalFilename:[dict objectForKey:@"original_filename"] avatar:[[dict objectForKey:@"avatar"] boolValue] orgId:[[dict objectForKey:@"original_filename"] intValue]];
                if([[r objectForKey:@"success"] intValue] == 1) {
                    CLS_LOG(@"IRCCloud upload successful");
                    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[dict objectForKey:@"bid"] intValue]];
                    if(b) {
                        NSString *msg = [dict objectForKey:@"msg"];
                        if(msg.length)
                            msg = [msg stringByAppendingString:@" "];
                        else
                            msg = @"";
                        msg = [msg stringByAppendingFormat:@"%@", [[o objectForKey:@"file"] objectForKey:@"url"]];
                        [[NetworkConnection sharedInstance] POSTsay:msg to:b.name cid:b.cid];
                        [self.mainViewController fileUploadDidFinish];
                        AudioServicesPlaySystemSound(1001);
                        if(imageUploadCompletionHandler)
                            imageUploadCompletionHandler();
                    }
                } else {
                    CLS_LOG(@"IRCCloud upload failed");
                    [self.mainViewController fileUploadDidFail:[o objectForKey:@"message"]];
                    [[NSNotificationCenter defaultCenter] removeObserver:_IRCEventObserver];
                    UILocalNotification *alert = [[UILocalNotification alloc] init];
                    alert.fireDate = [NSDate date];
                    if([[o objectForKey:@"message"] isEqualToString:@"upload_limit_reached"]) {
                        alert.alertBody = @"Sorry, you can’t upload more than 100 MB of files.  Delete some uploads and try again.";
                    } else if([[o objectForKey:@"message"] isEqualToString:@"upload_already_exists"]) {
                        alert.alertBody = @"You’ve already uploaded this file";
                    } else if([[o objectForKey:@"message"] isEqualToString:@"banned_content"]) {
                        alert.alertBody = @"Banned content";
                    } else {
                        alert.alertBody = @"Failed to upload file. Please try again shortly.";
                    }
                    [[UIApplication sharedApplication] scheduleLocalNotification:alert];
                    if(imageUploadCompletionHandler)
                        imageUploadCompletionHandler();
                }
            } else if([[dict objectForKey:@"service"] isEqualToString:@"imgur"]) {
                NSString *link = [[[r objectForKey:@"data"] objectForKey:@"link"] stringByReplacingOccurrencesOfString:@"http://" withString:@"https://"];
                
                if([dict objectForKey:@"msg"]) {
                    Buffer *b = [[BuffersDataSource sharedInstance] getBuffer:[[dict objectForKey:@"bid"] intValue]];
                    [[NetworkConnection sharedInstance] POSTsay:[NSString stringWithFormat:@"%@ %@",[dict objectForKey:@"msg"],link] to:b.name cid:b.cid];
                    AudioServicesPlaySystemSound(1001);
                    if(imageUploadCompletionHandler)
                        imageUploadCompletionHandler();
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
