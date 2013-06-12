//
//  ImageViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 6/12/13.
//  Copyright (c) 2013 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImageViewController : UIViewController {
    IBOutlet UIImageView *_imageView;
    IBOutlet UIScrollView *_scrollView;
    IBOutlet UIActivityIndicatorView *_activityView;
    NSURL *_url;
}
-(id)initWithURL:(NSURL *)url;
-(IBAction)viewTapped:(id)sender;
@end
