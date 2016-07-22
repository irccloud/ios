//
//  SamlLoginViewController.m
//
//  Copyright (C) 2016 IRCCloud, Ltd.
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

#import "SamlLoginViewController.h"
#import "NetworkConnection.h"
#import "AppDelegate.h"

@implementation SamlLoginViewController

- (id)initWithURL:(NSString *)url {
    self = [super init];
    if (self) {
        _url = [NSURL URLWithString:url];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
    if (cookies != nil && cookies.count > 0) {
        for (NSHTTPCookie *cookie in cookies) {
            [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    _activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _activity.hidesWhenStopped = YES;
    [_activity startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_activity];
    _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, self.view.frame.size.height)];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _webView.delegate = self;
    [_webView loadRequest:[NSURLRequest requestWithURL:_url]];
    [self.view addSubview:_webView];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102)
        return;
    NSLog(@"Error: %@", error);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [_activity stopAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:_activity];
    [_activity startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [_activity stopAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [self.view endEditing:YES];
    if([request.URL.host isEqualToString:IRCCLOUD_HOST] && [request.URL.path isEqualToString:@"/"]) {
        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
        if (cookies != nil && cookies.count > 0) {
            for (NSHTTPCookie *cookie in cookies) {
                if([cookie.name isEqualToString:@"session"]) {
                    [NetworkConnection sharedInstance].session = cookie.value;
                    [[NSUserDefaults standardUserDefaults] setObject:IRCCLOUD_HOST forKey:@"host"];
                    [[NSUserDefaults standardUserDefaults] setObject:IRCCLOUD_PATH forKey:@"path"];
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"greeting_3.0"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
#ifdef ENTERPRISE
                    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
                    NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
                    [d setObject:IRCCLOUD_HOST forKey:@"host"];
                    [d setObject:IRCCLOUD_PATH forKey:@"path"];
                    [d synchronize];
                    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
                        [((AppDelegate *)([UIApplication sharedApplication].delegate)) showMainView:YES];
                    }];
                }
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        return NO;
    }
    return YES;
}

- (void)cancelButtonPressed:(id)sender {
    [_webView stopLoading];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
