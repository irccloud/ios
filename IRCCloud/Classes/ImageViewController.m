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
#import "UIImage+animatedGIF.h"
#import "ARChromeActivity.h"
#import "TUSafariActivity.h"
#import "config.h"

@implementation ImageViewController
{
    NSMutableData *_imageData;
    long long _bytesExpected;
    long long _totalBytesReceived;
}

- (id)initWithURL:(NSURL *)url {
    self = [super initWithNibName:@"ImageViewController" bundle:nil];
    if (self) {
        _url = url;
        _chrome = [[OpenInChromeController alloc] init];
        _progressScale = 0;
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
                 
                 UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:_imageView.image?@[_url,_imageView.image]:@[_url] applicationActivities:@[([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [_chrome isChromeInstalled])?[[ARChromeActivity alloc] initWithCallbackURL:[NSURL URLWithString:
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
                         [Answers logShareWithMethod:activityType contentName:nil contentType:_movieController?@"Animation":@"Image" contentId:nil customAttributes:nil];
                     }
                 };
                 [mainViewController.slidingViewController presentViewController:activityController animated:YES completion:nil];
             }],
             [UIPreviewAction actionWithTitle:@"Open in Browser" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                 if(!([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [_chrome openInChrome:_url
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

-(SupportedOrientationsReturnType)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)inScroll {
    return _imageView;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    int height = ((UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 8)?[UIScreen mainScreen].applicationFrame.size.width:[UIScreen mainScreen].applicationFrame.size.height);
    int width = (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) && [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 8)?[UIScreen mainScreen].applicationFrame.size.height:[UIScreen mainScreen].applicationFrame.size.width;
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8)
        height += [UIApplication sharedApplication].statusBarFrame.size.height;
    else if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] == 7)
        height += UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)?[UIApplication sharedApplication].statusBarFrame.size.width:[UIApplication sharedApplication].statusBarFrame.size.height;

    _scrollView.frame = CGRectMake(0,0,width,height);
    if(_imageView.image) {
        [_imageView sizeToFit];
        CGRect frame = _imageView.frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        _imageView.frame = frame;
        _scrollView.contentSize = _imageView.frame.size;
    }
    [self scrollViewDidZoom:_scrollView];
    
    _progressView.center = CGPointMake(self.view.bounds.size.width / 2.0,self.view.bounds.size.height/2.0);
    
    if(_movieController)
        _movieController.view.frame = _scrollView.bounds;
}

-(void)_setImage:(UIImage *)img {
    _imageView.image = img;
    _imageView.frame = CGRectMake(0,0,img.size.width,img.size.height);
    CGFloat xScale = _scrollView.bounds.size.width / _imageView.frame.size.width;
    CGFloat yScale = _scrollView.bounds.size.height / _imageView.frame.size.height;
    CGFloat minScale = MIN(xScale, yScale);
    
    CGFloat maxScale = 4;
    
    if (minScale > maxScale) {
        minScale = maxScale;
    }

    _scrollView.minimumZoomScale = minScale;
    _scrollView.maximumZoomScale = maxScale;
    _scrollView.contentSize = _imageView.frame.size;
    _scrollView.zoomScale = minScale;
    [self scrollViewDidZoom:_scrollView];

    [_progressView removeFromSuperview];
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.25];
    _imageView.alpha = 1;
    [UIView commitAnimations];
    if(!_previewing)
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [Answers logContentViewWithName:nil contentType:@"Image" contentId:nil customAttributes:nil];
}

//Some centering magic from: http://stackoverflow.com/a/2189336/1406639
-(void)scrollViewDidZoom:(UIScrollView *)pScrollView {
    CGRect innerFrame = _imageView.frame;
    CGRect scrollerBounds = pScrollView.bounds;
    
    if ((innerFrame.size.width < scrollerBounds.size.width) || (innerFrame.size.height < scrollerBounds.size.height)) {
        CGFloat tempx = _imageView.center.x - (scrollerBounds.size.width / 2);
        CGFloat tempy = _imageView.center.y - (scrollerBounds.size.height / 2);
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
    
    if(_toolbar.hidden && !_previewing)
        [self _showToolbar];
    [_hideTimer invalidate];
    _hideTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
    
    pScrollView.alwaysBounceHorizontal = (pScrollView.zoomScale > pScrollView.minimumZoomScale);
    pScrollView.alwaysBounceVertical = (pScrollView.zoomScale > pScrollView.minimumZoomScale);
}

-(void)_showToolbar {
    [_hideTimer invalidate];
    _hideTimer = nil;
    [UIView animateWithDuration:0.5 animations:^{
        _toolbar.hidden = NO;
        _toolbar.alpha = 1;
    } completion:nil];
}

-(void)_hideToolbar {
    [_hideTimer invalidate];
    _hideTimer = nil;
    [UIView animateWithDuration:0.5 animations:^{
        _toolbar.alpha = 0;
    } completion:^(BOOL finished){
        _toolbar.hidden = YES;
    }];
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if(!_previewing)
        [self _showToolbar];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    _hideTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
}

-(void)fail {
    [_progressView removeFromSuperview];

    if(_previewing || self.view.window.rootViewController != self) {
        NSLog(@"Not launching fallback URL as we're not the root view controller");
        return;
    }
    if(!([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [_chrome openInChrome:_url
                                                                                  withCallbackURL:[NSURL URLWithString:
#ifdef ENTERPRISE
                                                                                                   @"irccloud-enterprise://"
#else
                                                                                                   @"irccloud://"
#endif
                                                                                                   ]
                                                                                     createNewTab:NO])) {
        if([SFSafariViewController class] && [_url.scheme hasPrefix:@"http"]) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                UIApplication *app = [UIApplication sharedApplication];
                AppDelegate *appDelegate = (AppDelegate *)app.delegate;
                MainViewController *mainViewController = [appDelegate mainViewController];
                
                [((AppDelegate *)[UIApplication sharedApplication].delegate) showMainView:NO];

                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
                    [UIApplication sharedApplication].statusBarHidden = NO;

                    [mainViewController.slidingViewController presentViewController:[[SFSafariViewController alloc] initWithURL:_url] animated:YES completion:nil];
                }];
            }];
        } else {
            [[UIApplication sharedApplication] openURL:_url];
        }
    }
}

-(void)loadOembed:(NSString *)url {
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error fetching oembed. Error %li : %@", (long)error.code, error.userInfo);
            [self fail];
        } else {
            SBJsonParser *parser = [[SBJsonParser alloc] init];
            NSDictionary *dict = [parser objectWithData:data];
            if([[dict objectForKey:@"type"] isEqualToString:@"photo"]) {
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[dict objectForKey:@"url"]]];
                _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
                
                [_connection start];
            } else if([[dict objectForKey:@"provider_name"] isEqualToString:@"Giphy"] && [[dict objectForKey:@"url"] rangeOfString:@"/gifs/"].location != NSNotFound) {
                if([dict objectForKey:@"image"] && [[dict objectForKey:@"image"] hasSuffix:@".gif"]) {
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[dict objectForKey:@"image"]]];
                    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
                    
                    [_connection start];
                } else {
                    [self loadGiphy:[[dict objectForKey:@"url"] substringFromIndex:[[dict objectForKey:@"url"] rangeOfString:@"/gifs/"].location + 6]];
                }
            } else {
                NSLog(@"Invalid type from oembed");
                [self fail];
            }
        }
    }];
}

-(void)loadVideo:(NSString *)url {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];
    _movieController = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL URLWithString:url]];
    _movieController.controlStyle = MPMovieControlStyleNone;
    _movieController.view.userInteractionEnabled = NO;
    _movieController.view.frame = _scrollView.bounds;
    [_scrollView addSubview:_movieController.view];
    _scrollView.userInteractionEnabled = NO;
    [_progressView removeFromSuperview];
    [_movieController play];
    if(!_previewing)
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
    [Answers logContentViewWithName:nil contentType:@"Animation" contentId:nil customAttributes:nil];
}

-(void)loadGfycat:(NSString *)gyfID {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://gfycat.com/cajax/get%@", gyfID]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error fetching gfycat. Error %li : %@", (long)error.code, error.userInfo);
            [self fail];
        } else {
            SBJsonParser *parser = [[SBJsonParser alloc] init];
            NSDictionary *dict = [parser objectWithData:data];
            if([dict objectForKey:@"gfyItem"]) {
                dict = [dict objectForKey:@"gfyItem"];
                if([[dict objectForKey:@"mp4Url"] length]) {
                    [self loadVideo:[dict objectForKey:@"mp4Url"]];
                    _movieController.repeatMode = MPMovieRepeatModeOne;
                } else if([[dict objectForKey:@"gifUrl"] length]) {
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[dict objectForKey:@"gifUrl"]]];
                    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
                    
                    [_connection start];
                } else {
                    NSLog(@"Invalid type from gfycat");
                    [self fail];
                }
            } else {
                NSLog(@"Gfycat failure");
                [self fail];
            }
        }
    }];
}

-(void)loadGiphy:(NSString *)gifID {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.giphy.com/v1/gifs/%@?api_key=dc6zaTOxFJmzC", gifID]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setHTTPShouldHandleCookies:NO];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error fetching giphy. Error %li : %@", (long)error.code, error.userInfo);
            [self fail];
        } else {
            SBJsonParser *parser = [[SBJsonParser alloc] init];
            NSDictionary *dict = [parser objectWithData:data];
            if([[[dict objectForKey:@"meta"] objectForKey:@"status"] intValue] == 200 && [[dict objectForKey:@"data"] objectForKey:@"images"]) {
                dict = [[[dict objectForKey:@"data"] objectForKey:@"images"] objectForKey:@"original"];
                if([[dict objectForKey:@"mp4"] length]) {
                    [self loadVideo:[dict objectForKey:@"mp4"]];
                    _movieController.repeatMode = MPMovieRepeatModeOne;
                } else if([[dict objectForKey:@"url"] hasSuffix:@".gif"]) {
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[dict objectForKey:@"url"]]];
                    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
                    
                    [_connection start];
                } else {
                    NSLog(@"Invalid type from giphy");
                    [self fail];
                }
            } else {
                NSLog(@"giphy failure");
                [self fail];
            }
        }
    }];
}

-(void)loadImgurImage:(NSString *)imageID {
#ifdef MASHAPE_KEY
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://imgur-apiv3.p.mashape.com/3/image/%@", imageID]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setValue:@MASHAPE_KEY forHTTPHeaderField:@"X-Mashape-Authorization"];
#else
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.imgur.com/3/image/%@", imageID]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
#endif
    [request setHTTPShouldHandleCookies:NO];
#ifdef IMGUR_KEY
    [request setValue:[NSString stringWithFormat:@"Client-ID %@", @IMGUR_KEY] forHTTPHeaderField:@"Authorization"];
#endif

    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error fetching imgur. Error %li : %@", (long)error.code, error.userInfo);
            [self fail];
        } else {
            SBJsonParser *parser = [[SBJsonParser alloc] init];
            NSDictionary *dict = [parser objectWithData:data];
            CLS_LOG(@"Imgur response: %@", dict);
            if([[dict objectForKey:@"success"] intValue]) {
                dict = [dict objectForKey:@"data"];
                if([[dict objectForKey:@"type"] hasPrefix:@"image/"] && [[dict objectForKey:@"animated"] intValue] == 0) {
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[dict objectForKey:@"link"]]];
                    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
                    
                    [_connection start];
                } else if([[dict objectForKey:@"animated"] intValue] == 1 && [[dict objectForKey:@"mp4"] length] > 0) {
                    [self loadVideo:[dict objectForKey:@"mp4"]];
                    if([[dict objectForKey:@"looping"] intValue] == 1)
                        _movieController.repeatMode = MPMovieRepeatModeOne;
                } else {
                    NSLog(@"Invalid type from imgur");
                    [self fail];
                }
            } else {
                NSLog(@"Imgur failure");
                [self fail];
            }
        }
    }];
}

-(void)loadImgurGallery:(NSString *)galleryID {
#ifdef MASHAPE_KEY
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://imgur-apiv3.p.mashape.com/3/gallery/%@", galleryID]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [request setValue:@MASHAPE_KEY forHTTPHeaderField:@"X-Mashape-Authorization"];
#else
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.imgur.com/3/gallery/%@", galleryID]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
#endif
    [request setHTTPShouldHandleCookies:NO];
#ifdef IMGUR_KEY
    [request setValue:[NSString stringWithFormat:@"Client-ID %@", @IMGUR_KEY] forHTTPHeaderField:@"Authorization"];
#endif
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error fetching imgur. Error %li : %@", (long)error.code, error.userInfo);
            [self fail];
        } else {
            SBJsonParser *parser = [[SBJsonParser alloc] init];
            NSDictionary *dict = [parser objectWithData:data];
            if([[dict objectForKey:@"success"] intValue]) {
                dict = [dict objectForKey:@"data"];
                if([[dict objectForKey:@"type"] hasPrefix:@"image/"] && [[dict objectForKey:@"animated"] intValue] == 0) {
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[dict objectForKey:@"link"]]];
                    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
                    
                    [_connection start];
                } else {
                    NSLog(@"Invalid type from imgur");
                    [self fail];
                }
            } else {
                NSLog(@"Imgur failure");
                [self fail];
            }
        }
    }];
}

-(void)load {
#ifdef DEBUG
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
#endif
    
    NSURL *url = _url;
    if([[url.host lowercaseString] isEqualToString:@"www.dropbox.com"]) {
        if([url.path hasPrefix:@"/s/"])
            url = [NSURL URLWithString:[NSString stringWithFormat:@"https://dl.dropboxusercontent.com%@", [url.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        else
            url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?dl=1", url.absoluteString]];
    } else if(([[url.host lowercaseString] isEqualToString:@"d.pr"] || [[url.host lowercaseString] isEqualToString:@"droplr.com"]) && [url.path hasPrefix:@"/i/"] && ![url.path hasSuffix:@"+"]) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://droplr.com%@+", [url.path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
    } else if([[url.host lowercaseString] isEqualToString:@"imgur.com"]) {
        NSString *imageID = [url.path substringFromIndex:1];
        if([imageID rangeOfString:@"/"].location == NSNotFound) {
            [self loadImgurImage:imageID];
        } else if([imageID hasPrefix:@"gallery/"]) {
            [self loadImgurGallery:[imageID substringFromIndex:8]];
        } else {
            [self fail];
        }
        return;
    } else if([[url.host lowercaseString] isEqualToString:@"i.imgur.com"] && ([url.path hasSuffix:@".gifv"] || [url.path hasSuffix:@".webm"])) {
        [self loadImgurImage:[url.path substringToIndex:url.path.length - 5]];
        return;
    } else if([[url.host lowercaseString] hasSuffix:@"gfycat.com"]) {
        [self loadGfycat:url.path];
        return;
    } else if(([[url.host lowercaseString] hasSuffix:@"giphy.com"] || [[url.host lowercaseString] isEqualToString:@"gph.is"]) && url.pathExtension.length == 0) {
        NSString *u = url.absoluteString;
        if([u rangeOfString:@"/gifs/"].location != NSNotFound) {
            u = [NSString stringWithFormat:@"http://giphy.com/gifs/%@", [url.pathComponents objectAtIndex:2]];
        }
        [self loadOembed:[NSString stringWithFormat:@"https://giphy.com/services/oembed/?url=%@", u]];
        return;
    } else if([[url.host lowercaseString] hasSuffix:@"flickr.com"] && [url.host rangeOfString:@"static"].location == NSNotFound) {
        [self loadOembed:[NSString stringWithFormat:@"https://www.flickr.com/services/oembed/?url=%@&format=json", url.absoluteString]];
        return;
    } else if(([[url.host lowercaseString] hasSuffix:@"instagram.com"] || [[url.host lowercaseString] hasSuffix:@"instagr.am"]) && [url.path hasPrefix:@"/p/"]) {
        [self loadOembed:[NSString stringWithFormat:@"http://api.instagram.com/oembed?url=%@", url.absoluteString]];
        return;
    } else if([url.host.lowercaseString isEqualToString:@"cl.ly"]) {
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (error) {
                NSLog(@"Error fetching cl.ly metadata. Error %li : %@", (long)error.code, error.userInfo);
                [self fail];
            } else {
                SBJsonParser *parser = [[SBJsonParser alloc] init];
                NSDictionary *dict = [parser objectWithData:data];
                if([[dict objectForKey:@"item_type"] isEqualToString:@"image"]) {
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[dict objectForKey:@"content_url"]]];
                    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
                    
                    [_connection start];
                } else {
                    NSLog(@"Invalid type from cl.ly");
                    [self fail];
                }
            }
        }];
        return;
    } else if([url.path hasPrefix:@"/wiki/File:"]) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@:%@%@", url.scheme, url.host, url.port,[[NSString stringWithFormat:@"/w/api.php?action=query&format=json&prop=imageinfo&iiprop=url&titles=%@", [url.path substringFromIndex:6]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
            if (error) {
                NSLog(@"Error fetching MediaWiki metadata. Error %li : %@", (long)error.code, error.userInfo);
                [self fail];
            } else {
                SBJsonParser *parser = [[SBJsonParser alloc] init];
                NSDictionary *dict = [parser objectWithData:data];
                NSDictionary *page = [[[[dict objectForKey:@"query"] objectForKey:@"pages"] allValues] objectAtIndex:0];
                if(page && [page objectForKey:@"imageinfo"]) {
                    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[[[page objectForKey:@"imageinfo"] objectAtIndex:0] objectForKey:@"url"]]];
                    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
                    
                    [_connection start];
                } else {
                    NSLog(@"Invalid data from MediaWiki");
                    [self fail];
                }
            }
        }];
        return;
    } else if([url.host hasSuffix:@"leetfiles.com"]) {
        NSString *u = url.absoluteString;
        u = [u stringByReplacingOccurrencesOfString:@"www." withString:@""];
        u = [u stringByReplacingOccurrencesOfString:@"leetfiles.com/image" withString:@"i.leetfiles.com/"];
        u = [u stringByReplacingOccurrencesOfString:@"?id=" withString:@""];
        url = [NSURL URLWithString:u];
    } else if([url.host hasSuffix:@"leetfil.es"]) {
        NSString *u = url.absoluteString;
        u = [u stringByReplacingOccurrencesOfString:@"www." withString:@""];
        u = [u stringByReplacingOccurrencesOfString:@"leetfil.es/image" withString:@"i.leetfiles.com/"];
        u = [u stringByReplacingOccurrencesOfString:@"?id=" withString:@""];
        url = [NSURL URLWithString:u];
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    
    [_connection start];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _bytesExpected = [response expectedContentLength];
    _imageData = [[NSMutableData alloc] initWithCapacity:_bytesExpected + 32]; // Just in case? Unsure if the extra 32 bytes are necessary
    if(response.MIMEType.length && ![response.MIMEType.lowercaseString hasPrefix:@"image/"] && ![response.MIMEType.lowercaseString isEqualToString:@"binary/octet-stream"]) {
        [connection cancel];
        [self fail];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSInteger receivedDataLength = [data length];
    _totalBytesReceived += receivedDataLength;
    [_imageData appendData:data];

    if(_progressScale == 0 && _totalBytesReceived > 3) {
        char GIF[3];
        [data getBytes:&GIF length:3];
        if(GIF[0] == 'G' && GIF[1] == 'I' && GIF[2] == 'F')
            _progressScale = 0.5;
        else
            _progressScale = 1.0;
    }
    
    if(_bytesExpected != NSURLResponseUnknownLength) {
        float progress = (((_totalBytesReceived/(float)_bytesExpected) * 100.f) / 100.f) * _progressScale;
        if(_progressView.progress < progress)
            _progressView.progress = progress;
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    if(connection == _connection) {
        NSLog(@"Couldn't download image. Error code %li: %@", (long)error.code, error.localizedDescription);
        [self fail];
        _connection = nil;
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    if(connection == _connection) {
        if(_imageData) {
            [self performSelectorInBackground:@selector(_parseImageData:) withObject:_imageData];
        } else {
            [self fail];
        }
        _connection = nil;
    }
}

- (void)_parseImageData:(NSData *)data {
    UIImage *img = nil;
    char GIF[3];
    [data getBytes:&GIF length:3];
    if(GIF[0] == 'G' && GIF[1] == 'I' && GIF[2] == 'F')
        img = [UIImage animatedImageWithAnimatedGIFData:data];
    else
        img = [UIImage imageWithData:data];
    if(img) {
        _progressView.progress = 1.f;
        [self performSelectorOnMainThread:@selector(_setImage:) withObject:img waitUntilDone:NO];
    } else {
        [self fail];
    }
}

-(void)_gifProgress:(NSNotification *)n {
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        _progressView.progress = 0.5 + ([[n.userInfo objectForKey:@"progress"] floatValue] / 2.0f);
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    [doubleTap setNumberOfTapsRequired:2];
    [_scrollView addGestureRecognizer:doubleTap];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)];
    [self.view addGestureRecognizer:panGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_gifProgress:) name:UIImageAnimatedGIFProgressNotification object:nil];
    [self willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
    [self performSelector:@selector(load) withObject:nil afterDelay:0.5]; //Let the fade animation finish
    
    if(_previewing)
        _toolbar.hidden = YES;
}

-(void)viewDidUnload {
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    _previewing = NO;
    _toolbar.hidden = NO;
    [self _showToolbar];
}

//From: http://stackoverflow.com/a/19146512
- (void)doubleTap:(UITapGestureRecognizer*)recognizer {
    if (_scrollView.zoomScale > _scrollView.minimumZoomScale) {
        [_scrollView setZoomScale:_scrollView.minimumZoomScale animated:YES];
    } else {
        CGPoint touch = [recognizer locationInView:_imageView];
        
        CGFloat w = _scrollView.bounds.size.width;
        CGFloat h = _scrollView.bounds.size.height;
        CGFloat x = touch.x-(w/2.0);
        CGFloat y = touch.y-(h/2.0);
        
        CGRect rectTozoom=CGRectMake(x, y, w, h);
        [_scrollView zoomToRect:rectTozoom animated:YES];
    }
}

- (void)panned:(UIPanGestureRecognizer *)recognizer {
    if(_previewing)
        return;
    
    if (_scrollView.zoomScale <= _scrollView.minimumZoomScale || _movieController) {
        CGRect frame = _scrollView.frame;
        
        switch(recognizer.state) {
            case UIGestureRecognizerStateBegan:
                if(fabs([recognizer velocityInView:self.view].y) > fabs([recognizer velocityInView:self.view].x)) {
                    [self _hideToolbar];
                }
                break;
            case UIGestureRecognizerStateCancelled: {
                frame.origin.y = 0;
                [UIView animateWithDuration:0.25 animations:^{
                    _scrollView.frame = frame;
                    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
                }];
                [self _showToolbar];
                _hideTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
                break;
            }
            case UIGestureRecognizerStateChanged:
                frame.origin.y = [recognizer translationInView:self.view].y;
                _scrollView.frame = frame;
                self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1-(fabs([recognizer translationInView:self.view].y) / self.view.frame.size.height / 2)];
                break;
            case UIGestureRecognizerStateEnded:
            {
                if(fabs([recognizer translationInView:self.view].y) > 100 || fabs([recognizer velocityInView:self.view].y) > 1000) {
                    frame.origin.y = ([recognizer translationInView:self.view].y > 0)?frame.size.height:-frame.size.height;
                    [UIView animateWithDuration:0.25 animations:^{
                        _scrollView.frame = frame;
                        self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
                    } completion:^(BOOL finished) {
                        [((AppDelegate *)[UIApplication sharedApplication].delegate) showMainView:NO];
                    }];
                } else {
                    frame.origin.y = 0;
                    [self _showToolbar];
                    _hideTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
                    [UIView animateWithDuration:0.25 animations:^{
                        _scrollView.frame = frame;
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
    [self willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
    _hideTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
        NSUserActivity *activity = [self userActivity];
        [activity invalidate];
        activity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
        activity.webpageURL = [NSURL URLWithString:[_url.absoluteString stringByReplacingCharactersInRange:NSMakeRange(0, _url.scheme.length) withString:_url.scheme.lowercaseString]];
        [self setUserActivity:activity];
        [activity becomeCurrent];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    if(_movieController)
        [_movieController stop];
}

-(IBAction)viewTapped:(id)sender {
    if(_toolbar.hidden && !_previewing) {
        [self _showToolbar];
        _hideTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
    } else {
        [self _hideToolbar];
    }
}

-(void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    _hideTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
}

-(IBAction)shareButtonPressed:(id)sender {
    if(NSClassFromString(@"UIActivityViewController")) {
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:_imageView.image?@[_url,_imageView.image]:@[_url] applicationActivities:@[([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [_chrome isChromeInstalled])?[[ARChromeActivity alloc] initWithCallbackURL:[NSURL URLWithString:
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
                    [Answers logShareWithMethod:activityType contentName:nil contentType:_movieController?@"Animation":@"Image" contentId:nil customAttributes:nil];
                }
            };
        } else {
            activityController.completionHandler = ^(NSString *activityType, BOOL completed) {
                if(completed) {
                    if([activityType hasPrefix:@"com.apple.UIKit.activity."])
                        activityType = [activityType substringFromIndex:25];
                    if([activityType hasPrefix:@"com.apple."])
                        activityType = [activityType substringFromIndex:10];
                    [Answers logShareWithMethod:activityType contentName:nil contentType:_movieController?@"Animation":@"Image" contentId:nil customAttributes:nil];
                }
            };
        }
        [self presentViewController:activityController animated:YES completion:nil];
        [_hideTimer invalidate];
        _hideTimer = nil;
    }
}

-(IBAction)doneButtonPressed:(id)sender {
    [_connection cancel];
    _connection = nil;
    [((AppDelegate *)[UIApplication sharedApplication].delegate) showMainView:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
