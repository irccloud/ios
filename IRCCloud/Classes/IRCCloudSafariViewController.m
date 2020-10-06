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
#import "OpenInFirefoxControllerObjC.h"
#import "IRCCloudSafariViewController.h"
#import "ARChromeActivity.h"
#import "TUSafariActivity.h"
#import "AppDelegate.h"
#import "MainViewController.h"
#import "UIColor+IRCCloud.h"

@implementation IRCCloudSafariViewController

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    NSMutableArray *items = @[
             [UIPreviewAction actionWithTitle:@"Copy URL" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                 UIPasteboard *pb = [UIPasteboard generalPasteboard];
                 [pb setValue:self->_url.absoluteString forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
             }],
             [UIPreviewAction actionWithTitle:@"Share" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                 UIApplication *app = [UIApplication sharedApplication];
                 AppDelegate *appDelegate = (AppDelegate *)app.delegate;
                 MainViewController *mainViewController = [appDelegate mainViewController];

                 [UIColor clearTheme];
                 UIActivityViewController *activityController = [URLHandler activityControllerForItems:@[self->_url] type:@"URL"];
                 activityController.popoverPresentationController.sourceView = mainViewController.slidingViewController.view;
                 [mainViewController.slidingViewController presentViewController:activityController animated:YES completion:nil];
             }]
     ].mutableCopy;
    
    [items addObject:[UIPreviewAction actionWithTitle:@"Open in Browser" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
        if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Chrome"] && [[OpenInChromeController sharedInstance] openInChrome:self->_url
                                              withCallbackURL:[NSURL URLWithString:
#ifdef ENTERPRISE
                                                               @"irccloud-enterprise://"
#else
                                                               @"irccloud://"
#endif
                                                               ]
                                                 createNewTab:NO])
            return;
        else if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Firefox"] && [[OpenInFirefoxControllerObjC sharedInstance] openInFirefox:self->_url])
            return;
        else
            [[UIApplication sharedApplication] openURL:self->_url options:@{UIApplicationOpenURLOptionUniversalLinksOnly:@NO} completionHandler:nil];
    }]
];
    
    return items;
}

-(instancetype)initWithURL:(NSURL *)URL {
    self = [super initWithURL:URL];
    if(self) {
        self->_url = URL;
    }
    return self;
}
@end
