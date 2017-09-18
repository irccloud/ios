//
//  ImageViewController.h
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


#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import "OpenInChromeController.h"
#import "YYAnimatedImageView.h"
#import "URLHandler.h"

@interface ImageViewController : UIViewController<UIScrollViewDelegate,NSURLConnectionDataDelegate,UIPopoverPresentationControllerDelegate,UIGestureRecognizerDelegate> {
    IBOutlet YYAnimatedImageView *_imageView;
    IBOutlet UIScrollView *_scrollView;
    MPMoviePlayerController *_movieController;
    __weak IBOutlet UIProgressView *_progressView;
    IBOutlet UIToolbar *_toolbar;
    NSURL *_url;
    NSTimer *_hideTimer;
    OpenInChromeController *_chrome;
    NSURLConnection *_connection;
    BOOL _previewing;
    UIPanGestureRecognizer *_panGesture;
    URLHandler *_urlHandler;
}
@property BOOL previewing;
-(id)initWithURL:(NSURL *)url;
-(IBAction)viewTapped:(id)sender;
-(IBAction)doneButtonPressed:(id)sender;
-(IBAction)shareButtonPressed:(id)sender;
@end
