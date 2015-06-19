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
#import <Twitter/Twitter.h>
#import "PastebinViewController.h"
#import "NetworkConnection.h"
#import "ARChromeActivity.h"
#import "TUSafariActivity.h"
#import "AppDelegate.h"
#import "PastebinEditorViewController.h"

@implementation PastebinViewController

-(id)initWithURL:(NSURL *)url {
    self = [super initWithNibName:@"PastebinViewController" bundle:nil];
    self.navigationItem.title = @"Pastebin";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_doneButtonPressed)];
    _chrome = [[OpenInChromeController alloc] init];
    _url = url.absoluteString;

    if([_url rangeOfString:@"?"].location != NSNotFound) {
        NSString *query = [_url substringFromIndex:[_url rangeOfString:@"?"].location + 1];
        NSArray *args = [query componentsSeparatedByString:@"&"];
        for(NSString *arg in args) {
            NSArray *pair = [arg componentsSeparatedByString:@"="];
            
            if([[pair objectAtIndex:0] isEqualToString:@"id"])
                _pasteID = [pair objectAtIndex:1];
            else if([[pair objectAtIndex:0] isEqualToString:@"own_paste"])
                _ownPaste = [[pair objectAtIndex:1] isEqualToString:@"1"];
        }
        
        _url = [_url substringToIndex:[_url rangeOfString:@"?"].location];
    }
    
    return self;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if(!_metadataLabel.text.length) {
        [_activity startAnimating];
        _lineNumbers.enabled = NO;
        _lineNumbers.on = YES;
        [self _fetch];
    }
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.clipsToBounds = YES;
    } else {
        _titleLabel.textColor = [UIColor whiteColor];
        _metadataLabel.textColor = [UIColor whiteColor];
    }

    _lineNumbers = [[UISwitch alloc] initWithFrame:CGRectZero];
    _lineNumbers.on = YES;
    [_lineNumbers addTarget:self action:@selector(_toggleLineNumbers) forControlEvents:UIControlEventValueChanged];
    
    if(_ownPaste) {
        [_toolbar setItems:@[[[UIBarButtonItem alloc] initWithTitle:([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)?@"Line Numbers":@"Line #s" style:UIBarButtonItemStylePlain target:self action:@selector(_toggleLineNumbersSwitch)],
                             [[UIBarButtonItem alloc] initWithCustomView:_lineNumbers],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(_editPaste)],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(_removePaste)],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonPressed:)]
                             ]];
    } else {
        [_toolbar setItems:@[[[UIBarButtonItem alloc] initWithTitle:([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7)?@"Line Numbers":@"Line #s" style:UIBarButtonItemStylePlain target:self action:@selector(_toggleLineNumbersSwitch)],
                             [[UIBarButtonItem alloc] initWithCustomView:_lineNumbers],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonPressed:)]
                             ]];
        
    }
    _lineNumbers.enabled = NO;
    [_lineNumbers sizeToFit];
    
    _titleView.frame = CGRectMake(0,0,self.navigationController.navigationBar.frame.size.width - 120, self.navigationController.navigationBar.frame.size.height);

    [self _fetch];
}

-(void)_fetch {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[_url stringByAppendingFormat:@"?mobile=ios&version=%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
    [request setHTTPShouldHandleCookies:NO];
    [_webView loadRequest:request];
}

-(void)_doneButtonPressed {
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}

-(void)_toggleLineNumbers {
    if(_lineNumbers.enabled)
        [_webView stringByEvaluatingJavaScriptFromString:@"window.PASTEVIEW.doToggleLines()"];
}

-(void)_toggleLineNumbersSwitch {
    if(_lineNumbers.enabled) {
        [_lineNumbers setOn:!_lineNumbers.on animated:YES];
        [self _toggleLineNumbers];
    }
}

-(void)_removePaste {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete Pastebin" message:@"Are you sure you want to delete this pastebin?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Delete", nil];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Delete"]) {
        [[NetworkConnection sharedInstance] deletePaste:_pasteID];
        if(self.navigationController.viewControllers.count == 1)
            [self.presentingViewController dismissModalViewControllerAnimated:YES];
        else
            [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)_editPaste {
    [self.navigationController pushViewController:[[PastebinEditorViewController alloc] initWithPasteID:_pasteID] animated:YES];
    self.navigationItem.titleView = nil;
    _metadataLabel.text = @"";
    [_webView loadHTMLString:@"" baseURL:nil];
}

-(IBAction)shareButtonPressed:(id)sender {
    if(NSClassFromString(@"UIActivityViewController")) {
        UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[_url] applicationActivities:@[([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [_chrome isChromeInstalled])?[[ARChromeActivity alloc] initWithCallbackURL:[NSURL URLWithString:
#ifdef ENTERPRISE
                                                                                                                                                                                                                                                                                                                                         @"irccloud-enterprise://"
#else
                                                                                                                                                                                                                                                                                                                                         @"irccloud://"
#endif
                                                                                                                                                                                                                                                                                                                                         ]]:[[TUSafariActivity alloc] init]]];
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8) {
            activityController.popoverPresentationController.delegate = self;
            activityController.popoverPresentationController.barButtonItem = sender;
        }
        [self presentViewController:activityController animated:YES completion:nil];
    } else {
        UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Copy To Clipboard", @"Share on Twitter", ([[NSUserDefaults standardUserDefaults] boolForKey:@"useChrome"] && [_chrome isChromeInstalled])?@"Open In Chrome":@"Open In Safari",nil];
        [sheet showFromToolbar:_toolbar];
    }
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if([title isEqualToString:@"Copy To Clipboard"]) {
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        pb.items = @[@{(NSString *)kUTTypeUTF8PlainText:_url,
                       (NSString *)kUTTypeURL:[NSURL URLWithString:_url]}];
    } else if([title isEqualToString:@"Share on Twitter"]) {
        TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
        [tweetViewController setInitialText:_url];
        [tweetViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
            [self dismissModalViewControllerAnimated:YES];
        }];
        [self presentModalViewController:tweetViewController animated:YES];
    } else if([title hasPrefix:@"Open "]) {
        [self _doneButtonPressed];
        [((AppDelegate *)[UIApplication sharedApplication].delegate) launchURL:[NSURL URLWithString:_url]];
    }
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102)
        return;
    NSLog(@"Error: %@", error);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [_activity stopAnimating];
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if([request.URL.scheme isEqualToString:@"hide-spinner"]) {
        [_activity stopAnimating];
        _lineNumbers.enabled = YES;
        return NO;
    } else if([request.URL.scheme isEqualToString:@"set-title"]) {
        NSString *url = request.URL.absoluteString;
        NSUInteger start = [url rangeOfString:@":"].location + 1;
        NSUInteger end = [url rangeOfString:@"&"].location;
        if(start != end)
            _titleLabel.text = [[url substringWithRange:NSMakeRange(start, end - start)] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        else
            _titleLabel.text = @"Pastebin";
        self.navigationItem.title = _titleLabel.text;
        _metadataLabel.text = [[[url substringFromIndex:end + 1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"%u2022" withString:@"•"];
        self.navigationItem.titleView = _titleView;
        return NO;
    }
    return YES;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    _titleView.frame = CGRectMake(0,0,self.navigationController.navigationBar.frame.size.width - 120, self.navigationController.navigationBar.frame.size.height);
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
