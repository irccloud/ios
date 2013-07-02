//
//  ImageViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 6/12/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageViewController : UIViewController<UIScrollViewDelegate> {
    IBOutlet UIImageView *_imageView;
    IBOutlet UIScrollView *_scrollView;
    IBOutlet UIActivityIndicatorView *_activityView;
    IBOutlet UIToolbar *_toolbar;
    NSURL *_url;
    NSTimer *_hideTimer;
}
-(id)initWithURL:(NSURL *)url;
-(IBAction)viewTapped:(id)sender;
-(IBAction)openInBrowser:(id)sender;
-(IBAction)doneButtonPressed:(id)sender;
@end
