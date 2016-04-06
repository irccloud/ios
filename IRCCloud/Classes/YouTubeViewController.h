//
//  YouTubeViewController.h
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

#import <UIKit/UIKit.h>
#import "YTPlayerView.h"

@interface YouTubeViewController : UIViewController<YTPlayerViewDelegate,UIPopoverPresentationControllerDelegate> {
    NSURL *_url;
    UIActivityIndicatorView *_activity;
    YTPlayerView *_player;
    UIToolbar *_toolbar;
}
@property YTPlayerView *player;
@property (readonly) NSURL *url;
@property (readonly) UIToolbar *toolbar;
-(id)initWithURL:(NSURL *)url;
@end
