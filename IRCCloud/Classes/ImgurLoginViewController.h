//
//  ImgurLoginViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 5/19/14.
//  Copyright (c) 2014 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImgurLoginViewController : UIViewController<UIWebViewDelegate> {
    UIWebView *_webView;
    UIActivityIndicatorView *_activity;
}
@end
