//
//  URLHandler.m
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

#import <objc/message.h>
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <SafariServices/SafariServices.h>
#import "URLHandler.h"
#import "AppDelegate.h"
#import "MainViewController.h"
#import "ImageViewController.h"
#import "OpenInChromeController.h"
#import "OpenInFirefoxControllerObjC.h"
#import "PastebinViewController.h"
#import "UIColor+IRCCloud.h"
#import "config.h"
#import "ARChromeActivity.h"
#import "TUSafariActivity.h"

@interface OpenInFirefoxActivity : UIActivity

@end

@implementation OpenInFirefoxActivity {
    NSURL *_URL;
}

- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
    return @"Open in Firefox";
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"Firefox"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    if([[OpenInFirefoxControllerObjC sharedInstance] isFirefoxInstalled]) {
        for (id activityItem in activityItems) {
            if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
                return YES;
            }
        }
    }
    
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]]) {
            _URL = activityItem;
        }
    }
}

- (void)performActivity {
    BOOL completed = [[OpenInFirefoxControllerObjC sharedInstance] openInFirefox:_URL];
    
    [self activityDidFinish:completed];
}

@end


@implementation URLHandler

#define HAS_IMAGE_SUFFIX(l) ([l hasSuffix:@"jpg"] || [l hasSuffix:@"jpeg"] || [l hasSuffix:@"png"] || [l hasSuffix:@"gif"] || [l hasSuffix:@"bmp"])

#define IS_IMGUR(url) (([[url.host lowercaseString] isEqualToString:@"imgur.com"] && [url.path rangeOfString:@"/a/"].location == NSNotFound) || ([[url.host lowercaseString] isEqualToString:@"i.imgur.com"] && ([url.path hasSuffix:@".gifv"] || [url.path hasSuffix:@".webm"])))

#define IS_FLICKR(url) ([[url.host lowercaseString] hasSuffix:@"flickr.com"] && [[url.path lowercaseString] hasPrefix:@"/photos/"])

#define IS_INSTAGRAM(url) (([[url.host lowercaseString] isEqualToString:@"instagram.com"] || \
                            [[url.host lowercaseString] isEqualToString:@"instagr.am"]) \
                           && [[url.path lowercaseString] hasPrefix:@"/p/"])

#define IS_DROPLR(url) (([[url.host lowercaseString] isEqualToString:@"droplr.com"] || \
                         [[url.host lowercaseString] isEqualToString:@"d.pr"]) \
                         && [[url.path lowercaseString] hasPrefix:@"/i/"])

#define IS_CLOUDAPP(url) ([url.host.lowercaseString isEqualToString:@"cl.ly"] \
                          && url.path.length \
                          && ![url.path.lowercaseString isEqualToString:@"/robots.txt"] \
                          && ![url.path.lowercaseString isEqualToString:@"/image"])

#define IS_STEAM(url) (([url.host.lowercaseString hasSuffix:@".steampowered.com"] || [url.host.lowercaseString hasSuffix:@".steamusercontent.com"]) && [url.path.lowercaseString hasPrefix:@"/ugc/"])

#define IS_LEET(url) (([url.host.lowercaseString hasSuffix:@"leetfiles.com"] || [url.host.lowercaseString hasSuffix:@"leetfil.es"]) \
                        && [url.path.lowercaseString hasPrefix:@"/image"])

#define IS_GFYCAT(url) (([[url.host lowercaseString] isEqualToString:@"gfycat.com"] || [[url.host lowercaseString] isEqualToString:@"www.gfycat.com"]) && url.path.length > 1 && [url.path rangeOfString:@"/" options:NSBackwardsSearch].location == 0)

#define IS_GIPHY(url) ((([url.host.lowercaseString isEqualToString:@"giphy.com"] || [url.host.lowercaseString isEqualToString:@"www.giphy.com"]) && [url.path.lowercaseString hasPrefix:@"/gifs/"]) || [url.host.lowercaseString isEqualToString:@"gph.is"])

#define IS_YOUTUBE(url) ((([url.host.lowercaseString isEqualToString:@"youtube.com"] || [url.host.lowercaseString hasSuffix:@".youtube.com"]) && [url.path.lowercaseString hasPrefix:@"/watch"]) || [url.host.lowercaseString isEqualToString:@"youtu.be"])

#define IS_WIKI(url) ([url.path.lowercaseString hasPrefix:@"/wiki/"] && HAS_IMAGE_SUFFIX(url.absoluteString.lowercaseString))

+ (BOOL)isImageURL:(NSURL *)url
{
    NSString *l = [url.path lowercaseString];
    // Use pre-processor macros instead of variables so conditions are still evaluated lazily
    return ([url.scheme.lowercaseString isEqualToString:@"http"] || [url.scheme.lowercaseString isEqualToString:@"https"]) && (HAS_IMAGE_SUFFIX(l) || IS_IMGUR(url) || IS_FLICKR(url) || IS_INSTAGRAM(url) || IS_DROPLR(url) || IS_CLOUDAPP(url) || IS_STEAM(url) || IS_LEET(url) || IS_GFYCAT(url) || IS_GIPHY(url) || IS_WIKI(url));
}

+ (BOOL)isYouTubeURL:(NSURL *)url
{
    return IS_YOUTUBE(url);
}

- (void)launchURL:(NSURL *)url
{
    if([[UIApplication sharedApplication] respondsToSelector:NSSelectorFromString(@"_deactivateReachability")])
        objc_msgSend([UIApplication sharedApplication], NSSelectorFromString(@"_deactivateReachability"));
    NSLog(@"Launch: %@", url);
    UIApplication *app = [UIApplication sharedApplication];
    AppDelegate *appDelegate = (AppDelegate *)app.delegate;
    MainViewController *mainViewController = [appDelegate mainViewController];
    
    if(mainViewController.slidingViewController.presentedViewController) {
        [mainViewController.slidingViewController dismissViewControllerAnimated:NO completion:^{
            [self launchURL:url];
        }];
        return;
    }
    
    if(mainViewController.presentedViewController) {
        [mainViewController dismissViewControllerAnimated:NO completion:^{
            [self launchURL:url];
        }];
        return;
    }
    
    if([url.host hasSuffix:@"irccloud.com"] && [url.path isEqualToString:@"/invite"]) {
        int port = 6667;
        int ssl = 0;
        NSString *host;
        NSString *channel;
        for(NSString *p in [url.query componentsSeparatedByString:@"&"]) {
            NSArray *args = [p componentsSeparatedByString:@"="];
            if(args.count == 2) {
                if([args[0] isEqualToString:@"channel"])
                    channel = args[1];
                else if([args[0] isEqualToString:@"hostname"])
                    host = args[1];
                else if([args[0] isEqualToString:@"port"])
                    port = [args[1] intValue];
                else if([args[0] isEqualToString:@"ssl"])
                    ssl = [args[1] intValue];
            }
        }
        url = [NSURL URLWithString:[NSString stringWithFormat:@"irc%@://%@:%i/%@",(ssl > 0)?@"s":@"",host,port,channel]];
    }
    
    if(![url.scheme hasPrefix:@"irc"]) {
        [mainViewController dismissKeyboard];
    }
    
    if([url.scheme hasPrefix:@"irccloud-paste-"]) {
        PastebinViewController *pvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"PastebinViewController"];
        [pvc setUrl:[NSURL URLWithString:[url.absoluteString substringFromIndex:15]]];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:pvc];
            [nc.navigationBar setBackgroundImage:[UIColor navBarBackgroundImage] forBarMetrics:UIBarMetricsDefault];
            [mainViewController.slidingViewController presentViewController:nc animated:YES completion:nil];
        }];
    } else if([url.scheme hasPrefix:@"irc"]) {
        [mainViewController launchURL:[NSURL URLWithString:[url.absoluteString stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
    } else if([url.scheme isEqualToString:@"spotify"]) {
        if(![[UIApplication sharedApplication] openURL:url])
            [self launchURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://open.spotify.com/%@",[[url.absoluteString substringFromIndex:8] stringByReplacingOccurrencesOfString:@":" withString:@"/"]]]];
    } else if([url.scheme isEqualToString:@"facetime"]) {
        [self launchURL:[NSURL URLWithString:[NSString stringWithFormat:@"facetime-prompt%@",[url.absoluteString substringFromIndex:8]]]];
    } else if([url.scheme isEqualToString:@"tel"]) {
        [self launchURL:[NSURL URLWithString:[NSString stringWithFormat:@"telprompt%@",[url.absoluteString substringFromIndex:3]]]];
    } else if([[self class] isImageURL:url]) {
        [self showImage:url];
    } else if([url.pathExtension.lowercaseString isEqualToString:@"mov"] || [url.pathExtension.lowercaseString isEqualToString:@"mp4"] || [url.pathExtension.lowercaseString isEqualToString:@"m4v"] || [url.pathExtension.lowercaseString isEqualToString:@"3gp"] || [url.pathExtension.lowercaseString isEqualToString:@"quicktime"]) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        if(NSClassFromString(@"AVPlayerViewController")) {
            AVPlayerViewController *player = [[AVPlayerViewController alloc] init];
            player.player = [[AVPlayer alloc] initWithURL:url];
            [mainViewController presentViewController:player animated:YES completion:nil];
        } else {
            MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
            [mainViewController presentMoviePlayerViewControllerAnimated:player];
        }
        [Answers logContentViewWithName:nil contentType:@"Video" contentId:nil customAttributes:nil];
    } else if(IS_YOUTUBE(url)) {
        [mainViewController launchURL:url];
#ifdef FB_ACCESS_TOKEN
    } else if([url.host.lowercaseString hasSuffix:@"facebook.com"] && ([url.path.lowercaseString isEqualToString:@"/video.php"] || (url.pathComponents.count > 3 && [url.pathComponents[2] isEqualToString:@"videos"]))) {
        NSString *videoID = nil;
        
        if([url.path.lowercaseString isEqualToString:@"/video.php"]) {
            for(NSString *p in [url.query componentsSeparatedByString:@"&"]) {
                if([p hasPrefix:@"v="]) {
                    videoID = [p substringFromIndex:2];
                    break;
                } else if([p hasPrefix:@"id="]) {
                    videoID = [p substringFromIndex:3];
                    break;
                }
            }
        } else {
            videoID = url.pathComponents[3];
        }

        if(videoID) {
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://graph.facebook.com/v2.2/%@?fields=source&access_token=%s", videoID, FB_ACCESS_TOKEN]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
            [request setHTTPShouldHandleCookies:NO];
            
            [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                if (error) {
                    NSLog(@"Error fetching Facebook. Error %li : %@", (long)error.code, error.userInfo);
                    [self openWebpage:url];
                } else {
                    SBJsonParser *parser = [[SBJsonParser alloc] init];
                    NSDictionary *dict = [parser objectWithData:data];
                    
                    if([[dict objectForKey:@"source"] length]) {
                        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
                        if(NSClassFromString(@"AVPlayerViewController")) {
                            AVPlayerViewController *player = [[AVPlayerViewController alloc] init];
                            player.player = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:[dict objectForKey:@"source"]]];
                            [mainViewController presentViewController:player animated:YES completion:nil];
                        } else {
                            MPMoviePlayerViewController *player = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:[dict objectForKey:@"source"]]];
                            [mainViewController presentMoviePlayerViewControllerAnimated:player];
                        }
                        [Answers logContentViewWithName:nil contentType:@"Video" contentId:nil customAttributes:nil];
                    } else {
                        NSLog(@"Facebook failure %@", dict);
                        [self openWebpage:url];
                    }
                }
            }];
        }
#endif
    } else {
        [self openWebpage:url];
    }
}

- (void)showImage:(NSURL *)url
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    ImageViewController *ivc = [[ImageViewController alloc] initWithURL:url];
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        appDelegate.window.backgroundColor = [UIColor blackColor];
        appDelegate.window.rootViewController = ivc;
        appDelegate.slideViewController.view.frame = appDelegate.window.bounds;
        [appDelegate.window insertSubview:appDelegate.slideViewController.view belowSubview:ivc.view];
        ivc.view.alpha = 0;
        [UIView animateWithDuration:0.5f animations:^{
            appDelegate.window.rootViewController.view.alpha = 1;
        } completion:nil];
    }];
}

- (void)openWebpage:(NSURL *)url
{
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Chrome"] && [[OpenInChromeController sharedInstance] isChromeInstalled]) {
        if([[OpenInChromeController sharedInstance] openInChrome:url withCallbackURL:self.appCallbackURL createNewTab:NO])
            return;
    }
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Firefox"] && [[OpenInFirefoxControllerObjC sharedInstance] isFirefoxInstalled]) {
        if([[OpenInFirefoxControllerObjC sharedInstance] openInFirefox:url])
            return;
    }
    if(![[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Safari"] && [SFSafariViewController class] && [url.scheme hasPrefix:@"http"]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UIApplication *app = [UIApplication sharedApplication];
            AppDelegate *appDelegate = (AppDelegate *)app.delegate;
            MainViewController *mainViewController = [appDelegate mainViewController];
            [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
            [UIApplication sharedApplication].statusBarHidden = NO;
            
            [mainViewController.slidingViewController presentViewController:[[SFSafariViewController alloc] initWithURL:url] animated:YES completion:nil];
        }];
    } else {
        [[UIApplication sharedApplication] openURL:url];
    }
}

+ (UIActivityViewController *)activityControllerForItems:(NSArray *)items type:(NSString *)type {
    NSArray *activities;
    
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Chrome"] && [[OpenInChromeController sharedInstance] isChromeInstalled]) {
        activities = @[[[ARChromeActivity alloc] initWithCallbackURL:[NSURL URLWithString:
#ifdef ENTERPRISE
                                                                      @"irccloud-enterprise://"
#else
                                                                      @"irccloud://"
#endif
                                                                      ]]];
    } else if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Firefox"] && [[OpenInFirefoxControllerObjC sharedInstance] isFirefoxInstalled]) {
        activities = @[[[OpenInFirefoxActivity alloc] init]];
    } else {
        activities = @[[[TUSafariActivity alloc] init]];
    }
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:activities];
    activityController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        if(completed) {
            if([activityType hasPrefix:@"com.apple.UIKit.activity."])
                activityType = [activityType substringFromIndex:25];
            if([activityType hasPrefix:@"com.apple."])
                activityType = [activityType substringFromIndex:10];
            [Answers logShareWithMethod:activityType contentName:nil contentType:type contentId:nil customAttributes:nil];
        }
    };
    return activityController;
}

@end
