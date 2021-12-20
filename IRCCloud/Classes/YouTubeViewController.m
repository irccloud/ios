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

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <SafariServices/SafariServices.h>
#import "OpenInChromeController.h"
#import "OpenInFirefoxControllerObjC.h"
#import "YouTubeViewController.h"
#import "AppDelegate.h"
#import "MainViewController.h"
#import "UIColor+IRCCloud.h"
@import Firebase;

#define YTMARGIN 130

@implementation YouTubeViewController

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if(self) {
        self->_url = url;
    }
    return self;
}

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    return @[
             [UIPreviewAction actionWithTitle:@"Copy URL" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                 UIPasteboard *pb = [UIPasteboard generalPasteboard];
                 [pb setValue:self->_url.absoluteString forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
             }],
             [UIPreviewAction actionWithTitle:@"Share" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                 UIApplication *app = [UIApplication sharedApplication];
                 AppDelegate *appDelegate = (AppDelegate *)app.delegate;
                 MainViewController *mainViewController = [appDelegate mainViewController];
                 
                 [UIColor clearTheme];
                 UIActivityViewController *activityController = [URLHandler activityControllerForItems:@[self->_url] type:@"Youtube"];
                 activityController.popoverPresentationController.sourceView = mainViewController.slidingViewController.view;
                 [mainViewController.slidingViewController presentViewController:activityController animated:YES completion:nil];
             }],
             [UIPreviewAction actionWithTitle:@"Open in Browser" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
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
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        int margin = (size.width > size.height)?YTMARGIN:0;
        CGFloat width = self.view.bounds.size.width - margin;
        CGFloat height = (width / 16.0f) * 9.0f;
        self->_player.frame = CGRectMake(margin/2, (self.view.bounds.size.height - height) / 2.0f, width, height);
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        
    }
    ];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.9];
    self.view.autoresizesSubviews = YES;
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(_YTpanned:)];
    [self.view addGestureRecognizer:panGesture];
    
    self->_toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0,self.view.bounds.size.height - 44,self.view.bounds.size.width, 44)];
    [self->_toolbar setBackgroundImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [self->_toolbar setShadowImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny];
    [self->_toolbar setBarStyle:UIBarStyleBlack];
    self->_toolbar.translucent = YES;
    self->_toolbar.items = @[
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(_YTShare:)],
                      [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                      [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(_YTWrapperTapped)]
                      ];
    self->_toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self->_toolbar];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_YTWrapperTapped)];
    [self.view addGestureRecognizer:tap];
    
    NSString *videoID;
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params setObject:self->_url.absoluteString forKey:@"origin"];
    
    if([self->_url.host isEqualToString:@"youtu.be"]) {
        videoID = [self->_url.path substringFromIndex:1];
    }
    
    for(NSString *param in [self->_url.query componentsSeparatedByString:@"&"]) {
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
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    self->_player = [[YTPlayerView alloc] initWithFrame:CGRectMake(margin/2, (self.view.bounds.size.height - height) / 2.0f, width, height)];
    self->_player.backgroundColor = [UIColor blackColor];
    self->_player.webView.backgroundColor = [UIColor blackColor];
    self->_player.hidden = YES;
    self->_player.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    self->_player.autoresizesSubviews = YES;
    self->_player.delegate = self;
    if(videoID)
        [self->_player loadWithVideoId:videoID playerVars:params];
    else
        CLS_LOG(@"Unable to extract video ID from URL: %@", _url);
    [self.view addSubview:self->_player];
    
    self->_activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self->_activity.center = self.view.center;
    self->_activity.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    self->_activity.hidesWhenStopped = YES;
    [self->_activity startAnimating];
    [self.view addSubview:self->_activity];
    
    [FIRAnalytics logEventWithName:kFIREventViewItem parameters:@{
        kFIRParameterContentType:@"Youtube"
    }];
}

-(void)_YTWrapperTapped {
    [UIView animateWithDuration:0.25 animations:^{
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self.presentingViewController dismissViewControllerAnimated:NO completion:nil];
    }];
    [self->_activity stopAnimating];
    self->_player.delegate = nil;
    self->_player.webView.navigationDelegate = nil;
    [self->_player stopVideo];
    [self->_player.webView stopLoading];
}

-(void)_YTShare:(id)sender {
    UIActivityViewController *activityController = [URLHandler activityControllerForItems:@[self->_url] type:@"Youtube"];
    activityController.popoverPresentationController.delegate = self;
    activityController.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:activityController animated:YES completion:nil];
}

-(void)playerViewDidBecomeReady:(YTPlayerView *)playerView {
    [self->_activity stopAnimating];
    playerView.hidden = NO;
}

-(void)playerView:(YTPlayerView *)playerView receivedError:(YTPlayerError)error {
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
}

- (void)_YTpanned:(UIPanGestureRecognizer *)recognizer {
    CGRect frame = self->_player.frame;
    
    switch(recognizer.state) {
        case UIGestureRecognizerStateBegan:
            if(fabs([recognizer velocityInView:self.view].y) > fabs([recognizer velocityInView:self.view].x)) {
            }
            break;
        case UIGestureRecognizerStateCancelled: {
            frame.origin.y = 0;
            [UIView animateWithDuration:0.25 animations:^{
                self->_player.frame = frame;
            }];
            self.view.alpha = 1;
            break;
        }
        case UIGestureRecognizerStateChanged:
            frame.origin.y = (self.view.bounds.size.height - frame.size.height) / 2 + [recognizer translationInView:self.view].y;
            self->_player.frame = frame;
            self.view.alpha = 1 - (fabs([recognizer translationInView:self.view].y) / self.view.frame.size.height / 2);
            break;
        case UIGestureRecognizerStateEnded:
        {
            if(fabs([recognizer translationInView:self.view].y) > 100 || fabs([recognizer velocityInView:self.view].y) > 1000) {
                frame.origin.y = ([recognizer translationInView:self.view].y > 0)?self.view.bounds.size.height:-self.view.bounds.size.height;
                [UIView animateWithDuration:0.25 animations:^{
                    self->_player.frame = frame;
                    self.view.alpha = 0;
                } completion:^(BOOL finished) {
                    [self _YTWrapperTapped];
                }];
            } else {
                frame.origin.y = (self.view.bounds.size.height - frame.size.height) / 2;
                [UIView animateWithDuration:0.25 animations:^{
                    self->_player.frame = frame;
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
