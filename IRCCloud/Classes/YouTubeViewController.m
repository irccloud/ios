//
//  YouTubeViewController.m
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
#import "YouTubeViewController.h"
#import "ARChromeActivity.h"
#import "TUSafariActivity.h"
#import "AppDelegate.h"
#import "MainViewController.h"

#define YTMARGIN 130

@implementation YouTubeViewController

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if(self) {
        _url = url;
    }
    return self;
}

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    return @[
             [UIPreviewAction actionWithTitle:@"Copy URL" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                 UIPasteboard *pb = [UIPasteboard generalPasteboard];
                 [pb setValue:_url.absoluteString forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
             }],
             [UIPreviewAction actionWithTitle:@"Share" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
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
             }],
             [UIPreviewAction actionWithTitle:@"Open in Browser" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                 if(!([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [[OpenInChromeController sharedInstance] openInChrome:_url
                                                                                               withCallbackURL:[NSURL URLWithString:
#ifdef ENTERPRISE
                                                                                                                @"irccloud-enterprise://"
#else
                                                                                                                @"irccloud://"
#endif
                                                                                                                ]
                                                                                                  createNewTab:NO])) {
                     if([SFSafariViewController class] && [_url.scheme hasPrefix:@"http"]) {
                         UIApplication *app = [UIApplication sharedApplication];
                         AppDelegate *appDelegate = (AppDelegate *)app.delegate;
                         MainViewController *mainViewController = [appDelegate mainViewController];
                         [mainViewController.slidingViewController presentViewController:[[SFSafariViewController alloc] initWithURL:_url] animated:YES completion:nil];
                     } else {
                         [[UIApplication sharedApplication] openURL:_url];
                     }
                 }
             }]
             ];
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    int margin = UIInterfaceOrientationIsLandscape(toInterfaceOrientation)?YTMARGIN:0;
    CGFloat width = self.view.bounds.size.width - margin;
    CGFloat height = (width / 16.0f) * 9.0f;
    _player.frame = CGRectMake(margin/2, (self.view.bounds.size.height - height) / 2.0f, width, height);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];
    self.view.autoresizesSubviews = YES;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_YTpanned:)];
    [self.view addGestureRecognizer:panGesture];
    
    _toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,self.view.bounds.size.height - 44,self.view.bounds.size.width, 44)];
    [_toolbar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [_toolbar setShadowImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny];
    [_toolbar setBarStyle:UIBarStyleBlack];
    _toolbar.translucent = YES;
    if(NSClassFromString(@"UIActivityViewController")) {
        _toolbar.items = @[
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(_YTShare:)],
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(_YTWrapperTapped)]
                          ];
    } else {
        _toolbar.items = @[
                          [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                          [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(_YTWrapperTapped)]
                          ];
    }
    _toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:_toolbar];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_YTWrapperTapped)];
    [self.view addGestureRecognizer:tap];
    
    NSString *videoID;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:_url.absoluteString forKey:@"origin"];
    
    if([_url.host isEqualToString:@"youtu.be"]) {
        videoID = [_url.path substringFromIndex:1];
    }
    
    for(NSString *param in [_url.query componentsSeparatedByString:@"&"]) {
        NSArray *kv = [param componentsSeparatedByString:@"="];
        if(kv.count == 2) {
            if([[kv objectAtIndex:0] isEqualToString:@"v"]) {
                videoID = [kv objectAtIndex:1];
            } else if([[kv objectAtIndex:0] isEqualToString:@"t"]) {
                int start = 0;
                NSString *t = [kv objectAtIndex:1];
                int number = 0;
                for(int i = 0; i < t.length; i++) {
                    switch([t characterAtIndex:i]) {
                        case '0':
                        case '1':
                        case '2':
                        case '3':
                        case '4':
                        case '5':
                        case '6':
                        case '7':
                        case '8':
                        case '9':
                            number *= 10;
                            number += [t characterAtIndex:i] - '0';
                            break;
                        case 'h':
                            start += number * 60;
                            number = 0;
                            break;
                        case 'm':
                            start += number * 60;
                            number = 0;
                            break;
                        case 's':
                            start += number;
                            number = 0;
                            break;
                        default:
                            CLS_LOG(@"Unrecognized time separator: %c", [t characterAtIndex:i]);
                            number = 0;
                            break;
                    }
                }
                start += number;
                [params setObject:@(start) forKey:@"start"];
            } else {
                [params setObject:[kv objectAtIndex:1] forKey:[kv objectAtIndex:0]];
            }
        }
    }
    
    int margin = UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)?YTMARGIN:0;
    CGFloat width = self.view.bounds.size.width - margin;
    CGFloat height = (width / 16.0f) * 9.0f;
    _player = [[YTPlayerView alloc] initWithFrame:CGRectMake(margin/2, (self.view.bounds.size.height - height) / 2.0f, width, height)];
    _player.backgroundColor = [UIColor blackColor];
    _player.webView.backgroundColor = [UIColor blackColor];
    _player.hidden = YES;
    _player.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _player.autoresizesSubviews = YES;
    _player.delegate = self;
    [_player loadWithVideoId:videoID playerVars:params];
    [self.view addSubview:_player];
    
    _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activity.center = self.view.center;
    _activity.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _activity.hidesWhenStopped = YES;
    [_activity startAnimating];
    [self.view addSubview:_activity];
    
    [Answers logContentViewWithName:nil contentType:@"Youtube" contentId:nil customAttributes:nil];
}

-(void)_YTWrapperTapped {
    [UIView animateWithDuration:0.25 animations:^{
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }];
    [_activity stopAnimating];
    [_player stopVideo];
}

-(void)_YTShare:(id)sender {
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[_url] applicationActivities:@[([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [[OpenInChromeController sharedInstance] isChromeInstalled])?[[ARChromeActivity alloc] initWithCallbackURL:[NSURL URLWithString:
#ifdef ENTERPRISE
                                                                                                                                                                                                                                                                                                                             @"irccloud-enterprise://"
#else
                                                                                                                                                                                                                                                                                                                             @"irccloud://"
#endif
                                                                                                                                                                                                                                                                                                                             ]]:[[TUSafariActivity alloc] init]]];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
        activityController.popoverPresentationController.delegate = self;
        activityController.popoverPresentationController.barButtonItem = sender;
        activityController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            if(completed) {
                if([activityType hasPrefix:@"com.apple.UIKit.activity."])
                    activityType = [activityType substringFromIndex:25];
                if([activityType hasPrefix:@"com.apple."])
                    activityType = [activityType substringFromIndex:10];
                [Answers logShareWithMethod:activityType contentName:nil contentType:@"Youtube" contentId:nil customAttributes:nil];
            }
        };
    } else {
        activityController.completionHandler = ^(NSString *activityType, BOOL completed) {
            if(completed) {
                if([activityType hasPrefix:@"com.apple.UIKit.activity."])
                    activityType = [activityType substringFromIndex:25];
                if([activityType hasPrefix:@"com.apple."])
                    activityType = [activityType substringFromIndex:10];
                [Answers logShareWithMethod:activityType contentName:nil contentType:@"Youtube" contentId:nil customAttributes:nil];
            }
        };
    }
    [self presentViewController:activityController animated:YES completion:nil];
}

-(void)playerViewDidBecomeReady:(YTPlayerView *)playerView {
    [_activity stopAnimating];
    playerView.hidden = NO;
}

-(void)playerView:(YTPlayerView *)playerView receivedError:(YTPlayerError)error {
    if(!([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [[OpenInChromeController sharedInstance] openInChrome:_url
                                                                                                                  withCallbackURL:[NSURL URLWithString:
#ifdef ENTERPRISE
                                                                                                                                   @"irccloud-enterprise://"
#else
                                                                                                                                   @"irccloud://"
#endif
                                                                                                                                   ]
                                                                                                                     createNewTab:NO]))
        [[UIApplication sharedApplication] openURL:_url];
}

- (void)_YTpanned:(UIPanGestureRecognizer *)recognizer {
    CGRect frame = _player.frame;
    
    switch(recognizer.state) {
        case UIGestureRecognizerStateBegan:
            if(fabs([recognizer velocityInView:self.view].y) > fabs([recognizer velocityInView:self.view].x)) {
            }
            break;
        case UIGestureRecognizerStateCancelled: {
            frame.origin.y = 0;
            [UIView animateWithDuration:0.25 animations:^{
                _player.frame = frame;
            }];
            self.view.alpha = 1;
            break;
        }
        case UIGestureRecognizerStateChanged:
            frame.origin.y = (self.view.bounds.size.height - frame.size.height) / 2 + [recognizer translationInView:self.view].y;
            _player.frame = frame;
            self.view.alpha = 1 - (fabs([recognizer translationInView:self.view].y) / self.view.frame.size.height / 2);
            break;
        case UIGestureRecognizerStateEnded:
        {
            if(fabs([recognizer translationInView:self.view].y) > 100 || fabs([recognizer velocityInView:self.view].y) > 1000) {
                frame.origin.y = ([recognizer translationInView:self.view].y > 0)?self.view.bounds.size.height:-self.view.bounds.size.height;
                [UIView animateWithDuration:0.25 animations:^{
                    _player.frame = frame;
                    self.view.alpha = 0;
                } completion:^(BOOL finished) {
                    [self _YTWrapperTapped];
                }];
            } else {
                frame.origin.y = (self.view.bounds.size.height - frame.size.height) / 2;
                [UIView animateWithDuration:0.25 animations:^{
                    _player.frame = frame;
                    self.view.alpha = 1;
                }];
            }
            break;
        }
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
