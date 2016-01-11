//
//  YouTubeViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 1/11/16.
//  Copyright © 2016 IRCCloud, Ltd. All rights reserved.
//

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
