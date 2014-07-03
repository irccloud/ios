//
//  URLHandler.m
//  IRCCloud
//
//  Created by Aditya KD on 03/07/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import "URLHandler.h"
#import "AppDelegate.h"
#import "MainViewController.h"
#import "ImageViewController.h"
#import "OpenInChromeController.h"
#import "SVWebViewController.h"

@implementation URLHandler
{
    OpenInChromeController *_openInChromeController;
    NSURL *_pendingURL;
}

#define HAS_IMAGE_SUFFIX(l) ([l hasSuffix:@"jpg"] || [l hasSuffix:@"png"] || [l hasSuffix:@"gif"])

#define IS_IMGUR(url) ([[url.host lowercaseString] isEqualToString:@"imgur.com"] && [url.path rangeOfString:@"/a/"].location == NSNotFound)

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

+ (BOOL)isImageURL:(NSURL *)url
{
    NSString *l = [url.path lowercaseString];
    // Use pre-processor macros instead of variables so conditions are still evaluated lazily
    return (HAS_IMAGE_SUFFIX(l) || IS_IMGUR(url) || IS_FLICKR(url) || IS_INSTAGRAM(url) || IS_DROPLR(url) || IS_CLOUDAPP(url));
}

- (void)launchURL:(NSURL *)url
{
    UIApplication *app = [UIApplication sharedApplication];
    AppDelegate *appDelegate = (AppDelegate *)app.delegate;
    MainViewController *mainViewController = [appDelegate mainViewController];
    
    if(appDelegate.window.rootViewController.presentedViewController) {
        [app.keyWindow.rootViewController dismissModalViewControllerAnimated:NO];
    }
    
    if([url.scheme hasPrefix:@"irc"]) {
        [mainViewController launchURL:[NSURL URLWithString:[url.description stringByReplacingOccurrencesOfString:@"#" withString:@"%23"]]];
    } else if([[self class] isImageURL:url]) {
        [self showImage:url];
    } else {
        [self openWebpage:url];
    }
}

- (void)showImage:(NSURL *)url
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        appDelegate.window.backgroundColor = [UIColor blackColor];
        appDelegate.window.rootViewController = [[ImageViewController alloc] initWithURL:url];
        [appDelegate.window insertSubview:appDelegate.slideViewController.view aboveSubview:appDelegate.window.rootViewController.view];
        [UIView animateWithDuration:0.5f animations:^{
            appDelegate.slideViewController.view.alpha = 0;
        } completion:^(BOOL finished){
            [appDelegate.slideViewController.view removeFromSuperview];
#ifdef __IPHONE_7_0
            if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)
                [UIApplication sharedApplication].statusBarHidden = YES;
#endif
        }];
    }];
}

- (void)openWebpage:(NSURL *)url
{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if(!_openInChromeController) {
        _openInChromeController = [[OpenInChromeController alloc] init];
    }
    BOOL shouldDisplayBrowser = ([[NSUserDefaults standardUserDefaults] objectForKey:@"useChrome"]
                                 || ![_openInChromeController isChromeInstalled]);
    BOOL useChrome = [[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"];
    if(shouldDisplayBrowser) {
        if(!(useChrome && [_openInChromeController openInChrome:url withCallbackURL:self.appCallbackURL createNewTab:NO])) {
            SVWebViewController *controller = [[SVWebViewController alloc] initWithURL:url];
            [appDelegate.mainViewController.navigationController pushViewController:controller animated:YES];
        }
    } else {
        [self showBrowserChooserAlertPendingURL:url];
    }
}

- (void)showBrowserChooserAlertPendingURL:(NSURL *)url
{
    _pendingURL = url;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Choose A Browser"
                                                    message:@"Would you prefer to open links in Safari or Chrome?"
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"Chrome", @"Safari", nil];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [[NSUserDefaults standardUserDefaults] setObject:@(buttonIndex == 0) forKey:@"useChrome"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self launchURL:_pendingURL];
    _pendingURL = nil;
}


@end
