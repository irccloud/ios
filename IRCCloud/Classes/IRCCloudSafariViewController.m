//
//  IRCCloudSafariViewController.m
//
//  Copyright (C) 2016 IRCCloud, Ltd.
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

#import <MobileCoreServices/UTCoreTypes.h>
#import <SafariServices/SafariServices.h>
#import "OpenInChromeController.h"
#import "IRCCloudSafariViewController.h"
#import "ARChromeActivity.h"
#import "TUSafariActivity.h"
#import "AppDelegate.h"
#import "MainViewController.h"

@implementation IRCCloudSafariViewController

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    return @[
             [UIPreviewAction actionWithTitle:@"Copy URL" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                 UIPasteboard *pb = [UIPasteboard generalPasteboard];
                 [pb setValue:_url forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
             }],
             [UIPreviewAction actionWithTitle:@"Share" style:UIPreviewActionStyleDestructive handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                 UIApplication *app = [UIApplication sharedApplication];
                 AppDelegate *appDelegate = (AppDelegate *)app.delegate;
                 MainViewController *mainViewController = [appDelegate mainViewController];
                 
                 UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[_url] applicationActivities:@[([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [[OpenInChromeController sharedInstance] isChromeInstalled])?[[ARChromeActivity alloc] initWithCallbackURL:[NSURL URLWithString:
#ifdef ENTERPRISE
                                                                                                                                                                                                                                                                                                                                        @"irccloud-enterprise://"
#else
                                                                                                                                                                                                                                                                                                                                        @"irccloud://"
#endif
                                                                                                                                                                                                                                                                                                                                        ]]:[[TUSafariActivity alloc] init]]];
                 activityController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
                     if(completed) {
                         if([activityType hasPrefix:@"com.apple.UIKit.activity."])
                             activityType = [activityType substringFromIndex:25];
                         if([activityType hasPrefix:@"com.apple."])
                             activityType = [activityType substringFromIndex:10];
                         [Answers logShareWithMethod:activityType contentName:nil contentType:@"Youtube" contentId:nil customAttributes:nil];
                     }
                 };
                 [mainViewController.slidingViewController presentViewController:activityController animated:YES completion:nil];
             }]
             ];
}

-(instancetype)initWithURL:(NSURL *)URL {
    self = [super initWithURL:URL];
    if(self) {
        _url = URL;
    }
    return self;
}
@end
