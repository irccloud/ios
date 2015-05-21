//
//  PastebinViewController.h
//  IRCCloud
//
//  Created by Sam Steele on 5/21/15.
//  Copyright (c) 2015 IRCCloud, Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OpenInChromeController.h"

@interface PastebinViewController : UIViewController<UIActionSheetDelegate,UIPopoverPresentationControllerDelegate> {
    IBOutlet UIWebView *_webView;
    IBOutlet UIToolbar *_toolbar;
    IBOutlet UIActivityIndicatorView *_activity;
    NSURL *_url;
    UISwitch *_lineNumbers;
    NSString *_pasteID;
    BOOL _ownPaste;
    OpenInChromeController *_chrome;
}
-(id)initWithURL:(NSURL *)url;
@end
