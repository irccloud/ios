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
        self->_url = [NSURL URLWithString:url];
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
    self->_activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self->_activity.hidesWhenStopped = YES;
    [self->_activity startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self->_activity];

    WKPreferences *prefs = [[WKPreferences alloc] init];
    prefs.javaScriptEnabled = YES;
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.preferences = prefs;
    
    self->_webView = [[WKWebView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, self.view.frame.size.height) configuration:config];
    self->_webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self->_webView.navigationDelegate = self;
    [self->_webView loadRequest:[NSURLRequest requestWithURL:self->_url]];
    [self.view addSubview:self->_webView];
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.view endEditing:YES];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    CLS_LOG(@"Error: %@", error);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self->_activity stopAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
}

-(void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self->_activity];
    [self->_activity startAnimating];
}

-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self->_activity stopAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    [self.view endEditing:YES];
    if([navigationAction.request.URL.host isEqualToString:IRCCLOUD_HOST] && [navigationAction.request.URL.path isEqualToString:@"/"]) {
        [[WKWebsiteDataStore defaultDataStore].httpCookieStore getAllCookies:^(NSArray *cookies) {
                    if (cookies != nil && cookies.count > 0) {
                        for (NSHTTPCookie *cookie in cookies) {
                            if([cookie.name isEqualToString:@"session"]) {
                                [NetworkConnection sharedInstance].session = cookie.value;
                                [[NSUserDefaults standardUserDefaults] setObject:IRCCLOUD_HOST forKey:@"host"];
                                [[NSUserDefaults standardUserDefaults] setObject:IRCCLOUD_PATH forKey:@"path"];
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
                            [[WKWebsiteDataStore defaultDataStore].httpCookieStore deleteCookie:cookie completionHandler:nil];
                        }
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                    decisionHandler(WKNavigationActionPolicyCancel);
        }];
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)cancelButtonPressed:(id)sender {
    [self->_webView stopLoading];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
