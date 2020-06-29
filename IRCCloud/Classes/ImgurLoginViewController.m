//
//  ImgurLoginViewController.m
//
//  Copyright (C) 2014 IRCCloud, Ltd.
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

#import "ImgurLoginViewController.h"
#import "UIColor+IRCCloud.h"
#import "config.h"

@implementation ImgurLoginViewController

- (id)init {
    self = [super init];
    if (self) {
        self.navigationItem.title = @"Login to Imgur";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.clipsToBounds = YES;
    self.navigationController.navigationBar.barStyle = [UIColor isDarkTheme]?UIBarStyleBlack:UIBarStyleDefault;
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
    self.view.backgroundColor = [UIColor blackColor];
    self->_webView = [[UIWebView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width, self.view.frame.size.height)];
    self->_webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self->_webView.backgroundColor = [UIColor blackColor];
    self->_webView.delegate = self;
#ifdef IMGUR_KEY
    [self->_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://api.imgur.com/oauth2/authorize?client_id=%@&response_type=token", @IMGUR_KEY]]]];
#endif
    [self.view addSubview:self->_webView];
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
    [self->_activity stopAnimating];
}

-(void)webViewDidStartLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [self->_activity startAnimating];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [self->_activity stopAnimating];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [self.view endEditing:YES];
    if([request.URL.host isEqualToString:@"imgur.com"]) {
        if([request.URL.fragment hasPrefix:@"access_token="]) {
            for(NSString *param in [request.URL.fragment componentsSeparatedByString:@"&"]) {
                NSArray *p = [param componentsSeparatedByString:@"="];
                NSString *name = [p objectAtIndex:0];
                NSString *value = [p objectAtIndex:1];
                [[NSUserDefaults standardUserDefaults] setObject:value forKey:[NSString stringWithFormat:@"imgur_%@", name]];
            }
            [[NSUserDefaults standardUserDefaults] synchronize];
#ifdef ENTERPRISE
            NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.enterprise.share"];
#else
            NSUserDefaults *d = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.irccloud.share"];
#endif
            if([[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_access_token"])
                [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_access_token"] forKey:@"imgur_access_token"];
            else
                [d removeObjectForKey:@"imgur_access_token"];
            if([[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_refresh_token"])
                [d setObject:[[NSUserDefaults standardUserDefaults] objectForKey:@"imgur_refresh_token"] forKey:@"imgur_refresh_token"];
            else
                [d removeObjectForKey:@"imgur_refresh_token"];
            [d synchronize];
            [self.navigationController popViewControllerAnimated:YES];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            return NO;
        } else if([request.URL.query isEqualToString:@"error=access_denied"]) {
            [self.navigationController popViewControllerAnimated:YES];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            return NO;
        } else {
            return YES;
        }
    }
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
