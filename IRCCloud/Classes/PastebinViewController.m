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

@implementation PastebinViewController

-(id)initWithURL:(NSURL *)url {
    self = [super initWithNibName:@"PastebinViewController" bundle:nil];
    self.navigationItem.title = @"Pastebin";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(_doneButtonPressed)];
    _chrome = [[OpenInChromeController alloc] init];
    _url = url;
    
    for(NSURLQueryItem *item in [[NSURLComponents componentsWithString:_url.absoluteString] queryItems]) {
        if([item.name isEqualToString:@"id"])
            _pasteID = item.value;
        else if([item.name isEqualToString:@"own_paste"])
            _ownPaste = [item.value isEqualToString:@"1"];
    }
    return self;
}

-(void)viewDidLoad {
    [super viewDidLoad];
    
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 7) {
        [self.navigationController.navigationBar setBackgroundImage:[[UIImage imageNamed:@"navbar"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 1, 0)] forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.clipsToBounds = YES;
    }

    _lineNumbers = [[UISwitch alloc] initWithFrame:CGRectZero];
    _lineNumbers.on = YES;
    [_lineNumbers addTarget:self action:@selector(_toggleLineNumbers) forControlEvents:UIControlEventValueChanged];
    
    if(_ownPaste) {
        [_toolbar setItems:@[[[UIBarButtonItem alloc] initWithTitle:@"Line Numbers" style:UIBarButtonItemStylePlain target:self action:@selector(_toggleLineNumbersSwitch)],
                             [[UIBarButtonItem alloc] initWithCustomView:_lineNumbers],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(_removePaste)],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonPressed:)]
                             ]];
    } else {
        [_toolbar setItems:@[[[UIBarButtonItem alloc] initWithTitle:@"Line Numbers" style:UIBarButtonItemStylePlain target:self action:@selector(_toggleLineNumbersSwitch)],
                             [[UIBarButtonItem alloc] initWithCustomView:_lineNumbers],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                             [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareButtonPressed:)]
                             ]];
        
    }
    _lineNumbers.enabled = NO;
    [self performSelectorInBackground:@selector(_fetch) withObject:nil];
}

-(void)_fetch {
    NSData *data;
    NSURLResponse *response = nil;
    NSError *error = nil;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
    [request setHTTPShouldHandleCookies:NO];
    
    data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if(data) {
        NSMutableString *html = [[NSMutableString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding];
        
        [html replaceCharactersInRange:[html rangeOfString:@"</head>"] withString:@"<style>\
html, body, .mainContainer, .pasteContainer { width: 100% }\
body, div.paste { background-color: #fff; }\
h1#title, div#pasteSidebar, div.paste h1 { display: none; }\
.mainContainerFull, .mainContent, .mainContentPaste, div.paste { margin: 0px; padding: 0px; border: none; width: 100%; }\
</style></head>"];
        
        [html replaceCharactersInRange:[html rangeOfString:@"</body>"] withString:
         @"<script>window.PASTEVIEW.on('rendered', _.bind(function () { \
            var height = window.PASTEVIEW.ace.container.style.height;\
            height = height.substring(0, height.length - 2);\
            if(height < window.innerHeight) { window.PASTEVIEW.ace.container.style.height = window.innerHeight + \"px\"; }\
            $('div.pasteContainer').height(window.PASTEVIEW.ace.container.style.height);\
            location.href = \"hide-spinner:\";\
         }, window.PASTEVIEW));</script></body>"];
        
        [html replaceCharactersInRange:[html rangeOfString:@"https://js.stripe.com/v2"] withString:@""];
        [html replaceCharactersInRange:[html rangeOfString:@"https://checkout.stripe.com/v3/checkout.js"] withString:@""];
        [html replaceCharactersInRange:[html rangeOfString:@"https://platform.twitter.com/widgets.js"] withString:@""];
        [html replaceCharactersInRange:[html rangeOfString:@"https://platform.vine.co/static/scripts/embed.js"] withString:@""];
        [html replaceCharactersInRange:[html rangeOfString:@"https://connect.facebook.net/en_US/all.js#xfbml=1&status=0&appId=1524400614444110"] withString:@""];
        [html replaceCharactersInRange:[html rangeOfString:@"https://apis.google.com/js/plusone.js"] withString:@""];
        [html replaceCharactersInRange:[html rangeOfString:@"//rum-static.pingdom.net/prum.min.js"] withString:@""];
        [html replaceCharactersInRange:[html rangeOfString:@"window.IRCCloudAppMapSource ="] withString:@"window.IRCCloudAppMapSourceDisabled ="];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [_webView loadHTMLString:html baseURL:_url];
        }];
    }
}

-(void)_doneButtonPressed {
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
}

-(void)_toggleLineNumbers {
    if(_lineNumbers.enabled)
        [_webView stringByEvaluatingJavaScriptFromString:@"$('a.lines').click()"];
}

-(void)_toggleLineNumbersSwitch {
    if(_lineNumbers.enabled) {
        [_lineNumbers setOn:!_lineNumbers.on animated:YES];
        [self _toggleLineNumbers];
    }
}

-(void)_removePaste {
    [[NetworkConnection sharedInstance] deletePaste:_pasteID];
    [self.presentingViewController dismissModalViewControllerAnimated:YES];
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
        pb.items = @[@{(NSString *)kUTTypeUTF8PlainText:_url.absoluteString,
                       (NSString *)kUTTypeURL:_url}];
    } else if([title isEqualToString:@"Share on Twitter"]) {
        TWTweetComposeViewController *tweetViewController = [[TWTweetComposeViewController alloc] init];
        [tweetViewController setInitialText:_url.absoluteString];
        [tweetViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result) {
            [self dismissModalViewControllerAnimated:YES];
        }];
        [self presentModalViewController:tweetViewController animated:YES];
    } else if([title hasPrefix:@"Open "]) {
        [self _doneButtonPressed];
        [((AppDelegate *)[UIApplication sharedApplication].delegate) launchURL:_url];
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
    }
    return YES;
}

-(void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
