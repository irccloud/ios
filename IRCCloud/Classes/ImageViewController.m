//
//  ImageViewController.m
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

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <Twitter/Twitter.h>
#import <SafariServices/SafariServices.h>
#import "ImageViewController.h"
#import "AppDelegate.h"
#import "OpenInFirefoxControllerObjC.h"
#import "config.h"
#import "ImageCache.h"
#import "UIColor+IRCCloud.h"

#define HIDE_DURATION 3

@implementation ImageViewController
{
    NSMutableData *_imageData;
    long long _bytesExpected;
    long long _totalBytesReceived;
}

- (id)initWithURL:(NSURL *)url {
    self = [super initWithNibName:@"ImageViewController" bundle:nil];
    if (self) {
        self->_url = url;
        self->_chrome = [[OpenInChromeController alloc] init];
        self->_urlHandler = [[URLHandler alloc] init];
    }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    return @[
             [UIPreviewAction actionWithTitle:@"Copy URL" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                 UIPasteboard *pb = [UIPasteboard generalPasteboard];
                 [pb setValue:self->_url.absoluteString forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
             }],
             [UIPreviewAction actionWithTitle:@"Share" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                 [UIColor clearTheme];
                 UIApplication *app = [UIApplication sharedApplication];
                 AppDelegate *appDelegate = (AppDelegate *)app.delegate;
                 MainViewController *mainViewController = [appDelegate mainViewController];
                 
                 UIActivityViewController *activityController = [URLHandler activityControllerForItems:self->_imageView.image?@[self->_url,self->_imageView.image]:@[self->_url] type:self->_movieController?@"Animation":@"Image"];

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
                     [[UIApplication sharedApplication] openURL:self->_url];
             }]
             ];
}

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)inScroll {
    return _imageView;
}

-(void)transitionToSize:(CGSize)size {
    self->_scrollView.frame = CGRectMake(0,0,size.width,size.height);
    if(self->_imageView.image) {
        [self->_imageView sizeToFit];
        CGRect frame = self->_imageView.frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        self->_imageView.frame = frame;
        self->_scrollView.contentSize = self->_imageView.frame.size;
    }
    [self scrollViewDidZoom:self->_scrollView];
    
    self->_progressView.center = CGPointMake(self.view.bounds.size.width / 2.0,self.view.bounds.size.height/2.0);
    
    if(self->_movieController)
        self->_movieController.view.frame = self->_scrollView.bounds;
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self transitionToSize:size];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
    }];
}

//Some centering magic from: http://stackoverflow.com/a/2189336/1406639
-(void)scrollViewDidZoom:(UIScrollView *)pScrollView {
    if(self->_movieController)
        return;
    
    CGRect innerFrame = self->_imageView.frame;
    CGRect scrollerBounds = pScrollView.bounds;
    
    if ((innerFrame.size.width < scrollerBounds.size.width) || (innerFrame.size.height < scrollerBounds.size.height)) {
        CGFloat tempx = self->_imageView.center.x - (scrollerBounds.size.width / 2);
        CGFloat tempy = self->_imageView.center.y - (scrollerBounds.size.height / 2);
        CGPoint myScrollViewOffset = CGPointMake(tempx, tempy);
        
        pScrollView.contentOffset = myScrollViewOffset;
        
    }
    
    UIEdgeInsets anEdgeInset = { 0, 0, 0, 0};
    if(scrollerBounds.size.width > innerFrame.size.width) {
        anEdgeInset.left = (scrollerBounds.size.width - innerFrame.size.width) / 2;
        anEdgeInset.right = -anEdgeInset.left;
    }
    if(scrollerBounds.size.height > innerFrame.size.height) {
        anEdgeInset.top = (scrollerBounds.size.height - innerFrame.size.height) / 2;
        anEdgeInset.bottom = -anEdgeInset.top;
    }
    pScrollView.contentInset = anEdgeInset;
    
    if(self->_toolbar.hidden && !_previewing)
        [self _showToolbar];
    [self->_hideTimer invalidate];
    self->_hideTimer = [NSTimer scheduledTimerWithTimeInterval:HIDE_DURATION target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
    
    pScrollView.alwaysBounceHorizontal = (pScrollView.zoomScale > pScrollView.minimumZoomScale);
    pScrollView.alwaysBounceVertical = (pScrollView.zoomScale > pScrollView.minimumZoomScale);
}

-(void)_showToolbar {
    [self->_hideTimer invalidate];
    self->_hideTimer = nil;
    [UIView animateWithDuration:0.5 animations:^{
        self->_toolbar.hidden = NO;
        self->_toolbar.alpha = 1;
    } completion:nil];
}

-(void)_hideToolbar {
    [self->_hideTimer invalidate];
    self->_hideTimer = nil;
    if(self->_imageView.image != nil || _movieController != nil) {
        [UIView animateWithDuration:0.5 animations:^{
            self->_toolbar.alpha = 0;
        } completion:^(BOOL finished){
            self->_toolbar.hidden = YES;
        }];
    }
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if(!_previewing)
        [self _showToolbar];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self->_hideTimer = [NSTimer scheduledTimerWithTimeInterval:HIDE_DURATION target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
}

-(void)fail:(NSString *)error {
    [self->_progressView removeFromSuperview];

    if(self->_previewing || self.view.window.rootViewController != self) {
        NSLog(@"Not launching fallback URL as we're not the root view controller");
        return;
    }
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"warnBeforeLaunchingBrowser"]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Unable To Load Image" message:error preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Open in Browser" style:UIAlertActionStyleDefault handler:^(UIAlertAction *alert) {
            [self _openInBrowser];
        }]];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction *alert) {
            [self doneButtonPressed:alert];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        [self _showToolbar];
    } else {
        [self _openInBrowser];
    }
}

-(void)_openInBrowser {
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Chrome"] && [[OpenInChromeController sharedInstance] isChromeInstalled]) {
        if([[OpenInChromeController sharedInstance] openInChrome:self->_url withCallbackURL:[NSURL URLWithString:
#ifdef ENTERPRISE
                                                                                       @"irccloud-enterprise://"
#else
                                                                                       @"irccloud://"
#endif
                                                                                       ] createNewTab:NO])
            return;
    }
    if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Firefox"] && [[OpenInFirefoxControllerObjC sharedInstance] isFirefoxInstalled]) {
        if([[OpenInFirefoxControllerObjC sharedInstance] openInFirefox:self->_url])
            return;
    }
    if(![[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Safari"] && [SFSafariViewController class] && [self->_url.scheme hasPrefix:@"http"]) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            UIApplication *app = [UIApplication sharedApplication];
            AppDelegate *appDelegate = (AppDelegate *)app.delegate;
            MainViewController *mainViewController = [appDelegate mainViewController];
            
            [((AppDelegate *)[UIApplication sharedApplication].delegate) showMainView:NO];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
                [UIApplication sharedApplication].statusBarHidden = NO;
                
                [mainViewController.slidingViewController presentViewController:[[SFSafariViewController alloc] initWithURL:self->_url] animated:YES completion:nil];
            }];
        }];
    } else {
        [[UIApplication sharedApplication] openURL:self->_url];
    }
}

-(void)_fetchVideo:(NSURL *)url {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    self->_movieController = [[AVPlayerViewController alloc] init];
    self->_movieController.player = [[AVPlayer alloc] initWithURL:url];
    self->_movieController.showsPlaybackControls = NO;
    self->_movieController.view.userInteractionEnabled = NO;
    self->_movieController.view.frame = self->_scrollView.bounds;
    self->_movieController.view.backgroundColor = [UIColor clearColor];
    [self->_scrollView addSubview:self->_movieController.view];
    self->_scrollView.userInteractionEnabled = NO;
    [self->_scrollView removeGestureRecognizer:self->_panGesture];
    [self.view addGestureRecognizer:self->_panGesture];
    [self->_progressView removeFromSuperview];
    [self->_movieController.player play];
    if([UIApplication sharedApplication].delegate.window.rootViewController == self)
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [Answers logContentViewWithName:nil contentType:@"Animation" contentId:nil customAttributes:nil];
    [self scrollViewDidZoom:self->_scrollView];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}

-(void)load {
#ifdef DEBUG
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
#endif
    
    NSDictionary *d = [self->_urlHandler MediaURLs:self->_url];
    if(d) {
        if([d objectForKey:@"mp4_loop"]) {
            [self _fetchVideo:[d objectForKey:@"mp4_loop"]];
            self->_movieController.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                       selector:@selector(playerItemDidReachEnd:)
                                                           name:AVPlayerItemDidPlayToEndTimeNotification
                                                         object:[self->_movieController.player currentItem]];
        } else if([d objectForKey:@"mp4"]) {
            [self _fetchVideo:[d objectForKey:@"mp4"]];
        } else if([d objectForKey:@"image"]) {
            [self _fetchImage:[d objectForKey:@"image"]];
        } else {
            [self fail:@"Unsupported media type"];
        }
    } else {
        [self->_urlHandler fetchMediaURLs:self->_url result:^(BOOL success, NSString *error) {
            if(success)
                [self load];
            else
                [self fail:error];
        }];
    }
}

- (void)_fetchImage:(NSURL *)url {
    CLS_LOG(@"Fetching image: %@", url);
    NSString *cacheFile = [[ImageCache sharedInstance] pathForURL:url].path;
    if([[NSFileManager defaultManager] fileExistsAtPath:cacheFile]) {
        self->_imageData = [[NSData alloc] initWithContentsOfFile:cacheFile].mutableCopy;
        [self _parseImageData:self->_imageData];
    } else {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        self->_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
        
        [self->_connection start];
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response {
    self->_bytesExpected = [response expectedContentLength];
    self->_imageData = [[NSMutableData alloc] initWithCapacity:(NSUInteger)(self->_bytesExpected + 32)]; // Just in case? Unsure if the extra 32 bytes are necessary
    if(response.statusCode != 200) {
        [self fail:[NSString stringWithFormat:@"HTTP error %ld: %@", (long)response.statusCode, [NSHTTPURLResponse localizedStringForStatusCode:response.statusCode]]];
        return;
    }
    if(response.MIMEType.length && ![response.MIMEType.lowercaseString hasPrefix:@"image/"] && ![response.MIMEType.lowercaseString isEqualToString:@"binary/octet-stream"]) {
        [connection cancel];
        [self fail:[NSString stringWithFormat:@"Invalid MIME type: %@", response.MIMEType]];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSInteger receivedDataLength = [data length];
    self->_totalBytesReceived += receivedDataLength;
    [self->_imageData appendData:data];

    if(self->_bytesExpected != NSURLResponseUnknownLength) {
        float progress = (((self->_totalBytesReceived/(float)_bytesExpected) * 100.f) / 100.f);
        if(self->_progressView.progress < progress)
            self->_progressView.progress = progress;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if(connection == self->_connection) {
        NSLog(@"Couldn't download image. Error code %li: %@", (long)error.code, error.localizedDescription);
        [self fail:error.localizedDescription];
        self->_connection = nil;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if(connection == self->_connection) {
        if(self->_imageData) {
            NSString *cacheFile = [[ImageCache sharedInstance] pathForURL:connection.originalRequest.URL].path;
            [self->_imageData writeToFile:cacheFile atomically:YES];
            [self performSelectorInBackground:@selector(_parseImageData:) withObject:self->_imageData];
        } else {
            [self fail:@"No image data recieved"];
        }
        self->_connection = nil;
    }
}

- (void)_parseImageData:(NSData *)data {
    YYImage *img = [YYImage imageWithData:data scale:[UIScreen mainScreen].scale];
    if(img) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self->_progressView.progress = 1.f;
            [self->_scrollView removeGestureRecognizer:self->_panGesture];
            [self.view addGestureRecognizer:self->_panGesture];
            CGSize size;
            size = img.size;
            self->_imageView.image = img;
            self->_imageView.frame = CGRectMake(0,0,size.width,size.height);
            CGFloat xScale = self->_scrollView.bounds.size.width / self->_imageView.frame.size.width;
            CGFloat yScale = self->_scrollView.bounds.size.height / self->_imageView.frame.size.height;
            CGFloat minScale = MIN(xScale, yScale);
            
            CGFloat maxScale = 4;
            
            if (minScale > maxScale) {
                minScale = maxScale;
            }
            
            self->_scrollView.minimumZoomScale = minScale;
            self->_scrollView.maximumZoomScale = maxScale;
            self->_scrollView.contentSize = self->_imageView.frame.size;
            self->_scrollView.zoomScale = minScale;
            [self scrollViewDidZoom:self->_scrollView];
            
            [self->_progressView removeFromSuperview];
            [UIView beginAnimations:nil context:nil];
            [UIView setAnimationDuration:0.25];
            self->_imageView.alpha = 1;
            [UIView commitAnimations];
            if([UIApplication sharedApplication].delegate.window.rootViewController == self)
                [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
            [Answers logContentViewWithName:nil contentType:@"Image" contentId:nil customAttributes:nil];
        }];
    } else {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self fail:@"Unable to display image"];
        }];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if(@available(iOS 11, *))
        self->_imageView.accessibilityIgnoresInvertColors = YES;

    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    [doubleTap setNumberOfTapsRequired:2];
    [self->_scrollView addGestureRecognizer:doubleTap];
    
    self->_panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    [self->_scrollView addGestureRecognizer:self->_panGesture];
    
    [self transitionToSize:self.view.bounds.size];
    [self performSelector:@selector(load) withObject:nil afterDelay:0.5]; //Let the fade animation finish
    
    if(self->_previewing)
        self->_toolbar.hidden = YES;
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    self->_previewing = NO;
    self->_toolbar.hidden = NO;
    [self _showToolbar];
}

//From: http://stackoverflow.com/a/19146512
- (void)doubleTap:(UITapGestureRecognizer*)recognizer {
    if (self->_scrollView.zoomScale > _scrollView.minimumZoomScale) {
        [self->_scrollView setZoomScale:self->_scrollView.minimumZoomScale animated:YES];
    } else {
        CGPoint touch = [recognizer locationInView:self->_imageView];
        
        CGFloat w = self->_imageView.bounds.size.width / _scrollView.maximumZoomScale;
        CGFloat h = self->_imageView.bounds.size.height / _scrollView.maximumZoomScale;
        CGFloat x = touch.x-(w/2.0);
        CGFloat y = touch.y-(h/2.0);
        
        CGRect rectTozoom=CGRectMake(x, y, w, h);
        [self->_scrollView zoomToRect:rectTozoom animated:YES];
    }
}

- (void)panned:(UIPanGestureRecognizer *)recognizer {
    if(self->_previewing)
        return;
    
    if (self->_scrollView.zoomScale <= self->_scrollView.minimumZoomScale || _movieController || !_imageView.image) {
        CGRect frame = self->_scrollView.frame;
        
        switch(recognizer.state) {
            case UIGestureRecognizerStateBegan:
                if(fabs([recognizer velocityInView:self.view].y) > fabs([recognizer velocityInView:self.view].x)) {
                    [self _hideToolbar];
                }
                break;
            case UIGestureRecognizerStateCancelled: {
                frame.origin.y = 0;
                [UIView animateWithDuration:0.25 animations:^{
                    self->_scrollView.frame = frame;
                    self->_progressView.center = self->_scrollView.center;
                    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
                }];
                [self _showToolbar];
                self->_hideTimer = [NSTimer scheduledTimerWithTimeInterval:HIDE_DURATION target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
                break;
            }
            case UIGestureRecognizerStateChanged:
                frame.origin.y = [recognizer translationInView:self.view].y;
                self->_scrollView.frame = frame;
                if(self->_movieController)
                    self->_movieController.view.frame = self->_scrollView.bounds;
                self->_progressView.center = self->_scrollView.center;
                self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1-(fabs([recognizer translationInView:self.view].y) / self.view.frame.size.height / 2)];
                break;
            case UIGestureRecognizerStateEnded:
            {
                if(fabs([recognizer translationInView:self.view].y) > 100 || fabs([recognizer velocityInView:self.view].y) > 1000) {
                    frame.origin.y = ([recognizer translationInView:self.view].y > 0)?frame.size.height:-frame.size.height;
                    [self->_hideTimer invalidate];
                    self->_hideTimer = nil;
                    [self->_connection cancel];
                    self->_connection = nil;
                    [UIView animateWithDuration:0.25 animations:^{
                        self->_scrollView.frame = frame;
                        self->_progressView.center = self->_scrollView.center;
                        self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
                    } completion:^(BOOL finished) {
                        [((AppDelegate *)[UIApplication sharedApplication].delegate) showMainView:NO];
                    }];
                } else {
                    frame.origin.y = 0;
                    [self _showToolbar];
                    self->_hideTimer = [NSTimer scheduledTimerWithTimeInterval:HIDE_DURATION target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
                    [UIView animateWithDuration:0.25 animations:^{
                        self->_scrollView.frame = frame;
                        self->_progressView.center = self->_scrollView.center;
                        self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
                    }];
                }
                break;
            }
            default:
                break;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self transitionToSize:self.view.bounds.size];
    self->_hideTimer = [NSTimer scheduledTimerWithTimeInterval:HIDE_DURATION target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
    NSUserActivity *activity = [self userActivity];
    [activity invalidate];
    activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    activity.webpageURL = [NSURL URLWithString:[self->_url.absoluteString stringByReplacingCharactersInRange:NSMakeRange(0, _url.scheme.length) withString:self->_url.scheme.lowercaseString]];
    [self setUserActivity:activity];
    [activity becomeCurrent];
    if(self->_movieController)
        [self->_movieController.player play];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if(self->_movieController)
        [self->_movieController.player pause];
    [self->_hideTimer invalidate];
    self->_hideTimer = nil;
}

-(IBAction)viewTapped:(id)sender {
    if(self->_toolbar.hidden && !_previewing) {
        [self _showToolbar];
    } else {
        [self _hideToolbar];
    }
}

-(void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    self->_hideTimer = [NSTimer scheduledTimerWithTimeInterval:HIDE_DURATION target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
}

-(IBAction)shareButtonPressed:(id)sender {
    [UIColor clearTheme];
    UIActivityViewController *activityController = [URLHandler activityControllerForItems:self->_imageView.image?@[self->_url,_imageView.image]:@[self->_url] type:self->_movieController?@"Animation":@"Image"];

    activityController.popoverPresentationController.delegate = self;
    activityController.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:activityController animated:YES completion:nil];
    [self->_hideTimer invalidate];
    self->_hideTimer = nil;
}

-(IBAction)doneButtonPressed:(id)sender {
    [self->_hideTimer invalidate];
    self->_hideTimer = nil;
    [self->_connection cancel];
    self->_connection = nil;
    [((AppDelegate *)[UIApplication sharedApplication].delegate) setActiveScene:self.view.window];
    [((AppDelegate *)[UIApplication sharedApplication].delegate) showMainView:YES];
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if(!_toolbar.hidden && CGRectContainsPoint(self->_toolbar.frame, [touch locationInView:self.view]))
        return NO;
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
