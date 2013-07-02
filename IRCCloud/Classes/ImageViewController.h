//
//  ImageViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 6/12/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OpenInChromeController.h"

@interface ImageViewController : UIViewController<UIScrollViewDelegate,UIActionSheetDelegate> {
    IBOutlet UIImageView *_imageView;
    IBOutlet UIScrollView *_scrollView;
    IBOutlet UIActivityIndicatorView *_activityView;
    IBOutlet UIToolbar *_toolbar;
    NSURL *_url;
    NSTimer *_hideTimer;
    OpenInChromeController *_chrome;
}
-(id)initWithURL:(NSURL *)url;
-(IBAction)viewTapped:(id)sender;
-(IBAction)doneButtonPressed:(id)sender;
-(IBAction)shareButtonPressed:(id)sender;
@end
