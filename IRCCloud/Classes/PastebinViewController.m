//
//  PastebinViewController.m
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
#import <SafariServices/SafariServices.h>
#import <Twitter/Twitter.h>
#import "PastebinViewController.h"
#import "NetworkConnection.h"
#import "OpenInChromeController.h"
#import "OpenInFirefoxControllerObjC.h"
#import "AppDelegate.h"
#import "PastebinEditorViewController.h"
#import "UIColor+IRCCloud.h"
@import Firebase;

@implementation PastebinViewController

-(void)setUrl:(NSURL *)url {
    self->_url = url.absoluteString;
    
    if([self->_url rangeOfString:@"?"].location != NSNotFound) {
        self->_url = [self->_url substringToIndex:[self->_url rangeOfString:@"?"].location];
    }

    NSRegularExpression *regexExpression = [NSRegularExpression regularExpressionWithPattern:@"/pastebin/([^/.&?]+)" options:0 error:NULL];
    NSRange range = NSMakeRange(0, self->_url.length);
    NSTextCheckingResult *r = [regexExpression firstMatchInString:self->_url options:0 range:range];
    if(r.numberOfRanges == 2)
        self->_pasteID = [self->_url substringWithRange:[r rangeAtIndex:1]];
}


- (NSArray<id<UIPreviewActionItem>> *)previewActionItems {
    NSURL *url = [NSURL URLWithString:self->_url];
    
    return @[
                              [UIPreviewAction actionWithTitle:@"Copy URL" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                  UIPasteboard *pb = [UIPasteboard generalPasteboard];
                                  [pb setValue:self->_url forPasteboardType:(NSString *)kUTTypeUTF8PlainText];
                              }],
                              [UIPreviewAction actionWithTitle:@"Share" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                  UIApplication *app = [UIApplication sharedApplication];
                                  AppDelegate *appDelegate = (AppDelegate *)app.delegate;
                                  MainViewController *mainViewController = [appDelegate mainViewController];
                                  
                                  [UIColor clearTheme];
                                  UIActivityViewController *activityController = [URLHandler activityControllerForItems:@[url] type:@"Pastebin"];
                                  activityController.popoverPresentationController.sourceView = mainViewController.slidingViewController.view;
                                  [mainViewController.slidingViewController presentViewController:activityController animated:YES completion:nil];
                              }],
                              [UIPreviewAction actionWithTitle:@"Open in Browser" style:UIPreviewActionStyleDefault handler:^(UIPreviewAction * _Nonnull action, UIViewController * _Nonnull previewViewController) {
                                  if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Chrome"] && [[OpenInChromeController sharedInstance] openInChrome:url
                                                                                                                                                                          withCallbackURL:[NSURL URLWithString:
#ifdef ENTERPRISE
                                                                                                                                                                                           @"irccloud-enterprise://"
#else
                                                                                                                                                                                           @"irccloud://"
#endif
                                                                                                                                                                                           ]
                                                                                                                                                                             createNewTab:NO])
                                      return;
                                  else if([[[NSUserDefaults standardUserDefaults] objectForKey:@"browser"] isEqualToString:@"Firefox"] && [[OpenInFirefoxControllerObjC sharedInstance] openInFirefox:url])
                                      return;
                                  else
                                      [[UIApplication sharedApplication] openURL:url];
                              }]
                              ];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self->_activity startAnimating];
    self->_lineNumbers.enabled = NO;
    self->_lineNumbers.on = YES;
    [self _fetch];
    [FIRAnalytics logEventWithName:kFIREventViewItem parameters:@{
        kFIRParameterContentType:@"Pastebin"
    }];
    [self didMoveToParentViewController:nil];
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_doneButtonPressed)];
    self->_chrome = [[OpenInChromeController alloc] init];
    self.navigationController.navigationBar.clipsToBounds = YES;
    self.navigationController.navigationBar.barStyle = [UIColor isDarkTheme]?UIBarStyleBlack:UIBarStyleDefault;
    self.automaticallyAdjustsScrollViewInsets = NO;

    self->_lineNumbers = [[UISwitch alloc] initWithFrame:CGRectZero];
    self->_lineNumbers.on = YES;
    [self->_lineNumbers addTarget:self action:@selector(_toggleLineNumbers) forControlEvents:UIControlEventValueChanged];
    
    self->_lineNumbers.enabled = NO;
    [self->_lineNumbers sizeToFit];
    
    self->_webView.opaque = NO;
    self->_webView.backgroundColor = [UIColor contentBackgroundColor];
    self->_webView.scrollView.scrollsToTop = YES;
    
    self.view.backgroundColor = [UIColor contentBackgroundColor];
    
    if([UIColor isDarkTheme]) {
        self.navigationController.view.backgroundColor = [UIColor navBarColor];
        self->_activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
        [self->_toolbar setBackgroundImage:[UIColor navBarBackgroundImage] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
        [self->_toolbar setTintColor:[UIColor navBarSubheadingColor]];
    } else {
        self.navigationController.view.backgroundColor = [UIColor navBarColor];
        self->_activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    }
}

-(void)didMoveToParentViewController:(UIViewController *)parent {
    CGRect frame = self->_webView.frame;
    if(self.navigationController.navigationBarHidden) {
        self->_toolbar.hidden = YES;
        frame.size.height = self.view.frame.size.height - _webView.frame.origin.y;
    } else {
        self->_toolbar.hidden = NO;
        frame.size.height = self.view.frame.size.height - _webView.frame.origin.y - _toolbar.frame.size.height;
    }
    self->_webView.frame = frame;
}

-(void)_fetch {
    if([self->_url hasPrefix:[NSString stringWithFormat:@"https://%@/pastebin/", IRCCLOUD_HOST]] || [self->_url hasPrefix:@"https://www.irccloud.com/pastebin/"]) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        NSString *url = [[NetworkConnection sharedInstance].pasteURITemplate relativeStringWithVariables:@{@"id":self->_pasteID, @"type":@"json"} error:nil];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
        [request setHTTPShouldHandleCookies:NO];
        [request setValue:[NSString stringWithFormat:@"session=%@",NetworkConnection.sharedInstance.session] forHTTPHeaderField:@"Cookie"];

        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) {
                CLS_LOG(@"Error fetching pastebin. Error %li : %@", (long)error.code, error.userInfo);
            } else {
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
                self->_ownPaste = [[dict objectForKey:@"own_paste"] intValue] == 1;
            }
            NSURL *url = [NSURL URLWithString:[self->_url stringByAppendingFormat:@"?mobile=ios&version=%@&theme=%@&own_paste=%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [UIColor currentTheme], self->_ownPaste ? @"1" : @"0"]];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
            [request setHTTPShouldHandleCookies:NO];
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self->_webView loadRequest:request];

                if(self->_ownPaste) {
                    [self->_toolbar setItems:@[[[UIBarButtonItem alloc] initWithTitle:@"Line Numbers" style:UIBarButtonItemStylePlain target:self action:@selector(_toggleLineNumbersSwitch)],
                                               [[UIBarButtonItem alloc] initWithCustomView:self->_lineNumbers],
                                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(_editPaste)],
                                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(_removePaste)],
                                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonPressed:)]
                                               ]];
                } else {
                    [self->_toolbar setItems:@[[[UIBarButtonItem alloc] initWithTitle:@"Line Numbers" style:UIBarButtonItemStylePlain target:self action:@selector(_toggleLineNumbersSwitch)],
                                               [[UIBarButtonItem alloc] initWithCustomView:self->_lineNumbers],
                                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonPressed:)]
                                               ]];
                    
                }
            }];
        }] resume];
    }
}

-(void)_doneButtonPressed {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)_toggleLineNumbers {
    if(self->_lineNumbers.enabled)
        [self->_webView stringByEvaluatingJavaScriptFromString:@"window.PASTEVIEW.doToggleLines()"];
}

-(void)_toggleLineNumbersSwitch {
    if(self->_lineNumbers.enabled) {
        [self->_lineNumbers setOn:!_lineNumbers.on animated:YES];
        [self _toggleLineNumbers];
    }
}

-(void)_removePaste {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Snippet" message:@"Are you sure you want to delete this text snippet?" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [[NetworkConnection sharedInstance] deletePaste:self->_pasteID handler:nil];
        if(self.navigationController.viewControllers.count == 1)
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        else
            [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)_editPaste {
    [self.navigationController pushViewController:[[PastebinEditorViewController alloc] initWithPasteID:self->_pasteID] animated:YES];
    [self->_webView loadHTMLString:@"" baseURL:nil];
}

-(IBAction)shareButtonPressed:(id)sender {
    [UIColor clearTheme];
    UIActivityViewController *activityController = [URLHandler activityControllerForItems:@[[NSURL URLWithString:self->_url]] type:@"Pastebin"];
    activityController.popoverPresentationController.delegate = self;
    activityController.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:activityController animated:YES completion:nil];
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if(([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102) || ([error.domain isEqualToString:NSURLErrorDomain] && error.code == NSURLErrorCancelled))
        return;
    CLS_LOG(@"Error: %@", error);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self->_activity stopAnimating];
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if([request.URL.scheme isEqualToString:@"hide-spinner"]) {
        [self->_activity stopAnimating];
        self->_lineNumbers.enabled = YES;
        return NO;
    }
    return YES;
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
