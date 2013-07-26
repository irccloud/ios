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

@implementation ImageViewController

- (id)initWithURL:(NSURL *)url {
    self = [super initWithNibName:@"ImageViewController" bundle:nil];
    if (self) {
        _url = url;
        _chrome = [[OpenInChromeController alloc] init];
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

    [_activityView stopAnimating];
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

-(void)_load {
    UIImage *img = nil;
    NSData *data = [NSData dataWithContentsOfURL:_url];
    if(data) {
        if([[[_url description] lowercaseString] hasSuffix:@"gif"])
            img = [UIImage animatedImageWithAnimatedGIFData:data];
        else
            img = [UIImage imageWithData:data];
        if(img)
            [self performSelectorOnMainThread:@selector(_setImage:) withObject:img waitUntilDone:YES];
    }
    if(!data || !img) {
        [((AppDelegate *)[UIApplication sharedApplication].delegate) showMainView];
        if(!([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [_chrome openInChrome:_url
                  withCallbackURL:[NSURL URLWithString:@"irccloud://"]
                     createNewTab:NO]))
            [[UIApplication sharedApplication] openURL:_url];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if(UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        self.view.frame = _scrollView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width);
    } else {
        self.view.frame = _scrollView.frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    }
    [self performSelectorInBackground:@selector(_load) withObject:nil];
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
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:_imageView.image?@[_url,_imageView.image]:@[_url] applicationActivities:@[([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [_chrome isChromeInstalled])?[[ARChromeActivity alloc] initWithCallbackURL:[NSURL URLWithString:@"irccloud://"]]:[[TUSafariActivity alloc] init]]];
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
        [((AppDelegate *)[UIApplication sharedApplication].delegate) showMainView];
        if(!([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [_chrome openInChrome:_url
                  withCallbackURL:[NSURL URLWithString:@"irccloud://"]
                     createNewTab:NO]))
            [[UIApplication sharedApplication] openURL:_url];
    }
}

-(IBAction)doneButtonPressed:(id)sender {
    [((AppDelegate *)[UIApplication sharedApplication].delegate) showMainView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
