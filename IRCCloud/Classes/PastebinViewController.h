//
//  PastebinViewController.h
//
//  Copyright (C) 2015 IRCCloud, Ltd.
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
#import "OpenInChromeController.h"

@interface PastebinViewController : UIViewController<UIPopoverPresentationControllerDelegate,UIAlertViewDelegate> {
    IBOutlet UIWebView *_webView;
    IBOutlet UIToolbar *_toolbar;
    IBOutlet UIActivityIndicatorView *_activity;
    NSString *_url;
    UISwitch *_lineNumbers;
    NSString *_pasteID;
    BOOL _ownPaste;
    OpenInChromeController *_chrome;
}
-(id)initWithURL:(NSURL *)url;
@end
