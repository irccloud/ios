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


#import <MobileCoreServices/UTCoreTypes.h>
#import <Twitter/Twitter.h>
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

-(NSUInteger)supportedInterfaceOrientations {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)?UIInterfaceOrientationMaskAllButUpsideDown:UIInterfaceOrientationMaskAll;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return YES;
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)inScroll {
    return _imageView;
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        _scrollView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width);
    } else {
        _scrollView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    }
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
    
    if(_toolbar.hidden)
        [self _showToolbar];
    [_hideTimer invalidate];
    _hideTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
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
    [self _showToolbar];
}

-(void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    _hideTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
}

-(void)fail {
    if(!([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [_chrome openInChrome:_url
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

-(void)loadOembed:(NSString *)url {
    NSURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            NSLog(@"Error fetching oembed. Error %li : %@", (long)error.code, error.userInfo);
            [self fail];
        } else {
            SBJsonParser *parser = [[SBJsonParser alloc] init];
            NSDictionary *dict = [parser objectWithData:data];
            if([[dict objectForKey:@"type"] isEqualToString:@"photo"]) {
                NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[dict objectForKey:@"url"]]];
                NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
                
                [connection start];
            } else {
                NSLog(@"Invalid type from oembed");
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
        [self loadOembed:[NSString stringWithFormat:@"https://api.imgur.com/oembed.json?url=%@", url.absoluteString]];
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
                    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
                    
                    [connection start];
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
                    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
                    
                    [connection start];
                } else {
                    NSLog(@"Invalid data from MediaWiki");
                    [self fail];
                }
            }
        }];
        return;
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    _connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    
    [_connection start];
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_gifProgress:) name:UIImageAnimatedGIFProgressNotification object:nil];
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        self.view.frame = _scrollView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width);
    } else {
        self.view.frame = _scrollView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    }
    
    [self performSelector:@selector(load) withObject:nil afterDelay:0.5]; //Let the fade animation finish
}

-(void)viewDidUnload {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        _scrollView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width);
    } else {
        _scrollView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    }
    _hideTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
}

-(IBAction)viewTapped:(id)sender {
    if(_toolbar.hidden) {
        [self _showToolbar];
        _hideTimer = [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(_hideToolbar) userInfo:nil repeats:NO];
    } else {
        [self _hideToolbar];
    }
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
        [self presentViewController:activityController animated:YES completion:nil];
    } else {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Copy To Clipboard", @"Share on Twitter", ([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [_chrome isChromeInstalled])?@"Open In Chrome":@"Open In Safari",nil];
        [sheet showFromToolbar:_toolbar];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"Copy To Clipboard"]) {
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        if(_imageView.image) {
            NSData* imageData = UIImageJPEGRepresentation(_imageView.image, 1);
            pb.items = @[@{(NSString *)kUTTypeUTF8PlainText:_url.absoluteString,
                           (NSString *)kUTTypeJPEG:imageData,
                           (NSString *)kUTTypeURL:_url}];
        } else {
            pb.items = @[@{(NSString *)kUTTypeUTF8PlainText:_url.absoluteString,
                           (NSString *)kUTTypeURL:_url}];
        }
    } else if([title isEqualToString:@"Share on Twitter"]) {
        TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
        [tweetViewController setInitialText:_url.absoluteString];
        [tweetViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
            [self dismissModalViewControllerAnimated:YES];
        }];
        [self presentModalViewController:tweetViewController animated:YES];
    } else if([title hasPrefix:@"Open "]) {
        [((AppDelegate *)[UIApplication sharedApplication].delegate) showMainView:NO];
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self fail];
        }];
    }
}

-(IBAction)doneButtonPressed:(id)sender {
    [((AppDelegate *)[UIApplication sharedApplication].delegate) showMainView:YES];
    [_connection cancel];
    _connection = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
